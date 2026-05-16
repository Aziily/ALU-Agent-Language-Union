"""Auto-generate an agent-lang skeleton from a commit0 repo's stripped Python.

For each .py file under a repo's src dir, walk the AST and emit one
``code`` node per stripped (body == [pass]) top-level function or class
method. Group code nodes by source file into a `flow <stem>_group`.

This gives us a workable skeleton for the giant lite repos (jinja,
babel, minitorch, imapclient, marshmallow, simpy) where hand-design
of ~50-300 nodes would take days.

Per Phase 1.H'.A fairness decisions: no intent/input/output fields
emitted — only flow + steps + code + body with docstring + pass.

Usage:
    python -m benchmarks.skeletons._autogen <repo_name> <src_subdir>

    # examples:
    python -m benchmarks.skeletons._autogen simpy src/simpy
    python -m benchmarks.skeletons._autogen jinja src/jinja2
    python -m benchmarks.skeletons._autogen babel babel

Writes to ``benchmarks/skeletons/<repo_name>.al``.
"""

from __future__ import annotations

import ast
import re
import sys
from collections import defaultdict
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SKELETONS_DIR = Path(__file__).resolve().parent


def _is_stripped(node) -> bool:
    """True iff function body == ['pass'] optionally after a docstring."""
    body = list(node.body)
    if body and isinstance(body[0], ast.Expr) and isinstance(body[0].value, ast.Constant) \
       and isinstance(body[0].value.value, str):
        body = body[1:]
    return len(body) == 1 and isinstance(body[0], ast.Pass)


_VALID_NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _node_name_for_method(cls: str, meth: str) -> str:
    """Build agent-lang node name for a class method.

    Conventions (per Phase 1.E):
      - `Class__method` for regular methods
      - For methods with leading underscore, the underscore goes between
        Class__ and _method (e.g. `Schema___compile_dict`)
    """
    return f"{cls}__{meth}"


def _rel_inject_path(src_file: Path, repo_root: Path, src_dir: Path) -> str:
    """Path of ``src_file`` relative to the repo's root (the dir that
    contains setup.py / pyproject.toml). This is what the workdir uses
    when it's copied and what ``# inject-into:`` needs to point at.

    For a src-layout repo where src_dir is e.g. ``<repo>/src/<pkg>/``,
    rel-to-repo is ``src/<pkg>/<file>``. For a flat-layout where
    src_dir is ``<repo>/<pkg>/``, rel-to-repo is ``<pkg>/<file>``.
    Falls back to src_dir-relative as a last resort.
    """
    try:
        return src_file.relative_to(repo_root).as_posix()
    except ValueError:
        try:
            return src_file.relative_to(src_dir.parent).as_posix()
        except ValueError:
            return src_file.relative_to(src_dir).as_posix()


def _collect_stripped(src_dir: Path, repo_root: Path) -> dict[str, list[tuple[str, str, str, str, str]]]:
    """Return ``{file_stem: [(node_name, signature, docstring, kind, rel_inject_path), ...]}``.

    ``rel_inject_path`` is the source file's path relative to ``src_dir.parent``
    (e.g. ``cachetools/keys.py``). It gets emitted as a
    ``# inject-into: <rel_path>`` comment at the top of each code body so
    ``inject_filled_al`` can disambiguate when the same function name appears
    in multiple files (e.g. ``deprecated/classic.py:deprecated`` vs
    ``deprecated/sphinx.py:deprecated`` — both have a top-level
    ``def deprecated(...): pass`` and without a hint inject picks one
    arbitrarily, breaking the other).
    """
    out: dict[str, list[tuple[str, str, str, str, str]]] = defaultdict(list)
    for src_file in sorted(src_dir.rglob("*.py")):
        # Skip tests / build
        if any(p in src_file.parts for p in ("tests", "test", "__pycache__")):
            continue
        try:
            tree = ast.parse(src_file.read_text(encoding="utf-8", errors="replace"))
        except SyntaxError:
            continue
        rel = src_file.relative_to(src_dir).as_posix().replace("/", "_").replace(".py", "")
        rel_inject = _rel_inject_path(src_file, repo_root, src_dir)
        for node in tree.body:
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                if _is_stripped(node):
                    doc = _get_docstring(node)
                    if not _VALID_NAME.match(node.name):
                        continue
                    out[rel].append((node.name, ast.unparse(node.args), doc, "function", rel_inject))
            elif isinstance(node, ast.ClassDef):
                if not _VALID_NAME.match(node.name):
                    continue
                for m in node.body:
                    if isinstance(m, (ast.FunctionDef, ast.AsyncFunctionDef)):
                        if _is_stripped(m):
                            if not _VALID_NAME.match(m.name):
                                continue
                            doc = _get_docstring(m)
                            nname = _node_name_for_method(node.name, m.name)
                            out[rel].append((nname, ast.unparse(m.args), doc, "method", rel_inject))
    return out


