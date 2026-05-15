"""Phase 1.AL.6 — preamble defs are silently skipped by inject_filled_al.

The agent-lang `preamble` keyword carries module-level Python (imports,
classes, constants) shown to the LLM as context. The stripped commit0
repo already contains those module-level decls, so the inject step must
NOT try to re-write them — preamble blocks exist purely for LLM-facing
prompt context.

This test asserts that:
  1. A filled .al containing a preamble + a code node injects ONLY the
     code node's body into the workdir.
  2. The preamble's body text is NEVER written to any workdir file.
  3. The InjectReport doesn't list the preamble as either injected or
     skipped (it shouldn't appear at all — it's not a code-node candidate).
"""

from __future__ import annotations

from pathlib import Path

import pytest

from benchmarks.harness.inject import inject_filled_al


def _make_stripped_workdir(tmp_path: Path) -> Path:
    """Build a tiny stripped repo: one Python module with a stub function
    and module-level scaffolding the LLM should NOT need to rewrite."""
    pkg = tmp_path / "demo"
    pkg.mkdir()
    (pkg / "__init__.py").write_text("")
    (pkg / "core.py").write_text(
        '"""Demo module docstring."""\n'
        "import sys\n"
        "\n"
        "_MARK = (sys.version_info[:2],)\n"
        "\n"
        "\n"
        "def get_mark():\n"
        "    \"\"\"Return the version marker.\"\"\"\n"
        "    pass\n"
    )
    return tmp_path


def test_inject_skips_preamble_def(tmp_path):
    """The preamble in a filled .al MUST NOT modify the workdir."""
    workdir = _make_stripped_workdir(tmp_path)
    original_text = (workdir / "demo" / "core.py").read_text()

    filled_al = (
        "preamble demo_core:\n"
        "  source: demo/core.py\n"
        "  body: |\n"
        "    # LLM hallucinated something here\n"
        "    _MARK = (object(),)\n"  # intentionally wrong — must NOT get written
        "\n\n"
        "code get_mark:\n"
        "  body: |\n"
        "    def get_mark():\n"
        "        \"\"\"Return the version marker.\"\"\"\n"
        "        return _MARK\n"
    )

    report = inject_filled_al(workdir, filled_al)

    # Verify the code node WAS injected.
    final = (workdir / "demo" / "core.py").read_text()
    assert "return _MARK" in final, "code-node body should be injected"
    # Verify the preamble's body was NOT written anywhere.
    assert "LLM hallucinated something here" not in final
    # The original module-level _MARK assignment should remain unchanged
    # (the preamble's bogus override must not have leaked).
    assert "_MARK = (sys.version_info[:2],)" in final

    # InjectReport: preamble is neither injected nor recorded as skipped.
    assert "get_mark" in report.injected
    assert "demo_core" not in report.injected
    assert "demo_core" not in report.skipped


def test_inject_multiple_preambles_silently_ignored(tmp_path):
    """Multiple preambles in one .al — still no workdir effect from them."""
    workdir = _make_stripped_workdir(tmp_path)

    filled_al = (
        "preamble a:\n"
        "  body: |\n"
        "    DEFINITELY_NOT_HERE = 1\n"
        "\n\n"
        "preamble b:\n"
        "  body: |\n"
        "    ALSO_NOT_HERE = 2\n"
        "\n\n"
        "code get_mark:\n"
        "  body: |\n"
        "    def get_mark():\n"
        "        return _MARK\n"
    )

    report = inject_filled_al(workdir, filled_al)
    final = (workdir / "demo" / "core.py").read_text()
    assert "DEFINITELY_NOT_HERE" not in final
    assert "ALSO_NOT_HERE" not in final
    assert "return _MARK" in final
    assert report.injected == ["get_mark"]
