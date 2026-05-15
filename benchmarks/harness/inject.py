"""Inject implementations back into a commit0 stripped repo.

Two inject pipelines, both writing to ``workdir`` in-place:

  inject_python_files(workdir, files) — Pipeline A's filled
      ``{rel_path: source}`` dict overwrites stripped files.

  inject_filled_al(workdir, filled_text) — Pipeline B parses the
      filled agent-lang, extracts each ``code`` node's body Python,
      derives the target function name + (optional) class hint from the
      node name, walks ``workdir``'s .py files via ast, and replaces the
      matching stripped function body.

Node naming conventions for Pipeline B (must be honored by hand-written
skeletons in benchmarks/skeletons/):

  * ``<name>``                — top-level function ``<name>`` (case-preserving)
  * ``<Class>__<method>``     — Class.method (双下划线分隔；Class 必首字母大写)
  * ``<file>_<function>``     — file.py 中的 function（首字母小写时优先这个解读，
                                  作为跨文件同名冲突消歧；e.g. classic_deprecated)
  * a body-line comment ``# inject-into: <relpath>`` overrides everything

The 'still stripped' check (function body == pass) disambiguates when
the same name appears in multiple files: only the stripped one is the
target. Phase 1.G runner relies on this.
"""

from __future__ import annotations

import ast
import re
from dataclasses import dataclass, field
from pathlib import Path

from al.parser import parse
from al.parser.ast_nodes import BlockScalar, Definition, Program


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class InjectReport:
    """What got injected, what didn't, why."""

    injected: list[str] = field(default_factory=list)
    """Node names whose body was successfully written back."""

    skipped: dict[str, str] = field(default_factory=dict)
    """{node_name: reason} — nodes we couldn't inject."""

    files_modified: set[str] = field(default_factory=set)
    """Relative paths whose source was rewritten."""

    @property
    def success_rate(self) -> float:
        total = len(self.injected) + len(self.skipped)
        return len(self.injected) / total if total else 0.0


# ---------------------------------------------------------------------------
# Pipeline A — write python files
# ---------------------------------------------------------------------------


def inject_python_files(workdir: Path, files: dict[str, str]) -> InjectReport:
    """Overwrite stripped files with filled Python sources.

    Each key in ``files`` is a path RELATIVE to ``workdir``. Missing
    parents are created. Returns a report listing every path written.
    """
    report = InjectReport()
    for rel_path, source in files.items():
        target = workdir / rel_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(source, encoding="utf-8")
        report.injected.append(rel_path)
        report.files_modified.add(rel_path)
    return report


# ---------------------------------------------------------------------------
# Pipeline B — agent-lang inject
# ---------------------------------------------------------------------------


_INJECT_INTO_RE = re.compile(r"^\s*#\s*inject-into:\s*(\S+?)\s*$", re.MULTILINE)


def inject_filled_al(
    workdir: Path,
    filled_text: str,
) -> InjectReport:
    """Apply each code node's body to the matching stripped function in workdir.

    Algorithm per code node:

      1. Parse the node's body to find ``def <fn_name>(...):``. Skip on parse fail.
      2. Detect ``# inject-into: <relpath>`` comment as a file hint.
      3. Detect ``Class__method`` form in node name for class scoping.
      4. Walk workdir .py files; find the (still-stripped) target by
         (fn_name, optional class, optional file). Inject body if exactly
         one match.
      5. Otherwise record in report.skipped with reason.

    Phase 1.AL.6: top-level defs other than ``code`` are skipped silently:
      - ``preamble`` defs are LLM-facing module-level context (imports,
        classes, constants) that already exist in the stripped repo; we
        don't re-inject them.
      - ``flow`` / ``agent`` / ``set`` are orchestration concepts not
        relevant to the commit0 benchmark pipeline.

    Returns an InjectReport.
    """
    report = InjectReport()
    program = parse(filled_text)
    for d in program.defs:
        if d.kind != "code":
            continue
        body_text = _get_body(d)
        if body_text is None:
            report.skipped[d.name] = "no body field"
            continue
        try:
            target_fn_name, body_ast = _parse_body_function(body_text)
        except ValueError as e:
            report.skipped[d.name] = f"body parse failed: {e}"
            continue
        # File hint from comment + class hint from node name
        file_hint = _extract_file_hint(body_text)
        class_hint = _class_hint_from_node_name(d.name)

        matched = _find_and_inject(
            workdir=workdir,
            fn_name=target_fn_name,
            body_ast=body_ast,
            file_hint=file_hint,
            class_hint=class_hint,
        )
        if matched is None:
            report.skipped[d.name] = (
                f"no stripped target for {target_fn_name!r}"
                + (f" in class {class_hint!r}" if class_hint else "")
                + (f" in {file_hint!r}" if file_hint else "")
            )
        else:
            report.injected.append(d.name)
            report.files_modified.add(str(matched))
    return report


# ---------------------------------------------------------------------------
# Body parsing helpers
# ---------------------------------------------------------------------------


def _get_body(d: Definition) -> str | None:
    for f in d.fields:
        if f.name == "body" and isinstance(f.value, BlockScalar):
            return f.value.text
    return None


def _parse_body_function(body_text: str) -> tuple[str, ast.AST]:
    """Parse body_text as Python; return (function_name, the function node).

    Skips leading decorators. The first FunctionDef in body_text wins.
    Raises ValueError on parse error or no function found.
    """
    try:
        tree = ast.parse(body_text)
    except SyntaxError as e:
        raise ValueError(f"SyntaxError: {e}")
    for n in tree.body:
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)):
            return n.name, n
    raise ValueError("no function definition in body")