def _is_import_only_try(node: ast.AST) -> bool:
    """True if a ``try: ... except: ...`` block contains ONLY import statements.

    Many libraries have ``try: from X import Y\nexcept ImportError: from Z
    import Y`` — that whole block is conceptually an import, so H4 hoists
    it out alongside other imports. A try block that does real work
    (computation, side-effects) stays in body.
    """
    if not isinstance(node, ast.Try):
        return False

    def _stmts_are_imports(stmts: list[ast.stmt]) -> bool:
        return bool(stmts) and all(
            isinstance(s, (ast.Import, ast.ImportFrom)) for s in stmts
        )

    if not _stmts_are_imports(node.body):
        return False
    for handler in node.handlers:
        if not _stmts_are_imports(handler.body):
            return False
    if node.orelse and not _stmts_are_imports(node.orelse):
        return False
    if node.finalbody and not _stmts_are_imports(node.finalbody):
        return False
    return True


def _collect_module_bindings(tree: ast.Module) -> set[str]:
    """Names bound at module-execution scope: imports / defs / classes /
    assignments anywhere in the module's body, INCLUDING inside Try /
    If / For / With statements (those execute at module load). Skips
    function and lambda bodies (their own scope). Plus standard builtins.

    Used by H12 to decide whether a referenced ``Name`` is dangling.
    """
    bound: set[str] = set()

    def _record_assign(node: ast.stmt) -> None:
        if isinstance(node, ast.Assign):
            for t in node.targets:
                if isinstance(t, ast.Name):
                    bound.add(t.id)
                elif isinstance(t, (ast.Tuple, ast.List)):
                    for el in t.elts:
                        if isinstance(el, ast.Name):
                            bound.add(el.id)
                        elif isinstance(el, ast.Starred) and isinstance(el.value, ast.Name):
                            bound.add(el.value.id)
        elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
            bound.add(node.target.id)

    def _walk(stmts: list[ast.stmt]) -> None:
        for node in stmts:
            if isinstance(node, ast.Import):
                for n in node.names:
                    bound.add(n.asname or n.name.split(".", 1)[0])
            elif isinstance(node, ast.ImportFrom):
                for n in node.names:
                    if n.name == "*":
                        continue
                    bound.add(n.asname or n.name)
            elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                bound.add(node.name)
                # Skip body — function / class internals are their own scope
                # for the purposes of bindings visible at module-execution.
                # (Class bodies DO execute at module load, but the names
                # they bind become attributes of the class, not module
                # names. So we don't recurse here either.)
                continue
            elif isinstance(node, (ast.Assign, ast.AnnAssign)):
                _record_assign(node)
            elif isinstance(node, ast.Try):
                _walk(node.body)
                for h in node.handlers:
                    if h.name:
                        bound.add(h.name)
                    _walk(h.body)
                _walk(node.orelse)
                _walk(node.finalbody)
            elif isinstance(node, ast.If):
                _walk(node.body)
                _walk(node.orelse)
            elif isinstance(node, (ast.For, ast.AsyncFor)):
                # For target var (``for x in ...``) is bound after loop runs.
                if isinstance(node.target, ast.Name):
                    bound.add(node.target.id)
                elif isinstance(node.target, (ast.Tuple, ast.List)):
                    for el in node.target.elts:
                        if isinstance(el, ast.Name):
                            bound.add(el.id)
                _walk(node.body)
                _walk(node.orelse)
            elif isinstance(node, ast.While):
                _walk(node.body)
                _walk(node.orelse)
            elif isinstance(node, (ast.With, ast.AsyncWith)):
                for item in node.items:
                    if item.optional_vars and isinstance(item.optional_vars, ast.Name):
                        bound.add(item.optional_vars.id)
                _walk(node.body)

    _walk(tree.body)

    # Standard builtins
    import builtins as _b
    bound.update(dir(_b))
    # Common dunders / Python implicit names
    bound.update({"__name__", "__file__", "__doc__", "__all__", "__version__",
                  "__author__", "__path__", "__package__", "__spec__",
                  "__loader__", "__builtins__", "__dict__", "__class__"})
    return bound


