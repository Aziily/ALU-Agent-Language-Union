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
    "validate_uses",
]


# ---------------------------------------------------------------------------
# v0.7.3 (Codex co-iter round 3) — Uses Lint
# ---------------------------------------------------------------------------

import builtins as _builtins
from al.parser.ast_nodes import BlockScalar, ReferenceList


# Free names we silently allow even without explicit ``uses:`` /
# preamble declaration. Adding _these_ to every node's uses: list
# would be noise.
_ALWAYS_OK_NAMES: frozenset[str] = frozenset(
    dir(_builtins)
) | frozenset({"self", "cls", "__class__", "super"})


def validate_uses(program: Program) -> list[ValidationIssue]:
    """Flag free names in each ``code`` node's body that aren't
    declared anywhere visible (uses:, preamble imports/constants/body,
    or builtins).

    For each ``code`` node:
    1. Collect names declared in the same file's ``preamble`` defs
       (imports + constants + body's top-level class/def names).
    2. Collect names in the node's own ``uses:`` list.
    3. AST-parse the body; collect every ``Name(Load)`` and
       ``Attribute(value=Name(Load))`` root not bound by an outer
       scope of the function (args / for-target / assignments / etc.).
    4. Any remaining name → ValidationIssue with code ``uses-undeclared``.

    The check is WARNING-level — fed back to the LLM but never blocks
    inject. False positives possible (dynamic globals, late binding); the
    feedback loop and explicit ``uses:`` declarations let the LLM resolve.
    """
    issues: list[ValidationIssue] = []
    preamble_syms = _collect_preamble_symbols(program)

    for d in program.defs:
        if d.kind != "code":
            continue
        body_field = next(
            (f for f in d.fields if f.name == "body" and isinstance(f.value, BlockScalar)),
            None,
        )
        if body_field is None:
            continue
        uses_decl = _collect_uses_declared(d)
        # AST-parse the body. If it fails, skip — TypedAnnotation / parser
        # already surfaces parse errors elsewhere.
        try:
            tree = ast.parse(body_field.value.text)
        except SyntaxError:
            continue
        free = _free_names_in_body(tree)
        for name in sorted(free):
            if name in _ALWAYS_OK_NAMES:
                continue
            if name in uses_decl:
                continue
            if name in preamble_syms:
                continue
            issues.append(
                ValidationIssue(
                    code="uses-undeclared",
                    message=(
                        f"code node {d.name!r} body references {name!r} "
                        f"which is not in ``uses:``, not in any preamble's "
                        f"imports / constants / body, and not a built-in. "
                        f"Either add to ``uses:`` or import it."
                    ),
                    line=body_field.value.loc.line,
                    col=body_field.value.loc.col,
                    node_name=d.name,
                )
            )
    return issues


def _collect_uses_declared(d) -> set[str]:
    for f in d.fields:
        if f.name == "uses" and isinstance(f.value, ReferenceList):
            return set(f.value.names)
    return set()


def _collect_preamble_symbols(program: Program) -> set[str]:
    """Walk every preamble def; collect every name it defines at module
    scope (imports, constants, top-level class/def/assignment names).

    The greenfield use-case has each .al file contain one or more
    preambles (one per .py file). We pool them per-program — name
    collisions between preambles are rare and we err on permissive.
    """
    out: set[str] = set()
    for d in program.defs:
        if d.kind != "preamble":
            continue
        for f in d.fields:
            if f.name in {"imports", "constants", "body"} and isinstance(f.value, BlockScalar):
                out.update(_top_level_names(f.value.text))
    # Also include any top-level Program.imports (v0.7 cross-file).
    for imp in program.imports:
        if imp.kind == "import":
            out.add(imp.alias or imp.module.split(".")[0])
        else:
            out.update(imp.names)
    return out


