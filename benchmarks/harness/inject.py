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

      1. If the node has a ``target: <relpath>::<qualname>`` field (v0.7.1)
         and its ``body:`` lacks a ``def`` line, synthesize a full def from
         the stripped Python's signature so the existing inject path can
         proceed unchanged. See ``_synthesize_def_for_target``.
      2. Parse the node's body to find ``def <fn_name>(...):``. Skip on parse fail.
      3. Detect ``# inject-into: <relpath>`` comment as a file hint.
      4. Detect ``Class__method`` form in node name for class scoping.
      5. Walk workdir .py files; find the (still-stripped) target by
         (fn_name, optional class, optional file). Inject body if exactly
         one match.
      6. Otherwise record in report.skipped with reason.

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
        # v0.7.1: if ``target:`` is set and body has no ``def`` line,
        # synthesize a full def using the signature from the stripped
        # source. Lets the LLM emit just function-body statements.
        # v0.7.3+: if the target's qualname does NOT exist in the stripped
        # file (commit0 sometimes strips the whole def, not just the body),
        # append the synthesized def to the file (similar to the H12
        # dangling-name mechanism for Pipeline B). This unblocks Pipeline C
        # on projects like portalocker that have entirely-stripped functions.
        target = _get_target(d)
        target_append_path: Path | None = None  # set when we'll need to append
        # v1.1: when target: is set, its relpath authoritatively narrows
        # _find_and_inject to one file — fixing the name-collision
        # regression on deprecated (def deprecated in both classic.py
        # and sphinx.py) found in v1.0 Phase C.
        target_file_hint: str | None = None
        target_class_hint: str | None = None
        if target:
            parsed_tgt = _parse_target(target)
            if parsed_tgt is not None:
                target_file_hint = parsed_tgt[0]
                # Class qualname like "Cache.get" → class hint = "Cache".
                if "." in parsed_tgt[1]:
                    target_class_hint = parsed_tgt[1].split(".", 1)[0]
            has_def_in_body = _body_has_def(body_text)
            if not has_def_in_body:
                synth = _synthesize_def_for_target(workdir, target, body_text)
                if synth is None:
                    # Target qualname not found in stripped file. Append-fallback
                    # for top-level functions only (class methods need a class
                    # body to insert into — too brittle without explicit hints).
                    if parsed_tgt is not None and "." not in parsed_tgt[1]:
                        target_append_path = workdir / parsed_tgt[0]
                        # Re-synthesize the def by treating body_text as
                        # *function body*; we don't know the original
                        # signature, so use ``def <qualname>(*args, **kwargs):``
                        # as a permissive shim.
                        rel, qualname = parsed_tgt
                        body_indented = "\n".join(
                            ("    " + ln) if ln.strip() else ln
                            for ln in body_text.splitlines()
                        )
                        body_text = (
                            f"def {qualname}(*args, **kwargs):\n"
                            + (body_indented or "    pass") + "\n"
                        )
                    else:
                        report.skipped[d.name] = (
                            f"target {target!r} not found in workdir"
                        )
                        continue
                else:
                    body_text = synth
        try:
            target_fn_name, body_ast = _parse_body_function(body_text)
        except ValueError as e:
            report.skipped[d.name] = f"body parse failed: {e}"
            continue
        # File hint from comment + class hint from node name.
        # Precedence: target: > # inject-into: comment > Class__method dunder.
        file_hint = target_file_hint or _extract_file_hint(body_text)
        class_hint = target_class_hint or _class_hint_from_node_name(d.name)
        dangling = _extract_dangling_marker(body_text)

        # v0.7.3+: when ``target:`` set and the qualname is missing,
        # append directly to the target file (no find-and-replace search).
        if target_append_path is not None:
            from al.parser.ast_nodes import Definition  # not used; kept for clarity
            # Convert the synthesized body_text into ast for _append_to_file.
            try:
                synth_tree = ast.parse(body_text)
                synth_node = next(
                    n for n in synth_tree.body
                    if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))
                )
            except (SyntaxError, StopIteration):
                report.skipped[d.name] = f"target-append: body did not yield a def"
                continue
            rel = target_append_path.relative_to(workdir).as_posix()
            appended = _append_to_file(
                workdir=workdir, file_hint=rel, body_ast=synth_node,
                fn_name=synth_node.name,
            )
            if appended is not None:
                report.injected.append(d.name)
                report.files_modified.add(str(appended))
            else:
                report.skipped[d.name] = (
                    f"target-append: failed to append to {rel}"
                )
            continue  # don't fall through to find-and-inject

        matched = _find_and_inject(
            workdir=workdir,
            fn_name=target_fn_name,
            body_ast=body_ast,
            file_hint=file_hint,
            class_hint=class_hint,
        )
        if matched is None and dangling and file_hint:
            # H12: no stripped target exists because the source removed
            # the def entirely. Append the new function to the hinted
            # file so subsequent imports resolve it.
            appended = _append_to_file(
                workdir=workdir, file_hint=file_hint, body_ast=body_ast,
                fn_name=target_fn_name,
            )
            if appended is not None:
                matched = appended
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


