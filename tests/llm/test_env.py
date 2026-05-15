"""Tests for al.llm.env (.env loader).

Covers: defaults, env-var priority, LLM_*/OPENAI_*/YUNWU_* fallback
chain, override mode, missing-key detection.
"""

from __future__ import annotations

import os
from unittest.mock import patch

import pytest

from al.llm.env import LLMConfig, load_api_config


def _clear_all_llm_vars(monkeypatch):
    """Delete every env var that load_api_config might read."""
    for v in (
        "LLM_API_KEY", "LLM_BASE_URL", "LLM_MODEL",
        "OPENAI_API_KEY", "OPENAI_BASE_URL", "OPENAI_MODEL",
        "YUNWU_API_KEY", "YUNWU_BASE_URL", "YUNWU_MODEL",
    ):
        monkeypatch.delenv(v, raising=False)


# ---------------------------------------------------------------------------
# Defaults when no .env / no env vars
# ---------------------------------------------------------------------------


def test_defaults_when_nothing_set(tmp_path, monkeypatch):
    """No .env file and no env vars → defaults + None key."""
    _clear_all_llm_vars(monkeypatch)
    cfg = load_api_config(dotenv_path=tmp_path / "absent.env")
    assert cfg.api_key is None
    # default base_url is a placeholder for local proxy; users override via .env
    assert cfg.base_url.startswith("http")
    assert cfg.model  # some non-empty default


# ---------------------------------------------------------------------------
# .env file loading — preferred LLM_ prefix
# ---------------------------------------------------------------------------


def test_loads_from_dotenv_LLM_prefix(tmp_path, monkeypatch):
    """LLM_* env vars are the canonical names."""
    _clear_all_llm_vars(monkeypatch)
    env = tmp_path / ".env"
    env.write_text(
        "LLM_API_KEY=sk-test-key\n"
        "LLM_BASE_URL=https://custom.example/v1\n"
        "LLM_MODEL=custom-model\n"
    )
    cfg = load_api_config(dotenv_path=env)
    assert cfg.api_key == "sk-test-key"
    assert cfg.base_url == "https://custom.example/v1"
    assert cfg.model == "custom-model"


# ---------------------------------------------------------------------------
# Fallback chain: LLM_ > OPENAI_ > YUNWU_
# ---------------------------------------------------------------------------


def test_falls_back_to_OPENAI_when_LLM_unset(tmp_path, monkeypatch):
    _clear_all_llm_vars(monkeypatch)
    env = tmp_path / ".env"
    env.write_text("OPENAI_API_KEY=sk-openai\nOPENAI_MODEL=gpt-4o\n")
    cfg = load_api_config(dotenv_path=env)
    assert cfg.api_key == "sk-openai"
    assert cfg.model == "gpt-4o"


def test_falls_back_to_YUNWU_when_LLM_and_OPENAI_unset(tmp_path, monkeypatch):
    """Legacy YUNWU_* fallback for backward compat."""
    _clear_all_llm_vars(monkeypatch)
    env = tmp_path / ".env"
    env.write_text("YUNWU_API_KEY=legacy-key\nYUNWU_MODEL=legacy-model\n")
    cfg = load_api_config(dotenv_path=env)
    assert cfg.api_key == "legacy-key"
    assert cfg.model == "legacy-model"


def test_LLM_prefix_wins_over_legacy(tmp_path, monkeypatch):
    """If both LLM_* and YUNWU_* are set, LLM_* wins."""
    _clear_all_llm_vars(monkeypatch)
    env = tmp_path / ".env"
    env.write_text(
        "LLM_API_KEY=new\n"
        "YUNWU_API_KEY=legacy\n"
    )
    cfg = load_api_config(dotenv_path=env)
    assert cfg.api_key == "new"


# ---------------------------------------------------------------------------
# Env-var-vs-dotenv override
# ---------------------------------------------------------------------------


def test_existing_env_wins_by_default(tmp_path, monkeypatch):
    """Existing process env var beats .env file value (override=False)."""
    _clear_all_llm_vars(monkeypatch)
    monkeypatch.setenv("LLM_API_KEY", "from-env")
    env = tmp_path / ".env"
    env.write_text("LLM_API_KEY=from-file\n")
    cfg = load_api_config(dotenv_path=env, override=False)
    assert cfg.api_key == "from-env"


def test_override_true_lets_file_win(tmp_path, monkeypatch):
    _clear_all_llm_vars(monkeypatch)
    monkeypatch.setenv("LLM_API_KEY", "from-env")
    env = tmp_path / ".env"
    env.write_text("LLM_API_KEY=from-file\n")
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
