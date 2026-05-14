"""Tests for al.llm.claude_code.ClaudeCodeClient.

All subprocess invocations mocked — no real claude CLI required.
"""

from __future__ import annotations

import json
import subprocess
from unittest.mock import patch

import pytest

from al.llm import LLMClient
from al.llm.claude_code import (
    ClaudeCodeClient,
    ClaudeCodeConfig,
    _completion_from_json,
)


# ---------------------------------------------------------------------------
# Protocol conformance
# ---------------------------------------------------------------------------


def test_claude_code_satisfies_protocol(monkeypatch):
    monkeypatch.setenv("ANTHROPIC_AUTH_TOKEN", "x")
    c = ClaudeCodeClient()
    assert isinstance(c, LLMClient)


# ---------------------------------------------------------------------------
# Env check
# ---------------------------------------------------------------------------


def test_init_raises_without_auth_env(monkeypatch):
    monkeypatch.delenv("ANTHROPIC_AUTH_TOKEN", raising=False)
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    with pytest.raises(RuntimeError, match="ANTHROPIC_AUTH_TOKEN"):
        ClaudeCodeClient()


def test_init_accepts_api_key_alt(monkeypatch):
    """If only ANTHROPIC_API_KEY is set (no AUTH_TOKEN), still ok."""
    monkeypatch.delenv("ANTHROPIC_AUTH_TOKEN", raising=False)
    monkeypatch.setenv("ANTHROPIC_API_KEY", "k")
    ClaudeCodeClient()  # should not raise


def test_env_check_can_be_disabled():
    """env_check=False lets us construct in unit tests without real env."""
    c = ClaudeCodeClient(env_check=False)
    assert c.config.binary == "claude"


# ---------------------------------------------------------------------------
# Command building
# ---------------------------------------------------------------------------


def test_default_command_shape():
    c = ClaudeCodeClient(env_check=False)
    cmd = c._build_command()
    assert cmd[0] == "claude"
    assert "-p" in cmd
    assert "--output-format" in cmd
    assert "json" in cmd
    assert "--max-turns" in cmd
    assert "--permission-mode" in cmd
    assert "acceptEdits" in cmd  # safe under root container
    assert "--input-format" in cmd
    assert "text" in cmd


def test_custom_config_propagates():
    cfg = ClaudeCodeConfig(
        binary="/custom/claude",
        max_turns=3,
        output_format="text",
        permission_mode="dontAsk",
        max_budget_usd=5.0,
        no_session_persistence=False,
        extra_args=["--debug", "--verbose"],
    )
    c = ClaudeCodeClient(cfg, env_check=False)
    cmd = c._build_command()
    assert cmd[0] == "/custom/claude"
    assert "text" in cmd  # output-format value
    assert "dontAsk" in cmd  # permission-mode value
    assert "3" in cmd  # max-turns
    assert "5.00" in cmd  # max-budget-usd
    assert "--no-session-persistence" not in cmd
    assert "--debug" in cmd
    assert "--verbose" in cmd


def test_no_max_budget_omitted_by_default():
    cmd = ClaudeCodeClient(env_check=False)._build_command()
    assert "--max-budget-usd" not in cmd


# ---------------------------------------------------------------------------
# Prompt composition
# ---------------------------------------------------------------------------


def test_compose_prompt_no_system():
    c = ClaudeCodeClient(env_check=False)
    out = c._compose_prompt("hello", None)
    assert "hello" in out
    assert "Do NOT call any tools" in out  # anti-tool-use preamble


def test_compose_prompt_with_system():
    c = ClaudeCodeClient(env_check=False)
    out = c._compose_prompt("user msg", "you are X")
    assert "you are X" in out
    assert "user msg" in out
    assert "---" in out  # separator
    assert "Do NOT call any tools" in out


# ---------------------------------------------------------------------------
# Subprocess result parsing
# ---------------------------------------------------------------------------


def _cp(stdout="", stderr="", returncode=0):
    return subprocess.CompletedProcess(
        args=["claude"], returncode=returncode, stdout=stdout, stderr=stderr,
    )


