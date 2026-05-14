"""Smoke tests for webui routes — verify each returns 200 with valid fixtures."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from benchmarks.webui import create_app


def _seed(root: Path) -> None:
    """Seed one minimal run fixture."""
    run_dir = root / "ts_xxx"
    (run_dir / "per_repo").mkdir(parents=True)
    (run_dir / "raw").mkdir()
    (run_dir / "workdirs" / "myproj-k0-baseline").mkdir(parents=True)
    (run_dir / "workdirs" / "myproj-k0-baseline" / "x.py").write_text("x = 1\n")
    (run_dir / "run.json").write_text(json.dumps({
        "timestamp": "ts_xxx", "n_projects": 1, "k_repeats": 1,
        "baseline_pass_pct": 80.0, "al_pass_pct": 75.0,
        "tax_pp": 5.0, "total_llm_tokens": 1000,
        "results": [{"project": "myproj", "k_iter": 0, "pipeline": "baseline",
                     "test_total": 10, "test_passing": 8, "test_failing": 2,
                     "llm_total_tokens": 500, "implementer_ok": True,
                     "inject_injected": 3, "inject_skipped": 0, "error": ""},
                    {"project": "myproj", "k_iter": 0, "pipeline": "al",
                     "test_total": 10, "test_passing": 7, "test_failing": 3,
                     "llm_total_tokens": 500, "implementer_ok": True,
                     "inject_injected": 5, "inject_skipped": 0, "error": ""}],
    }))
    (run_dir / "per_repo" / "myproj.json").write_text(json.dumps({
        "project": "myproj",
        "baseline": [{"project": "myproj", "k_iter": 0, "pipeline": "baseline",
                      "test_total": 10, "test_passing": 8, "test_failing": 2,
                      "llm_total_tokens": 500, "implementer_ok": True,
                      "inject_injected": 3, "inject_skipped": 0, "error": ""}],
        "al": [{"project": "myproj", "k_iter": 0, "pipeline": "al",
                       "test_total": 10, "test_passing": 7, "test_failing": 3,
                       "llm_total_tokens": 500, "implementer_ok": True,
                       "inject_injected": 5, "inject_skipped": 0, "error": ""}],
    }))
    (run_dir / "raw" / "myproj-k0-baseline.txt").write_text(
        "=== PROMPT (5 chars) ===\nhello\n\n=== COMPLETION (3 chars) ===\nbye\n"
    )
    (run_dir / "raw" / "myproj-k0-al.txt").write_text(
        "=== PROMPT (5 chars) ===\nhello\n\n=== COMPLETION (3 chars) ===\nbye\n"
    )


@pytest.fixture
def client(tmp_path):
    _seed(tmp_path)
    app = create_app(runs_root=tmp_path)
    app.config["TESTING"] = True
    return app.test_client()


def test_index(client):
    r = client.get("/")
    assert r.status_code == 200
    assert b"ts_xxx" in r.data


def test_run_view(client):
    r = client.get("/runs/ts_xxx")
    assert r.status_code == 200
    assert b"myproj" in r.data
    assert b"Tax" in r.data


def test_repo_view(client):
    r = client.get("/runs/ts_xxx/repos/myproj")
    assert r.status_code == 200
    assert b"baseline" in r.data
    assert b"al" in r.data


def test_cell_view_baseline(client):
    r = client.get("/runs/ts_xxx/cells/myproj/0/baseline")
    assert r.status_code == 200
    assert b"hello" in r.data  # the prompt content


def test_cell_view_al(client):
    r = client.get("/runs/ts_xxx/cells/myproj/0/al")
    assert r.status_code == 200


def test_cell_view_bad_pipeline(client):
    r = client.get("/runs/ts_xxx/cells/myproj/0/wrong_pipeline")
    assert r.status_code == 400


def test_raw_passthrough(client):
    r = client.get("/runs/ts_xxx/raw/myproj/0/baseline.txt")
    assert r.status_code == 200
    assert b"hello" in r.data


def test_cell_file_view(client):
    r = client.get("/runs/ts_xxx/cells/myproj/0/baseline/file/x.py")
    assert r.status_code == 200
    assert b"x = 1" in r.data


def test_404_unknown_run(client):
    r = client.get("/runs/nonexistent")
    assert r.status_code == 404


def test_404_unknown_repo(client):
    r = client.get("/runs/ts_xxx/repos/no_such_repo")
    assert r.status_code == 404


def test_diff_view_ok(client):
    """Phase 1.H'.E — side-by-side BL/AL prompt diff."""
    r = client.get("/runs/ts_xxx/diff/myproj/0")
    assert r.status_code == 200
    # difflib.HtmlDiff emits a <table class="diff">
    assert b'class="diff"' in r.data
    # Should mention both pipelines
    assert b"BL prompt" in r.data
    assert b"AL prompt" in r.data


def test_diff_view_404_unknown_repo(client):
    r = client.get("/runs/ts_xxx/diff/no_such_repo/0")
    assert r.status_code == 404