class _ModuleLevelNameRefs(ast.NodeVisitor):
    """Walk a module collecting ``Name`` and ``Attribute`` references
    that occur at MODULE-LEVEL scope: class bodies, top-level
    assignments, top-level expressions. Skips function / lambda bodies
    entirely — those are evaluated lazily at call time, not at module
    load.

    ``refs`` maps each loaded name to its first AST node (for
    diagnostics). ``attr_refs`` collects ``(base_name, attr_name)``
    pairs for ``base_name.attr_name`` accesses — used by H12d to detect
    "imported submodule doesn't define this attribute" dangling cases.
    """

    def __init__(self) -> None:
        self.refs: dict[str, ast.AST] = {}
        self.attr_refs: set[tuple[str, str]] = set()

    def visit_FunctionDef(self, node: ast.FunctionDef) -> None:  # noqa
        # Skip the body — only visit decorators / args defaults / returns
        # which DO execute at module load.
        for d in node.decorator_list:
            self.visit(d)
        for default in node.args.defaults + node.args.kw_defaults:
            if default is not None:
                self.visit(default)
        if node.returns is not None:
            self.visit(node.returns)

    visit_AsyncFunctionDef = visit_FunctionDef  # type: ignore[assignment]

    def visit_Lambda(self, node: ast.Lambda) -> None:  # noqa
        # Skip lambda body
        for default in node.args.defaults + node.args.kw_defaults:
            if default is not None:
                self.visit(default)

    def visit_Name(self, node: ast.Name) -> None:  # noqa
        if isinstance(node.ctx, ast.Load):
            self.refs.setdefault(node.id, node)

    def visit_Attribute(self, node: ast.Attribute) -> None:  # noqa
        """Record ``base.attr`` patterns (only when base is a simple Name)
        and recurse for nested attribute chains."""
        if isinstance(node.value, ast.Name) and isinstance(node.ctx, ast.Load):
            self.attr_refs.add((node.value.id, node.attr))
        self.generic_visit(node)

    # ClassDef bodies DO run at module load — fall through to generic_visit