def test_complete_success_parses_json():
    c = ClaudeCodeClient(env_check=False)
    payload = {
        "type": "result",
        "subtype": "success",
        "result": "42",
        "is_error": False,
        "usage": {
            "input_tokens": 12,
            "output_tokens": 3,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0,
        },
        "modelUsage": {"gemini-3-flash": {"input_tokens": 12, "output_tokens": 3}},
    }
    fake = _cp(stdout=json.dumps(payload))
    with patch("subprocess.run", return_value=fake):
        r = c.complete("what is 6 times 7?")
    assert r.text == "42"
    assert r.prompt_tokens == 12
    assert r.completion_tokens == 3
    assert r.total_tokens == 15
    assert r.model == "gemini-3-flash"


def test_complete_includes_cached_tokens_in_prompt_count():
    c = ClaudeCodeClient(env_check=False)
    payload = {
        "type": "result",
        "result": "ok",
        "usage": {
            "input_tokens": 5,
            "cache_creation_input_tokens": 10,
            "cache_read_input_tokens": 200,
            "output_tokens": 7,
        },
    }
    with patch("subprocess.run", return_value=_cp(stdout=json.dumps(payload))):
        r = c.complete("x")
    # input + cache_creation + cache_read all count toward "prompt tokens" for accounting
    assert r.prompt_tokens == 5 + 10 + 200
    assert r.completion_tokens == 7


def test_complete_returncode_nonzero_raises():
    c = ClaudeCodeClient(env_check=False)
    fake = _cp(stdout="", stderr="api error: invalid model id", returncode=2)
    with patch("subprocess.run", return_value=fake):
        with pytest.raises(RuntimeError, match="claude -p exited 2"):
            c.complete("x")


def test_complete_invalid_json_raises():
    c = ClaudeCodeClient(env_check=False)
    fake = _cp(stdout="not json output", returncode=0)
    with patch("subprocess.run", return_value=fake):
        with pytest.raises(RuntimeError, match="not JSON"):
            c.complete("x")


def test_complete_missing_result_field_falls_back_to_stdout():
    """If 'result' isn't in JSON, take whole stdout as text."""
    c = ClaudeCodeClient(env_check=False)
    payload = {"type": "result", "other": "stuff"}  # no 'result' field
    raw = json.dumps(payload)
    with patch("subprocess.run", return_value=_cp(stdout=raw)):
        r = c.complete("x")
    assert r.text == raw  # fallback


def test_complete_passes_prompt_via_stdin():
    """Verify the prompt is passed to subprocess.run via stdin."""
    c = ClaudeCodeClient(env_check=False)
    captured = {}
    def fake_run(cmd, *, input, capture_output, text, timeout, check, env=None):
        captured["input"] = input
        captured["cmd"] = cmd
        captured["env"] = env
        return _cp(stdout='{"result": "x"}')
    with patch("subprocess.run", side_effect=fake_run):
        c.complete("my prompt here", system="be brief")
    assert "be brief" in captured["input"]
    assert "my prompt here" in captured["input"]
    assert "---" in captured["input"]
    assert "Do NOT call any tools" in captured["input"]


# ---------------------------------------------------------------------------
# _completion_from_json edge cases
# ---------------------------------------------------------------------------


def test_completion_from_json_minimal():
    r = _completion_from_json({"result": "hi"}, fallback_text="")
    assert r.text == "hi"
    assert r.prompt_tokens == 0
    assert r.completion_tokens == 0
    assert r.model == "claude-code"


def test_completion_from_json_with_model_usage():
    r = _completion_from_json({
        "result": "x",
        "modelUsage": {"some/model": {"input_tokens": 1}},
    }, fallback_text="")
    assert r.model == "some/model"


def test_completion_from_json_string_result_not_required():
    """If result is not a string, fall back to fallback_text."""
    r = _completion_from_json({"result": None}, fallback_text="raw output")
    assert r.text == "raw output"


# ---------------------------------------------------------------------------
# Phase 1.H'.F.2: model-pool fallback
# ---------------------------------------------------------------------------


