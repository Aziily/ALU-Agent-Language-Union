"""LLMClient Protocol + CompletionResult dataclass.

Both ``OpenAICompatClient`` (real) and ``MockLLMClient`` (test) satisfy this
Protocol. Phase ①.1 only needs sync ``complete``; streaming留 phase ②+。

Token counting follows the OpenAI convention (prompt + completion tokens).
``raw`` carries the full API response for debugging — caller may stash it
into trace files but should not log full transcripts to stdout.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol, runtime_checkable


@dataclass
class CompletionResult:
    """One complete() call's result.

    Attributes:
        text: The generated completion text (assistant message content).
        prompt_tokens: Tokens consumed by the prompt + system message.
        completion_tokens: Tokens generated.
        model: Model name actually used (server may differ from request).
        raw: Full JSON response from the provider. Don't log this verbatim.
    """

    text: str
    prompt_tokens: int = 0
    completion_tokens: int = 0
    model: str = ""
    raw: dict[str, Any] = field(default_factory=dict)

    @property
    def total_tokens(self) -> int:
        """Convenience: prompt + completion. 0 if neither was reported."""
        return self.prompt_tokens + self.completion_tokens


@runtime_checkable
class LLMClient(Protocol):
    """Common shape of any LLM backend."""

    def complete(
        self,
        prompt: str,
        *,
        system: str | None = None,
        max_tokens: int = 4096,
        temperature: float = 0.0,
        stop: list[str] | None = None,
    ) -> CompletionResult: ...