def _extract_file_hint(body_text: str) -> str | None:
    """Look for ``# inject-into: <path>`` comment anywhere in body."""
    m = _INJECT_INTO_RE.search(body_text)
    return m.group(1) if m else None


def _class_hint_from_node_name(node_name: str) -> str | None:
    """Detect ``Class__method`` convention. Returns Class or None.

    Heuristic: split on '__', if first segment is non-empty and starts
    with an uppercase letter, treat it as a class name.
    """
    if "__" not in node_name:
        return None
    head, _, _ = node_name.partition("__")
    if not head:
        return None
    if not head[0].isupper():
        return None
    return head


# ---------------------------------------------------------------------------
# Walk + inject
# ---------------------------------------------------------------------------


def _find_and_inject(
    *,
    workdir: Path,
    fn_name: str,
    body_ast: ast.AST,
    file_hint: str | None,
    class_hint: str | None,
) -> Path | None:
    """Find (file, function-or-method) whose body is `pass` and matches the
    name + hints. Inject ``body_ast`` and return the relative file path.
    """
    candidates = list(_walk_py_files(workdir, file_hint))
    matches: list[tuple[Path, ast.AST, ast.AST | None]] = []
    # (file_path, function_ast_to_replace, parent_class_ast_or_None)

    for py_file in candidates:
        try:
            tree = ast.parse(py_file.read_text(encoding="utf-8"))
        except (SyntaxError, UnicodeDecodeError):
            continue
        # Top-level functions
        for node in tree.body:
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                if node.name == fn_name and _is_stripped(node):
                    matches.append((py_file, node, None))
            elif isinstance(node, ast.ClassDef):
                if class_hint and node.name != class_hint:
                    continue
                for m in node.body:
                    if isinstance(m, (ast.FunctionDef, ast.AsyncFunctionDef)):
                        if m.name == fn_name and _is_stripped(m):
                            matches.append((py_file, m, node))

    if len(matches) != 1:
        return None  # 0 = nothing to inject; >1 = ambiguous

    target_file, target_node, _ = matches[0]
    _replace_function_in_file(target_file, target_node, body_ast)
    return target_file.relative_to(workdir)


def _walk_py_files(workdir: Path, file_hint: str | None):
    """Iterate Python files under workdir, optionally filtered by file_hint."""
    if file_hint is not None:
        candidate = workdir / file_hint
        if candidate.exists():
            yield candidate
        return
    for p in workdir.rglob("*.py"):
        # Skip tests / build artifacts
        parts = p.parts
        if any(x in parts for x in ("tests", "test", "__pycache__", ".git", "build", "dist")):
            continue
        yield p


def _is_stripped(node: ast.FunctionDef | ast.AsyncFunctionDef) -> bool:
    """True if the function body == just ``pass`` (optionally after a docstring)."""
    body = list(node.body)
    if body and isinstance(body[0], ast.Expr) and isinstance(body[0].value, ast.Constant) and isinstance(body[0].value.value, str):
        body = body[1:]
    return len(body) == 1 and isinstance(body[0], ast.Pass)


def _replace_function_in_file(
    py_file: Path,
    target_node: ast.AST,
    body_ast: ast.AST,
) -> None:
    """In-place replace ``target_node``'s body with ``body_ast.body``.

    Uses ast.parse → modify → ast.unparse. This loses original formatting
    + comments but preserves semantics. v1 acceptable; phase ② could
    swap to libcst for byte-precise patching.
    """
    src = py_file.read_text(encoding="utf-8")
    tree = ast.parse(src)
    replaced = _Replacer(target_node, body_ast).visit(tree)
    ast.fix_missing_locations(replaced)
    py_file.write_text(ast.unparse(replaced) + "\n", encoding="utf-8")


class _Replacer(ast.NodeTransformer):
    """Walks an ast and replaces the body of one specific function node."""

    def __init__(self, target_node, body_ast):
        self.target_name = target_node.name
        self.body_ast = body_ast
        # Preserve the original docstring if present
        self._matched_once = False

    def visit_FunctionDef(self, node):  # type: ignore[override]
        return self._maybe_replace(node)

    def visit_AsyncFunctionDef(self, node):  # type: ignore[override]
        return self._maybe_replace(node)

    def _maybe_replace(self, node):
        # Only replace the first stripped match (NodeTransformer walks deeply)
        if (
            not self._matched_once
            and node.name == self.target_name
            and _is_stripped(node)
        ):
            self._matched_once = True
            # Preserve docstring if present in original
            preserved_doc = []
            if (
                node.body
                and isinstance(node.body[0], ast.Expr)
                and isinstance(node.body[0].value, ast.Constant)
                and isinstance(node.body[0].value.value, str)
            ):
                preserved_doc.append(node.body[0])
            # Use body_ast's function body (skip its own docstring if any)
            new_body_stmts = list(self.body_ast.body)
            if (
                new_body_stmts
                and isinstance(new_body_stmts[0], ast.Expr)
                and isinstance(new_body_stmts[0].value, ast.Constant)
                and isinstance(new_body_stmts[0].value.value, str)
            ):
                # LLM-written body already has docstring — drop the original
                node.body = new_body_stmts
            else:
                node.body = preserved_doc + new_body_stmts
            return node
        # Don't descend into other functions (no nested matching)
        self.generic_visit(node)
        return node