def _transient_503_payload(model: str) -> str:
    return json.dumps({
        "type": "result", "subtype": "success", "is_error": True,
        "api_error_status": 503,
        "result": f"API Error: 503 No available channel for model {model} under group X (distributor)",
        "stop_reason": "stop_sequence", "usage": {},
    })


def test_model_pool_swap_skips_backoff_on_transient_error():
    """When model_pool has multiple entries, a transient error should
    rotate to the next model instead of sleeping."""
    cfg = ClaudeCodeConfig(
        model_pool=["gemini-3-flash", "gemini-3-flash-preview"],
        max_retries=2, retry_backoff_sec=0.0,  # backoff irrelevant when swapping
    )
    c = ClaudeCodeClient(cfg, env_check=False)

    captured_envs: list[str] = []

    def fake_run(cmd, *, input, capture_output, text, timeout, check, env=None):
        # Record which model the env said to use this call
        captured_envs.append((env or {}).get("ANTHROPIC_DEFAULT_OPUS_MODEL", ""))
        if len(captured_envs) == 1:
            # First model: 503
            return _cp(stdout=_transient_503_payload("gemini-3-flash"),
                       returncode=1)
        # Second model: success
        return _cp(stdout=json.dumps({"result": "yo", "usage": {}}),
                   returncode=0)

    with patch("subprocess.run", side_effect=fake_run):
        r = c.complete("hi")

    assert r.text == "yo"
    assert captured_envs == ["gemini-3-flash", "gemini-3-flash-preview"]


def test_model_pool_sticks_to_working_model_on_subsequent_calls():
    """After a swap, subsequent calls keep using the new model
    (don't oscillate back to the original)."""
    cfg = ClaudeCodeConfig(
        model_pool=["A", "B"], max_retries=1, retry_backoff_sec=0.0,
    )
    c = ClaudeCodeClient(cfg, env_check=False)

    call_log: list[str] = []

    def fake_run(cmd, *, input, capture_output, text, timeout, check, env=None):
        model = (env or {}).get("ANTHROPIC_DEFAULT_OPUS_MODEL", "")
        call_log.append(model)
        if model == "A":
            return _cp(stdout=_transient_503_payload("A"), returncode=1)
        return _cp(stdout=json.dumps({"result": "ok", "usage": {}}), returncode=0)

    with patch("subprocess.run", side_effect=fake_run):
        c.complete("first call")
        c.complete("second call")
        c.complete("third call")

    # First call: A 503 → swap → B succeed
    # Subsequent calls: should start with B (no oscillation)
    assert call_log == ["A", "B", "B", "B"]


def test_model_pool_empty_uses_inherited_env():
    """Empty pool → env var not overridden (subprocess inherits parent env)."""
    c = ClaudeCodeClient(ClaudeCodeConfig(model_pool=[]), env_check=False)
    captured = {}

    def fake_run(cmd, *, input, capture_output, text, timeout, check, env=None):
        captured["env"] = env
        return _cp(stdout=json.dumps({"result": "x", "usage": {}}))

    with patch("subprocess.run", side_effect=fake_run):
        c.complete("hi")
    # env=None ⇒ subprocess.run uses parent env as-is
    assert captured["env"] is None


def test_model_pool_single_entry_still_overrides_env():
    """Pool of 1 entry sets the env var but never swaps."""
    cfg = ClaudeCodeConfig(model_pool=["solo-model"])
    c = ClaudeCodeClient(cfg, env_check=False)
    captured = {}

    def fake_run(cmd, *, input, capture_output, text, timeout, check, env=None):
        captured["env"] = env
        return _cp(stdout=json.dumps({"result": "x", "usage": {}}))

    with patch("subprocess.run", side_effect=fake_run):
        c.complete("hi")
    assert captured["env"]["ANTHROPIC_DEFAULT_OPUS_MODEL"] == "solo-model"


def test_model_pool_exhausts_then_raises():
    """If every model in pool is down, after max_retries we raise."""
    cfg = ClaudeCodeConfig(
        model_pool=["A", "B"], max_retries=3, retry_backoff_sec=0.0,
    )
    c = ClaudeCodeClient(cfg, env_check=False)

    def fake_run(cmd, *, input, capture_output, text, timeout, check, env=None):
        model = (env or {}).get("ANTHROPIC_DEFAULT_OPUS_MODEL", "")
        return _cp(stdout=_transient_503_payload(model), returncode=1)

    with patch("subprocess.run", side_effect=fake_run):
        with pytest.raises(RuntimeError, match="503"):
            c.complete("hi")