def _top_level_names(py_text: str) -> set[str]:
    """Names introduced at module level by ``py_text``: imports, class /
    function defs, simple assignments.
    """
    out: set[str] = set()
    try:
        tree = ast.parse(py_text)
    except SyntaxError:
        return out
    for node in tree.body:
        if isinstance(node, ast.Import):
            for alias in node.names:
                out.add(alias.asname or alias.name.split(".")[0])
        elif isinstance(node, ast.ImportFrom):
            for alias in node.names:
                if alias.name == "*":
                    continue
                out.add(alias.asname or alias.name)
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            out.add(node.name)
        elif isinstance(node, ast.Assign):
            for tgt in node.targets:
                _collect_assign_targets(tgt, out)
        elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
            out.add(node.target.id)
        elif isinstance(node, ast.Try):
            # Common pattern: ``try: import X except ImportError: ...``
            for sub in node.body + (node.orelse or []):
                if isinstance(sub, (ast.Import, ast.ImportFrom)):
                    for alias in sub.names:
                        if alias.name == "*":
                            continue
                        out.add(alias.asname or alias.name.split(".")[0])
            for h in node.handlers:
                for sub in h.body:
                    if isinstance(sub, (ast.Import, ast.ImportFrom)):
                        for alias in sub.names:
                            if alias.name == "*":
                                continue
                            out.add(alias.asname or alias.name.split(".")[0])
    return out


def _collect_assign_targets(node: ast.AST, out: set[str]) -> None:
    if isinstance(node, ast.Name):
        out.add(node.id)
    elif isinstance(node, (ast.Tuple, ast.List)):
        for elt in node.elts:
            _collect_assign_targets(elt, out)


def _free_names_in_body(tree: ast.AST) -> set[str]:
    """Find every Name(Load) referenced in the body whose definition is
    NOT in any enclosing function scope. Returns the set of names.

    Approach: find the outermost FunctionDef / AsyncFunctionDef; walk
    the function recursively, building scope info; emit names that
    aren't bound by any nested scope. For ``Attribute`` accesses, only
    the root ``Name`` matters (``a.b.c`` → root is ``a``).
    """
    funcs = [
        n for n in tree.body
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))
    ]
    if not funcs:
        return set()

    free: set[str] = set()
    for fn in funcs:
        # Names defined in this function: args + assignments + nested
        # function/class defs. We collect them by a single pass.
        defined: set[str] = set()
        defined.update(_collect_fn_args(fn))
        for n in ast.walk(fn):
            if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                # nested function / class binds its name into the enclosing scope
                if n is not fn:
                    defined.add(n.name)
                defined.update(_collect_fn_args(n) if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)) else [])
            elif isinstance(n, ast.Assign):
                for tgt in n.targets:
                    _collect_assign_targets(tgt, defined)
            elif isinstance(n, ast.AnnAssign) and isinstance(n.target, ast.Name):
                defined.add(n.target.id)
            elif isinstance(n, ast.AugAssign) and isinstance(n.target, ast.Name):
                defined.add(n.target.id)
            elif isinstance(n, ast.NamedExpr) and isinstance(n.target, ast.Name):
                defined.add(n.target.id)
            elif isinstance(n, ast.For):
                _collect_assign_targets(n.target, defined)
            elif isinstance(n, ast.AsyncFor):
                _collect_assign_targets(n.target, defined)
            elif isinstance(n, (ast.With, ast.AsyncWith)):
                for item in n.items:
                    if item.optional_vars is not None:
                        _collect_assign_targets(item.optional_vars, defined)
            elif isinstance(n, ast.ExceptHandler):
                if n.name:
                    defined.add(n.name)
            elif isinstance(n, ast.comprehension):
                _collect_assign_targets(n.target, defined)
            elif isinstance(n, (ast.Lambda,)):
                defined.update(_collect_fn_args(n))
            elif isinstance(n, ast.Global):
                defined.update(n.names)
            elif isinstance(n, ast.Nonlocal):
                defined.update(n.names)
        # Now walk all Name(Load) — root names of Attribute too.
        for n in ast.walk(fn):
            if isinstance(n, ast.Name) and isinstance(n.ctx, ast.Load):
                if n.id not in defined:
                    free.add(n.id)
            elif isinstance(n, ast.Attribute):
                root = n
                while isinstance(root, ast.Attribute):
                    root = root.value
                if isinstance(root, ast.Name) and isinstance(root.ctx, ast.Load):
                    if root.id not in defined:
                        free.add(root.id)
    return free


def _collect_fn_args(fn) -> list[str]:
    """Collect argument names from a FunctionDef / AsyncFunctionDef / Lambda."""
    args = fn.args
    out: list[str] = []
    for a in args.posonlyargs + args.args + args.kwonlyargs:
        out.append(a.arg)
    if args.vararg:
        out.append(args.vararg.arg)
    if args.kwarg:
        out.append(args.kwarg.arg)
    return out
