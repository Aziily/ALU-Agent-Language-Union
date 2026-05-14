"""Tests for benchmarks.agents.python_implementer."""

from __future__ import annotations

from al.llm import MockLLMClient
from benchmarks.agents.python_implementer import (
    PythonImplementerResult,
    run_python_implementer,
    _strip_code_fences,
    _split_file_markers,
)


# ---------------------------------------------------------------------------
# Smoke
# ---------------------------------------------------------------------------


def test_python_implementer_single_file_basic():
    """LLM returns the file content with FILE marker."""
    canned_completion = (
        "# === FILE: example.py ===\n"
        "def add(x, y):\n"
        "    return x + y\n"
    )
    llm = MockLLMClient(default=canned_completion)
    stripped = {"example.py": "def add(x, y): pass\n"}
    r = run_python_implementer(
        spec_text="adds two numbers",
        stripped_files=stripped,
        llm=llm,
    )
    assert r.parse_ok is True
    assert "example.py" in r.files
    assert "return x + y" in r.files["example.py"]


def test_python_implementer_multi_file():
    """Multiple files separated by FILE markers."""
    canned = (
        "# === FILE: a.py ===\n"
        "def a(): return 1\n"
        "\n"
        "# === FILE: b.py ===\n"
        "def b(): return 2\n"
    )
    llm = MockLLMClient(default=canned)
    r = run_python_implementer(
        spec_text="spec",
        stripped_files={"a.py": "def a(): pass", "b.py": "def b(): pass"},
        llm=llm,
    )
    assert r.parse_ok is True
    assert set(r.files) == {"a.py", "b.py"}
    assert "return 1" in r.files["a.py"]
    assert "return 2" in r.files["b.py"]


def test_python_implementer_lenient_single_file_no_marker():
    """Single stripped file + LLM forgot marker → use whole output for that file."""
    llm = MockLLMClient(default="def x(): return 42\n")
    r = run_python_implementer(
        spec_text="",
        stripped_files={"only.py": "def x(): pass"},
        llm=llm,
    )
    assert r.parse_ok is True
    assert "only.py" in r.files
    assert "return 42" in r.files["only.py"]


def test_python_implementer_invalid_syntax_caught():
    """LLM emits broken Python → parse_ok=False with error message."""
    llm = MockLLMClient(default="# === FILE: x.py ===\ndef bad(: invalid syntax\n")
    r = run_python_implementer(
        spec_text="",
        stripped_files={"x.py": "def bad(): pass"},
        llm=llm,
    )
    assert r.parse_ok is False
    assert "x.py" in r.parse_error


def test_python_implementer_no_marker_multifile_fails():
    """No marker + multiple stripped files → can't split, empty files."""
    llm = MockLLMClient(default="def a(): return 1\n")
    r = run_python_implementer(
        spec_text="",
        stripped_files={"a.py": "...", "b.py": "..."},
        llm=llm,
    )
    assert r.parse_ok is False
    assert r.files == {}
    assert "forgotten file markers" in r.parse_error


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def test_strip_code_fences_python():
    text = "```python\ndef x(): pass\n```"
    assert _strip_code_fences(text).strip() == "def x(): pass"


def test_strip_code_fences_plain():
    text = "```\ndef x(): pass\n```"
    assert _strip_code_fences(text).strip() == "def x(): pass"


def test_strip_code_fences_no_fences():
    text = "def x(): pass"
    assert _strip_code_fences(text).strip() == "def x(): pass"


# ---------------------------------------------------------------------------
# Prompt content
# ---------------------------------------------------------------------------


def test_prompt_includes_spec_and_files():
    """Verify the LLM saw both spec and stripped files in the prompt."""
    captured = {}
    def grab(prompt, **kw):
        captured["prompt"] = prompt
        return "# === FILE: x.py ===\ndef x(): pass\n"
    llm = MockLLMClient(grab)
    run_python_implementer(
        spec_text="MY SPEC HERE",
        stripped_files={"x.py": "STRIPPED CONTENT"},
        llm=llm,
    )
    assert "MY SPEC HERE" in captured["prompt"]
    assert "STRIPPED CONTENT" in captured["prompt"]
    assert "# === FILE: x.py ===" in captured["prompt"]


