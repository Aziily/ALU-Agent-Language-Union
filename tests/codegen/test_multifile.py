"""v0.7 Phase 3c: multi-file codegen via :func:`emit_project`."""

from __future__ import annotations

import ast

from al.codegen.emit_python import emit_project, emit_python
from al.parser.parser import parse
from al.parser.resolver import resolve_from_text


def test_single_module_codegen_unchanged():
    """v0.6 single-file path still works."""
    text = (
        "code add:\n"
        "  body: |\n"
        "    def add(a, b):\n"
        "        return a + b\n"
    )
    g = resolve_from_text(text, "main")
    out = emit_project(g)
    assert list(out) == ["main"]
    # ast.parse should succeed on emitted Python.
    ast.parse(out["main"])


def test_two_module_imports_translate_to_python():
    """``import utils`` → Python ``import utils`` in emitted main."""
    main_text = (
        "import utils\n\n"
        "code call_helper:\n"
        "  body: |\n"
        "    def call_helper():\n"
        "        return utils.helper()\n"
    )
    utils_text = (
        "code helper:\n"
        "  body: |\n"
        "    def helper():\n"
        "        return 42\n"
    )
    g = resolve_from_text(main_text, "main", {"utils": utils_text})
    out = emit_project(g)
    assert set(out) == {"main", "utils"}
    assert "import utils" in out["main"]
    # Both modules parse as valid Python.
    ast.parse(out["main"])
    ast.parse(out["utils"])


def test_from_import_translates():
    main_text = (
        "from utils import helper\n\n"
        "code call:\n"
        "  body: |\n"
        "    def call():\n"
        "        return helper()\n"
    )
    utils_text = (
        "code helper:\n"
        "  body: |\n"
        "    def helper():\n"
        "        return 42\n"
    )
    g = resolve_from_text(main_text, "main", {"utils": utils_text})
    out = emit_project(g)
    assert "from utils import helper" in out["main"]


def test_import_alias_translates():
    main_text = (
        "import data_models as dm\n\n"
        "code build:\n"
        "  body: |\n"
        "    def build():\n"
        "        return dm.Article()\n"
    )
    data_text = (
        "code Article:\n"
        "  body: |\n"
        "    class Article: pass\n"
    )
    g = resolve_from_text(main_text, "main", {"data_models": data_text})
    out = emit_project(g)
    assert "import data_models as dm" in out["main"]


def test_emission_order_matches_graph_order():
    """Leaves emit first; the result dict preserves graph.order."""
    a = "import b\n\ncode fa:\n  body: |\n    def fa(): pass\n"
    b = "import c\n\ncode fb:\n  body: |\n    def fb(): pass\n"
    c = "code fc:\n  body: |\n    def fc(): pass\n"
    g = resolve_from_text(a, "a", {"b": b, "c": c})
    out = emit_project(g)
    # In dict insertion order, "c" comes first (leaf), then "b", then "a".
    assert list(out) == ["c", "b", "a"]


def test_strict_mode_propagates():
    """Name mismatch in any module raises CodegenError."""
    import pytest
    from al.codegen.emit_code import CodegenError

    text = (
        "code parse_url:\n"
        "  body: |\n"
        "    def parse_urls(s):\n"
        "        return s\n"
    )
    g = resolve_from_text(text, "main")
    with pytest.raises(CodegenError):
        emit_project(g)
    # Lenient mode: emits anyway.
    out = emit_project(g, strict=False)
    assert "def parse_urls(s):" in out["main"]


def test_emit_python_preamble_skipped():
    """``preamble`` defs are LLM context, not emitted code."""
    text = (
        "preamble setup:\n"
        "  body: |\n"
        "    import os\n"
        "    FOO = 1\n"
        "\n"
        "code use_foo:\n"
        "  body: |\n"
        "    def use_foo():\n"
        "        return FOO\n"
    )
    out = emit_python(parse(text), strict=False)
    assert "FOO = 1" not in out  # preamble body not emitted
    assert "def use_foo():" in out
