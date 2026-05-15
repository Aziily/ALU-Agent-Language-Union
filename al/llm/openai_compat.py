"""Generic OpenAI-compatible chat-completions client.

A single HTTP client that works against ANY OpenAI-compatible endpoint:
  - openai.com         /v1/chat/completions
  - yunwu.ai           /v1/chat/completions
  - canvas.aipaibox    /v1/chat/completions
  - localhost proxies  /v1/chat/completions
  - mistral / together / anyscale / groq / ollama / ...

Configuration is via :class:`LLMConfig` (loaded from .env). No
endpoint-specific code lives here — every OpenAI-compatible API speaks
the same request shape, so one client suffices.

For Anthropic-format APIs (``/v1/messages`` with ``x-api-key`` header),
use :class:`al.llm.claude_code.ClaudeCodeClient` instead (it wraps the
``claude -p`` CLI which talks Anthropic format natively).

Cost-tracking and rate-limiting are caller responsibility (the benchmark
runner does it via :attr:`CompletionResult.total_tokens`).
"""

from __future__ import annotations

import json
import sys
import time
from typing import Any

import httpx

from al.llm.base import CompletionResult
from al.llm.env import LLMConfig, load_api_config


# HTTP status codes worth retrying. 408/429/5xx are server-side transient.
# 401/403/404/422 are caller-side and never retried.
_TRANSIENT_HTTP_STATUSES = {408, 425, 429, 500, 502, 503, 504, 522, 524}


class OpenAICompatClient:
    """OpenAI-compatible HTTP client. Implements the ``LLMClient`` Protocol.

    Generic over any endpoint that accepts the standard
    ``POST /chat/completions`` shape with bearer auth. Endpoint specifics
    (yunwu vs openai vs local proxy) are entirely configured via
    :class:`LLMConfig` — there is no per-vendor code in this class.
    """

    def __init__(
        self,
        config: LLMConfig | None = None,
        *,
        timeout: float = 300.0,
        transport: httpx.BaseTransport | None = None,
        max_retries: int = 3,
        retry_backoff_sec: float = 5.0,
    ) -> None:
        """Build a client.

        Args:
            config: Pre-loaded :class:`LLMConfig`. If None, calls
                :func:`load_api_config()` which reads ``.env`` /
                process environment.
            timeout: Per-request HTTP timeout (seconds).
            transport: Override httpx transport for testing.
            max_retries: How many extra attempts on transient errors
                (HTTP 408 / 429 / 5xx, or network timeouts). Total
                attempts = max_retries + 1. Set to 0 to disable retry.
            retry_backoff_sec: Initial sleep between attempts. Doubles
                per attempt (5s, 10s, 20s) for max_retries=3.
        """
        self.config = config or load_api_config()
        self._timeout = timeout
        self._max_retries = max_retries
        self._retry_backoff = retry_backoff_sec
        self._client = httpx.Client(
            base_url=self.config.base_url,
            timeout=timeout,
            transport=transport,
            headers=self._default_headers(),
        )

    def _default_headers(self) -> dict[str, str]:
        h = {"Content-Type": "application/json"}
        if self.config.api_key:
            h["Authorization"] = f"Bearer {self.config.api_key}"
        return h

    def complete(
        self,
        prompt: str,
        *,
        system: str | None = None,
        max_tokens: int = 4096,
        temperature: float = 0.0,
        stop: list[str] | None = None,
    ) -> CompletionResult:
        """POST to ``/chat/completions`` and parse the response.

        Retries up to ``self._max_retries`` times on transient errors
        (HTTP 408 / 425 / 429 / 5xx, network timeout, connection
        error). Non-transient failures (auth, bad request, JSON parse)
        raise immediately.

        Raises:
            RuntimeError: if API key missing, or after all retries fail.
        """
        self.config.assert_has_key()

        payload = self._build_request(
            prompt=prompt,
            system=system,
            max_tokens=max_tokens,
            temperature=temperature,
            stop=stop,
        )

        attempts = self._max_retries + 1
        last_err: Exception | None = None
        for attempt in range(1, attempts + 1):
            try:
                resp = self._client.post("/chat/completions", json=payload)
            except (httpx.TimeoutException, httpx.NetworkError) as e:
                last_err = e
                if attempt < attempts:
                    wait = self._retry_backoff * (2 ** (attempt - 1))
                    print(
                        f"  [openai-compat] {type(e).__name__} on attempt "
                        f"{attempt}/{attempts}, retrying in {wait:.0f}s",
                        file=sys.stderr, flush=True,
                    )
                    time.sleep(wait)
                    continue
                raise RuntimeError(
                    f"{self.config.base_url}/chat/completions: "
                    f"network failure after {attempts} attempts: {e!r}"
                ) from e

            if resp.status_code < 300:
                data = resp.json()
                return self._parse_response(data)

            transient = resp.status_code in _TRANSIENT_HTTP_STATUSES
            if transient and attempt < attempts:
                wait = self._retry_backoff * (2 ** (attempt - 1))
                print(
                    f"  [openai-compat] HTTP {resp.status_code} on attempt "
                    f"{attempt}/{attempts}, retrying in {wait:.0f}s",
                    file=sys.stderr, flush=True,
                )
                time.sleep(wait)
                continue

            # Either non-transient (auth, bad request, etc.) or last attempt.
            raise RuntimeError(
                f"{self.config.base_url}/chat/completions returned "
                f"{resp.status_code} after {attempt} attempt(s): "
                f"{resp.text[:500]}"
            )

        # Defensive: the loop returns or raises before this point.
        assert last_err is not None  # pragma: no cover
        raise RuntimeError(  # pragma: no cover
            f"{self.config.base_url}/chat/completions: exhausted retries: {last_err!r}"
        )

    def _build_request(
        self,
        *,
        prompt: str,
        system: str | None,
        max_tokens: int,
        temperature: float,
        stop: list[str] | None,
    ) -> dict[str, Any]:
        """Standard OpenAI chat completions payload."""
        messages: list[dict[str, str]] = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})

        payload: dict[str, Any] = {
            "model": self.config.model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }
        if stop:
            payload["stop"] = stop
        return payload

    def _parse_response(self, data: dict[str, Any]) -> CompletionResult:
        """Pull text + token usage from OpenAI-compatible response shape."""
        try:
            text = data["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError) as e:
            raise RuntimeError(
                f"unexpected OpenAI-compat response: {json.dumps(data)[:500]}"
            ) from e

        usage = data.get("usage") or {}
        return CompletionResult(
            text=text,
            prompt_tokens=int(usage.get("prompt_tokens") or 0),
            completion_tokens=int(usage.get("completion_tokens") or 0),
            model=data.get("model") or self.config.model,
            raw=data,
        )

    def close(self) -> None:
        """Close the underlying HTTP client."""
        self._client.close()

    def __enter__(self) -> "OpenAICompatClient":
        return self

    def __exit__(self, *exc) -> None:
        self.close()


# Backward-compat alias — keep ``YunwuClient`` working for one release so
# external scripts that imported it don't break on this rename.
YunwuClient = OpenAICompatClient