def test_total_tokens_pulls_from_completion():
    """Mock returns zero tokens; result reflects that."""
    llm = MockLLMClient(default="# === FILE: x.py ===\ndef x(): pass\n")
    r = run_python_implementer(
        spec_text="", stripped_files={"x.py": "pass"}, llm=llm,
    )
    assert r.total_tokens == 0


# ---------------------------------------------------------------------------
# Phase 1.H'.F.2: multi-iteration feedback
# ---------------------------------------------------------------------------


def test_iter0_prompt_has_no_feedback_section():
    """iter_idx=0 → '## Previous attempt' section must NOT appear."""
    captured = {}
    def grab(prompt, **kw):
        captured["p"] = prompt
        return "# === FILE: x.py ===\ndef x(): pass\n"
    llm = MockLLMClient(grab)
    run_python_implementer(
        spec_text="S", stripped_files={"x.py": "pass"}, llm=llm,
        iter_idx=0,
    )
    assert "Previous attempt" not in captured["p"]


def test_iter1_prompt_includes_previous_filled_and_test_output():
    """iter_idx=1 → feedback section must contain both."""
    captured = {}
    def grab(prompt, **kw):
        captured["p"] = prompt
        return "# === FILE: x.py ===\ndef x(): pass\n"
    llm = MockLLMClient(grab)
    run_python_implementer(
        spec_text="S", stripped_files={"x.py": "pass"}, llm=llm,
        previous_filled={"x.py": "def x(): return 1\n"},
        previous_test_output="===== 0 passed, 1 failed =====\nFAILED test_x.py::test_x",
        iter_idx=1,
    )
    p = captured["p"]
    assert "Previous attempt (iter 0)" in p  # iter_idx-1 in label
    assert "return 1" in p  # the previous_filled body
    assert "1 failed" in p
    assert "FAILED test_x.py::test_x" in p


def test_iter_feedback_truncates_long_test_output():
    """Test output > 8 KB → tail-truncated with marker."""
    long_out = "x" * 20000 + "\nFAILED at_the_end\n"
    captured = {}
    def grab(prompt, **kw):
        captured["p"] = prompt
        return "# === FILE: x.py ===\ndef x(): pass\n"
    llm = MockLLMClient(grab)
    run_python_implementer(
        spec_text="S", stripped_files={"x.py": "pass"}, llm=llm,
        previous_filled={"x.py": "def x(): pass\n"},
        previous_test_output=long_out,
        iter_idx=2,
    )
    p = captured["p"]
    assert "FAILED at_the_end" in p          # tail preserved
    assert "truncated" in p                   # marker added
    # Length sanity: prompt mention of the test_output section is ~8 KB tail
    # plus marker + frame; not the full 20 KB.
    section_start = p.index("Pytest output from previous attempt")
    section_end = p.index("Now: emit a corrected", section_start)
    assert section_end - section_start < 12000  # 8 KB + frame


def test_iter_feedback_works_with_only_test_output_no_previous():
    """If for some reason previous_filled is missing, still feed back tests."""
    captured = {}
    def grab(prompt, **kw):
        captured["p"] = prompt
        return "# === FILE: x.py ===\ndef x(): pass\n"
    llm = MockLLMClient(grab)
    run_python_implementer(
        spec_text="S", stripped_files={"x.py": "pass"}, llm=llm,
        previous_filled=None,
        previous_test_output="0 passed, 1 failed",
        iter_idx=1,
    )
    p = captured["p"]
    assert "Previous attempt" in p
    assert "1 failed" in p


def test_signature_accepts_keyword_only_feedback_params():
    """All new params (previous_filled / previous_test_output / iter_idx)
    must be keyword-only — guard against accidental positional misuse."""
    import inspect
    from benchmarks.agents.python_implementer import run_python_implementer
    sig = inspect.signature(run_python_implementer)
    kw_only = {
        n for n, p in sig.parameters.items()
        if p.kind == inspect.Parameter.KEYWORD_ONLY
    }
    assert "previous_filled" in kw_only
    assert "previous_test_output" in kw_only
    assert "iter_idx" in kw_only
