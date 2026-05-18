"""Recursive-descent parser for agent-lang v0.7.

Consumes tokens from :mod:`al.parser.tokenizer` and produces an AST
rooted at :class:`al.parser.ast_nodes.Program`.

Function naming convention: ``parse_<rule>`` mirrors the grammar in
``docs/al-spec.md`` § 4.

Disambiguation table for ``key:`` (no inline value):
    next significant tokens are                  → produce
    --------------------------------------------- ---------------
    LIST_ITEM_DASH series                          StepList (if key=='steps')
                                                   ReferenceList (if key in tools/skills/extensions/use)
    IDENT COLON ... at deeper indent               FieldGroup (nested key:value)
    BLOCK_SCALAR_BODY                              BlockScalar (already opened by tokenizer)

v0.7 additions handled here:
- ``import`` / ``from`` top-level decls (parsed before first Definition)
- ``T(description)`` inline values for ``input:`` / ``output:``
- ``- return <ref>`` step item

See docs/design/parser.md § 4 for full design notes.
"""

from __future__ import annotations

import re

from al.parser.errors import ParseError
from al.parser.tokenizer import Token, tokenize
from al.parser.ast_nodes import (
    Program,
    Definition,
    Field,
    ImportDecl,
    InlineText,
    TypedAnnotation,
    BlockScalar,
    FieldGroup,
    StepList,
    Reference,
    ReferenceList,
    RefStep,
    ParallelStep,
    EachStep,
    IfStep,
    ReturnStep,
    Loc,
    FIELD_VALUE_HINTS,
)


# Pattern for splitting ``T(description)`` in input/output inline values.
# The ``type_ann`` part is greedy up to the LAST '(' that has a matching
# ')' at end-of-string. We use a non-greedy capture for type_ann and let
# the optional ``(description)`` consume everything between the LAST
# unmatched paren and the closing one. Simpler heuristic: split on the
# first '(' whose matching ')' is at the very end of the string.
_IO_SPLIT_RE = re.compile(r"^\s*(?P<ann>[^(]+?)\s*(?:\((?P<desc>.*)\))?\s*$", re.DOTALL)


# ---------------------------------------------------------------------------
# Public entry
# ---------------------------------------------------------------------------


def parse(source: str) -> Program:
    """Parse ``source`` text and return the AST root :class:`Program`.

    Raises :class:`al.parser.errors.ParseError` on grammar errors
    or :class:`al.parser.errors.LexError` on tokenization errors.
    """
    tokens = tokenize(source)
    p = _Parser(tokens)
    return p.parse_program()


# ---------------------------------------------------------------------------
# Internal parser state
# ---------------------------------------------------------------------------


