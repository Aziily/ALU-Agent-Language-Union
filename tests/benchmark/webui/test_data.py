"""Tests for benchmarks.webui.data."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from benchmarks.webui.data import (
    CellData,
    list_repos,
    list_runs,
    list_workdir_files,
    load_cell,
    load_per_repo,
    load_run,
    parse_raw_transcript,
    read_workdir_file,
)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


def _make_run_dir(root: Path, ts: str, *, tax_pp: float = 0.0, n_proj: int = 1, k: int = 1) -> Path:
    run_dir = root / ts
    (run_dir / "per_repo").mkdir(parents=True)
    (run_dir / "raw").mkdir()
    (run_dir / "workdirs").mkdir()
    (run_dir / "run.json").write_text(json.dumps({
        "timestamp": ts,
        "n_projects": n_proj,
        "k_repeats": k,
        "baseline_pass_pct": 80.0,
        "al_pass_pct": 80.0 - tax_pp,
        "tax_pp": tax_pp,
        "total_llm_tokens": 100_000,
        "results": [],
    }))
    return run_dir


def _make_per_repo(run_dir: Path, repo: str) -> None:
    """Make minimal per_repo + raw for one cell."""
    pr = {
        "project": repo,
        "baseline": [{
            "project": repo, "k_iter": 0, "pipeline": "baseline",
            "test_passed": False, "test_total": 10, "test_passing": 7,
            "test_failing": 3, "llm_total_tokens": 5000, "implementer_ok": True,
            "inject_injected": 3, "inject_skipped": 0, "error": "",
        }],
        "al": [{
            "project": repo, "k_iter": 0, "pipeline": "al",
            "test_passed": False, "test_total": 10, "test_passing": 8,
            "test_failing": 2, "llm_total_tokens": 4000, "implementer_ok": True,
            "inject_injected": 5, "inject_skipped": 0, "error": "",
        }],
    }
    (run_dir / "per_repo" / f"{repo}.json").write_text(json.dumps(pr))
    (run_dir / "raw" / f"{repo}-k0-baseline.txt").write_text(
        f"=== PROMPT (50 chars) ===\nfill {repo} in Python\n\n"
        f"=== COMPLETION (30 chars) ===\ndef x(): return 1\n"
    )
    (run_dir / "raw" / f"{repo}-k0-al.txt").write_text(
        f"=== PROMPT (60 chars) ===\nfill {repo} in agent-lang\n\n"
        f"=== COMPLETION (40 chars) ===\ncode x:\n  body: |\n    def x(): return 1\n"
    )


# ---------------------------------------------------------------------------
# list_runs
# ---------------------------------------------------------------------------


def test_list_runs_empty(tmp_path):
    assert list_runs(tmp_path) == []


def test_list_runs_skips_dirs_without_run_json(tmp_path):
    (tmp_path / "incomplete").mkdir()
    assert list_runs(tmp_path) == []


def test_list_runs_sorts_desc(tmp_path):
    _make_run_dir(tmp_path, "20260101-000000", tax_pp=1.0)
    _make_run_dir(tmp_path, "20260201-000000", tax_pp=2.0)
    _make_run_dir(tmp_path, "20260301-000000", tax_pp=3.0)
    runs = list_runs(tmp_path)
    assert [r.timestamp for r in runs] == [
        "20260301-000000", "20260201-000000", "20260101-000000",
    ]


def test_list_runs_extracts_fields(tmp_path):
    _make_run_dir(tmp_path, "20260101-000000", tax_pp=2.5, n_proj=3, k=5)
    runs = list_runs(tmp_path)
    assert runs[0].tax_pp == 2.5
    assert runs[0].n_projects == 3
    assert runs[0].k_repeats == 5
    assert runs[0].total_llm_tokens == 100_000


def test_list_runs_skips_malformed_json(tmp_path):
    bad = tmp_path / "bad"
    (bad / "per_repo").mkdir(parents=True)
    (bad / "run.json").write_text("{not json")
    runs = list_runs(tmp_path)
    assert runs == []


# ---------------------------------------------------------------------------
# load_run / load_per_repo
# ---------------------------------------------------------------------------


def test_load_run_returns_dict(tmp_path):
    _make_run_dir(tmp_path, "ts", tax_pp=1.5)
    data = load_run(tmp_path, "ts")
    assert data["tax_pp"] == 1.5
    assert data["timestamp"] == "ts"


def test_load_run_missing_raises(tmp_path):
    with pytest.raises(FileNotFoundError):
        load_run(tmp_path, "nope")


def test_load_per_repo(tmp_path):
    run_dir = _make_run_dir(tmp_path, "ts")
    _make_per_repo(run_dir, "myproj")
    pr = load_per_repo(tmp_path, "ts", "myproj")
    assert pr["project"] == "myproj"
    assert len(pr["baseline"]) == 1
    assert len(pr["al"]) == 1


def test_list_repos(tmp_path):
    run_dir = _make_run_dir(tmp_path, "ts")
    _make_per_repo(run_dir, "alpha")
    _make_per_repo(run_dir, "beta")
    assert list_repos(tmp_path, "ts") == ["alpha", "beta"]


# ---------------------------------------------------------------------------
# parse_raw_transcript
# ---------------------------------------------------------------------------


def test_parse_raw_transcript_well_formed():
    text = (
        "=== PROMPT (5 chars) ===\n"
        "hello\n\n"
        "=== COMPLETION (3 chars) ===\n"
        "bye\n"
    )
    prompt, comp = parse_raw_transcript(text)
    assert prompt == "hello"
    assert comp == "bye"


def test_parse_raw_transcript_no_completion():
    text = "=== PROMPT (5 chars) ===\nhello\n"
    prompt, comp = parse_raw_transcript(text)
    assert prompt == "hello"
    assert comp == ""


def test_parse_raw_transcript_no_markers():
    text = "just some text"
    prompt, comp = parse_raw_transcript(text)
    assert prompt == text
    assert comp == ""


# ---------------------------------------------------------------------------
# load_cell
# ---------------------------------------------------------------------------


def test_load_cell_baseline(tmp_path):
    run_dir = _make_run_dir(tmp_path, "ts")
    _make_per_repo(run_dir, "myproj")
    cell = load_cell(tmp_path, "ts", "myproj", 0, "baseline")
    assert cell.project == "myproj"
    assert cell.k_iter == 0
    assert cell.pipeline == "baseline"
    assert cell.test_total == 10
    assert cell.test_passing == 7
    assert cell.llm_total_tokens == 5000
    assert "fill myproj in Python" in cell.prompt
    assert "return 1" in cell.completion


def test_load_cell_al(tmp_path):
    run_dir = _make_run_dir(tmp_path, "ts")
    _make_per_repo(run_dir, "myproj")
    cell = load_cell(tmp_path, "ts", "myproj", 0, "al")
    assert cell.pipeline == "al"
    assert cell.test_passing == 8


def test_load_cell_unknown_pipeline_raises(tmp_path):
    run_dir = _make_run_dir(tmp_path, "ts")
    _make_per_repo(run_dir, "myproj")
    with pytest.raises(ValueError, match="unknown pipeline"):
        load_cell(tmp_path, "ts", "myproj", 0, "wrong")


def test_load_cell_missing_k_raises(tmp_path):
    run_dir = _make_run_dir(tmp_path, "ts")
    _make_per_repo(run_dir, "myproj")
    with pytest.raises(FileNotFoundError):
        load_cell(tmp_path, "ts", "myproj", 5, "baseline")


# ---------------------------------------------------------------------------
# Workdir files (path traversal)
# ---------------------------------------------------------------------------


def test_read_workdir_file_blocks_traversal(tmp_path):
    run_dir = _make_run_dir(tmp_path, "ts")
    workdir = run_dir / "workdirs" / "x-k0-baseline"
    workdir.mkdir(parents=True)
    (workdir / "a.py").write_text("x = 1\n")
    with pytest.raises(ValueError, match="traversal"):
        read_workdir_file(tmp_path, "ts", "x", 0, "baseline", "../../../etc/passwd")


def test_read_workdir_file_ok(tmp_path):
    run_dir = _make_run_dir(tmp_path, "ts")
    workdir = run_dir / "workdirs" / "x-k0-baseline"
    workdir.mkdir(parents=True)
    (workdir / "a.py").write_text("x = 1\n")
    content, truncated = read_workdir_file(tmp_path, "ts", "x", 0, "baseline", "a.py")
    assert "x = 1" in content
    assert not truncated


def test_read_workdir_file_missing(tmp_path):
    run_dir = _make_run_dir(tmp_path, "ts")
    workdir = run_dir / "workdirs" / "x-k0-baseline"
    workdir.mkdir(parents=True)
    with pytest.raises(FileNotFoundError):
        read_workdir_file(tmp_path, "ts", "x", 0, "baseline", "nope.py")


def test_list_workdir_files(tmp_path):
    run_dir = _make_run_dir(tmp_path, "ts")
    workdir = run_dir / "workdirs" / "x-k0-baseline"
    workdir.mkdir(parents=True)
    (workdir / "a.py").write_text("a")
    (workdir / "pkg").mkdir()
    (workdir / "pkg" / "b.py").write_text("b")
    (workdir / "__pycache__").mkdir()
    (workdir / "__pycache__" / "c.pyc").write_text("c")
    files, truncated = list_workdir_files(tmp_path, "ts", "x", 0, "baseline")
    paths = {p for p, _ in files}
    assert "a.py" in paths
    assert "pkg/b.py" in paths
    assert not any("__pycache__" in p for p in paths)
    assert not truncated
