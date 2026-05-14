"""Tests for benchmarks.harness.inject."""

from __future__ import annotations

import ast
from pathlib import Path

import pytest

from benchmarks.harness.inject import (
    InjectReport,
    _class_hint_from_node_name,
    _extract_file_hint,
    _is_stripped,
    _parse_body_function,
    inject_filled_al,
    inject_python_files,
)


# ---------------------------------------------------------------------------
# inject_python_files (Pipeline A)
# ---------------------------------------------------------------------------


def test_inject_python_writes_files(tmp_path):
    files = {
        "pkg/a.py": "def a(): return 1\n",
        "pkg/b.py": "def b(): return 2\n",
    }
    report = inject_python_files(tmp_path, files)
    assert (tmp_path / "pkg" / "a.py").read_text() == "def a(): return 1\n"
    assert (tmp_path / "pkg" / "b.py").read_text() == "def b(): return 2\n"
    assert set(report.injected) == {"pkg/a.py", "pkg/b.py"}
    assert report.success_rate == 1.0


def test_inject_python_creates_missing_dirs(tmp_path):
    files = {"deep/nested/dir/x.py": "x = 1\n"}
    inject_python_files(tmp_path, files)
    assert (tmp_path / "deep" / "nested" / "dir" / "x.py").exists()


def test_inject_python_overwrites(tmp_path):
    (tmp_path / "x.py").write_text("def x(): pass\n")
    inject_python_files(tmp_path, {"x.py": "def x(): return 42\n"})
    assert (tmp_path / "x.py").read_text() == "def x(): return 42\n"


# ---------------------------------------------------------------------------
# Helper unit tests
# ---------------------------------------------------------------------------


def test_class_hint_pascalcase():
    assert _class_hint_from_node_name("Schema__compile_dict") == "Schema"
    assert _class_hint_from_node_name("Lock__acquire") == "Lock"


def test_class_hint_no_dunder():
    assert _class_hint_from_node_name("hashkey") is None
    assert _class_hint_from_node_name("simple_name") is None


def test_class_hint_lowercase_prefix_treated_as_file():
    """Lowercase first segment → not a class (it's a file hint via different convention)."""
    assert _class_hint_from_node_name("classic_deprecated") is None
    assert _class_hint_from_node_name("sphinx_versionadded") is None


def test_extract_file_hint_present():
    body = "# inject-into: deprecated/classic.py\ndef x(): pass\n"
    assert _extract_file_hint(body) == "deprecated/classic.py"


def test_extract_file_hint_absent():
    body = "def x(): pass\n"
    assert _extract_file_hint(body) is None


def test_parse_body_function_simple():
    name, node = _parse_body_function("def foo(x):\n    return x + 1\n")
    assert name == "foo"
    assert isinstance(node, ast.FunctionDef)


def test_parse_body_function_with_decorator():
    body = "@property\ndef bar(self):\n    return self._x\n"
    name, _ = _parse_body_function(body)
    assert name == "bar"


def test_parse_body_function_no_function():
    with pytest.raises(ValueError, match="no function definition"):
        _parse_body_function("x = 1\n")


def test_parse_body_function_syntax_error():
    with pytest.raises(ValueError, match="SyntaxError"):
        _parse_body_function("def foo(: invalid\n")


def test_is_stripped_pass_only():
    tree = ast.parse("def f(): pass\n")
    assert _is_stripped(tree.body[0])


def test_is_stripped_docstring_then_pass():
    tree = ast.parse('def f():\n    """doc."""\n    pass\n')
    assert _is_stripped(tree.body[0])


def test_is_stripped_real_body():
    tree = ast.parse("def f(): return 1\n")
    assert not _is_stripped(tree.body[0])


# ---------------------------------------------------------------------------
# inject_filled_al — single top-level function
# ---------------------------------------------------------------------------


def test_inject_al_top_level_function(tmp_path):
    # Set up a tiny stripped repo
    (tmp_path / "lib.py").write_text(
        "def hashkey(*args):\n"
        "    \"\"\"Return a cache key.\"\"\"\n"
        "    pass\n"
    )
    filled = """\
code hashkey:
  intent: return a hashable cache key
  body: |
    def hashkey(*args):
        return tuple(args)
"""
    report = inject_filled_al(tmp_path, filled)
    assert "hashkey" in report.injected
    assert not report.skipped
    new_src = (tmp_path / "lib.py").read_text()
    assert "return tuple(args)" in new_src
    assert "pass" not in new_src.split("def hashkey")[1].split("\ndef")[0]


