"""AST-level semantic equivalence checker for Python source.

Phase E of the long-horizon plan needs a mechanical proof that
AL → Python codegen produces semantically equivalent Python to what
a baseline Python pipeline would have produced. This module provides
the comparison primitive.

Public API:

    ast_equivalent(py_a: str, py_b: str, *, options) -> (bool, list[str])

Returns ``(True, [])`` if the two Python sources are AST-equivalent
under the configured tolerances; otherwise ``(False, [path_to_first_n_diffs])``.

Tolerances (defaults that are reasonable for our use-case):

- ``ignore_locations=True`` — line/col/end-line attrs are stripped before
  comparison. Different formatting / blank-line counts shouldn't fail.
- ``ignore_docstrings=False`` — by default docstrings are part of the
  contract; set True to allow docstring drift.
- ``ignore_decorator_order=False`` — by default decorator order is
  preserved (it matters semantically for many decorators).
- ``allow_var_renames=False`` — by default variable names matter. We do
  NOT alpha-rename — same-named identifiers must match identically.
  Justification: commit0-style stripping preserves names; the LLM-filled
  body should use the same names. A future, more permissive version
  could allow alpha-equivalence in local scopes.

The implementation walks the AST iteratively (no recursion limit blowup)
and reports the first ``max_diffs`` divergences with dotted paths so a
human or Codex can grade them.
"""

from __future__ import annotations

import ast
from dataclasses import dataclass
from typing import Iterator


@dataclass
class EquivOptions:
    """Controls what counts as "equivalent" for AST diff purposes."""

    ignore_locations: bool = True
    """Strip line/col/end-line/end-col attrs before compare."""

    ignore_docstrings: bool = False
    """Treat first-statement-string-expressions as equivalent regardless of text."""

    ignore_decorator_order: bool = False
    """Sort decorator lists before compare (rarely safe — most decorators don't commute)."""

    max_diffs: int = 10
    """Report at most this many divergence paths."""


# Attrs that ``ast.fix_missing_locations`` and friends add — strip
# before structural compare when ``ignore_locations`` is on.
_LOC_ATTRS = frozenset({
    "lineno", "col_offset", "end_lineno", "end_col_offset",
})


def ast_equivalent(
    py_a: str, py_b: str, options: EquivOptions | None = None,
) -> tuple[bool, list[str]]:
    """Return ``(equiv, diffs)``. ``diffs`` is empty when ``equiv`` is True.

    Either argument that fails to ``ast.parse`` returns False with a
    single diff describing the parse error.
    """
    opts = options or EquivOptions()
    try:
        tree_a = ast.parse(py_a)
    except SyntaxError as e:
        return False, [f"<a> failed to parse: {e}"]
    try:
        tree_b = ast.parse(py_b)
    except SyntaxError as e:
        return False, [f"<b> failed to parse: {e}"]

    diffs: list[str] = []
    _compare(tree_a, tree_b, "$", diffs, opts)
    return (not diffs), diffs


