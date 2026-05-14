"""Indent-aware line-oriented tokenizer for agent-lang v0.6.

Pipeline: text → list[Token].

Token kinds:
    DECL              flow | agent | code | set
    IDENT             snake_case identifier
    COLON             ':'
    INLINE_VALUE      free text after ``key:`` until end of line
    BLOCK_SCALAR_OPEN '|' marker
    BLOCK_SCALAR_BODY captured multi-line text (already dedented)
    LIST_ITEM_DASH    '- ' bullet at line start
    CONTROL           parallel | each <X> | if <expr> | else
    COMMENT           '# ...' to end of line (preserved as token; serializer can drop)
    NEWLINE           end of logical line
    INDENT / DEDENT   indentation change (relative to outer block)
    EOF

Indentation contract: 2 spaces per level, tabs forbidden (raises LexError).
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Iterator

from al.parser.errors import LexError


# ---------------------------------------------------------------------------
# Token dataclass
# ---------------------------------------------------------------------------


@dataclass
class Token:
    """Single lexical token. ``indent`` = number of leading spaces."""

    kind: str
    text: str
    line: int
    col: int
    indent: int = 0


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DECLARATORS = {"flow", "agent", "code", "set"}
CONTROL_HEADS = {"parallel", "each", "if", "else"}

_IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


# ---------------------------------------------------------------------------
# Public entry
# ---------------------------------------------------------------------------


def tokenize(source: str) -> list[Token]:
    """Tokenize ``source`` text into a flat list of :class:`Token`.

    Block scalars are pre-collected: the ``BLOCK_SCALAR_BODY`` token text
    is the dedented multi-line body, ready for AST consumption.
    """
    lines = source.splitlines()
    tokens: list[Token] = []

    i = 0
    while i < len(lines):
        raw = lines[i]
        lineno = i + 1

        # Skip blank lines (still emit NEWLINE for serializer fidelity? v1: skip).
        if not raw.strip():
            i += 1
            continue

        # Tab check.
        if "\t" in raw:
            tab_col = raw.index("\t") + 1
            raise LexError("tabs are forbidden; use 2 spaces per indent", lineno, tab_col)

        indent = _leading_spaces(raw)
        if indent % 2 != 0:
            raise LexError(
                f"indent must be a multiple of 2 spaces (got {indent})",
                lineno,
                1,
            )

        body = raw[indent:]

        # Whole-line comment.
        if body.startswith("#"):
            tokens.append(Token("COMMENT", body, lineno, indent + 1, indent))
            i += 1
            continue

        # List item: ``- ...``.
        if body.startswith("- "):
            tokens.append(Token("LIST_ITEM_DASH", "-", lineno, indent + 1, indent))
            # Tokenize what's after the dash on the same line.
            after_dash = body[2:]
            _emit_inline_or_header(after_dash, lineno, indent + 2, tokens)
            tokens.append(Token("NEWLINE", "", lineno, len(raw) + 1, indent))
            i += 1
            continue

        # Block scalar opener: ``key: |`` (handle here to capture body).
        m = re.match(r"([a-z_][a-z0-9_]*)\s*:\s*\|\s*(?:#.*)?$", body)
        if m:
            key = m.group(1)
            tokens.append(Token("IDENT", key, lineno, indent + 1, indent))
            tokens.append(Token("COLON", ":", lineno, indent + 1 + len(key), indent))
            tokens.append(Token("BLOCK_SCALAR_OPEN", "|", lineno, indent + 1, indent))
            # Collect body — every subsequent line whose indent > the introducing line's.
            body_lines: list[str] = []
            j = i + 1
            base_indent = indent  # the key's indent
            while j < len(lines):
                lr = lines[j]
                if not lr.strip():
                    body_lines.append("")
                    j += 1
                    continue
                lr_indent = _leading_spaces(lr)
                if lr_indent <= base_indent:
                    break
                body_lines.append(lr)
                j += 1
            # Trim trailing blank lines.
            while body_lines and body_lines[-1] == "":
                body_lines.pop()
            dedented = _dedent_block(body_lines)
            tokens.append(
                Token(
                    "BLOCK_SCALAR_BODY",
                    dedented,
                    lineno + 1,
                    1,
                    base_indent + 2,
                )
            )
            tokens.append(Token("NEWLINE", "", j, 1, indent))
            i = j
            continue

        # Top-level declarator: ``flow|agent|code|set <name>:``
        m = re.match(r"(flow|agent|code|set)\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?:#.*)?$", body)
        if m and indent == 0:
            decl, name = m.group(1), m.group(2)
            tokens.append(Token("DECL", decl, lineno, 1, 0))
            tokens.append(Token("IDENT", name, lineno, len(decl) + 2, 0))
            tokens.append(Token("COLON", ":", lineno, len(decl) + 2 + len(name), 0))
            tokens.append(Token("NEWLINE", "", lineno, len(raw) + 1, 0))
            i += 1
            continue

        # ``key:`` (no inline value, no | — opens nested block / list / group).
        m = re.match(r"([a-z_][a-z0-9_]*)\s*:\s*(?:#.*)?$", body)
        if m:
            key = m.group(1)
            tokens.append(Token("IDENT", key, lineno, indent + 1, indent))
            tokens.append(Token("COLON", ":", lineno, indent + 1 + len(key), indent))
            tokens.append(Token("NEWLINE", "", lineno, len(raw) + 1, indent))
            i += 1
            continue

        # ``key: value`` — inline.
        m = re.match(r"([a-z_][a-z0-9_]*)\s*:\s*(.+?)\s*(?:#.*)?$", body)
        if m:
            key, val = m.group(1), m.group(2).rstrip()
            tokens.append(Token("IDENT", key, lineno, indent + 1, indent))
            tokens.append(Token("COLON", ":", lineno, indent + 1 + len(key), indent))
            tokens.append(
                Token("INLINE_VALUE", val, lineno, indent + len(key) + 3, indent)
            )
            tokens.append(Token("NEWLINE", "", lineno, len(raw) + 1, indent))
            i += 1
            continue

        # Bare control header at non-list position? Not legal in v1 grammar.
        raise LexError(
            f"could not lex line: {raw!r}",
            lineno,
            indent + 1,
        )

    tokens.append(Token("EOF", "", len(lines) + 1, 1, 0))
    return tokens


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _leading_spaces(s: str) -> int:
    """Number of leading space characters in ``s``."""
    n = 0
    for ch in s:
        if ch == " ":
            n += 1
        else:
            break
    return n


def _dedent_block(lines: list[str]) -> str:
    """Strip the minimum common leading whitespace across non-empty lines.

    Mirrors YAML literal block dedent rule. Empty lines are preserved as
    empty strings in the result.
    """
    non_empty = [ln for ln in lines if ln.strip()]
    if not non_empty:
        return ""
    min_indent = min(_leading_spaces(ln) for ln in non_empty)
    out: list[str] = []
    for ln in lines:
        if not ln.strip():
            out.append("")
        else:
            out.append(ln[min_indent:])
    return "\n".join(out)


def _emit_inline_or_header(
    after_dash: str, lineno: int, col: int, tokens: list[Token]
) -> None:
    """Tokenize the text following ``-`` on a list item line.

    Produces either:
      * a CONTROL token (parallel / each X / if X / else) followed by COLON, or
      * an IDENT token (bare name reference), or
      * an IDENT + COLON + INLINE_VALUE triple if it's an inline ``key: value``
        inside a list (rare but supported).
    """
    after_dash = after_dash.rstrip()
    if not after_dash:
        # ``-`` alone (followed by nested block on next line). v1: not used.
        return

    # parallel:
    m = re.match(r"(parallel)\s*:\s*$", after_dash)
    if m:
        tokens.append(Token("CONTROL", "parallel", lineno, col, col - 1))
        tokens.append(Token("COLON", ":", lineno, col + len("parallel"), col - 1))
        return

    # each <name>:
    m = re.match(r"each\s+([a-z_][a-z0-9_]*)\s*:\s*$", after_dash)
    if m:
        binding = m.group(1)
        tokens.append(Token("CONTROL", f"each {binding}", lineno, col, col - 1))
        tokens.append(Token("COLON", ":", lineno, col + len("each ") + len(binding), col - 1))
        return

    # if <expr>:
    m = re.match(r"if\s+(.+?)\s*:\s*$", after_dash)
    if m:
        cond = m.group(1).strip()
        tokens.append(Token("CONTROL", f"if {cond}", lineno, col, col - 1))
        tokens.append(Token("COLON", ":", lineno, col + len("if ") + len(cond), col - 1))
        return

    # else:
    m = re.match(r"else\s*:\s*$", after_dash)
    if m:
        tokens.append(Token("CONTROL", "else", lineno, col, col - 1))
        tokens.append(Token("COLON", ":", lineno, col + len("else"), col - 1))
        return

    # bare ident (a node reference)
    m = _IDENT_RE.match(after_dash)
    if m and m.end() == len(after_dash):
        tokens.append(Token("IDENT", after_dash, lineno, col, col - 1))
        return

    # otherwise treat as inline text reference (lenient)
    tokens.append(Token("INLINE_VALUE", after_dash, lineno, col, col - 1))


def iter_tokens(tokens: list[Token]) -> Iterator[Token]:
    """Plain iterator helper used by parser tests."""
    yield from tokens
