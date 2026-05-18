"""v0.7 multi-file resolver — load + link a project of .al files.

A "project" is a directory tree containing one or more ``.al`` files.
The resolver:

1. Loads a root .al by path or text, parses it into a Program.
2. For each ``import X`` / ``from X import Y`` in the Program, locates
   the target .al on disk (``<project_root>/X.al`` or ``X/.../sub.al``
   for dotted paths) and recursively loads it.
3. Builds a :class:`ModuleGraph` with one :class:`Module` per file,
   tracking the import edges.
4. Detects cycles via DFS during build; raises :class:`ImportCycleError`.

The resolver is read-only — it doesn't mutate Programs. Codegen and
runtime are the consumers: they walk the graph to know which symbols are
visible in which module and emit ``from .X import Y`` accordingly.

Single-file (no imports) programs build a trivial graph with one Module
and no edges — this is the v0.6-compatible path.

See spec § 4.13 for resolution rules.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from al.parser.ast_nodes import ImportDecl, Program
from al.parser.parser import parse


# ---------------------------------------------------------------------------
# Exceptions
# ---------------------------------------------------------------------------


class ModuleNotFoundError(Exception):
    """An ``import X`` did not resolve to any .al on disk."""


class ImportCycleError(Exception):
    """A → B → ... → A. ``cycle`` lists the modules in cycle order."""

    def __init__(self, cycle: list[str]) -> None:
        self.cycle = cycle
        super().__init__(" → ".join(cycle) + f" → {cycle[0]}")


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class Module:
    """One .al file in the project — its parsed Program + filesystem info.

    ``name`` is the dotted module path used in ``import`` statements
    (e.g. ``pkg.sub`` for ``<root>/pkg/sub.al``). ``path`` is the
    absolute on-disk location. ``program`` is the parsed AST.
    ``imports_resolved`` maps each ImportDecl in the Program to the
    target Module's name — codegen uses this to emit the right
    Python import statements.
    """

    name: str
    path: Path
    program: Program
    imports_resolved: dict[int, str] = field(default_factory=dict)
    """``id(ImportDecl)`` → resolved module name. Keyed by id() because
    ImportDecl isn't hashable (mutable dataclass)."""


@dataclass
class ModuleGraph:
    """All :class:`Module` instances + the entry root.

    ``modules`` is name → Module. ``root_name`` is the entry-point
    module (the one passed to :func:`resolve_project`). ``order`` is a
    topological order suitable for codegen — leaf modules first, root
    last — so emitted Python compiles bottom-up.
    """

    modules: dict[str, Module] = field(default_factory=dict)
    root_name: str = ""
    order: list[str] = field(default_factory=list)

    def get(self, name: str) -> Module:
        return self.modules[name]

    @property
    def root(self) -> Module:
        return self.modules[self.root_name]


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def resolve_project(root_path: Path) -> ModuleGraph:
    """Load and link the .al project rooted at ``root_path``.

    ``root_path`` should be the path to the entry .al file. Its parent
    directory becomes the project root for resolving ``import`` targets,
    unless an ancestor contains a ``.al-project`` marker file (then that
    ancestor is the project root — useful for nested directory layouts).
    """
    root_path = Path(root_path).resolve()
    if not root_path.exists():
        raise FileNotFoundError(f"entry .al not found: {root_path}")
    if root_path.suffix != ".al":
        raise ValueError(f"entry must be a .al file: {root_path}")
    project_root = _find_project_root(root_path)
    root_name = _module_name_for_path(root_path, project_root)

    graph = ModuleGraph(root_name=root_name)
    _load_module(root_name, root_path, project_root, graph, stack=[])
    graph.order = _topo_order(graph, root_name)
    return graph


def resolve_from_text(
    root_text: str, root_name: str, project_files: dict[str, str] | None = None
) -> ModuleGraph:
    """In-memory variant of :func:`resolve_project` — useful for tests
    and Pipeline C (LLM emits multiple .al strings without writing to
    disk).

    ``root_text`` is the entry program text. ``project_files`` is a dict
    {module_name: source_text} of the rest of the project (no ``.al``
    suffix in keys). Imports resolve only against this in-memory dict.
    """
    project_files = dict(project_files or {})

    graph = ModuleGraph(root_name=root_name)
    _load_text_module(root_name, root_text, project_files, graph, stack=[])
    graph.order = _topo_order(graph, root_name)
    return graph


