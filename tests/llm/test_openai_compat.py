"""Tests for al.llm.openai_compat.OpenAICompatClient.

覆盖：
- 缺 key 时 complete() raise（不发请求）
- request payload shape (model / messages / max_tokens / temperature / stop)
- response 解析（text + token usage + model）
- 服务端错误（4xx / 5xx）抛 RuntimeError
- 异常响应格式（没 choices）抛 RuntimeError
- context manager 关闭 client

所有 HTTP 走 httpx.MockTransport（不发真请求）。
"""

from __future__ import annotations

import json

import httpx
import pytest

from al.llm import LLMClient, OpenAICompatClient
from al.llm.env import LLMConfig


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------


def _mock_response_factory(status_code=200, body=None, *, capture=None):
    """Build an httpx.MockTransport handler returning a fixed response."""
    body = body if body is not None else _default_ok_body()

    def handler(request: httpx.Request) -> httpx.Response:
        if capture is not None:
            capture["request"] = request
            capture["payload"] = json.loads(request.content)
        return httpx.Response(status_code, json=body)

    return httpx.MockTransport(handler)


def _default_ok_body():
    return {
        "model": "gpt-5.4-nano",
        "choices": [{"message": {"content": "hello from mock"}}],
        "usage": {"prompt_tokens": 12, "completion_tokens": 7},
    }


def _client(transport, *, api_key="sk-test", max_retries=0, retry_backoff_sec=0.0):
    """Build a test client. Default: no retry (so tests fail fast on
    transient-looking responses). Tests that exercise retry behavior
    explicitly pass max_retries=N + retry_backoff_sec=0.0."""
    cfg = LLMConfig(api_key=api_key, base_url="https://yunwu.example/v1",
                    model="gpt-5.4-nano")
    return OpenAICompatClient(
        cfg, transport=transport, timeout=5.0,
        max_retries=max_retries, retry_backoff_sec=retry_backoff_sec,
    )


# ---------------------------------------------------------------------------
# Protocol conformance
# ---------------------------------------------------------------------------


def test_yunwu_satisfies_protocol():
    """No transport needed — just check the class implements the Protocol."""
    cfg = LLMConfig(api_key="x", base_url="https://x.example", model="m")
    c = OpenAICompatClient(cfg, transport=httpx.MockTransport(lambda r: httpx.Response(200, json={})))
    assert isinstance(c, LLMClient)
    c.close()


# ---------------------------------------------------------------------------
# Missing key
# ---------------------------------------------------------------------------


def test_complete_raises_when_no_api_key():
    cfg = LLMConfig(api_key=None, base_url="https://x.example/v1", model="m")
    captured = {}
    transport = _mock_response_factory(capture=captured)
    c = OpenAICompatClient(cfg, transport=transport)
    with pytest.raises(RuntimeError, match="api_key is empty"):
        c.complete("hi")
    # And no HTTP request was made
    assert "request" not in captured
    c.close()


# ---------------------------------------------------------------------------
# Request payload shape
# ---------------------------------------------------------------------------


def test_request_includes_user_message():
    captured = {}
    c = _client(_mock_response_factory(capture=captured))
    c.complete("hello world")
    payload = captured["payload"]
    assert payload["model"] == "gpt-5.4-nano"
    assert payload["messages"] == [{"role": "user", "content": "hello world"}]
    assert payload["max_tokens"] == 4096
    assert payload["temperature"] == 0.0
    assert "stop" not in payload  # only added when caller provides
    c.close()


def test_request_includes_system_message_when_given():
    captured = {}
    c = _client(_mock_response_factory(capture=captured))
    c.complete("user prompt", system="you are X")
    payload = captured["payload"]
    assert payload["messages"][0] == {"role": "system", "content": "you are X"}
    assert payload["messages"][1] == {"role": "user", "content": "user prompt"}
    c.close()


def test_request_honors_custom_kwargs():
    captured = {}
    c = _client(_mock_response_factory(capture=captured))
    c.complete("p", max_tokens=200, temperature=0.7, stop=["END", "STOP"])
    payload = captured["payload"]
    assert payload["max_tokens"] == 200
    assert payload["temperature"] == 0.7
    assert payload["stop"] == ["END", "STOP"]
    c.close()


def test_request_authorization_header():
    captured = {}
    c = _client(_mock_response_factory(capture=captured), api_key="sk-secret")
    c.complete("p")
    auth = captured["request"].headers.get("authorization")
    assert auth == "Bearer sk-secret"
    c.close()


# ---------------------------------------------------------------------------
# Response parsing
# ---------------------------------------------------------------------------


def test_response_parses_text_and_usage():
    c = _client(_mock_response_factory())
    r = c.complete("p")
    assert r.text == "hello from mock"
    assert r.prompt_tokens == 12
    assert r.completion_tokens == 7
    assert r.total_tokens == 19
    assert r.model == "gpt-5.4-nano"
    assert r.raw["choices"][0]["message"]["content"] == "hello from mock"
    c.close()


