"""Tests for al.llm base + mock.

覆盖：CompletionResult dataclass、LLMClient Protocol 检查、MockLLMClient
四种行为（None / dict / callable / default）、call recording。
"""

from __future__ import annotations

import pytest

from al.llm import CompletionResult, LLMClient, MockLLMClient


# ---------------------------------------------------------------------------
# CompletionResult
# ---------------------------------------------------------------------------


def test_completion_result_total_tokens():
    r = CompletionResult(text="hi", prompt_tokens=10, completion_tokens=5)
    assert r.total_tokens == 15


def test_completion_result_total_tokens_zero_by_default():
    r = CompletionResult(text="hi")
    assert r.total_tokens == 0


# ---------------------------------------------------------------------------
# Protocol conformance
# ---------------------------------------------------------------------------


def test_mock_satisfies_protocol():
    assert isinstance(MockLLMClient(), LLMClient)


# ---------------------------------------------------------------------------
# MockLLMClient — 4 modes
# ---------------------------------------------------------------------------


def test_mock_default_empty():
    """No responses configured → returns empty string."""
    m = MockLLMClient()
    r = m.complete("any prompt")
    assert r.text == ""
    assert r.model == "mock"


def test_mock_custom_default():
    m = MockLLMClient(default="hello")
    assert m.complete("foo").text == "hello"


def test_mock_dict_substring_match():
    m = MockLLMClient({"summarize": "DONE", "translate": "TRANSLATED"})
    assert m.complete("please summarize this").text == "DONE"
    assert m.complete("please translate this").text == "TRANSLATED"


def test_mock_dict_fallback_to_default():
    m = MockLLMClient({"foo": "FOO"}, default="X")
    assert m.complete("bar").text == "X"


def test_mock_dict_first_match_wins():
    """When multiple keys could match, first dict key in iteration order wins."""
    m = MockLLMClient({"foo": "FIRST", "bar": "SECOND"})
    # Python 3.7+ dicts preserve insertion order
    assert m.complete("foo bar").text == "FIRST"


def test_mock_callable_response():
    m = MockLLMClient(lambda prompt, **kw: f"got: {prompt[:5]}")
    assert m.complete("hello world").text == "got: hello"


def test_mock_callable_sees_kwargs():
    received = {}
    def fn(prompt, **kw):
        received.update(kw)
        return "ok"
    m = MockLLMClient(fn)
    m.complete("p", system="sys", max_tokens=100, temperature=0.5,
               stop=["END"])
    assert received["system"] == "sys"
    assert received["max_tokens"] == 100
    assert received["temperature"] == 0.5
    assert received["stop"] == ["END"]


# ---------------------------------------------------------------------------
# Call recording for assertions
# ---------------------------------------------------------------------------


def test_mock_records_calls():
    m = MockLLMClient(default="ok")
    m.complete("first", system="sys1")
    m.complete("second", max_tokens=200)
    assert len(m.calls) == 2
    assert m.calls[0]["prompt"] == "first"
    assert m.calls[0]["system"] == "sys1"
    assert m.calls[1]["max_tokens"] == 200


def test_mock_returns_zero_tokens():
    """Mock never reports fake token counts."""
    m = MockLLMClient(default="anything")
    r = m.complete("p")
    assert r.prompt_tokens == 0
    assert r.completion_tokens == 0
    assert r.total_tokens == 0
