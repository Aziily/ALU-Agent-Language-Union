"""Tests for v0.7 multi-file resolver (al.parser.resolver)."""

from __future__ import annotations

from pathlib import Path

import pytest

from al.parser.resolver import (
    ImportCycleError,
    ModuleNotFoundError,
    resolve_from_text,
    resolve_project,
)


# ---------------------------------------------------------------------------
# In-memory resolver (used heavily by Pipeline C)
# ---------------------------------------------------------------------------


def test_resolve_single_file_no_imports():
    """v0.6-compatible: a single .al with no imports builds a trivial graph."""
    text = "code f:\n  body: |\n    def f(): pass\n"
    g = resolve_from_text(text, "main")
    assert list(g.modules) == ["main"]
    assert g.order == ["main"]
    assert g.root_name == "main"
    assert g.root.program.imports == []


def test_resolve_simple_two_file():
    """``main`` imports ``utils``; graph has both modules."""
    main_text = (
        "import utils\n\n"
        "code f:\n  body: |\n    def f(): pass\n"
    )
    utils_text = "code helper:\n  body: |\n    def helper(): pass\n"
    g = resolve_from_text(main_text, "main", {"utils": utils_text})
    assert set(g.modules) == {"main", "utils"}
    assert g.order == ["utils", "main"]
    assert g.root.imports_resolved
    [resolved] = list(g.root.imports_resolved.values())
    assert resolved == "utils"


def test_resolve_from_import_form():
    main_text = (
        "from data import Article\n\n"
        "code build:\n  body: |\n    def build(): return Article()\n"
    )
    data_text = "code Article:\n  body: |\n    class Article: pass\n"
    g = resolve_from_text(main_text, "main", {"data": data_text})
    assert g.order == ["data", "main"]


def test_resolve_chain_a_b_c():
    """a → b → c; topological order is c, b, a."""
    a = "import b\n\ncode fa:\n  body: |\n    def fa(): pass\n"
    b = "import c\n\ncode fb:\n  body: |\n    def fb(): pass\n"
    c = "code fc:\n  body: |\n    def fc(): pass\n"
    g = resolve_from_text(a, "a", {"b": b, "c": c})
    assert g.order == ["c", "b", "a"]


def test_resolve_diamond_a_imports_b_and_c_both_import_d():
    """a → {b, c} → d; d visited once, order respects dependencies."""
    a = "import b\nimport c\n\ncode fa:\n  body: |\n    def fa(): pass\n"
    b = "import d\n\ncode fb:\n  body: |\n    def fb(): pass\n"
    c = "import d\n\ncode fc:\n  body: |\n    def fc(): pass\n"
    d = "code fd:\n  body: |\n    def fd(): pass\n"
    g = resolve_from_text(a, "a", {"b": b, "c": c, "d": d})
    # d must come before b and c; b and c must come before a.
    assert g.order.index("d") < g.order.index("b")
    assert g.order.index("d") < g.order.index("c")
    assert g.order.index("b") < g.order.index("a")
    assert g.order.index("c") < g.order.index("a")
    # Each module loaded once.
    assert len(g.order) == 4


def test_resolve_cycle_self_import_raises():
    text = "import main\n\ncode f:\n  body: |\n    def f(): pass\n"
    with pytest.raises(ImportCycleError):
        resolve_from_text(text, "main", {"main": text})


def test_resolve_cycle_a_b_a_raises():
    a = "import b\n\ncode fa:\n  body: |\n    def fa(): pass\n"
    b = "import a\n\ncode fb:\n  body: |\n    def fb(): pass\n"
    with pytest.raises(ImportCycleError) as exc:
        resolve_from_text(a, "a", {"b": b, "a": a})
    # The cycle path mentions both modules.
    assert "a" in str(exc.value) and "b" in str(exc.value)


def test_resolve_missing_module_raises():
    text = "import does_not_exist\n\ncode f:\n  body: |\n    def f(): pass\n"
    with pytest.raises(ModuleNotFoundError):
        resolve_from_text(text, "main", {})


# ---------------------------------------------------------------------------
# Filesystem-backed resolver (used by CLI / human .al projects)
# ---------------------------------------------------------------------------


def test_resolve_project_from_disk(tmp_path: Path):
    (tmp_path / "main.al").write_text(
        "import utils\n\ncode f:\n  body: |\n    def f(): pass\n"
    )
    (tmp_path / "utils.al").write_text(
        "code helper:\n  body: |\n    def helper(): pass\n"
    )
    g = resolve_project(tmp_path / "main.al")
    assert set(g.modules) == {"main", "utils"}
    assert g.order == ["utils", "main"]


def test_resolve_project_dotted_path(tmp_path: Path):
    (tmp_path / "main.al").write_text(
        "from pkg.sub import x\n\ncode f:\n  body: |\n    def f(): pass\n"
    )
    pkg = tmp_path / "pkg"
    pkg.mkdir()
    (pkg / "sub.al").write_text(
        "code x:\n  body: |\n    def x(): pass\n"
    )
    g = resolve_project(tmp_path / "main.al")
    assert "pkg.sub" in g.modules


def test_resolve_project_missing_file_raises(tmp_path: Path):
    (tmp_path / "main.al").write_text(
        "import ghost\n\ncode f:\n  body: |\n    def f(): pass\n"
    )
    with pytest.raises(ModuleNotFoundError):
        resolve_project(tmp_path / "main.al")


def test_resolve_project_root_marker(tmp_path: Path):
    """``.al-project`` marker fixes the project root even when the entry
    file lives inside a subdirectory."""
    (tmp_path / ".al-project").write_text("")
    (tmp_path / "shared.al").write_text(
        "code helper:\n  body: |\n    def helper(): pass\n"
    )
    sub = tmp_path / "app"
    sub.mkdir()
    (sub / "main.al").write_text(
        "import shared\n\ncode f:\n  body: |\n    def f(): pass\n"
    )
    g = resolve_project(sub / "main.al")
    # Root was tmp_path due to marker, so ``shared`` resolves at top level.
    assert "shared" in g.modules
