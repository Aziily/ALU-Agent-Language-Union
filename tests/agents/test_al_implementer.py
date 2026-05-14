"""Tests for benchmarks.agents.al_implementer."""

from __future__ import annotations

import pytest

from al.llm import MockLLMClient
from benchmarks.agents.al_implementer import (
    ALImplementerResult,
    run_al_implementer,
    _strip_fences,
)


SAMPLE_SKELETON = """\
code add_one:
  intent: add 1 to integer input
  input: int
  output: int
  body: |
    def add_one(x):
        pass
"""


# ---------------------------------------------------------------------------
# Smoke
# ---------------------------------------------------------------------------


def test_al_implementer_filled():
    canned = """\
code add_one:
  intent: add 1 to integer input
  input: int
  output: int
  body: |
    def add_one(x):
        return x + 1
"""
    llm = MockLLMClient(default=canned)
    r = run_al_implementer(
        spec_text="add 1 to a number",
        skeleton_text=SAMPLE_SKELETON,
        llm=llm,
        guide_text="(mock guide)",
    )
    assert r.al_parse_ok is True
    assert r.all_bodies_valid is True
    assert "return x + 1" in r.filled_al


def test_al_implementer_parse_error():
    """LLM returns broken agent-lang → parse_ok=False."""
    llm = MockLLMClient(default="not an agent-lang file at all")
    r = run_al_implementer(
        spec_text="",
        skeleton_text=SAMPLE_SKELETON,
        llm=llm,
        guide_text="(mock guide)",
    )
    # Empty string parses to empty Program; "not an agent-lang file"
    # actually triggers a parse error
    if r.al_parse_ok:
        # If parser is lenient and produces empty program, no bodies to validate
        assert r.body_validation == {}
    else:
        assert r.al_parse_error  # error message present


def test_al_implementer_body_python_invalid():
    """agent-lang parses but a code body's Python is invalid."""
    canned = """\
code add_one:
  intent: x
  body: |
    def add_one(:
        broken
"""
    llm = MockLLMClient(default=canned)
    r = run_al_implementer(
        spec_text="",
        skeleton_text=SAMPLE_SKELETON,
        llm=llm,
        guide_text="(mock guide)",
    )
    assert r.al_parse_ok is True
    assert r.all_bodies_valid is False
    assert "add_one" in r.body_validation
    assert r.body_validation["add_one"]  # non-empty error


def test_al_implementer_multiple_code_nodes():
    skeleton = """\
code a:
  intent: a
  body: |
    def a():
        pass

code b:
  intent: b
  body: |
    def b():
        pass
"""
    canned = """\
code a:
  intent: a
  body: |
    def a():
        return 1

code b:
  intent: b
  body: |
    def b():
        return 2
"""
    llm = MockLLMClient(default=canned)
    r = run_al_implementer(
        spec_text="",
        skeleton_text=skeleton,
        llm=llm,
        guide_text="(mock guide)",
    )
    assert r.al_parse_ok is True
    assert r.all_bodies_valid is True
    assert set(r.body_validation) == {"a", "b"}


def test_al_implementer_strips_markdown_fences():
    canned = """\
```al
code add_one:
  intent: x
  body: |
    def add_one(x):
        return x + 1
```
"""
    llm = MockLLMClient(default=canned)
    r = run_al_implementer(
        spec_text="",
        skeleton_text=SAMPLE_SKELETON,
        llm=llm,
        guide_text="(mock guide)",
    )
    assert r.al_parse_ok is True
    assert "return x + 1" in r.filled_al


# ---------------------------------------------------------------------------
# Guide loading
# ---------------------------------------------------------------------------


def test_default_guide_is_loaded():
    """When guide_text is None, the canonical guide is loaded from docs/."""
    captured = {}
    def grab(prompt, **kw):
        captured["prompt"] = prompt
        return SAMPLE_SKELETON.replace("pass", "return x + 1")
    llm = MockLLMClient(grab)
    run_al_implementer(
        spec_text="",
        skeleton_text=SAMPLE_SKELETON,
        llm=llm,
        # no guide_text — uses default
    )
    # Look for a phrase from the real guide
    assert "TL;DR" in captured["prompt"] or "agent-lang" in captured["prompt"]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def test_strip_fences_no_fences():
    assert _strip_fences("hello").strip() == "hello"


def test_strip_fences_with_lang():
    assert _strip_fences("```al\nhello\n```").strip() == "hello"


def test_strip_fences_only_close():
    assert _strip_fences("hello\n```").strip() == "hello"


# ---------------------------------------------------------------------------
# Phase 1.H'.F.2: multi-iteration feedback (symmetric with python_implementer)
# ---------------------------------------------------------------------------


_MINIMAL_AL = (
    "flow demo:\n"
    "  steps:\n"
    "    - run\n"
    "\n\n"
    "code run:\n"
    "  body: |\n"
    "    def run():\n"
    "        return 1\n"
)


def test_al_iter0_prompt_has_no_feedback_section():
    captured = {}
    def grab(prompt, **kw):
        captured["p"] = prompt
        return _MINIMAL_AL
    llm = MockLLMClient(grab)
    run_al_implementer(
        spec_text="S", skeleton_text=_MINIMAL_AL, llm=llm,
        guide_text="GUIDE",
        iter_idx=0,
    )
    assert "Previous attempt" not in captured["p"]


def test_al_iter1_prompt_includes_previous_and_test_output():
    captured = {}
    def grab(prompt, **kw):
        captured["p"] = prompt
        return _MINIMAL_AL
    llm = MockLLMClient(grab)
    run_al_implementer(
        spec_text="S", skeleton_text=_MINIMAL_AL, llm=llm,
        guide_text="GUIDE",
        previous_filled="flow demo:\n  steps:\n    - run\n",
        previous_test_output="==== 0 passed, 1 failed ====",
        iter_idx=1,
    )
    p = captured["p"]
    assert "Previous attempt (iter 0)" in p
    assert "flow demo" in p
    assert "1 failed" in p


def test_al_iter_truncates_long_test_output():
    long_out = "x" * 20000 + "\nFAILED at_the_end"
    captured = {}
    def grab(prompt, **kw):
        captured["p"] = prompt
        return _MINIMAL_AL
    llm = MockLLMClient(grab)
    run_al_implementer(
        spec_text="S", skeleton_text=_MINIMAL_AL, llm=llm,
        guide_text="GUIDE",
        previous_filled=_MINIMAL_AL,
        previous_test_output=long_out,
        iter_idx=2,
    )
    assert "FAILED at_the_end" in captured["p"]
    assert "truncated" in captured["p"]


def test_al_signature_accepts_keyword_only_feedback_params():
    import inspect
    sig = inspect.signature(run_al_implementer)
    kw_only = {
        n for n, p in sig.parameters.items()
        if p.kind == inspect.Parameter.KEYWORD_ONLY
    }
    assert "previous_filled" in kw_only
    assert "previous_test_output" in kw_only
    assert "iter_idx" in kw_only