def _detect_dangling_names(src_dir: Path, repo_root: Path) -> dict[str, list[tuple[str, str]]]:
    """H12 (Round 5) — find names referenced at module scope but never
    bound. Returns ``{file_stem: [(name, rel_inject_path), ...]}``.

    Two sources:
      1. **Within-file**: a ``Name`` is loaded at module-level
         (class body, top-level assignment RHS, top-level decorator,
         default arg value, return annotation, etc.) but the file's
         top-level scope doesn't bind it. ``_immutable`` in tinydb's
         ``utils.py`` (referenced by ``class FrozenDict: __setitem__
         = _immutable`` but no ``def _immutable``) is the canonical
         example.
      2. **Cross-file**: a ``from X import Y`` line in some file
         requests ``Y`` from module ``X``, but ``X`` doesn't bind ``Y``
         at top level. ``raises`` in ``voluptuous.schema_builder``
         (imported from ``validators.py`` but the source file
         doesn't define it) is the canonical example.

    Common cause: commit0 dataset removes function definitions entirely
    rather than stubbing them to ``pass`` — so they don't even show up
    as stripped functions for the autogen to pick up. The result is
    that ``import <module>`` fails at the workdir stage because some
    name expected by class declarations or other modules is missing.

    For each detected dangling name, the returned tuple records
    ``(name, file_path_to_create_def_in)`` so the autogen can emit a
    ``code <name>:`` stub with a ``# inject-into: <path>`` hint.

    Names that are clearly Sphinx / type-hint / docstring-only
    references are not detected (we walk AST, not raw text). Some
    false positives are possible if a name comes from ``from X import
    *`` — those are conservatively NOT flagged.
    """
    if not src_dir.exists():
        return {}
    out: dict[str, list[tuple[str, str]]] = defaultdict(list)

    # First pass: per-file binding + ref maps. Within-file dangling
    # analysis is library-only (test files skipped — they have their
    # own helper fns + fixtures and can't be inject-augmented anyway).
    # But for cross-file dangling, test-file ``from <pkg> import Y``
    # IS a real signal — if the test file imports ``Self`` from
    # ``voluptuous`` and the package doesn't export it, that's a
    # dangling name that must be added.
    file_bindings: dict[Path, set[str]] = {}
    file_refs: dict[Path, dict[str, ast.AST]] = {}
    file_attr_refs: dict[Path, set[tuple[str, str]]] = {}
    file_star_imports: dict[Path, bool] = {}
    test_file_imports: list[tuple[Path, ast.ImportFrom]] = []  # for cross-file pass
    for src_file in sorted(src_dir.rglob("*.py")):
        is_test = any(p in src_file.parts for p in ("tests", "test", "__pycache__"))
        try:
            tree = ast.parse(src_file.read_text(encoding="utf-8", errors="replace"))
        except SyntaxError:
            continue
        if is_test:
            # Only collect this file's from-imports for cross-file
            # dangling pass below; skip everything else.
            for node in tree.body:
                if isinstance(node, ast.ImportFrom):
                    test_file_imports.append((src_file, node))
            continue
        file_bindings[src_file] = _collect_module_bindings(tree)
        v = _ModuleLevelNameRefs()
        v.visit(tree)
        file_refs[src_file] = v.refs
        # H12d: collect Attribute references at module-level scope of
        # the form ``<Name>.<attr>``. We use these to detect cases like
        # ``portalocker/__init__.py`` doing ``lock = portalocker.lock``
        # where ``portalocker`` is an imported submodule but the
        # submodule doesn't define ``lock`` at top level.
        file_attr_refs[src_file] = v.attr_refs
        file_star_imports[src_file] = any(
            isinstance(n, ast.ImportFrom) and any(a.name == "*" for a in n.names)
            for n in tree.body
        )

    # Pass 1: within-file dangling
    for src_file, refs in file_refs.items():
        if file_star_imports.get(src_file):
            continue  # conservatively skip — * could bring anything
        bound = file_bindings[src_file]
        rel_inject = _rel_inject_path(src_file, repo_root, src_dir)
        rel_stem = src_file.relative_to(src_dir).as_posix().replace("/", "_").replace(".py", "")
        for name in sorted(refs):
            if name in bound:
                continue
            if name.startswith("_") and name.startswith("__") and name.endswith("__"):
                continue  # dunder — implicitly bound by the runtime
            # Filter: only flag names that look like Python identifiers and
            # aren't single underscores / common type-hint capitals like
            # ``Self`` which Python adds via typing in real code.
            if not _VALID_NAME.match(name):
                continue
            out[rel_stem].append((name, rel_inject))

    # Pass 2: cross-file dangling. Walk each file's `from X import Y` and
    # try to resolve X to a sibling file in the repo.
    pkg_root = src_dir  # treat src_dir as the package root
    def _resolve_module_to_file(import_module: str, current_file: Path) -> Path | None:
        """Map ``voluptuous.schema_builder`` etc. to the .py file backing
        the module. Prefer ``<dotted>/__init__.py`` over ``<dotted>.py``
        — for a ``from <pkg> import name`` line, ``<pkg>`` is the package
        regardless of whether a same-named submodule exists alongside it.
        """
        if not import_module:
            return None
        candidates: list[Path] = []
        dotted = import_module.replace(".", "/")
        # __init__.py FIRST so packages win when both forms exist (e.g.
        # ``portalocker/__init__.py`` vs ``portalocker/portalocker.py``
        # — the package wins because that's what ``from . import X``
        # consults first).
        for ext in ("/__init__.py", ".py"):
            cand = pkg_root.parent / (dotted + ext)
            if cand.exists() and cand in file_bindings:
                candidates.append(cand)
            cand2 = pkg_root / (dotted + ext)
            if cand2.exists() and cand2 in file_bindings:
                candidates.append(cand2)
        return candidates[0] if candidates else None

    # Gather all from-imports across library + test files for cross-file
    # detection. Test files' imports are equally a source of truth — if
    # the test does ``from voluptuous import Self`` and the package
    # doesn't export ``Self``, we MUST add it.
    cross_file_imports: list[tuple[Path, ast.ImportFrom]] = list(test_file_imports)
    for src_file in file_refs:
        try:
            tree = ast.parse(src_file.read_text(encoding="utf-8", errors="replace"))
        except SyntaxError:
            continue
        for node in tree.body:
            if isinstance(node, ast.ImportFrom):
                cross_file_imports.append((src_file, node))

    def _transitive_bindings(target: Path, visiting: set[Path] | None = None) -> set[str]:
        """Bindings visible at the top of ``target``, including names
        brought in by ``from X import *``. Recurses through star
        sources one hop (avoiding cycles). Conservative: if a star
        source can't be resolved, we treat the import as opaque and
        don't add anything for it.
        """
        if visiting is None:
            visiting = set()
        if target in visiting:
            return set()
        visiting.add(target)
        bound = set(file_bindings.get(target, set()))
        try:
            t = ast.parse(target.read_text(encoding="utf-8", errors="replace"))
        except (SyntaxError, OSError):
            return bound
        for node in t.body:
            if not isinstance(node, ast.ImportFrom):
                continue
            if not any(a.name == "*" for a in node.names):
                continue
            mod_str = node.module or ""
            if node.level > 0 and target.is_relative_to(pkg_root.parent):
                pkg_path = target.parent
                for _ in range(node.level - 1):
                    pkg_path = pkg_path.parent
                rel_pkg = pkg_path.relative_to(pkg_root.parent).as_posix().replace("/", ".")
                full_mod = f"{rel_pkg}.{mod_str}" if mod_str else rel_pkg
            else:
                full_mod = mod_str
            star_src = _resolve_module_to_file(full_mod, target)
            if star_src is None:
                continue
            bound |= _transitive_bindings(star_src, visiting)
        return bound

    for src_file, node in cross_file_imports:
        if not isinstance(node, ast.ImportFrom):
            continue
        mod_str = node.module or ""
        # Resolve relative imports
        if node.level > 0 and src_file.is_relative_to(pkg_root.parent):
            pkg_path = src_file.parent
            for _ in range(node.level - 1):
                pkg_path = pkg_path.parent
            rel_pkg = pkg_path.relative_to(pkg_root.parent).as_posix().replace("/", ".")
            full_mod = f"{rel_pkg}.{mod_str}" if mod_str else rel_pkg
        else:
            full_mod = mod_str
        target = _resolve_module_to_file(full_mod, src_file)
        if target is None:
            continue
        # Include names brought in by ``from X import *`` chains.
        target_bound = _transitive_bindings(target)
        # Identify sibling submodules of `target`: any .py file or
        # subpackage right next to (or under) target's package. Their
        # names are valid `from <pkg> import <submodule>` targets even
        # without a top-level binding inside <pkg>/__init__.py.
        target_pkg = target.parent
        submodules = set()
        if target.name == "__init__.py" and target_pkg.exists():
            for p in target_pkg.iterdir():
                if p.is_file() and p.suffix == ".py" and p.name != "__init__.py":
                    submodules.add(p.stem)
                elif p.is_dir() and (p / "__init__.py").exists():
                    submodules.add(p.name)
        for alias in node.names:
            if alias.name == "*":
                continue
            imported_name = alias.name
            if imported_name in target_bound:
                continue
            if imported_name in submodules:
                continue
            # Dangling cross-file import. Record on the TARGET file
            # (where the def must be added).
            rel_inject = _rel_inject_path(target, repo_root, src_dir)
            rel_stem = target.relative_to(src_dir).as_posix().replace("/", "_").replace(".py", "")
            entry = (imported_name, rel_inject)
            if entry not in out[rel_stem]:
                out[rel_stem].append(entry)

    # Pass 3 (H12d): module-level attribute access on an imported
    # submodule where the attr doesn't exist in the submodule's
    # top-level. Example: ``portalocker/__init__.py`` does
    # ``from . import portalocker; lock = portalocker.lock`` —
    # ``portalocker.portalocker`` (the submodule) doesn't define
    # ``lock`` at top level, so we flag ``lock`` as needing creation
    # in ``portalocker/portalocker.py``.
    for src_file, attr_refs in file_attr_refs.items():
        if not attr_refs:
            continue
        # We need to know what each module-level Name in src_file BINDS
        # to — specifically, which Names are imported submodules. Walk
        # the file again to build that mapping.
        try:
            tree = ast.parse(src_file.read_text(encoding="utf-8", errors="replace"))
        except SyntaxError:
            continue
        # name -> file Path of submodule
        name_to_module: dict[str, Path] = {}
        def _walk_imports(stmts: list[ast.stmt]) -> None:
            for n in stmts:
                if isinstance(n, ast.Import):
                    for a in n.names:
                        # `import foo.bar` binds `foo`
                        top = a.asname or a.name.split(".", 1)[0]
                        target = _resolve_module_to_file(top, src_file)
                        if target is not None:
                            name_to_module[top] = target
                elif isinstance(n, ast.ImportFrom):
                    if n.level > 0 and src_file.is_relative_to(pkg_root.parent):
                        pkg_path = src_file.parent
                        for _ in range(n.level - 1):
                            pkg_path = pkg_path.parent
                        rel_pkg = pkg_path.relative_to(pkg_root.parent).as_posix().replace("/", ".")
                        full_mod = f"{rel_pkg}.{n.module}" if n.module else rel_pkg
                    else:
                        full_mod = n.module or ""
                    for a in n.names:
                        if a.name == "*":
                            continue
                        bound_name = a.asname or a.name
                        # Resolve `<full_mod>.<a.name>` to a file. If
                        # `<full_mod>` is a package and `<a.name>` is a
                        # submodule, the access ``bound_name.attr`` is
                        # looking inside that submodule.
                        candidate_dotted = (
                            f"{full_mod}.{a.name}" if full_mod else a.name
                        )
                        target = _resolve_module_to_file(candidate_dotted, src_file)
                        if target is not None:
                            name_to_module[bound_name] = target
                elif isinstance(n, (ast.Try, ast.If)):
                    _walk_imports(n.body)
                    if isinstance(n, ast.Try):
                        for h in n.handlers:
                            _walk_imports(h.body)
                        _walk_imports(n.orelse)
                        _walk_imports(n.finalbody)
                    else:
                        _walk_imports(n.orelse)
        _walk_imports(tree.body)
        for base, attr in attr_refs:
            mod_path = name_to_module.get(base)
            if mod_path is None:
                continue
            mod_bindings = file_bindings.get(mod_path, set())
            if file_star_imports.get(mod_path):
                continue
            if attr in mod_bindings:
                continue
            if attr.startswith("__") and attr.endswith("__"):
                continue
            if not _VALID_NAME.match(attr):
                continue
            rel_inject = _rel_inject_path(mod_path, repo_root, src_dir)
            rel_stem = mod_path.relative_to(src_dir).as_posix().replace("/", "_").replace(".py", "")
            entry = (attr, rel_inject)
            if entry not in out[rel_stem]:
                out[rel_stem].append(entry)

    # Dedup per file_stem (preserve order).
    deduped: dict[str, list[tuple[str, str]]] = {}
    for stem, items in out.items():
        seen: set[tuple[str, str]] = set()
        deduped[stem] = []
        for entry in items:
            if entry not in seen:
                seen.add(entry)
                deduped[stem].append(entry)
    return deduped