# ---------------------------------------------------------------------------
# Internal: filesystem-backed loader
# ---------------------------------------------------------------------------


_PROJECT_MARKER = ".al-project"


def _find_project_root(entry: Path) -> Path:
    """Walk up from ``entry`` looking for a ``.al-project`` marker; if
    none found, return the entry's parent directory."""
    for parent in entry.parents:
        if (parent / _PROJECT_MARKER).exists():
            return parent
    return entry.parent


def _module_name_for_path(p: Path, project_root: Path) -> str:
    """Convert a .al path into a dotted module name relative to root.

    ``<root>/utils.al`` → ``utils``
    ``<root>/pkg/sub.al`` → ``pkg.sub``
    """
    rel = p.resolve().relative_to(project_root.resolve())
    parts = list(rel.parts)
    parts[-1] = parts[-1][: -len(".al")] if parts[-1].endswith(".al") else parts[-1]
    return ".".join(parts)


def _path_for_module_name(name: str, project_root: Path) -> Path:
    """Inverse of :func:`_module_name_for_path`."""
    parts = name.split(".")
    return project_root.joinpath(*parts).with_suffix(".al")


def _load_module(
    name: str,
    path: Path,
    project_root: Path,
    graph: ModuleGraph,
    stack: list[str],
) -> None:
    # Stack check FIRST — catches self-imports and back-edges to a
    # module that is still being loaded. graph.modules only contains
    # FULLY-loaded modules, so an early-return on it is safe.
    if name in stack:
        raise ImportCycleError(stack[stack.index(name) :])
    if name in graph.modules:
        return
    stack = stack + [name]

    text = path.read_text(encoding="utf-8")
    program = parse(text)
    module = Module(name=name, path=path, program=program)

    for imp in program.imports:
        target_name = imp.module
        target_path = _path_for_module_name(target_name, project_root)
        if not target_path.exists():
            raise ModuleNotFoundError(
                f"{name}: cannot resolve `{_render_import(imp)}` — "
                f"{target_path} not found"
            )
        _load_module(target_name, target_path, project_root, graph, stack)
        module.imports_resolved[id(imp)] = target_name
    # Add to graph AFTER children resolve, so cycle detection on the
    # stack works correctly.
    graph.modules[name] = module


def _load_text_module(
    name: str,
    text: str,
    project_files: dict[str, str],
    graph: ModuleGraph,
    stack: list[str],
) -> None:
    if name in stack:
        raise ImportCycleError(stack[stack.index(name) :])
    if name in graph.modules:
        return
    stack = stack + [name]

    program = parse(text)
    module = Module(name=name, path=Path(f"<memory:{name}>"), program=program)

    for imp in program.imports:
        target_name = imp.module
        if target_name not in project_files:
            raise ModuleNotFoundError(
                f"{name}: cannot resolve `{_render_import(imp)}` — "
                f"no in-memory text for module {target_name!r}"
            )
        _load_text_module(
            target_name, project_files[target_name], project_files, graph, stack
        )
        module.imports_resolved[id(imp)] = target_name
    graph.modules[name] = module


def _render_import(imp: ImportDecl) -> str:
    """Reconstruct the source-level text for an ImportDecl (for error messages)."""
    if imp.kind == "import":
        return (
            f"import {imp.module} as {imp.alias}" if imp.alias
            else f"import {imp.module}"
        )
    return f"from {imp.module} import {', '.join(imp.names)}"


# ---------------------------------------------------------------------------
# Topological order
# ---------------------------------------------------------------------------


def _topo_order(graph: ModuleGraph, root_name: str) -> list[str]:
    """Return modules in dependency order (leaves first, root last).

    Cycles already rejected at load time, so a simple DFS suffices.
    """
    order: list[str] = []
    visited: set[str] = set()

    def visit(name: str) -> None:
        if name in visited:
            return
        visited.add(name)
        for dep_name in graph.modules[name].imports_resolved.values():
            visit(dep_name)
        order.append(name)

    visit(root_name)
    # Append any disconnected modules (shouldn't happen via load, but be safe).
    for n in graph.modules:
        if n not in visited:
            visit(n)
    return order
