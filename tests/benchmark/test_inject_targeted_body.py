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


def test_target_not_found_skipped(tmp_path):
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
    assert "ghost" in report.skipped
    assert "target" in report.skipped["ghost"].lower()


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