def _compress_stripped_class_methods(cls_def: ast.ClassDef) -> ast.ClassDef:
    """H6 (Round 4) — compress stripped methods inside a class definition.

    In the preamble's class body, methods whose implementation has been
    stripped to ``pass`` (the ones that get filled by separate
    ``code <Class>__<method>`` nodes downstream) are rewritten to a
    single-line ``def m(args): ...`` form. The docstring is dropped —
    it's preserved verbatim on the matching code node, so removing it
    here de-duplicates without information loss.

    Methods with real bodies (helpers, ``__init__``, etc. — not
    stripped) are left untouched: the LLM needs to see what they do
    to reason about the class.

    Returns a NEW ``ast.ClassDef`` so the caller's tree isn't mutated.
    """
    new_body: list[ast.stmt] = []
    for member in cls_def.body:
        if isinstance(member, (ast.FunctionDef, ast.AsyncFunctionDef)) \
                and _is_stripped(member):
            ctor = type(member)  # FunctionDef vs AsyncFunctionDef
            stub = ctor(
                name=member.name,
                args=member.args,
                body=[ast.Expr(value=ast.Constant(value=...))],
                decorator_list=member.decorator_list,
                returns=member.returns,
                type_comment=getattr(member, "type_comment", None),
            )
            ast.copy_location(stub, member)
            new_body.append(stub)
        else:
            new_body.append(member)
    new_cls = ast.ClassDef(
        name=cls_def.name,
        bases=cls_def.bases,
        keywords=cls_def.keywords,
        body=new_body,
        decorator_list=cls_def.decorator_list,
    )
    ast.copy_location(new_cls, cls_def)
    # Preserve module-level decorators on the class (rare but possible)
    return new_cls