# ---------------------------------------------------------------------------
# Retry on transient gateway errors (Phase 1.H'.F bug fix)
# ---------------------------------------------------------------------------


def test_complete_non_transient_error_does_not_retry():
    """rc != 0 with non-transient stderr → raise immediately, no retries."""
    cfg = ClaudeCodeConfig(max_retries=2, retry_backoff_sec=0.01)
    c = ClaudeCodeClient(cfg, env_check=False)
    fake = _cp(stdout="", stderr="invalid model id", returncode=2)
    calls = []
    def counted(*a, **kw):
        calls.append(1)
        return fake
    with patch("subprocess.run", side_effect=counted):
        with pytest.raises(RuntimeError, match="claude -p exited 2"):
            c.complete("x")
    assert len(calls) == 1  # no retry on non-transient


def test_complete_transient_503_retries_then_raises():
    """Transient 503 → retries max_retries times, then raises."""
    cfg = ClaudeCodeConfig(max_retries=2, retry_backoff_sec=0.01)
    c = ClaudeCodeClient(cfg, env_check=False)
    fake_503 = _cp(
        stdout=json.dumps({
            "type": "result", "is_error": True, "api_error_status": 503,
            "result": "API Error: 503 No available channel for model X",
        }),
        returncode=1,
    )
    calls = []
    def counted(*a, **kw):
        calls.append(1)
        return fake_503
    with patch("subprocess.run", side_effect=counted):
        with pytest.raises(RuntimeError):
            c.complete("x")
    # 1 initial + 2 retries = 3 calls
    assert len(calls) == 3


def test_complete_transient_503_then_recovery():
    """Transient 503 on first call, success on retry → returns success."""
    cfg = ClaudeCodeConfig(max_retries=2, retry_backoff_sec=0.01)
    c = ClaudeCodeClient(cfg, env_check=False)
    fake_503 = _cp(
        stdout=json.dumps({
            "is_error": True, "api_error_status": 503,
            "result": "API Error: 503 No available channel",
        }),
        returncode=1,
    )
    fake_ok = _cp(stdout=json.dumps({
        "type": "result", "result": "recovered", "is_error": False,
        "usage": {"input_tokens": 1, "output_tokens": 1},
    }))
    seq = iter([fake_503, fake_ok])
    with patch("subprocess.run", side_effect=lambda *a, **kw: next(seq)):
        r = c.complete("x")
    assert r.text == "recovered"


def test_complete_retry_disabled_when_max_retries_zero():
    """max_retries=0 → exactly 1 call, no retries even on transient error."""
    cfg = ClaudeCodeConfig(max_retries=0, retry_backoff_sec=0.01)
    c = ClaudeCodeClient(cfg, env_check=False)
    fake_503 = _cp(
        stdout=json.dumps({
            "is_error": True, "api_error_status": 503,
            "result": "API Error: 503",
        }),
        returncode=1,
    )
    calls = []
    def counted(*a, **kw):
        calls.append(1)
        return fake_503
    with patch("subprocess.run", side_effect=counted):
        with pytest.raises(RuntimeError):
            c.complete("x")
    assert len(calls) == 1


def test_looks_transient_detects_known_keywords():
    """Test the _looks_transient heuristic directly."""
    from al.llm.claude_code import _looks_transient
    assert _looks_transient(json.dumps({
        "api_error_status": 503, "result": "API Error: 503"
    }))
    assert _looks_transient(json.dumps({
        "result": "API Error: 503 No available channel"
    }))
    assert _looks_transient(json.dumps({"result": "rate limit exceeded"}))
    assert _looks_transient(json.dumps({"result": "model overloaded"}))
    assert not _looks_transient(json.dumps({"result": "invalid model id"}))
    assert not _looks_transient("garbage non-json output")
