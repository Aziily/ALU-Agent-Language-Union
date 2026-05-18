"""v0.7.1 Codex round 1 — Targeted Body inject tests.

When a `code` node has `target: <relpath>::<qualname>` and its `body:`
lacks a `def` line, the inject pipeline should synthesize the def using
the stripped Python's existing signature, then proceed normally.
"""

from __future__ import annotations

from pathlib import Path

from benchmarks.harness.inject import inject_filled_al


def _write_stripped(tmp_path: Path, relpath: str, source: str) -> Path:
    p = tmp_path / relpath
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(source)
    return p


# ---------------------------------------------------------------------------
# Top-level function targets
# ---------------------------------------------------------------------------


def test_targeted_body_toplevel_function(tmp_path):
    _write_stripped(
        tmp_path, "mylib/keys.py",
        "def hashkey(*args, **kwargs):\n"
        "    pass\n",
    )
    al_text = (
        "code hashkey:\n"
        "  target: mylib/keys.py::hashkey\n"
        "  body: |\n"
        "    if kwargs:\n"
        "        return (args, tuple(sorted(kwargs.items())))\n"
        "    return args\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "hashkey" in report.injected
    assert not report.skipped
    out = (tmp_path / "mylib/keys.py").read_text()
    assert "def hashkey(*args, **kwargs):" in out
    assert "if kwargs:" in out
    assert "NotImplementedError" not in out


def test_targeted_body_preserves_signature_defaults(tmp_path):
    """``def f(maxsize=128, typed=False)`` defaults are taken from stripped
    Python — LLM never has to re-state them."""
    _write_stripped(
        tmp_path, "mylib/cache.py",
        "def fifo_cache(maxsize=128, typed=False):\n"
        "    pass\n",
    )
    al_text = (
        "code fifo_cache:\n"
        "  target: mylib/cache.py::fifo_cache\n"
        "  body: |\n"
        "    return (maxsize, typed)\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "fifo_cache" in report.injected
    out = (tmp_path / "mylib/cache.py").read_text()
    # Defaults preserved verbatim
    assert "def fifo_cache(maxsize=128, typed=False):" in out
    assert "return (maxsize, typed)" in out


def test_targeted_body_preserves_decorators(tmp_path):
    _write_stripped(
        tmp_path, "mylib/decorated.py",
        "import functools\n"
        "\n"
        "@functools.lru_cache\n"
        "def memoized(x):\n"
        "    pass\n",
    )
    al_text = (
        "code memoized:\n"
        "  target: mylib/decorated.py::memoized\n"
        "  body: |\n"
        "    return x * 2\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "memoized" in report.injected
    out = (tmp_path / "mylib/decorated.py").read_text()
    assert "@functools.lru_cache" in out
    assert "def memoized(x):" in out
    assert "return x * 2" in out


def test_targeted_body_class_method(tmp_path):
    _write_stripped(
        tmp_path, "mylib/cache.py",
        "class LRUCache:\n"
        "    def __init__(self, maxsize):\n"
        "        self._store = {}\n"
        "    def get(self, key, default=None):\n"
        "        pass\n",
    )
    al_text = (
        "code LRUCache_get:\n"
        "  target: mylib/cache.py::LRUCache.get\n"
        "  body: |\n"
        "    return self._store.get(key, default)\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "LRUCache_get" in report.injected
    out = (tmp_path / "mylib/cache.py").read_text()
    # The method body got replaced.
    assert "return self._store.get(key, default)" in out
    # Class structure preserved.
    assert "class LRUCache:" in out
    assert "def __init__(self, maxsize):" in out


# ---------------------------------------------------------------------------
# Coexistence with legacy (no-target) path
# ---------------------------------------------------------------------------


def test_legacy_full_def_path_still_works(tmp_path):
    """Without ``target:``, the body MUST contain a full def — current behavior."""
    _write_stripped(
        tmp_path, "mylib/x.py",
        "def add(a, b):\n"
        "    pass\n",
    )
    al_text = (
        "code add:\n"
        "  body: |\n"
        "    def add(a, b):\n"
        "        return a + b\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "add" in report.injected


def test_target_overrides_when_body_has_def(tmp_path):
    """If both ``target:`` and a full ``def`` in body are present, the body
    takes precedence (target acts as a hint that's ignored when redundant)."""
    _write_stripped(
        tmp_path, "mylib/x.py",
        "def add(a, b):\n"
        "    pass\n",
    )
    al_text = (
        "code add:\n"
        "  target: mylib/x.py::add\n"
        "  body: |\n"
        "    def add(a, b):\n"
        "        return a - b\n"  # different impl
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "add" in report.injected
    out = (tmp_path / "mylib/x.py").read_text()
    assert "return a - b" in out


# ---------------------------------------------------------------------------
# Failure modes
# ---------------------------------------------------------------------------


def test_target_not_found_appends_toplevel(tmp_path):
    """v0.7.3+: when target's qualname is missing AND it's a top-level
    function name (no dot in qualname), append the def to the file."""
    _write_stripped(
        tmp_path, "mylib/x.py",
        "def real_function():\n    pass\n",
    )
    al_text = (
        "code ghost:\n"
        "  target: mylib/x.py::ghost\n"
        "  body: |\n"
        "    return 1\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "ghost" in report.injected, report.skipped
    out = (tmp_path / "mylib/x.py").read_text()
    assert "def ghost(" in out
    assert "return 1" in out


def test_target_file_missing_skipped(tmp_path):
    al_text = (
        "code orphan:\n"
        "  target: nonexistent/dir.py::orphan\n"
        "  body: |\n"
        "    return None\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "orphan" in report.skipped


def test_target_malformed_skipped(tmp_path):
    """``target:`` without ``::`` is malformed."""
    _write_stripped(tmp_path, "mylib/x.py", "def f(): pass\n")
    al_text = (
        "code bad:\n"
        "  target: mylib/x.py\n"  # missing ::qualname
        "  body: |\n"
        "    return 1\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "bad" in report.skipped


# ---------------------------------------------------------------------------
# v0.7.3+ — Append when target's qualname doesn't exist
# ---------------------------------------------------------------------------


def test_target_append_when_qualname_missing(tmp_path):
    """When ``target:`` points to a function NOT in the stripped file (commit0
    sometimes strips the whole def), inject should APPEND it to the file."""
    _write_stripped(
        tmp_path, "pkg/mod.py",
        "import os\n"
        "\n"
        "class Existing: pass\n",  # no `def lock` here
    )
    al_text = (
        "code lock:\n"
        "  target: pkg/mod.py::lock\n"
        "  body: |\n"
        "    return os.path.exists('lockfile')\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "lock" in report.injected
    out = (tmp_path / "pkg/mod.py").read_text()
    # The function got appended
    assert "def lock(" in out
    assert "os.path.exists('lockfile')" in out


def test_target_append_skips_class_method(tmp_path):
    """Class methods need a class body to insert into — too brittle to
    auto-append. Should fail-skip cleanly."""
    _write_stripped(
        tmp_path, "pkg/mod.py", "class A: pass\n",
    )
    al_text = (
        "code A_get:\n"
        "  target: pkg/mod.py::A.get\n"
        "  body: |\n"
        "    return self._x\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    # Should skip with "not found" — not crash
    assert "A_get" in report.skipped


# ---------------------------------------------------------------------------
# v1.1 — target: relpath disambiguates same-name functions across files
# ---------------------------------------------------------------------------


def test_target_disambiguates_same_name_across_files(tmp_path):
    """When two files have ``def deprecated()``, target:'s relpath says
    which one to inject. Without this, _find_and_inject can pick either
    (the Phase C deprecated/portalocker regression in v1.0)."""
    _write_stripped(
        tmp_path, "pkg/classic.py",
        "def deprecated(reason=None):\n    pass\n",
    )
    _write_stripped(
        tmp_path, "pkg/sphinx.py",
        "def deprecated(reason=None):\n    pass\n",
    )
    # Inject into ONLY pkg/classic.py
    al_text = (
        "code deprecated:\n"
        "  target: pkg/classic.py::deprecated\n"
        "  body: |\n"
        "    return f'CLASSIC: {reason}'\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "deprecated" in report.injected
    classic = (tmp_path / "pkg/classic.py").read_text()
    sphinx = (tmp_path / "pkg/sphinx.py").read_text()
    assert "CLASSIC" in classic, "expected body injected into classic.py"
    assert "CLASSIC" not in sphinx, "sphinx.py must NOT be touched"
    # sphinx.py's deprecated remains stubbed
    assert "pass" in sphinx


def test_target_relpath_wins_over_class_hint(tmp_path):
    """If node name suggests a class (``Foo__bar``) but target: points
    elsewhere, target: wins."""
    _write_stripped(
        tmp_path, "pkg/x.py",
        "def bar(self):\n    pass\n",
    )
    al_text = (
        "code Foo__bar:\n"
        "  target: pkg/x.py::bar\n"
        "  body: |\n"
        "    def bar(self):\n"
        "        return 'top-level'\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "Foo__bar" in report.injected
    assert "top-level" in (tmp_path / "pkg/x.py").read_text()


def test_target_relpath_class_method_disambiguates(tmp_path):
    """``target: pkg/x.py::Foo.bar`` should find Foo class in x.py, not
    some other Foo elsewhere."""
    _write_stripped(
        tmp_path, "pkg/x.py",
        "class Foo:\n"
        "    def bar(self):\n        pass\n",
    )
    _write_stripped(
        tmp_path, "pkg/y.py",
        "class Foo:\n"
        "    def bar(self):\n        pass\n",
    )
    al_text = (
        "code XFoo__bar:\n"  # unusual name; tests that target: drives, not node name
        "  target: pkg/x.py::Foo.bar\n"
        "  body: |\n"
        "    return 'x'\n"
    )
    report = inject_filled_al(tmp_path, al_text)
    assert "XFoo__bar" in report.injected, report.skipped
    x_text = (tmp_path / "pkg/x.py").read_text()
    y_text = (tmp_path / "pkg/y.py").read_text()
    assert "return 'x'" in x_text
    assert "return 'x'" not in y_text