def _is_simple_constant_assign(node: ast.AST) -> bool:
    """True if ``node`` is a module-level value assignment whose target is
    a simple ``Name`` (H5 Round 3 — hoist into ``constants:``).

    Accepts:
      * ``ast.Assign`` with all targets ``ast.Name`` (``X = 1`` / ``__all__ = (...)``).
      * ``ast.AnnAssign`` with target ``ast.Name`` (``X: int = 1``,
        also ``X: int`` without value — declares a typed module slot).

    Rejects:
      * Tuple / list / starred / attribute / subscript targets
        (``a, b = 1, 2``; ``cls.attr = 1``; ``d['k'] = 1``) — those are
        often state mutation, not pure declarations.
      * ``ast.AugAssign`` (``X += 1``) — same reasoning.
    """
    if isinstance(node, ast.Assign):
        return all(isinstance(t, ast.Name) for t in node.targets)
    if isinstance(node, ast.AnnAssign):
        return isinstance(node.target, ast.Name)
    return False


def _collect_preambles(src_dir: Path, repo_root: Path) -> dict[str, tuple[str, str, str, str]]:
    """Phase 1.AL.5 + H4 + H5 — return
    ``{file_stem: (rel_path, imports_text, constants_text, body_text)}``.

    For each .py under ``src_dir`` (excluding tests / build), extract
    the module-level Python that is NOT a stripped function/method, and
    split it into:

      * ``imports_text``: every ``ast.Import`` / ``ast.ImportFrom`` and
        every ``try: ... except: ...`` block whose entire body is imports.
      * ``constants_text``: simple-name module-level value assignments —
        ``X = 1``, ``X: int = 2``, ``__all__ = (...)``. See
        :func:`_is_simple_constant_assign` for the precise rule.
      * ``body_text``: the remainder — module docstring, class
        definitions, complex assignments (tuple-unpack, attribute,
        subscript), AugAssign, and conditional non-import blocks.

    Order is preserved WITHIN each bucket. Imports are visually emitted
    first by the skeleton emitter, then constants, then body.

    Module-level top-level functions are EXCLUDED whether stripped or
    not — those become ``code <name>`` nodes elsewhere.
    """
    out: dict[str, tuple[str, str, str, str]] = {}
    for src_file in sorted(src_dir.rglob("*.py")):
        if any(p in src_file.parts for p in ("tests", "test", "__pycache__")):
            continue
        try:
            tree = ast.parse(src_file.read_text(encoding="utf-8", errors="replace"))
        except SyntaxError:
            continue
        rel_path = _rel_inject_path(src_file, repo_root, src_dir)
        rel_stem = src_file.relative_to(src_dir).as_posix().replace("/", "_").replace(".py", "")

        import_nodes: list[ast.AST] = []
        constant_nodes: list[ast.AST] = []
        body_nodes: list[ast.AST] = []
        for idx, node in enumerate(tree.body):
            # Module docstring at body[0] → body (not a constant; semantically
            # documentation, kept verbatim with the class block).
            if idx == 0 and isinstance(node, ast.Expr) \
                    and isinstance(node.value, ast.Constant) \
                    and isinstance(node.value.value, str):
                body_nodes.append(node)
                continue
            if isinstance(node, (ast.Import, ast.ImportFrom)):
                import_nodes.append(node)
            elif _is_import_only_try(node):
                import_nodes.append(node)
            elif _is_simple_constant_assign(node):
                constant_nodes.append(node)
            elif isinstance(node, ast.ClassDef):
                # H6 (Round 4): compress stripped methods inside the class
                # to ``def m(args): ...`` so the preamble's class skeleton
                # is structural only — docstring + body live in the
                # matching ``code <Class>__<method>`` node.
                body_nodes.append(_compress_stripped_class_methods(node))
            elif isinstance(node, (ast.Assign, ast.AnnAssign, ast.AugAssign)):
                # Complex assignments (tuple unpack, attr / subscript targets,
                # AugAssign) stay in body — often state mutation, not pure
                # declarations.
                body_nodes.append(node)
            elif isinstance(node, ast.If):
                # Module-level `if sys.version_info >= ...:` keep verbatim
                body_nodes.append(node)
            elif isinstance(node, ast.Try):
                # Try block with non-import statements — keep in body
                body_nodes.append(node)
            # else: skip FunctionDef / AsyncFunctionDef — handled in _collect_stripped

        if not import_nodes and not constant_nodes and not body_nodes:
            continue
        try:
            imports_text = "\n".join(ast.unparse(n) for n in import_nodes)
            constants_text = "\n".join(ast.unparse(n) for n in constant_nodes)
            body_text = "\n".join(ast.unparse(n) for n in body_nodes)
        except Exception:
            continue
        if not (imports_text.strip() or constants_text.strip() or body_text.strip()):
            continue
        out[rel_stem] = (rel_path, imports_text, constants_text, body_text)
    return out