def _get_target(d: Definition) -> str | None:
    """Return the ``target:`` field text if present (v0.7.1 Targeted Body)."""
    from al.parser.ast_nodes import InlineText
    for f in d.fields:
        if f.name == "target" and isinstance(f.value, InlineText):
            return f.value.text.strip()
    return None


_DEF_RE = re.compile(r"^\s*(?:@[^\n]+\n\s*)*\s*(?:async\s+)?def\s+", re.MULTILINE)


def _body_has_def(body_text: str) -> bool:
    """True if ``body_text`` starts (after optional decorators / leading
    blank lines) with a ``def`` or ``async def`` statement.

    Targeted-Body mode triggers when ``target:`` is set AND this returns
    False — we then synthesize the def line from the stripped Python's
    signature, so the LLM's body is treated as function-body statements.
    """
    if not body_text.strip():
        return False
    # Strict check via ast — body must parse as Python and contain at
    # least one top-level FunctionDef at the top.
    try:
        tree = ast.parse(body_text)
    except SyntaxError:
        return False
    for node in tree.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            return True
        # Skip leading docstring / comment-likes
        if isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant):
            continue
        # First real statement that isn't a def → body-without-def shape
        return False
    return False


def _parse_target(target: str) -> tuple[str, str] | None:
    """Split ``relpath.py::qualname`` into ``(relpath, qualname)``.

    Returns None if malformed.
    """
    if "::" not in target:
        return None
    relpath, _, qualname = target.partition("::")
    relpath = relpath.strip()
    qualname = qualname.strip()
    if not relpath or not qualname:
        return None
    return relpath, qualname


def _synthesize_def_for_target(
    workdir: Path, target: str, body_statements: str,
) -> str | None:
    """Synthesize a full ``def <name>(...): <body>`` block from the
    stripped Python's signature.

    ``target`` is ``relpath::qualname``; we read ``workdir/relpath``,
    locate the function by qualname (supports ``Class.method`` and
    ``Class.Inner.method``), grab its decorator list + ``def`` line
    verbatim from the source text, and append the LLM's body
    statements at the function's body indent level + 4 spaces.

    Returns the synthesized text, or None if the target cannot be
    resolved (file missing, function not found, or source unparseable).
    """
    parsed = _parse_target(target)
    if parsed is None:
        return None
    relpath, qualname = parsed
    file_path = workdir / relpath
    if not file_path.exists():
        return None
    try:
        src_text = file_path.read_text(encoding="utf-8")
        tree = ast.parse(src_text)
    except (OSError, UnicodeDecodeError, SyntaxError):
        return None
    func_node = _find_func_by_qualname(tree, qualname)
    if func_node is None:
        return None

    src_lines = src_text.splitlines()
    # Decorator-list lines + def-line, taken verbatim from source so we
    # preserve original argument list, annotations, defaults, etc.
    head_start = func_node.lineno  # 1-indexed, points to def line
    if func_node.decorator_list:
        head_start = min(d.lineno for d in func_node.decorator_list)
    # Find the def-line's column-zero indent so we know where to dedent
    # for the synthesized body. Code nodes typically inject at module
    # level (top-level def) or via the Class__method dunder convention;
    # for class methods we want the body dedented to the *function*'s
    # own indent + 4 (so the synthesized text remains valid Python on
    # its own and the rest of the inject pipeline replaces it correctly).
    def_line = src_lines[func_node.lineno - 1]
    leading = len(def_line) - len(def_line.lstrip())
    # Decorator+signature, dedented so the synthesized snippet starts
    # at column 0 — matching how AL body: blocks are emitted.
    head_lines = []
    for ln_idx in range(head_start - 1, func_node.lineno):
        head_lines.append(src_lines[ln_idx][leading:])
    # The ``def name(args):`` line. Find its end (where ``:`` is, after
    # multi-line signatures) — we'll fall through to ``func_node.body[0].lineno``.
    body_first_line = func_node.body[0].lineno  # 1-indexed
    # If signature spans multiple lines, include all lines up to (but not
    # including) the first body line.
    for ln_idx in range(func_node.lineno, body_first_line - 1):
        head_lines.append(src_lines[ln_idx][leading:])

    # Body statements — indent by 4 spaces from column 0.
    body_indented = "\n".join(
        ("    " + ln) if ln.strip() else ln
        for ln in body_statements.splitlines()
    )
    return "\n".join(head_lines) + "\n" + body_indented + "\n"


