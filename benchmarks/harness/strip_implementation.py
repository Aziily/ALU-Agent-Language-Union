"""Reusable utility: strip Python implementations down to skeletons.

Used for Commit0-like benchmarks where we want to start from
``raise NotImplementedError`` bodies and let the pipeline fill them in.

For SWE-bench-style "patch a buggy file" benchmarks, see
:mod:`benchmarks.harness.swebench_adapter` (阶段 ③).

Implementation strategy: parse the file with stdlib ``ast``, walk function
defs, replace each body with ``raise NotImplementedError("...")``.

[UPGRADE] Use LibCST for byte-precise CST manipulation when we need to
preserve docstrings, comments, and surrounding format (per benchmark eval
report § 4).
"""

from __future__ import annotations

import ast
from pathlib import Path


def strip_file(path: Path) -> str:  # [TODO] 阶段 ③ 完整实现
    """Read ``path`` and return Python source with all function bodies stripped.

    Preserves: imports, class structure, function signatures (incl. type
    hints), module-level constants, docstrings.

    Replaces: function body → ``raise NotImplementedError("body stripped")``.
    """
    src = path.read_text(encoding="utf-8")
    tree = ast.parse(src)
    transformer = _BodyStripper()
    new_tree = transformer.visit(tree)
    ast.fix_missing_locations(new_tree)
    return ast.unparse(new_tree)


class _BodyStripper(ast.NodeTransformer):
    """AST transformer: replace function bodies with NotImplementedError."""

    def visit_FunctionDef(self, node: ast.FunctionDef):  # type: ignore[override]
        return self._strip(node)

    def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef):  # type: ignore[override]
        return self._strip(node)

    def _strip(self, node):
        # Preserve a leading docstring if present.
        new_body = []
        if (
            node.body
            and isinstance(node.body[0], ast.Expr)
            and isinstance(node.body[0].value, ast.Constant)
            and isinstance(node.body[0].value.value, str)
        ):
            new_body.append(node.body[0])
        new_body.append(
            ast.Raise(
                exc=ast.Call(
                    func=ast.Name(id="NotImplementedError", ctx=ast.Load()),
                    args=[ast.Constant(value="body stripped")],
                    keywords=[],
                ),
                cause=None,
            )
        )
        node.body = new_body
        return node