def _get_docstring(node) -> str:
    body = node.body
    if body and isinstance(body[0], ast.Expr) and isinstance(body[0].value, ast.Constant) \
       and isinstance(body[0].value.value, str):
        return body[0].value.value
    return ""


def _format_body(node_name: str, signature: str, docstring: str, kind: str,
                  inject_path: str | None = None) -> str:
    """Emit the body Python source for one code node.

    If ``inject_path`` is given, prepend a ``# inject-into: <path>`` comment
    so ``inject_filled_al`` always knows which source file to patch
    (resolves same-named functions across multiple files unambiguously).
    The comment is plain Python, so the LLM seeing it knows to preserve it
    verbatim like any other body line.

    For ``kind="dangling"`` (H12), an additional ``# dangling-name`` marker
    tells the LLM the function doesn't exist in workdir yet — inject_filled_al
    will APPEND the new def to the hinted file rather than replacing a
    stripped target.
    """
    # method nodes: node_name is `Class__method`; actual def is `def method(...)`
    if kind == "method":
        fn = node_name.split("__", 1)[1]
        # method names starting with _ get encoded as Class___method, so revert
        if fn.startswith("_") and not fn.startswith("__"):
            # already correct
            pass
    else:
        fn = node_name

    lines: list[str] = []
    if inject_path:
        lines.append(f"# inject-into: {inject_path}")
    if kind == "dangling":
        # Append marker — read by inject_filled_al fallback path.
        lines.append("# dangling-name: append-if-missing")
    lines.append(f"def {fn}({signature}):")
    if docstring:
        # Use triple-quoted docstring; escape any """ inside (very rare)
        safe_doc = docstring.replace('"""', '\\"\\"\\"')
        if "\n" in safe_doc:
            lines.append(f'    """{safe_doc}')
            lines.append('    """')
        else:
            lines.append(f'    """{safe_doc}"""')
    lines.append("    pass")
    return "\n".join(lines)


