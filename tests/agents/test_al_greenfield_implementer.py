"""Tests for the v0.7 greenfield (Pipeline C) implementer."""

from __future__ import annotations

from al.llm import MockLLMClient
from benchmarks.agents.al_greenfield_implementer import (
    _split_files,
    run_al_greenfield_implementer,
)


# ---------------------------------------------------------------------------
# _split_files — markers parsing
# ---------------------------------------------------------------------------


def test_split_files_single_block():
    raw = (
        "---FILE: main.al---\n"
        "code f:\n"
        "  body: |\n"
        "    def f(): return 1\n"
    )
    files = _split_files(raw)
    assert len(files) == 1
    assert files[0].relpath == "main.al"
    assert "code f:" in files[0].al_text


def test_split_files_two_blocks():
    raw = (
        "---FILE: a/main.al---\n"
        "code f1:\n  body: |\n    def f1(): pass\n"
        "\n---FILE: a/util.al---\n"
        "code f2:\n  body: |\n    def f2(): pass\n"
    )
    files = _split_files(raw)
    assert [f.relpath for f in files] == ["a/main.al", "a/util.al"]


def test_split_files_no_markers_returns_unnamed():
    raw = "code f:\n  body: |\n    def f(): pass\n"
    files = _split_files(raw)
    assert len(files) == 1
    assert files[0].relpath == "<unnamed>.al"


def test_split_files_tolerates_leading_prose():
    raw = (
        "Sure, here are the files:\n\n"
        "---FILE: main.al---\n"
        "code f:\n  body: |\n    def f(): return 1\n"
    )
    files = _split_files(raw)
    assert len(files) == 1
    assert files[0].relpath == "main.al"


# ---------------------------------------------------------------------------
# Full run with mock LLM
# ---------------------------------------------------------------------------


SAMPLE_STRIPPED = {
    "pkg/main.py": (
        "def add(a, b):\n"
        "    raise NotImplementedError('IMPLEMENT ME HERE')\n"
    ),
}


def test_greenfield_smoke_single_file():
    canned = (
        "---FILE: pkg/main.al---\n"
        "code add:\n"
        "  body: |\n"
        "    def add(a, b):\n"
        "        return a + b\n"
    )
    llm = MockLLMClient(default=canned)
    r = run_al_greenfield_implementer(
        spec_text="add two numbers",
        stripped_files=SAMPLE_STRIPPED,
        llm=llm,
        guide_text="(mock guide)",
    )
    assert r.parse_overall_ok is True
    assert len(r.files) == 1
    f = r.files[0]
    assert f.relpath == "pkg/main.al"
    assert f.ok is True
    assert "return a + b" in f.al_text


def test_greenfield_two_files_with_import():
    canned = (
        "---FILE: pkg/main.al---\n"
        "from util import helper\n\n"
        "code use:\n"
        "  body: |\n"
        "    def use():\n"
        "        return helper()\n"
        "\n---FILE: util.al---\n"
        "code helper:\n"
        "  body: |\n"
        "    def helper():\n"
        "        return 42\n"
    )
    llm = MockLLMClient(default=canned)
    r = run_al_greenfield_implementer(
        spec_text="call helper",
        stripped_files=SAMPLE_STRIPPED,
        llm=llm,
        guide_text="(mock guide)",
    )
    assert r.parse_overall_ok is True
    assert len(r.files) == 2
    # Note: pkg/main.al → pkg.main module name; resolver may not pick it
    # as root if "main" isn't a direct match. Just verify both parsed.
    assert all(f.ok for f in r.files)


def test_greenfield_invalid_python_body_flagged():
    canned = (
        "---FILE: main.al---\n"
        "code broken:\n"
        "  body: |\n"
        "    def broken(:\n"
        "        syntax error\n"
    )
    llm = MockLLMClient(default=canned)
    r = run_al_greenfield_implementer(
        spec_text="",
        stripped_files=SAMPLE_STRIPPED,
        llm=llm,
        guide_text="(mock guide)",
    )
    # File parsed as AL but body has Python SyntaxError
    f = r.files[0]
    assert "broken" in f.body_errors
    assert "syntax" in f.body_errors["broken"].lower() or "invalid" in f.body_errors["broken"].lower() or "(" in f.body_errors["broken"]
    assert r.all_files_clean is False


def test_greenfield_al_parse_error():
    canned = (
        "---FILE: main.al---\n"
        "not a valid agent-lang file at all\n"
    )
    llm = MockLLMClient(default=canned)
    r = run_al_greenfield_implementer(
        spec_text="",
        stripped_files=SAMPLE_STRIPPED,
        llm=llm,
        guide_text="(mock guide)",
    )
    # Either parses as empty program, or fails. Either way, not clean.
    if r.files[0].parse_error:
        assert not r.parse_overall_ok
    assert r.all_files_clean is False or not r.files[0].program.defs


def test_greenfield_iter_feedback_in_prompt():
    """When iter_idx > 0, the prompt includes previous attempt + test output."""
    canned = (
        "---FILE: main.al---\n"
        "code f:\n  body: |\n    def f(): return 1\n"
    )
    llm = MockLLMClient(default=canned)
    r = run_al_greenfield_implementer(
        spec_text="",
        stripped_files=SAMPLE_STRIPPED,
        llm=llm,
        guide_text="(mock guide)",
        previous_filled="---FILE: main.al---\ncode f:\n  body: |\n    def f(): pass\n",
        previous_test_output="FAILED test_x",
        iter_idx=1,
    )
    assert "Previous attempt" in r.prompt_used
    assert "FAILED test_x" in r.prompt_used


def test_greenfield_strict_io_validation_surfaces_warnings():
    """TypedAnnotation issues surface in file.validation_issues — they're
    warnings, not blockers."""
    canned = (
        "---FILE: main.al---\n"
        "code f:\n"
        "  input: raw HTML\n"
        "  body: |\n"
        "    def f(x): return x\n"
    )
    llm = MockLLMClient(default=canned)
    r = run_al_greenfield_implementer(
        spec_text="", stripped_files=SAMPLE_STRIPPED, llm=llm,
        guide_text="(mock guide)",
    )
    f = r.files[0]
    # Body still ok, but strict validation flags the legacy I/O.
    assert f.ok  # parses + body valid
    assert any(i.code == "io-not-python-type" for i in f.validation_issues)
