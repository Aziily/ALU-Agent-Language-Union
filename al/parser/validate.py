"""v0.7 strict-mode validation for AL programs.

The parser is lenient at parse time: ``input: raw HTML`` becomes
:class:`TypedAnnotation` with ``type_ann="raw HTML"`` and ``description=None``,
preserving v0.6 files without forcing migration. This module provides the
**strict** check that flags such legacy values — useful for:

- A future ``al check --strict`` CLI mode.
- Greenfield Pipeline C, where the LLM's AL output is expected to use
  proper Python type annotations.
- Authoring guides that want to fail-fast on hand-written .al.

The validator walks the Program AST and returns a list of issues; the
caller decides whether to raise. We keep this OUT of the parser so the
benchmark regression path (which deliberately tolerates legacy syntax)
stays unaffected.
"""

from __future__ import annotations

import ast
import re
from dataclasses import dataclass

from al.parser.ast_nodes import (
    Definition,
    FieldGroup,
    InlineText,
    Program,
    TypedAnnotation,
)


@dataclass
class ValidationIssue:
    """One issue found during validation."""

    code: str
    """Short stable identifier (e.g. ``"io-not-python-type"``)."""

    message: str
    """Human-readable description."""

    line: int
    col: int
    node_name: str = ""
    """Definition name where the issue lives, or empty if at file scope."""


# Acceptable as a top-level "type expression". This is a coarse check —
# we don't fully parse Python types, just verify the shape resembles
# ``Identifier`` / ``Identifier[...]`` / ``Optional[Identifier]`` etc.
# The full validation hands the string to ``ast.parse(expr_str)`` and
# accepts only Names + Subscripts.
def _looks_like_python_type(ann: str) -> bool:
    """True if ``ann`` parses as a Python type expression.

    Accepts: ``str``, ``list[str]``, ``dict[str, int]``,
    ``Optional[bytes]``, ``tuple[str, int]``, ``str | None`` (PEP 604),
    dotted names like ``data_models.Article``, and PascalCase class
    names like ``Article``.

    Rejects free-English like ``raw HTML``, ``top 10 items, ordered``,
    or anything that doesn't ``ast.parse`` as a typing-shaped expr.
    Whitespace-only space-separated identifiers (``raw HTML``) fail
    syntactically; commas at top level (``list[str], int``) also fail
    because they'd need to be wrapped in a tuple or generic.
    """
    s = ann.strip()
    if not s:
        return False
    try:
        tree = ast.parse(s, mode="eval")
    except SyntaxError:
        return False
    return _is_type_expr(tree.body)


def _is_type_expr(node: ast.expr) -> bool:
    """Recursively check ``node`` is a valid type expression."""
    if isinstance(node, ast.Name):
        return True
    if isinstance(node, ast.Attribute):
        # ``data_models.Article``
        return _is_type_expr(node.value)
    if isinstance(node, ast.Subscript):
        return _is_type_expr(node.value) and _is_type_expr_slice(node.slice)
    if isinstance(node, ast.Tuple):
        return all(_is_type_expr(e) for e in node.elts)
    if isinstance(node, ast.Constant) and node.value is None:
        # ``None`` is a valid type (for Optional[T] = Union[T, None]).
        return True
    if isinstance(node, ast.BinOp) and isinstance(node.op, ast.BitOr):
        # PEP 604: ``X | Y``
        return _is_type_expr(node.left) and _is_type_expr(node.right)
    return False


def _is_type_expr_slice(node) -> bool:
    """Subscript slice: in Python 3.9+ this is the expr itself; in older
    versions it would have been an ast.Index wrapper. We support 3.9+.
    """
    if isinstance(node, ast.Tuple):
        return all(_is_type_expr(e) for e in node.elts)
    return _is_type_expr(node)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def validate_typed_annotations(program: Program) -> list[ValidationIssue]:
    """Return all I/O annotation issues in ``program``.

    Each ``input:`` / ``output:`` field is checked. Issues:
    - ``io-not-python-type``: TypedAnnotation.type_ann is not a valid
      Python type expression (free-English or bad syntax).
    - ``io-empty``: TypedAnnotation with empty type_ann.

    Nested FieldGroup leaves are also checked (their values are
    currently InlineText for v0.7.0, but the rule still applies to the
    raw text).

    Returns an empty list when the program is strictly typed.
    """
    issues: list[ValidationIssue] = []
    for d in program.defs:
        for f in d.fields:
            if f.name not in {"input", "output"}:
                continue
            issues.extend(_check_value(f.value, f.name, d))
    return issues


def _check_value(value, field_name: str, d: Definition) -> list[ValidationIssue]:
    out: list[ValidationIssue] = []
    if isinstance(value, TypedAnnotation):
        if not value.type_ann.strip():
            out.append(
                ValidationIssue(
                    code="io-empty",
                    message=(
                        f"`{field_name}:` has empty type annotation"
                    ),
                    line=value.loc.line, col=value.loc.col,
                    node_name=d.name,
                )
            )
        elif not _looks_like_python_type(value.type_ann):
            out.append(
                ValidationIssue(
                    code="io-not-python-type",
                    message=(
                        f"`{field_name}:` value {value.type_ann!r} is not a "
                        f"valid Python type expression. Use a structured "
                        f"type (e.g. ``str(...)`` or ``list[str](...)``)"
                    ),
                    line=value.loc.line, col=value.loc.col,
                    node_name=d.name,
                )
            )
    elif isinstance(value, FieldGroup):
        # Recurse into nested members. Their values are InlineText for
        # v0.7.0 (planned upgrade to TypedAnnotation in v0.7.1); for now
        # treat their text as a type expression.
        for sub in value.fields:
            if isinstance(sub.value, InlineText):
                if not _looks_like_python_type(sub.value.text):
                    out.append(
                        ValidationIssue(
                            code="io-not-python-type",
                            message=(
                                f"`{field_name}.{sub.name}:` value "
                                f"{sub.value.text!r} is not a valid Python "
                                f"type expression"
                            ),
                            line=sub.loc.line, col=sub.loc.col,
                            node_name=d.name,
                        )
                    )
            elif isinstance(sub.value, TypedAnnotation):
                out.extend(_check_value(sub.value, f"{field_name}.{sub.name}", d))
    return out


__all__ = [
    "ValidationIssue",
    "validate_typed_annotations",
]
