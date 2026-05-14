"""ClaudeCodeClient — call ``claude -p`` CLI as an LLM backend.

This client lets us reuse the same ``LLMClient`` Protocol (used by
``python_implementer`` / ``al_implementer``) but route every prompt
through the Claude Code CLI, which itself is configured via standard
``ANTHROPIC_*`` env vars to point at an arbitrary OpenAI/Anthropic-compatible
gateway (e.g. traxnode).

Why this layer:

  Phase 1.H runs inside a Docker container that has:
    - python:3.11 + this project + commit0
    - node:20 + @anthropic-ai/claude-code installed globally
    - ENV ANTHROPIC_BASE_URL=https://canvas.aipaibox.com
    - ENV ANTHROPIC_AUTH_TOKEN=<from .env>
    - ENV ANTHROPIC_DEFAULT_OPUS_MODEL=gemini-3-flash

  When our implementer calls ``llm.complete(prompt)``, ``ClaudeCodeClient``
  spawns ``claude -p --output-format json``, pipes the prompt via stdin,
  parses the JSON result, and returns a ``CompletionResult``.

References:
  - https://code.claude.com/docs/en/llm-gateway.md
  - https://code.claude.com/docs/en/model-config.md
  - ``claude --help`` (2.1.x)
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field
from typing import Any

from al.llm.base import CompletionResult


# Match upstream api errors we should retry rather than abort on.
# Includes the various forms claude -p surfaces them:
#   - top-level "api_error_status": 503
#   - "result" payload starts with "API Error: 503 ..."
#   - "result" mentions "No available channel" / "rate limit" / "overloaded"
_TRANSIENT_STATUS_CODES = {429, 500, 502, 503, 504}
_TRANSIENT_KEYWORDS = (
    "No available channel",
    "rate limit",
    "overloaded",
    "temporarily unavailable",
    "try again",
)


def _looks_transient(stdout: str) -> bool:
    """Heuristic: does ``claude -p`` stdout describe a retryable gateway error?

    We parse the JSON (if any) and inspect ``api_error_status`` +
    ``result``. Falls back to substring match on the raw text so
    even partial stdout (no JSON) still gets retried for known errors.
    """
    try:
        data = json.loads(stdout)
        if isinstance(data, dict):
            status = data.get("api_error_status")
            if isinstance(status, int) and status in _TRANSIENT_STATUS_CODES:
                return True
            result = data.get("result", "")
            if isinstance(result, str):
                m = re.match(r"API Error:\s*(\d+)", result)
                if m and int(m.group(1)) in _TRANSIENT_STATUS_CODES:
                    return True
                if any(kw.lower() in result.lower() for kw in _TRANSIENT_KEYWORDS):
                    return True
    except (json.JSONDecodeError, AttributeError):
        pass
    return any(kw.lower() in stdout.lower() for kw in _TRANSIENT_KEYWORDS)


@dataclass
class ClaudeCodeConfig:
    """Knobs for the ``claude`` CLI invocation. Env vars used by claude itself
    (``ANTHROPIC_BASE_URL`` etc.) are read from process env — NOT set here."""

    binary: str = "claude"
    extra_args: list[str] = field(default_factory=list)
    timeout_sec: float = 600.0
    # max_turns must be ≥ 2: Claude Code's text-only completion still
    # internally counts the assistant turn that produces the result. With
    # max_turns=1 the model often hits stop_reason="tool_use" and aborts
    # with error_max_turns before producing usable text. 5 leaves headroom
    # for one or two internal tool uses while keeping cost bounded.
    max_turns: int = 5
    output_format: str = "json"
    # `bypassPermissions` is rejected by Claude Code when running as root
    # ("cannot be used with root/sudo privileges"). Our container runs as
    # root, so use `acceptEdits` — non-interactive auto-accept that is
    # safe under root and works for our use case (we don't ask the model
    # to edit files; just generate text).
    permission_mode: str = "acceptEdits"
    no_session_persistence: bool = True
    max_budget_usd: float | None = None
    # Retry knobs for transient gateway errors (5xx / 429 / overloaded).
    # The traxnode gateway sometimes 503s on the first call after channel
    # rebalance; one or two retries with a short backoff is usually enough.
    # Set max_retries=0 to disable retry behaviour.
    max_retries: int = 3
    retry_backoff_sec: float = 20.0
    # Phase 1.H'.F.2: model fallback list. When the current model returns
    # a transient gateway error (503 "no channel" etc), the next call tries
    # the next entry; on success we *stay* on the working model rather than
    # cycling back, so a degraded channel doesn't keep poisoning us.
    # Empty list → use whatever ANTHROPIC_DEFAULT_OPUS_MODEL env var says
    # (legacy behaviour).
    # Order matters: head of list is the preferred model; later entries
    # are fallbacks.
    model_pool: list[str] = field(default_factory=list)


class ClaudeCodeClient:
    """LLMClient impl wrapping ``claude -p`` subprocess.

    Reads ``ANTHROPIC_*`` env vars only via the inherited environment. The
    container / shell that launched us must have set them correctly. We
    fail fast if no auth token is reachable.
    """

    def __init__(
        self,
        config: ClaudeCodeConfig | None = None,
        *,
        env_check: bool = True,
    ) -> None:
        self.config = config or ClaudeCodeConfig()
        if env_check:
            self._assert_env_ready()
        # Index into config.model_pool. Sticks to the last working model.
        self._current_model_idx = 0

    def _assert_env_ready(self) -> None:
        """Fail loudly if no auth env is visible. Caught early ≫ retried later."""
        if not (os.environ.get("ANTHROPIC_AUTH_TOKEN") or os.environ.get("ANTHROPIC_API_KEY")):
            raise RuntimeError(
                "ClaudeCodeClient: neither ANTHROPIC_AUTH_TOKEN nor "
                "ANTHROPIC_API_KEY is set in the environment. Configure "
                "via .env (and pass --env-file to docker run)."
            )

    def complete(
        self,
        prompt: str,
        *,
        system: str | None = None,
        max_tokens: int = 4096,
        temperature: float = 0.0,
        stop: list[str] | None = None,
    ) -> CompletionResult:
        """Run ``claude -p`` with prompt on stdin; parse JSON result.

        ``system`` / ``max_tokens`` / ``temperature`` / ``stop`` are accepted
        for protocol compatibility but **ignored** — Claude Code controls
        these itself. Callers that need them should embed system instructions
        directly into the prompt text.

        Retries up to ``config.max_retries`` times on transient gateway
        errors (5xx / 429 / "No available channel" / "overloaded") with
        ``config.retry_backoff_sec`` spacing. Non-transient failures
        (auth, bad request, JSON parse) raise immediately.

        If ``config.model_pool`` is non-empty, transient errors trigger a
        **model swap** (rotate to the next entry) instead of a backoff
        retry on the same model. This handles channel-level outages
        (e.g. ``gemini-3-flash`` 503 while ``gemini-3-flash-preview``
        still works). On success we keep the new model as the current
        one — so a single outage doesn't make us keep oscillating.
        """
        cmd = self._build_command()
        full_prompt = self._compose_prompt(prompt, system)
        attempts = self.config.max_retries + 1  # 1 initial + N retries
        last_err: Exception | None = None
        for attempt in range(1, attempts + 1):
            env = self._build_env()
            result = subprocess.run(
                cmd,
                input=full_prompt,
                capture_output=True,
                text=True,
                timeout=self.config.timeout_sec,
                check=False,
                env=env,
            )
            if result.returncode == 0:
                try:
                    return self._parse_result(result)
                except RuntimeError as e:
                    last_err = e
                    # JSON parse error on rc=0: not transient, fail now.
                    raise
            # rc != 0 — decide whether to retry.
            transient = _looks_transient(result.stdout) or _looks_transient(result.stderr)
            if transient and attempt < attempts:
                # If we have a model pool, swap models BEFORE sleeping;
                # often the next model works immediately and we don't need
                # to wait. Backoff still applies between attempts on the
                # same model.
                swapped = self._rotate_model_if_possible()
                if swapped:
                    print(
                        f"  [claude-code] transient error on attempt {attempt}/{attempts}, "
                        f"swapping to model {self._current_model()!r}",
                        file=sys.stderr, flush=True,
                    )
                else:
                    wait = self.config.retry_backoff_sec * attempt
                    print(
                        f"  [claude-code] transient error on attempt {attempt}/{attempts}, "
                        f"retrying in {wait:.0f}s",
                        file=sys.stderr, flush=True,
                    )
                    time.sleep(wait)
                continue
            # Non-transient OR exhausted retries → raise the standard error.
            try:
                return self._parse_result(result)
            except RuntimeError as e:
                last_err = e
                raise
        # Defensive: loop always exits via return or raise; this is unreachable.
        assert last_err is not None  # pragma: no cover
        raise last_err  # pragma: no cover

    # ------------------------------------------------------------------
    # Model pool helpers
    # ------------------------------------------------------------------

    def _current_model(self) -> str | None:
        """The model name we'll set in the subprocess env, or None to defer
        to whatever ANTHROPIC_DEFAULT_OPUS_MODEL the inherited env has."""
        pool = self.config.model_pool
        if not pool:
            return None
        return pool[self._current_model_idx % len(pool)]

    def _rotate_model_if_possible(self) -> bool:
        """Advance the model pointer to the next entry. Returns True if
        the model actually changed, False otherwise (pool empty or
        single-item)."""
        pool = self.config.model_pool
        if len(pool) <= 1:
            return False
        self._current_model_idx = (self._current_model_idx + 1) % len(pool)
        return True

    def _build_env(self) -> dict[str, str] | None:
        """Compose subprocess env. If model_pool is set, override
        ANTHROPIC_DEFAULT_OPUS_MODEL with the current pool entry. Other
        env vars are inherited from the parent process (auth token,
        base URL, etc)."""
        model = self._current_model()
        if model is None:
            # No override — let subprocess inherit env directly (return
            # None so subprocess.run uses the default).
            return None
        env = os.environ.copy()
        env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = model
        return env

    # ------------------------------------------------------------------
    # Command building
    # ------------------------------------------------------------------

    def _build_command(self) -> list[str]:
        c = self.config
        cmd = [
            c.binary,
            "-p",
            "--output-format", c.output_format,
            "--max-turns", str(c.max_turns),
            "--permission-mode", c.permission_mode,
            "--input-format", "text",
        ]
        if c.no_session_persistence:
            cmd.append("--no-session-persistence")
        if c.max_budget_usd is not None:
            cmd += ["--max-budget-usd", f"{c.max_budget_usd:.2f}"]
        cmd.extend(c.extra_args)
        return cmd

    def _compose_prompt(self, prompt: str, system: str | None) -> str:
        """Embed system message + an anti-tool-use preamble into the prompt.

        Claude Code defaults its `-p` mode with tools enabled; with a
        bare instruction to "generate code", it often tries to call
        Read/Write/Bash tools instead of returning text. We tell it
        explicitly not to use tools and to put the entire answer in its
        single text reply.
        """
        preamble = (
            "Respond with the final answer text only. Do NOT call any tools "
            "(no file reads, no shell commands, no edits). Put the complete "
            "answer in a single assistant text reply.\n\n---\n\n"
        )
        if system:
            return f"{preamble}{system}\n\n---\n\n{prompt}"
        return f"{preamble}{prompt}"

    # ------------------------------------------------------------------
    # Result parsing
    # ------------------------------------------------------------------

    def _parse_result(self, r: subprocess.CompletedProcess) -> CompletionResult:
        if r.returncode != 0:
            raise RuntimeError(
                f"claude -p exited {r.returncode}\n"
                f"stderr:\n{r.stderr}\n"
                f"stdout:\n{r.stdout}"
            )
        try:
            data = json.loads(r.stdout)
        except json.JSONDecodeError as e:
            raise RuntimeError(
                f"claude -p output was not JSON (output-format mismatch?):\n"
                f"first 500 chars:\n{r.stdout[:500]}\n"
                f"parse error: {e}"
            ) from e
        return _completion_from_json(data, fallback_text=r.stdout)


def _completion_from_json(
    data: dict[str, Any],
    *,
    fallback_text: str = "",
) -> CompletionResult:
    """Pull text + usage from claude -p --output-format json.

    Claude Code's JSON shape (2.1.x):
        {
          "type": "result",
          "subtype": "success",
          "result": "<the completion text>",
          "session_id": "...",
          "is_error": false,
          "duration_ms": ...,
          "num_turns": 1,
          "total_cost_usd": ...,
          "usage": {
            "input_tokens": ...,
            "cache_creation_input_tokens": ...,
            "cache_read_input_tokens": ...,
            "output_tokens": ...,
            "server_tool_use": {...}
          },
          "modelUsage": {...},
          "permission_denials": [...]
        }

    On unexpected shapes we fall back to the raw stdout for ``text``.
    """
    text = data.get("result")
    if not isinstance(text, str):
        text = fallback_text
    usage = data.get("usage") or {}
    input_tokens = int(
        (usage.get("input_tokens") or 0)
        + (usage.get("cache_creation_input_tokens") or 0)
        + (usage.get("cache_read_input_tokens") or 0)
    )
    output_tokens = int(usage.get("output_tokens") or 0)
    model = ""
    model_usage = data.get("modelUsage") or {}
    if isinstance(model_usage, dict) and model_usage:
        # Pick first key as a label
        model = next(iter(model_usage.keys()), "")
    return CompletionResult(
        text=text,
        prompt_tokens=input_tokens,
        completion_tokens=output_tokens,
        model=model or "claude-code",
        raw=data,
    )