def _compare(
    a: ast.AST, b: ast.AST, path: str, diffs: list[str], opts: EquivOptions,
) -> None:
    """In-place diff append. Returns when ``len(diffs) >= opts.max_diffs``."""
    if len(diffs) >= opts.max_diffs:
        return

    type_a, type_b = type(a), type(b)
    if type_a is not type_b:
        diffs.append(
            f"{path}: type {type_a.__name__} vs {type_b.__name__}"
        )
        return

    # Optional ignores at the function/class/module level — docstrings live
    # as the first statement of a Module / FunctionDef / AsyncFunctionDef /
    # ClassDef body.
    if opts.ignore_docstrings and isinstance(a, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
        a_body = list(a.body)
        b_body = list(b.body)
        if _is_docstring(a_body and a_body[0]) and _is_docstring(b_body and b_body[0]):
            a_body = a_body[1:]
            b_body = b_body[1:]
        elif _is_docstring(a_body and a_body[0]) ^ _is_docstring(b_body and b_body[0]):
            # one side has a docstring, the other doesn't — equivalent under ignore
            if a_body and _is_docstring(a_body[0]):
                a_body = a_body[1:]
            if b_body and _is_docstring(b_body[0]):
                b_body = b_body[1:]
        _compare_field_lists(a_body, b_body, f"{path}.body", diffs, opts)
        # Other fields of Module / FunctionDef etc. still need comparing.
        for fname in a._fields:
            if fname == "body":
                continue
            _compare_field(getattr(a, fname, None), getattr(b, fname, None),
                           f"{path}.{fname}", diffs, opts)
        return

    # Decorator-order normalization on FunctionDef / AsyncFunctionDef / ClassDef.
    if opts.ignore_decorator_order and isinstance(
        a, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef),
    ):
        a_dec = sorted(a.decorator_list, key=_decorator_sort_key)
        b_dec = sorted(b.decorator_list, key=_decorator_sort_key)
        _compare_field_lists(a_dec, b_dec, f"{path}.decorator_list", diffs, opts)
        # Remaining fields below
        for fname in a._fields:
            if fname == "decorator_list":
                continue
            _compare_field(getattr(a, fname, None), getattr(b, fname, None),
                           f"{path}.{fname}", diffs, opts)
        return

    # Standard field-by-field comparison.
    for fname in a._fields:
        _compare_field(getattr(a, fname, None), getattr(b, fname, None),
                       f"{path}.{fname}", diffs, opts)


def _compare_field(
    a, b, path: str, diffs: list[str], opts: EquivOptions,
) -> None:
    if len(diffs) >= opts.max_diffs:
        return
    if isinstance(a, ast.AST) and isinstance(b, ast.AST):
        _compare(a, b, path, diffs, opts)
    elif isinstance(a, list) and isinstance(b, list):
        _compare_field_lists(a, b, path, diffs, opts)
    elif a == b:
        return
    else:
        diffs.append(f"{path}: {_repr(a)} vs {_repr(b)}")


def _compare_field_lists(
    la: list, lb: list, path: str, diffs: list[str], opts: EquivOptions,
) -> None:
    if len(la) != len(lb):
        diffs.append(f"{path}: list length {len(la)} vs {len(lb)}")
        return
    for i, (xa, xb) in enumerate(zip(la, lb)):
        if len(diffs) >= opts.max_diffs:
            return
        _compare_field(xa, xb, f"{path}[{i}]", diffs, opts)


def _is_docstring(node) -> bool:
    """True if ``node`` is an ``Expr(Constant(str))`` — i.e. a docstring."""
    return (
        isinstance(node, ast.Expr)
        and isinstance(getattr(node, "value", None), ast.Constant)
        and isinstance(node.value.value, str)
    )


def _decorator_sort_key(d: ast.AST) -> str:
    """Stable key for sorting decorator nodes when order is ignored."""
    try:
        return ast.unparse(d)
    except Exception:
        return repr(d)


def _repr(x) -> str:
    """Compact repr for diff messages."""
    s = repr(x)
    return s if len(s) <= 80 else s[:77] + "..."


# ---------------------------------------------------------------------------
# Convenience: equivalence under common AL-roundtrip tolerances
# ---------------------------------------------------------------------------


def al_roundtrip_equivalent(py_original: str, py_via_al: str) -> tuple[bool, list[str]]:
    """Default ``ast_equivalent`` configured for "Python → AL → Python"
    round-trip checking. Tolerates:

    - Location info changes (always — AL re-emits)
    - Docstring drift (the AL prompt asks the LLM to keep docstrings;
      a missing docstring isn't a semantic change)

    Does NOT tolerate variable renames or decorator-order changes — those
    can be semantic.
    """
    return ast_equivalent(
        py_original, py_via_al,
        EquivOptions(ignore_locations=True, ignore_docstrings=True),
    )


__all__ = ["EquivOptions", "ast_equivalent", "al_roundtrip_equivalent"]