def generate_skeleton(repo: str, src_subdir: str) -> str:
    """Produce agent-lang skeleton text for one repo.

    Phase 1.AL.5: also emits ``preamble <file_stem>: body: |``
    blocks at the top, one per source file that has module-level
    Python (imports, classes, constants). The preamble gives the LLM
    the module-level context it would otherwise be blind to.
    """
    repo_root = REPO_ROOT / "thirdparty" / "commit0_repos" / repo
    src_dir = repo_root / src_subdir
    if not src_dir.exists():
        raise FileNotFoundError(f"src dir not found: {src_dir}")
    grouped = _collect_stripped(src_dir, repo_root)
    preambles = _collect_preambles(src_dir, repo_root)
    dangling = _detect_dangling_names(src_dir, repo_root)
    if not grouped:
        raise RuntimeError(f"no stripped functions found under {src_dir}")

    # H12: fold dangling names into ``grouped`` so they appear as
    # ``code <name>:`` nodes alongside real stripped functions. The body
    # is a stub ``def <name>(*args, **kwargs): pass`` with a marker
    # comment so the LLM knows to reconstruct the implementation from
    # context (class-level usage, cross-file import names).
    DANGLING_DOCSTRING = (
        "Auto-detected dangling name: referenced at module scope or "
        "imported elsewhere but never defined in the stripped source. "
        "Reconstruct from usage context."
    )
    seen_in_grouped: dict[str, set[str]] = {
        stem: {entry[0] for entry in entries}
        for stem, entries in grouped.items()
    }
    for stem, items in dangling.items():
        for name, rel_inject in items:
            # Skip if already covered by a real stripped def for this file.
            if name in seen_in_grouped.get(stem, set()):
                continue
            grouped.setdefault(stem, []).append(
                (name, "*args, **kwargs", DANGLING_DOCSTRING,
                 "dangling", rel_inject)
            )
            seen_in_grouped.setdefault(stem, set()).add(name)

    out: list[str] = []

    # 1. Preambles first (module-level Python context per source file).
    #    H4 (Round 2): imports are emitted as a separate ``imports:`` block
    #    above ``body:`` so the LLM sees them as a discrete unit.
    #    H5 (Round 3): simple-name module-level constants get their own
    #    ``constants:`` block between imports and body. The body block
    #    then carries the module docstring + class definitions + complex
    #    assignments only.
    for stem, (rel_path, imports_text, constants_text, body_text) in preambles.items():
        out.append(f"preamble {stem}:")
        out.append(f"  source: {rel_path}")
        if imports_text.strip():
            out.append("  imports: |")
            for line in imports_text.splitlines():
                if line:
                    out.append(f"    {line}")
                else:
                    out.append("")
        if constants_text.strip():
            out.append("  constants: |")
            for line in constants_text.splitlines():
                if line:
                    out.append(f"    {line}")
                else:
                    out.append("")
        if body_text.strip():
            out.append("  body: |")
            for line in body_text.splitlines():
                if line:
                    out.append(f"    {line}")
                else:
                    out.append("")
        out.append("")
        out.append("")

    # 2. Top-level flow with group refs
    out.append(f"flow {repo}_lib:")
    out.append("  steps:")
    for grp in grouped:
        out.append(f"    - {grp}_group")
    out.append("")
    out.append("")

    # 3. Each file → one group flow
    for grp, entries in grouped.items():
        out.append(f"flow {grp}_group:")
        out.append("  steps:")
        for entry in entries:
            nname = entry[0]
            out.append(f"    - {nname}")
        out.append("")
        out.append("")

    # 4. Each function → one code node (with # inject-into: <path> for
    #    deterministic file selection).
    for grp, entries in grouped.items():
        for entry in entries:
            nname, sig, doc, kind, inject_path = entry
            body = _format_body(nname, sig, doc, kind, inject_path=inject_path)
            out.append(f"code {nname}:")
            out.append(f"  body: |")
            for line in body.splitlines():
                out.append(f"    {line}")
            out.append("")
            out.append("")

    return "\n".join(out).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if len(args) < 2:
        print("usage: python -m benchmarks.skeletons._autogen <repo> <src_subdir>",
              file=sys.stderr)
        print("example: python -m benchmarks.skeletons._autogen simpy src/simpy",
              file=sys.stderr)
        return 1
    repo, src_subdir = args[0], args[1]
    out = generate_skeleton(repo, src_subdir)
    target = SKELETONS_DIR / f"{repo}.al"
    target.write_text(out, encoding="utf-8")
    print(f"wrote {target}  ({out.count(chr(10))} lines, "
          f"{out.count('code ')} code nodes, {out.count('flow ')} flow nodes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
