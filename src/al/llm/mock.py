"""MockLLMClient — canned responses for tests and dry-runs.

Two modes:

* Dict-based: ``MockLLMClient({"prompt_substring": "canned response"})``
  — first matching key triggers the response.
* Callable-based: ``MockLLMClient(lambda prompt, **kw: "...")`` — full
  control for fixture-style tests.

Always returns a :class:`CompletionResult` with token counts = 0 (don't
fake what we can't measure; tests that care should mock token counts
explicitly).
"""

from __future__ import annotations

from typing import Callable

from al.llm.base import CompletionResult


_CannedFn = Callable[..., str]


class MockLLMClient:
    """Test-only LLMClient. Implements the LLMClient Protocol."""

    def __init__(
        self,
        responses: dict[str, str] | _CannedFn | None = None,
        *,
        default: str = "",
    ) -> None:
        """Configure mock behavior.

        Args:
            responses: Either a dict (key = substring to match in prompt)
                or a callable ``(prompt, **kw) -> str``. None = always
                return ``default``.
            default: Fallback when ``responses`` is a dict and no key
                matches. Empty by default.
        """
        self._responses = responses
        self._default = default
        # Recording for assertion in tests
        self.calls: list[dict] = []

    def complete(
        self,
        prompt: str,
        *,
        system: str | None = None,
        max_tokens: int = 4096,
        temperature: float = 0.0,
        stop: list[str] | None = None,
    ) -> CompletionResult:
        self.calls.append({
            "prompt": prompt,
            "system": system,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "stop": stop,
        })

        if callable(self._responses):
            text = self._responses(prompt, system=system, max_tokens=max_tokens,
                                   temperature=temperature, stop=stop)
        elif isinstance(self._responses, dict):
            text = self._default
            for key, value in self._responses.items():
                if key in prompt:
                    text = value
                    break
        else:
            text = self._default

        return CompletionResult(
            text=text,
            prompt_tokens=0,
            completion_tokens=0,
            model="mock",
            raw={"mock": True},
        )
