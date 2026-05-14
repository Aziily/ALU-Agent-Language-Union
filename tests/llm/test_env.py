"""Tests for al.llm.env (.env loader).

覆盖：默认值、env var 优先级、override 模式、缺 key 的检测。
"""

from __future__ import annotations

import os
from unittest.mock import patch

import pytest

from al.llm.env import LLMConfig, load_api_config


# ---------------------------------------------------------------------------
# Defaults when no .env / no env vars
# ---------------------------------------------------------------------------


def test_defaults_when_nothing_set(tmp_path, monkeypatch):
    """No .env file and no env vars → defaults + None key."""
    monkeypatch.delenv("YUNWU_API_KEY", raising=False)
    monkeypatch.delenv("YUNWU_BASE_URL", raising=False)
    monkeypatch.delenv("YUNWU_MODEL", raising=False)

    cfg = load_api_config(dotenv_path=tmp_path / "absent.env")
    assert cfg.api_key is None
    assert cfg.base_url == "https://yunwu.ai/v1"
    assert cfg.model == "gpt-5.4-nano"


# ---------------------------------------------------------------------------
# .env file loading
# ---------------------------------------------------------------------------


def test_loads_from_dotenv(tmp_path, monkeypatch):
    """Reads YUNWU_API_KEY etc. from a .env file."""
    monkeypatch.delenv("YUNWU_API_KEY", raising=False)
    monkeypatch.delenv("YUNWU_BASE_URL", raising=False)
    monkeypatch.delenv("YUNWU_MODEL", raising=False)

    env = tmp_path / ".env"
    env.write_text(
        "YUNWU_API_KEY=sk-test-key\n"
        "YUNWU_BASE_URL=https://custom.example/v1\n"
        "YUNWU_MODEL=custom-model\n"
    )
    cfg = load_api_config(dotenv_path=env)
    assert cfg.api_key == "sk-test-key"
    assert cfg.base_url == "https://custom.example/v1"
    assert cfg.model == "custom-model"


def test_existing_env_wins_by_default(tmp_path, monkeypatch):
    """Existing process env var beats .env file value (override=False)."""
    monkeypatch.setenv("YUNWU_API_KEY", "from-env")
    env = tmp_path / ".env"
    env.write_text("YUNWU_API_KEY=from-file\n")
    cfg = load_api_config(dotenv_path=env, override=False)
    assert cfg.api_key == "from-env"


def test_override_true_lets_file_win(tmp_path, monkeypatch):
    monkeypatch.setenv("YUNWU_API_KEY", "from-env")
    env = tmp_path / ".env"
    env.write_text("YUNWU_API_KEY=from-file\n")
    cfg = load_api_config(dotenv_path=env, override=True)
    assert cfg.api_key == "from-file"


# ---------------------------------------------------------------------------
# assert_has_key
# ---------------------------------------------------------------------------


def test_assert_has_key_raises_when_missing():
    cfg = LLMConfig(api_key=None, base_url="x", model="y")
    with pytest.raises(RuntimeError, match="api_key is empty"):
        cfg.assert_has_key()


def test_assert_has_key_raises_when_empty_string():
    cfg = LLMConfig(api_key="", base_url="x", model="y")
    with pytest.raises(RuntimeError):
        cfg.assert_has_key()


def test_assert_has_key_passes_when_set():
    cfg = LLMConfig(api_key="sk-x", base_url="x", model="y")
    cfg.assert_has_key()  # should not raise


# ---------------------------------------------------------------------------
# Frozen dataclass
# ---------------------------------------------------------------------------


def test_llm_config_is_frozen():
    cfg = LLMConfig(api_key="k", base_url="x", model="y")
    with pytest.raises((AttributeError, TypeError)):  # frozen dataclass
        cfg.api_key = "other"  # type: ignore[misc]
