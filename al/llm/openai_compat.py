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
from typing import Any

import httpx

from al.llm.base import CompletionResult
from al.llm.env import LLMConfig, load_api_config


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
        timeout: float = 120.0,
        transport: httpx.BaseTransport | None = None,
    ) -> None:
        """Build a client.

        Args:
            config: Pre-loaded :class:`LLMConfig`. If None, calls
                :func:`load_api_config()` which reads ``.env`` /
                process environment.
            timeout: Per-request HTTP timeout (seconds).
            transport: Override httpx transport for testing.
        """
        self.config = config or load_api_config()
        self._timeout = timeout
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

        Raises:
            RuntimeError: if API key missing or server returns non-2xx.
        """
        self.config.assert_has_key()

        payload = self._build_request(
            prompt=prompt,
            system=system,
            max_tokens=max_tokens,
            temperature=temperature,
            stop=stop,
        )
        resp = self._client.post("/chat/completions", json=payload)
        if resp.status_code >= 300:
            raise RuntimeError(
                f"{self.config.base_url}/chat/completions returned "
                f"{resp.status_code}: {resp.text[:500]}"
            )

        data = resp.json()
        return self._parse_response(data)

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