def test_response_handles_missing_usage():
    body = {
        "model": "gpt-5.4-nano",
        "choices": [{"message": {"content": "x"}}],
        # no usage field
    }
    c = _client(_mock_response_factory(body=body))
    r = c.complete("p")
    assert r.text == "x"
    assert r.prompt_tokens == 0
    assert r.completion_tokens == 0
    c.close()


def test_response_handles_missing_model():
    """When server doesn't echo model, fall back to config.model."""
    body = {"choices": [{"message": {"content": "x"}}]}
    c = _client(_mock_response_factory(body=body))
    r = c.complete("p")
    assert r.model == "gpt-5.4-nano"
    c.close()


# ---------------------------------------------------------------------------
# Error paths
# ---------------------------------------------------------------------------


def test_5xx_raises_runtime_error():
    c = _client(_mock_response_factory(status_code=500, body={"error": "boom"}))
    with pytest.raises(RuntimeError, match="500"):
        c.complete("p")
    c.close()


def test_4xx_raises_runtime_error():
    c = _client(_mock_response_factory(status_code=401, body={"error": "unauthorized"}))
    with pytest.raises(RuntimeError, match="401"):
        c.complete("p")
    c.close()


def test_response_without_choices_raises():
    c = _client(_mock_response_factory(body={"weird": "shape"}))
    with pytest.raises(RuntimeError, match="unexpected OpenAI-compat response"):
        c.complete("p")
    c.close()


# ---------------------------------------------------------------------------
# Context manager
# ---------------------------------------------------------------------------


def test_context_manager_closes_client():
    transport = _mock_response_factory()
    cfg = LLMConfig(api_key="k", base_url="https://x.example/v1", model="m")
    with OpenAICompatClient(cfg, transport=transport) as c:
        r = c.complete("p")
        assert r.text  # responded
    # After exit, internal client closed — can still get config but no requests
    # (we don't have a clean way to assert closed; just verify no crash on exit)


# ---------------------------------------------------------------------------
# Retry behavior (Round 0.1 — transient errors are retried)
# ---------------------------------------------------------------------------


def _flaky_transport(*, attempts_until_ok, transient_status=503,
                     ok_body=None, capture=None):
    """Build a transport whose first ``attempts_until_ok`` requests return
    ``transient_status``, then a 200 with ``ok_body``."""
    if ok_body is None:
        ok_body = _default_ok_body()
    counter = {"n": 0}

    def handler(request: httpx.Request) -> httpx.Response:
        counter["n"] += 1
        if capture is not None:
            capture.setdefault("attempts", []).append(counter["n"])
        if counter["n"] <= attempts_until_ok:
            return httpx.Response(transient_status, json={"error": "transient"})
        return httpx.Response(200, json=ok_body)

    return httpx.MockTransport(handler), counter


def test_retries_on_5xx_and_eventually_succeeds():
    """503 on attempt 1, 200 on attempt 2 → returns success after 1 retry."""
    transport, counter = _flaky_transport(attempts_until_ok=1)
    c = _client(transport, max_retries=3, retry_backoff_sec=0.0)
    r = c.complete("p")
    assert r.text  # got the success body
    assert counter["n"] == 2  # one retry consumed
    c.close()


def test_retries_on_503_until_exhausted_raises_runtime():
    """All 4 attempts return 503 → raise RuntimeError on the last."""
    transport, counter = _flaky_transport(attempts_until_ok=999)
    c = _client(transport, max_retries=3, retry_backoff_sec=0.0)
    with pytest.raises(RuntimeError, match="503"):
        c.complete("p")
    assert counter["n"] == 4  # 1 initial + 3 retries
    c.close()


def test_no_retry_on_non_transient_4xx():
    """401 is non-transient — raise immediately, no retry attempt."""
    transport, counter = _flaky_transport(
        attempts_until_ok=999, transient_status=401,
    )
    c = _client(transport, max_retries=3, retry_backoff_sec=0.0)
    with pytest.raises(RuntimeError, match="401"):
        c.complete("p")
    assert counter["n"] == 1  # no retry
    c.close()


def test_retries_on_429_rate_limit():
    """429 (Too Many Requests) is in the transient set."""
    transport, counter = _flaky_transport(attempts_until_ok=2, transient_status=429)
    c = _client(transport, max_retries=3, retry_backoff_sec=0.0)
    r = c.complete("p")
    assert r.text
    assert counter["n"] == 3


def test_retries_on_network_timeout():
    """httpx.TimeoutException is transient — retry."""
    calls = {"n": 0}

    def handler(req: httpx.Request) -> httpx.Response:
        calls["n"] += 1
        if calls["n"] <= 1:
            raise httpx.ReadTimeout("timed out", request=req)
        return httpx.Response(200, json=_default_ok_body())

    transport = httpx.MockTransport(handler)
    c = _client(transport, max_retries=3, retry_backoff_sec=0.0)
    r = c.complete("p")
    assert r.text
    assert calls["n"] == 2


def test_max_retries_zero_disables_retry():
    """max_retries=0 → first 5xx raises immediately."""
    transport, counter = _flaky_transport(attempts_until_ok=99)
    c = _client(transport, max_retries=0)
    with pytest.raises(RuntimeError, match="503"):
        c.complete("p")
    assert counter["n"] == 1
