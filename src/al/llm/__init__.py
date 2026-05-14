"""LLM client abstraction for benchmark and (future) editor backend.

公共符号：

    LLMClient        Protocol (call: ``complete(prompt, *, system, ...)``)
    CompletionResult dataclass (text + token counts + raw)
    MockLLMClient    canned-response client for tests / dry-runs
    YunwuClient      OpenAI-compatible POST against yunwu (spec § 8 default)
    LLMConfig        dataclass loaded from ``.env``
    load_api_config  helper to build LLMConfig

设计依据：`docs/PROJECT_PLAN.md § 2 阶段 ①.1` D-γ (yunwu / gpt-5.4-nano)。
"""

from __future__ import annotations

from al.llm.base import CompletionResult, LLMClient
from al.llm.claude_code import ClaudeCodeClient, ClaudeCodeConfig
from al.llm.env import LLMConfig, load_api_config
from al.llm.mock import MockLLMClient
from al.llm.yunwu import YunwuClient


__all__ = [
    "ClaudeCodeClient",
    "ClaudeCodeConfig",
    "CompletionResult",
    "LLMClient",
    "LLMConfig",
    "MockLLMClient",
    "YunwuClient",
    "load_api_config",
]
