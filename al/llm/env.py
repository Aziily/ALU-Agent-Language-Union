""".env loader + LLMConfig dataclass.

Generic configuration for any OpenAI-compatible HTTP backend. The
recommended env-var prefix is ``LLM_`` (vendor-neutral):

    LLM_API_KEY       Bearer token / api-key
    LLM_BASE_URL      e.g. http://localhost:9000/v1
                            https://api.openai.com/v1
                            https://yunwu.ai/v1
    LLM_MODEL         e.g. gpt-5.4 / gpt-4o / claude-sonnet-4-6 / qwen3-coder-plus

Legacy ``YUNWU_*`` and ``OPENAI_*`` env vars are read as fallbacks (old
deployments) so existing ``.env`` files keep working.

For Anthropic-format providers (``claude -p`` via gateway), see
``ClaudeCodeConfig`` in ``al.llm.claude_code`` — that's a separate
config because the subprocess CLI has its own knobs (max_turns,
permission_mode, model_pool, ...).
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


@dataclass(frozen=True)
class LLMConfig:
    """Resolved API config for the active OpenAI-compatible provider.

    ``api_key=None`` is allowed at construction time but
    :meth:`assert_has_key` will fail when the client tries to fire a
    request. This lets tests build a client and verify error handling
    without leaking real secrets.
    """

    api_key: str | None
    base_url: str
    model: str

    def assert_has_key(self) -> None:
        """Raise ``RuntimeError`` if api_key is missing — call before HTTP."""
        if not self.api_key:
            raise RuntimeError(
                "LLMConfig.api_key is empty. Set LLM_API_KEY in .env "
                "(or the legacy YUNWU_API_KEY / OPENAI_API_KEY) before "
                "calling complete()."
            )


# Resolution order per key (highest priority first):
#   1. LLM_*               (new canonical)
#   2. OPENAI_*            (industry default)
#   3. YUNWU_*             (legacy /AL pre-rename)
#   4. hard-coded default  (only for base_url; key/model have no default)
_KEY_VAR_CANDIDATES = ("LLM_API_KEY", "OPENAI_API_KEY", "YUNWU_API_KEY")
_BASE_URL_CANDIDATES = ("LLM_BASE_URL", "OPENAI_BASE_URL", "YUNWU_BASE_URL")
_MODEL_CANDIDATES = ("LLM_MODEL", "OPENAI_MODEL", "YUNWU_MODEL")
_DEFAULT_BASE_URL = "http://localhost:9000/v1"
_DEFAULT_MODEL = "gpt-5.4"


def _first_set(*names: str, default: str | None = None) -> str | None:
    for n in names:
        v = os.environ.get(n)
        if v:
            return v
    return default


def load_api_config(
    *,
    dotenv_path: Path | None = None,
    override: bool = False,
) -> LLMConfig:
    """Load LLM config from ``.env`` + process environment.

    Args:
        dotenv_path: Custom .env path. Defaults to project root ``.env``.
        override: If True, .env values override existing env vars.
            Default False (existing env wins — easier for CI/secret
            injection).
    """
    if dotenv_path is None:
        dotenv_path = _default_dotenv()
    if dotenv_path.exists():
        load_dotenv(dotenv_path=dotenv_path, override=override)

    return LLMConfig(
        api_key=_first_set(*_KEY_VAR_CANDIDATES),
        base_url=_first_set(*_BASE_URL_CANDIDATES, default=_DEFAULT_BASE_URL),
        model=_first_set(*_MODEL_CANDIDATES, default=_DEFAULT_MODEL),
    )


def _default_dotenv() -> Path:
    """Project-root .env (sister to pyproject.toml)."""
    here = Path(__file__).resolve()
    # al/llm/env.py → project_root/.env
    return here.parents[2] / ".env"