class _Parser:
    """Mutable cursor over the token stream. Hand-written recursive descent."""

    REFERENCE_FIELDS = {"fallback", "use"}
    REFERENCE_LIST_FIELDS = {"tools", "skills", "extensions", "uses"}
    # v0.7: keys whose inline value parses as TypedAnnotation
    # (``T(description)`` form). Also applied to nested FieldGroup leaves
    # via the same code path so ``output: { title: str(headline) }`` works.
    TYPED_ANNOTATION_FIELDS = {"input", "output"}

    def __init__(self, tokens: list[Token]) -> None:
        self.tokens = [t for t in tokens if t.kind not in {"COMMENT"}]  # drop comments for now
        self.pos = 0

    # ------------------------------------------------------------------
    # Cursor primitives
    # ------------------------------------------------------------------

    def peek(self, k: int = 0) -> Token:
        """Look ahead ``k`` tokens; out-of-bounds returns EOF."""
        i = self.pos + k
        if i >= len(self.tokens):
            return self.tokens[-1]
        return self.tokens[i]

    def take(self) -> Token:
        """Consume current token and advance."""
        t = self.tokens[self.pos]
        self.pos += 1
        return t

    def expect(self, kind: str, what: str = "") -> Token:
        """Assert current token is ``kind`` and consume."""
        t = self.peek()
        if t.kind != kind:
            raise ParseError(
                f"expected {kind}{(' (' + what + ')') if what else ''}, got {t.kind} {t.text!r}",
                t.line,
                t.col,
            )
        return self.take()

    def skip_newlines(self) -> None:
        """Eat any number of NEWLINE tokens."""
        while self.peek().kind == "NEWLINE":
            self.take()

    # ------------------------------------------------------------------
    # Top level
    # ------------------------------------------------------------------

    def parse_program(self) -> Program:
        """``Program ::= ImportDecl* Definition*`` (v0.7).

        Imports MUST appear before the first Definition. Anything after
        a Definition that looks like an import is a ParseError.
        """
        imports: list[ImportDecl] = []
        defs: list[Definition] = []
        self.skip_newlines()
        first = self.peek()
        # v0.7: collect leading imports.
        while self.peek().kind == "IMPORT_DECL":
            imports.append(self._parse_import())
            self.skip_newlines()
        while self.peek().kind != "EOF":
            self.skip_newlines()
            t = self.peek()
            if t.kind == "EOF":
                break
            if t.kind == "IMPORT_DECL":
                raise ParseError(
                    "import declarations must appear before the first "
                    "flow/code/agent/set/preamble definition",
                    t.line,
                    t.col,
                )
            defs.append(self.parse_definition())
        return Program(defs=defs, imports=imports, loc=Loc(first.line, first.col))

    def _parse_import(self) -> ImportDecl:
        """Parse ``import X``, ``import X as Y``, ``from X import Y[, Z]``.

        The tokenizer captures the whole line as one IMPORT_DECL token
        whose ``text`` is everything from ``import``/``from`` to EOL.
        """
        tok = self.take()  # IMPORT_DECL
        # Optional trailing NEWLINE produced by tokenizer.
        if self.peek().kind == "NEWLINE":
            self.take()
        text = tok.text.strip()
        if text.startswith("import "):
            rest = text[len("import "):].strip()
            m = re.match(r"^([A-Za-z_][\w.]*)(?:\s+as\s+([A-Za-z_]\w*))?\s*$", rest)
            if not m:
                raise ParseError(
                    f"malformed import: {text!r}", tok.line, tok.col,
                )
            return ImportDecl(
                kind="import",
                module=m.group(1),
                names=[],
                alias=m.group(2),
                loc=Loc(tok.line, tok.col),
            )
        if text.startswith("from "):
            rest = text[len("from "):].strip()
            # v0.7.1: accept Python-style relative imports.
            # ``from . import X`` / ``from .. import X`` / ``from .pkg import X``
            # as well as the original absolute form ``from pkg.sub import X``.
            # Module part = optional leading dots + optional dotted identifier
            # path, but at least one of the two must be present.
            m = re.match(
                r"^(\.+|\.*[A-Za-z_][\w.]*)\s+import\s+(.+?)\s*$", rest,
            )
            if not m:
                raise ParseError(
                    f"malformed from-import: {text!r}", tok.line, tok.col,
                )
            module = m.group(1)
            names = [n.strip() for n in m.group(2).split(",") if n.strip()]
            if not names:
                raise ParseError(
                    f"from-import has empty name list: {text!r}",
                    tok.line, tok.col,
                )
            for n in names:
                if not re.fullmatch(r"[A-Za-z_]\w*", n):
                    raise ParseError(
                        f"invalid name in from-import: {n!r}",
                        tok.line, tok.col,
                    )
            return ImportDecl(
                kind="from",
                module=module,
                names=names,
                alias=None,
                loc=Loc(tok.line, tok.col),
            )
        raise ParseError(
            f"unrecognized import form: {text!r}", tok.line, tok.col,
        )

    # ------------------------------------------------------------------
    # Definition
    # ------------------------------------------------------------------

    def parse_definition(self) -> Definition:
        """``Definition ::= ('flow'|'agent'|'code'|'set'|'preamble') IDENT ':' NEWLINE Field*``

        Phase 1.AL.2: ``preamble`` added as a 5th declarator for
        module-level Python context (see ``docs/preamble-design.md``).
        """
        decl = self.expect("DECL", "flow|agent|code|set|preamble")
        name_tok = self.expect("IDENT", "definition name")
        self.expect("COLON", "after definition header")
        self.expect("NEWLINE")

        fields: list[Field] = []
        # Fields are everything indented > 0 until next DECL/IMPORT_DECL/EOF.
        while True:
            self.skip_newlines()
            t = self.peek()
            if t.kind in {"DECL", "EOF"}:
                break
            if t.kind == "IMPORT_DECL":
                # v0.7: surface this with a spec-correct message; the parser
                # state then unwinds to parse_program which re-raises the
                # actual "must appear before" error.
                raise ParseError(
                    "import declarations must appear before the first "
                    "flow/code/agent/set/preamble definition",
                    t.line, t.col,
                )
            if t.kind == "IDENT" and t.indent > 0:
                fields.append(self.parse_field(parent_indent=0))
            else:
                # tolerant: skip stray
                if t.kind == "EOF":
                    break
                raise ParseError(
                    f"unexpected token {t.kind} {t.text!r} inside definition '{name_tok.text}'",
                    t.line,
                    t.col,
                )

        return Definition(
            kind=decl.text,  # type: ignore[arg-type]
            name=name_tok.text,
            fields=fields,
            loc=Loc(decl.line, decl.col),
        )

    # ------------------------------------------------------------------
    # Field
    # ------------------------------------------------------------------

    def parse_field(self, parent_indent: int) -> Field:
        """``Field ::= IDENT ':' (inline | '|' body | NEWLINE nested)``"""
        key_tok = self.expect("IDENT", "field key")
        self.expect("COLON")
        next_t = self.peek()

        # Inline value: ``key: value\n``
        if next_t.kind == "INLINE_VALUE":
            val_tok = self.take()
            self.expect("NEWLINE")
            value = self._build_inline_value(key_tok.text, val_tok)
            return Field(name=key_tok.text, value=value, loc=Loc(key_tok.line, key_tok.col))

        # Block scalar: tokenizer already produced BLOCK_SCALAR_OPEN+BODY pair.
        if next_t.kind == "BLOCK_SCALAR_OPEN":
            self.take()  # consume |
            body = self.expect("BLOCK_SCALAR_BODY", "block scalar body")
            self.expect("NEWLINE")
            return Field(
                name=key_tok.text,
                value=BlockScalar(text=body.text, loc=Loc(body.line, body.col)),
                loc=Loc(key_tok.line, key_tok.col),
            )

        # Bare ``key:\n`` — opens nested block / list / group.
        if next_t.kind == "NEWLINE":
            self.take()
            return Field(
                name=key_tok.text,
                value=self._parse_field_body(key_tok),
                loc=Loc(key_tok.line, key_tok.col),
            )

        raise ParseError(
            f"after '{key_tok.text}:' expected value, '|' or newline; got {next_t.kind}",
            next_t.line,
            next_t.col,
        )

    def _build_inline_value(self, key: str, val_tok: Token):
        """Build a FieldValue for an inline ``key: value``.

        Reference-typed keys (``fallback``, single-value ``use``) become
        :class:`Reference`; ``input`` / ``output`` (v0.7) become
        :class:`TypedAnnotation` with the ``(description)`` suffix split
        out when present; everything else becomes :class:`InlineText`.
        """
        text = val_tok.text
        if key in self.REFERENCE_FIELDS and _is_bare_ident(text):
            return Reference(name=text, loc=Loc(val_tok.line, val_tok.col))
        if key in self.TYPED_ANNOTATION_FIELDS:
            return _build_typed_annotation(text, val_tok)
        return InlineText(text=text, loc=Loc(val_tok.line, val_tok.col))

    def _parse_field_body(self, key_tok: Token):
        """Parse the body of a ``key:`` line (no inline value).

        Distinguishes list / group / block by the next significant token's
        kind and the field's name.
        """
        t = self.peek()

        # Reference-list keys: tools / skills / extensions / use(list form)
        if key_tok.text in self.REFERENCE_LIST_FIELDS or (
            key_tok.text == "use" and t.kind == "LIST_ITEM_DASH"
        ):
            names = self._collect_reference_list(parent_indent=key_tok.indent)
            return ReferenceList(names=names, loc=Loc(key_tok.line, key_tok.col))

        # steps: → StepList
        if key_tok.text == "steps":
            items = self._collect_step_list(parent_indent=key_tok.indent)
            return StepList(items=items, loc=Loc(key_tok.line, key_tok.col))

        # Heuristic: a list of dashes at deeper indent → ReferenceList (lenient default)
        if t.kind == "LIST_ITEM_DASH":
            names = self._collect_reference_list(parent_indent=key_tok.indent)
            return ReferenceList(names=names, loc=Loc(key_tok.line, key_tok.col))

        # Otherwise nested key: value group
        if t.kind == "IDENT" and t.indent > key_tok.indent:
            sub_fields = self._collect_field_group(parent_indent=key_tok.indent)
            return FieldGroup(fields=sub_fields, loc=Loc(key_tok.line, key_tok.col))

        raise ParseError(
            f"empty body for field '{key_tok.text}'",
            key_tok.line,
            key_tok.col,
        )

    # ------------------------------------------------------------------
    # Collectors
    # ------------------------------------------------------------------

    def _collect_field_group(self, parent_indent: int) -> list[Field]:
        """Collect nested fields with indent > ``parent_indent``."""
        out: list[Field] = []
        while True:
            self.skip_newlines()
            t = self.peek()
            if t.kind != "IDENT" or t.indent <= parent_indent:
                break
            out.append(self.parse_field(parent_indent=t.indent))
        return out

    def _collect_reference_list(self, parent_indent: int) -> list[str]:
        """Collect a list of bare-name references following dashes."""
        out: list[str] = []
        while True:
            self.skip_newlines()
            t = self.peek()
            if t.kind != "LIST_ITEM_DASH" or t.indent <= parent_indent:
                break
            self.take()  # consume dash
            it = self.peek()
            if it.kind != "IDENT":
                raise ParseError(
                    f"expected bare reference after '-', got {it.kind} {it.text!r}",
                    it.line,
                    it.col,
                )
            out.append(self.take().text)
            self.expect("NEWLINE")
        return out

    def _collect_step_list(self, parent_indent: int):
        """Collect step items (Ref / Parallel / Each / If)."""
        out = []
        while True:
            self.skip_newlines()
            t = self.peek()
            if t.kind != "LIST_ITEM_DASH" or t.indent <= parent_indent:
                break
            out.append(self._parse_step_item())
        return out

    def _parse_step_item(self):
        """Parse a single step item starting at LIST_ITEM_DASH."""
        dash = self.expect("LIST_ITEM_DASH")
        t = self.peek()

        # bare reference: ``- foo``
        if t.kind == "IDENT":
            name_tok = self.take()
            self.expect("NEWLINE")
            return RefStep(name=name_tok.text, loc=Loc(dash.line, dash.col))

        # control: ``- parallel:`` / ``- each X:`` / ``- if X:`` / ``- else:`` / ``- return X``
        if t.kind == "CONTROL":
            ctrl = self.take()
            # v0.7: ``- return <ref>`` is a single-line step (no colon,
            # no nested body). Handle before the COLON expect.
            if ctrl.text.startswith("return "):
                target = ctrl.text.split(maxsplit=1)[1].strip()
                if not _is_bare_ident(target):
                    raise ParseError(
                        f"return target must be a bare reference, got {target!r}",
                        ctrl.line, ctrl.col,
                    )
                self.expect("NEWLINE")
                return ReturnStep(target=target, loc=Loc(dash.line, dash.col))
            self.expect("COLON")
            self.expect("NEWLINE")

            if ctrl.text == "parallel":
                items = self._collect_step_list(parent_indent=dash.indent)
                return ParallelStep(items=items, loc=Loc(dash.line, dash.col))
            if ctrl.text.startswith("each "):
                binding = ctrl.text.split(maxsplit=1)[1]
                items = self._collect_step_list(parent_indent=dash.indent)
                return EachStep(
                    binding=binding,
                    items=items,
                    loc=Loc(dash.line, dash.col),
                )
            if ctrl.text.startswith("if "):
                cond = ctrl.text.split(maxsplit=1)[1]
                then_items = self._collect_step_list(parent_indent=dash.indent)
                else_items = None
                # peek for ``else:`` at same indent
                self.skip_newlines()
                np = self.peek()
                if (
                    np.kind == "LIST_ITEM_DASH"
                    and np.indent == dash.indent
                    and self.peek(1).kind == "CONTROL"
                    and self.peek(1).text == "else"
                ):
                    self.take()  # dash
                    self.take()  # else
                    self.expect("COLON")
                    self.expect("NEWLINE")
                    else_items = self._collect_step_list(parent_indent=dash.indent)
                return IfStep(
                    cond=cond,
                    then=then_items,
                    else_=else_items,
                    loc=Loc(dash.line, dash.col),
                )
            raise ParseError(f"unknown control '{ctrl.text}'", ctrl.line, ctrl.col)

        raise ParseError(
            f"expected step (ref or control) after '-', got {t.kind}",
            t.line,
            t.col,
        )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _is_bare_ident(s: str) -> bool:
    """True iff ``s`` is a bare Python-compatible identifier.

    Accepts both snake_case and PascalCase (project rule loosened in v0.6.1
    after commit0 benchmark needed PascalCase validator names like ``Email``,
    ``Boolean`` etc.). Field names still use snake_case per spec § 4.5.
    """
    return re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", s) is not None