def test_inject_al_class_method(tmp_path):
    (tmp_path / "lib.py").write_text(
        "class Lock:\n"
        "    def acquire(self):\n"
        "        \"\"\"Acquire.\"\"\"\n"
        "        pass\n"
    )
    filled = """\
code Lock__acquire:
  intent: acquire the lock
  body: |
    def acquire(self):
        self.locked = True
        return True
"""
    report = inject_filled_al(tmp_path, filled)
    assert "Lock__acquire" in report.injected
    src = (tmp_path / "lib.py").read_text()
    assert "self.locked = True" in src


def test_inject_al_cross_file_collision_with_hint(tmp_path):
    """Two files have `deprecated`; use file hint to disambiguate."""
    (tmp_path / "classic.py").write_text(
        "def deprecated():\n    \"\"\"classic.\"\"\"\n    pass\n"
    )
    (tmp_path / "sphinx.py").write_text(
        "def deprecated():\n    \"\"\"sphinx.\"\"\"\n    pass\n"
    )
    filled = """\
code classic_deprecated:
  intent: classic
  body: |
    # inject-into: classic.py
    def deprecated():
        return "classic-fill"

code sphinx_deprecated:
  intent: sphinx
  body: |
    # inject-into: sphinx.py
    def deprecated():
        return "sphinx-fill"
"""
    report = inject_filled_al(tmp_path, filled)
    assert set(report.injected) == {"classic_deprecated", "sphinx_deprecated"}
    assert not report.skipped
    assert "classic-fill" in (tmp_path / "classic.py").read_text()
    assert "sphinx-fill" in (tmp_path / "sphinx.py").read_text()


def test_inject_al_ambiguous_skipped(tmp_path):
    """Cross-file collision WITHOUT hint → skipped (>1 match)."""
    (tmp_path / "a.py").write_text(
        "def foo():\n    \"\"\"a.\"\"\"\n    pass\n"
    )
    (tmp_path / "b.py").write_text(
        "def foo():\n    \"\"\"b.\"\"\"\n    pass\n"
    )
    filled = """\
code my_foo:
  intent: ambiguous
  body: |
    def foo():
        return 1
"""
    report = inject_filled_al(tmp_path, filled)
    assert "my_foo" in report.skipped
    assert "no stripped target" in report.skipped["my_foo"]


def test_inject_al_no_match_skipped(tmp_path):
    """Body references function that doesn't exist in workdir."""
    (tmp_path / "lib.py").write_text("def existing(): pass\n")
    filled = """\
code missing_node:
  intent: missing
  body: |
    def nonexistent():
        return 1
"""
    report = inject_filled_al(tmp_path, filled)
    assert "missing_node" in report.skipped


def test_inject_al_skips_non_stripped(tmp_path):
    """If the target is already implemented (not stripped), skip — don't overwrite."""
    (tmp_path / "lib.py").write_text(
        "def hashkey():\n    return 'already implemented'\n"
    )
    filled = """\
code hashkey:
  intent: x
  body: |
    def hashkey():
        return 'new'
"""
    report = inject_filled_al(tmp_path, filled)
    assert "hashkey" in report.skipped  # not stripped, no inject
    src = (tmp_path / "lib.py").read_text()
    assert "already implemented" in src


def test_inject_al_preserves_docstring_when_llm_omits(tmp_path):
    """LLM body without docstring → original docstring preserved."""
    (tmp_path / "lib.py").write_text(
        "def foo():\n    \"\"\"original doc.\"\"\"\n    pass\n"
    )
    filled = """\
code foo:
  intent: x
  body: |
    def foo():
        return 42
"""
    inject_filled_al(tmp_path, filled)
    src = (tmp_path / "lib.py").read_text()
    assert "original doc" in src
    assert "return 42" in src


def test_inject_al_uses_llm_docstring_when_present(tmp_path):
    """LLM body with docstring → that one wins."""
    (tmp_path / "lib.py").write_text(
        "def foo():\n    \"\"\"original.\"\"\"\n    pass\n"
    )
    filled = """\
code foo:
  intent: x
  body: |
    def foo():
        '''new doc.'''
        return 1
"""
    inject_filled_al(tmp_path, filled)
    src = (tmp_path / "lib.py").read_text()
    assert "new doc" in src


def test_inject_al_body_parse_error_recorded(tmp_path):
    (tmp_path / "lib.py").write_text("def foo(): pass\n")
    filled = """\
code foo:
  intent: x
  body: |
    def foo(:
        broken
"""
    report = inject_filled_al(tmp_path, filled)
    assert "foo" in report.skipped
    assert "parse failed" in report.skipped["foo"]


def test_inject_report_success_rate():
    r = InjectReport()
    r.injected = ["a", "b"]
    r.skipped = {"c": "nope"}
    assert r.success_rate == pytest.approx(2 / 3)
