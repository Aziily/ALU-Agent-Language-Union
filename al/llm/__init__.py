"""LLM client abstraction for the agent-lang benchmark.

Public symbols:

    LLMClient              Protocol (callable: ``complete(prompt, *, system, ...)``)
    CompletionResult       dataclass (text + token counts + raw)
    MockLLMClient          canned-response client for tests / dry-runs
    OpenAICompatClient     generic HTTP client for any OpenAI-compatible API
                           (openai / yunwu / aipaibox / localhost proxies / ...)
    ClaudeCodeClient       wrapper around ``claude -p`` CLI (Anthropic format)
    LLMConfig              resolved config (api_key + base_url + model)
    load_api_config        helper to load LLMConfig from .env + process env

Two transports, one abstraction:
  - ``OpenAICompatClient`` for any vendor that speaks OpenAI's
    ``/v1/chat/completions`` shape (the common case).
  - ``ClaudeCodeClient``  for Anthropic-format gateways via the
    ``claude -p`` subprocess CLI.

For backward compatibility, ``YunwuClient`` is re-exported as an alias
for ``OpenAICompatClient`` (will be removed in a future release).
"""

from __future__ import annotations

from al.llm.base import CompletionResult, LLMClient
from al.llm.claude_code import ClaudeCodeClient, ClaudeCodeConfig
from al.llm.env import LLMConfig, load_api_config
from al.llm.mock import MockLLMClient
from al.llm.openai_compat import OpenAICompatClient, YunwuClient


__all__ = [
    "ClaudeCodeClient",
    "ClaudeCodeConfig",
    "CompletionResult",
    "LLMClient",
    "LLMConfig",
    "MockLLMClient",
    "OpenAICompatClient",
    "YunwuClient",  # alias for OpenAICompatClient — deprecated
    "load_api_config",
]