def _find_func_by_qualname(
    tree: ast.AST, qualname: str,
) -> ast.FunctionDef | ast.AsyncFunctionDef | None:
    """Find a function whose dotted qualname matches.

    ``hashkey`` → top-level ``def hashkey``
    ``Cache.__init__`` → ``Cache`` class → ``__init__`` method
    ``Outer.Inner.method`` → nested classes
    """
    parts = qualname.split(".")

    def _walk(scope_nodes, parts_left):
        if not parts_left:
            return None
        head, rest = parts_left[0], parts_left[1:]
        for node in scope_nodes:
            if isinstance(node, ast.ClassDef) and node.name == head and rest:
                found = _walk(node.body, rest)
                if found is not None:
                    return found
            elif (
                isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
                and node.name == head and not rest
            ):
                return node
        return None

    return _walk(tree.body, parts)


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


_DANGLING_MARKER_RE = re.compile(r"#\s*dangling-name:\s*append-if-missing", re.IGNORECASE)


def _extract_dangling_marker(body_text: str) -> bool:
    """Detect H12's ``# dangling-name: append-if-missing`` marker.

    Tells ``inject_filled_al`` that the function is expected to NOT be
    present in workdir yet — instead of failing with "no stripped
    target", append the def at the end of the hinted source file so
    other modules' imports can resolve it.
    """
    return bool(_DANGLING_MARKER_RE.search(body_text))


def _append_to_file(
    *,
    workdir: Path,
    file_hint: str,
    body_ast: ast.AST,
    fn_name: str,
) -> Path | None:
    """Insert ``body_ast`` (unparsed) into ``workdir/file_hint`` BEFORE
    its first downstream reference at module level.

    Used by the H12 dangling-name path: if the AL filled .al contains a
    ``code <name>:`` node whose body has a ``# dangling-name:`` marker
    and no stripped target was found at injection time, we add the new
    function to the hinted file so that:

      (a) ``from <module> import <name>`` resolves at import time,
      (b) class-body references like ``__setitem__ = <name>`` see
          ``<name>`` already bound when the class is constructed.

    To satisfy (b), the def MUST be inserted BEFORE its first
    module-level use. We find the latest of (last top-level import,
    last top-level future import) and insert immediately after that
    block; this puts the new def before any class / module-level
    assignment that might reference it.

    Returns the relative path of the file written, or None on failure.
    """
    target = workdir / file_hint
    if not target.exists():
        return None
    src_text = target.read_text(encoding="utf-8")
    try:
        existing_tree = ast.parse(src_text)
    except (SyntaxError, UnicodeDecodeError):
        return None
    # If already defined at top level, fall through to the standard
    # replace path (only triggers when iter > 0 revert wasn't clean).
    for node in existing_tree.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == fn_name:
            _replace_function_in_file(target, node, body_ast)
            return target.relative_to(workdir)
    try:
        rendered = ast.unparse(body_ast)
    except Exception:
        return None

    # Find the insertion line — directly after the last top-level
    # ``import`` / ``from ... import`` statement (skipping initial
    # docstring), or position 0 if the file has no imports.
    src_lines = src_text.splitlines(keepends=True)
    insert_lineno = 0  # ast line numbers are 1-indexed; 0 = top of file
    for node in existing_tree.body:
        if isinstance(node, (ast.Import, ast.ImportFrom)):
            # node.end_lineno is the last line of this statement (1-indexed)
            end = getattr(node, "end_lineno", node.lineno)
            insert_lineno = max(insert_lineno, end)
        elif isinstance(node, ast.Expr) \
                and isinstance(node.value, ast.Constant) \
                and isinstance(node.value.value, str):
            # Module docstring — keep at top, advance insertion past it.
            end = getattr(node, "end_lineno", node.lineno)
            insert_lineno = max(insert_lineno, end)
        elif isinstance(node, ast.Try) and _is_import_only_try(node):
            # try/except-import wrapper — also part of the import block
            end = getattr(node, "end_lineno", node.lineno)
            insert_lineno = max(insert_lineno, end)
        else:
            # Stop at first non-import / non-docstring / non-import-try
            break
    # Splice in our rendered def at insert_lineno (0-indexed list pos).
    new_block = "\n\n" + rendered + "\n"
    src_lines.insert(insert_lineno, new_block)
    target.write_text("".join(src_lines), encoding="utf-8")
    return target.relative_to(workdir)


def _is_import_only_try(node: ast.Try) -> bool:
    """True when a top-level try/except block contains ONLY import
    statements (the common ``try: import C except ImportError: ...``
    pattern). Used by ``_append_to_file`` to extend the import-block
    boundary so dangling-name defs land below it.
    """
    def _all_imports(stmts: list[ast.stmt]) -> bool:
        return bool(stmts) and all(
            isinstance(s, (ast.Import, ast.ImportFrom)) for s in stmts
        )
    if not _all_imports(node.body):
        return False
    for h in node.handlers:
        if not _all_imports(h.body):
            return False
    if node.orelse and not _all_imports(node.orelse):
        return False
    if node.finalbody and not _all_imports(node.finalbody):
        return False
    return True


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