def _build_typed_annotation(text: str, val_tok: Token) -> TypedAnnotation:
    """Split ``T(description)`` inline value into type_ann + description.

    Splits on the LAST ``(`` whose matching ``)`` is at end-of-string.
    This handles complex type expressions like ``list[dict[str, int]]``
    correctly: the outer balance accumulates [,] but only () at the tail
    is treated as the description boundary.

    Lenient: if text doesn't end in ``)``, the whole text becomes
    ``type_ann`` and ``description`` is None — preserves v0.6 free-English
    inputs as TypedAnnotation without rejection.
    """
    stripped = text.strip()
    loc = Loc(val_tok.line, val_tok.col)
    if not stripped.endswith(")"):
        return TypedAnnotation(type_ann=stripped, description=None, loc=loc)
    # Find the matching '(' by paren counting from the right.
    depth = 0
    open_idx = -1
    for i in range(len(stripped) - 1, -1, -1):
        ch = stripped[i]
        if ch == ")":
            depth += 1
        elif ch == "(":
            depth -= 1
            if depth == 0:
                open_idx = i
                break
    if open_idx <= 0:  # no matching '(' or '(' is at position 0 → no type_ann
        return TypedAnnotation(type_ann=stripped, description=None, loc=loc)
    type_ann = stripped[:open_idx].rstrip()
    description = stripped[open_idx + 1 : -1].strip()
    if not type_ann:
        # E.g. ``(description only)`` — no type. Fall back to raw text.
        return TypedAnnotation(type_ann=stripped, description=None, loc=loc)
    return TypedAnnotation(type_ann=type_ann, description=description or None, loc=loc)


# ---------------------------------------------------------------------------
# Re-export for convenience
# ---------------------------------------------------------------------------

__all__ = ["parse", "FIELD_VALUE_HINTS"]
