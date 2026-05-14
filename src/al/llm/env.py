"""``.env`` loader + LLMConfig dataclass.

Reads ``YUNWU_API_KEY`` / ``YUNWU_BASE_URL`` / ``YUNWU_MODEL`` from the
project-root ``.env`` (or, if absent, the current process environment).
Defaults match spec § 8 (gpt-5.4-nano over yunwu).
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


@dataclass(frozen=True)
class LLMConfig:
    """Resolved API config for the active LLM provider.

    None ``api_key`` is allowed at construction time but will fail when
    :meth:`YunwuClient.complete` actually fires; this lets tests build a
    client and verify error handling without leaking real secrets.
    """

    api_key: str | None
    base_url: str
    model: str

    def assert_has_key(self) -> None:
        """Raise ``RuntimeError`` if api_key is missing — call before HTTP."""
        if not self.api_key:
            raise RuntimeError(
                "LLMConfig.api_key is empty. Set YUNWU_API_KEY in .env "
                "or pass via env var before calling complete()."
            )


def load_api_config(
    *,
    dotenv_path: Path | None = None,
    override: bool = False,
) -> LLMConfig:
    """Load LLM config from ``.env`` + process environment.

    Args:
        dotenv_path: Custom .env path. Defaults to project root ``.env``.
        override: If True, .env values override existing env vars. Default
            False (existing env wins — easier for CI/secret injection).

    Resolution order per key:
        1. existing process env var (unless override=True)
        2. .env file value
        3. hard-coded default (only for non-secret values like base_url)
    """
    if dotenv_path is None:
        dotenv_path = _default_dotenv()
    if dotenv_path.exists():
        load_dotenv(dotenv_path=dotenv_path, override=override)

    return LLMConfig(
        api_key=os.environ.get("YUNWU_API_KEY") or None,
        base_url=os.environ.get("YUNWU_BASE_URL", "https://yunwu.ai/v1"),
        model=os.environ.get("YUNWU_MODEL", "gpt-5.4-nano"),
    )


def _default_dotenv() -> Path:
    """Project-root .env (sister to pyproject.toml)."""
    here = Path(__file__).resolve()
    # src/al/llm/env.py → .../<project_root>/.env
    return here.parents[3] / ".env"
