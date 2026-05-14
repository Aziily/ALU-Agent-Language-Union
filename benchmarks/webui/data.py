"""Data-loading layer for the benchmark WebUI.

All functions are pure: take a ``runs_root: Path``, return Python dicts /
dataclasses parsed from the on-disk JSON files. No mutation, no I/O
side effects beyond reads.

The runs root is typically ``benchmarks/reports/runs/`` relative to the
project; each subdir is a timestamped benchmark run produced by
``benchmarks.harness.runner.run_pipeline``.

Schema source-of-truth: ``benchmarks/harness/runner.py`` defines
``PipelineRunResult`` + ``RunSummary``. We parse the JSON serializations
loosely (`.get()` with defaults) so old runs missing new fields don't crash.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
from typing import Any


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------


@dataclass
class RunMeta:
    """Lightweight per-run summary for the index page."""

    timestamp: str
    n_projects: int = 0
    k_repeats: int = 0
    baseline_pass_pct: float = 0.0
    al_pass_pct: float = 0.0
    tax_pp: float = 0.0
    total_llm_tokens: int = 0


@dataclass
class CellData:
    """One (repo, k_iter, pipeline) cell with its raw transcript + meta."""

    project: str
    k_iter: int
    pipeline: str
    test_passed: bool = False
    test_total: int = 0
    test_passing: int = 0
    test_passing_with_xfail: int = 0
    test_failing: int = 0
    duration_sec: float = 0.0
    llm_total_tokens: int = 0
    implementer_ok: bool = False
    inject_injected: int = 0
    inject_skipped: int = 0
    error: str = ""
    prompt: str = ""
    completion: str = ""
    prompt_chars: int = 0
    completion_chars: int = 0
    # Phase 1.H'.F.2: multi-iter loop bookkeeping
    n_iterations: int = 0
    final_iter_idx: int = -1
    iter_outcomes: list = field(default_factory=list)


# ---------------------------------------------------------------------------
# list_runs / load_run / load_per_repo
# ---------------------------------------------------------------------------


def list_runs(runs_root: Path) -> list[RunMeta]:
    """Scan ``runs_root`` for benchmark run dirs. Sort by timestamp desc."""
    if not runs_root.exists():
        return []
    out: list[RunMeta] = []
    for run_dir in sorted(runs_root.iterdir(), reverse=True):
        if not run_dir.is_dir():
            continue
        run_json = run_dir / "run.json"
        if not run_json.exists():
            continue
        try:
            data = json.loads(run_json.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        out.append(RunMeta(
            timestamp=data.get("timestamp", run_dir.name),
            n_projects=data.get("n_projects", 0),
            k_repeats=data.get("k_repeats", 0),
            baseline_pass_pct=data.get("baseline_pass_pct", 0.0),
            al_pass_pct=data.get("al_pass_pct", 0.0),
            tax_pp=data.get("tax_pp", 0.0),
            total_llm_tokens=data.get("total_llm_tokens", 0),
        ))
    return out


def load_run(runs_root: Path, ts: str) -> dict[str, Any]:
    """Return parsed ``run.json`` for one run. Raises FileNotFoundError if absent."""
    fp = runs_root / ts / "run.json"
    return json.loads(fp.read_text(encoding="utf-8"))


def load_per_repo(runs_root: Path, ts: str, repo: str) -> dict[str, Any]:
    """Return parsed ``per_repo/<repo>.json`` for one project."""
    fp = runs_root / ts / "per_repo" / f"{repo}.json"
    return json.loads(fp.read_text(encoding="utf-8"))


def list_repos(runs_root: Path, ts: str) -> list[str]:
    """List repos with per_repo data for a run."""
    per_repo_dir = runs_root / ts / "per_repo"
    if not per_repo_dir.exists():
        return []
    return sorted(p.stem for p in per_repo_dir.glob("*.json"))


# ---------------------------------------------------------------------------
# Cell loading
# ---------------------------------------------------------------------------


_PROMPT_MARKER = re.compile(r"^=== PROMPT \(\d+ chars\) ===\s*$", re.MULTILINE)
_COMPLETION_MARKER = re.compile(r"^=== COMPLETION \(\d+ chars\) ===\s*$", re.MULTILINE)


def parse_raw_transcript(text: str) -> tuple[str, str]:
    """Split a raw transcript into (prompt, completion) sections.

    Format produced by ``runner.py::_save_raw``:
        === PROMPT (N chars) ===
        <prompt body>

        === COMPLETION (M chars) ===
        <completion body>

    If markers are absent, returns (text, "") — treats whole content as
    a single prompt for graceful degradation.
    """
    p_match = _PROMPT_MARKER.search(text)
    c_match = _COMPLETION_MARKER.search(text)
    if p_match and c_match:
        prompt = text[p_match.end():c_match.start()].strip("\n")
        completion = text[c_match.end():].strip("\n")
        return prompt, completion
    if p_match and not c_match:
        return text[p_match.end():].strip("\n"), ""
    return text, ""


def load_cell(
    runs_root: Path,
    ts: str,
    repo: str,
    k: int,
    pipeline: str,
) -> CellData:
    """Load metadata + raw transcript for one cell."""
    if pipeline not in ("baseline", "al"):
        raise ValueError(f"unknown pipeline: {pipeline!r}")
    per = load_per_repo(runs_root, ts, repo)
    candidates = per.get(pipeline, [])
    meta = next((r for r in candidates if r.get("k_iter") == k), None)
    if meta is None:
        raise FileNotFoundError(
            f"no cell for {repo}/{pipeline}/k={k} in run {ts}"
        )

    cell = CellData(
        project=meta.get("project", repo),
        k_iter=meta.get("k_iter", k),
        pipeline=meta.get("pipeline", pipeline),
        test_passed=meta.get("test_passed", False),
        test_total=meta.get("test_total", 0),
        test_passing=meta.get("test_passing", 0),
        test_passing_with_xfail=meta.get("test_passing_with_xfail", 0),
        test_failing=meta.get("test_failing", 0),
        duration_sec=meta.get("duration_sec", 0.0),
        llm_total_tokens=meta.get("llm_total_tokens", 0),
        implementer_ok=meta.get("implementer_ok", False),
        inject_injected=meta.get("inject_injected", 0),
        inject_skipped=meta.get("inject_skipped", 0),
        error=meta.get("error", ""),
        n_iterations=meta.get("n_iterations", 0),
        final_iter_idx=meta.get("final_iter_idx", -1),
        iter_outcomes=meta.get("iter_outcomes", []),
    )

    raw_fp = runs_root / ts / "raw" / f"{repo}-k{k}-{pipeline}.txt"
    if raw_fp.exists():
        try:
            text = raw_fp.read_text(encoding="utf-8", errors="replace")
            cell.prompt, cell.completion = parse_raw_transcript(text)
            cell.prompt_chars = len(cell.prompt)
            cell.completion_chars = len(cell.completion)
        except OSError:
            pass

    return cell


# ---------------------------------------------------------------------------
# Workdir file access (read-only, path-traversal safe)
# ---------------------------------------------------------------------------


_MAX_INLINE_FILE_BYTES = 256 * 1024  # 256 KB


def list_workdir_files(
    runs_root: Path,
    ts: str,
    repo: str,
    k: int,
    pipeline: str,
    *,
    limit: int = 500,
) -> tuple[list[tuple[str, int]], bool]:
    """List files in the workdir. Returns ((rel_path, size_bytes), truncated)."""
    workdir = runs_root / ts / "workdirs" / f"{repo}-k{k}-{pipeline}"
    if not workdir.exists() or not workdir.is_dir():
        return [], False
    out: list[tuple[str, int]] = []
    for p in workdir.rglob("*"):
        if not p.is_file():
            continue
        parts = p.relative_to(workdir).parts
        if any(x in parts for x in ("__pycache__", ".git", ".pytest_cache")):
            continue
        try:
            size = p.stat().st_size
        except OSError:
            continue
        out.append((p.relative_to(workdir).as_posix(), size))
        if len(out) >= limit:
            return out, True
    return out, False


def read_workdir_file(
    runs_root: Path,
    ts: str,
    repo: str,
    k: int,
    pipeline: str,
    rel_path: str,
) -> tuple[str, bool]:
    """Read one workdir file. Returns (content, truncated).

    Raises FileNotFoundError if not found, ValueError on path traversal.
    """
    workdir = (runs_root / ts / "workdirs" / f"{repo}-k{k}-{pipeline}").resolve()
    target = (workdir / rel_path).resolve()
    if not str(target).startswith(str(workdir) + "/") and target != workdir:
        raise ValueError(f"path traversal blocked: {rel_path}")
    if not target.exists() or not target.is_file():
        raise FileNotFoundError(rel_path)
    try:
        size = target.stat().st_size
    except OSError:
        raise FileNotFoundError(rel_path)
    if size > _MAX_INLINE_FILE_BYTES:
        head = target.read_bytes()[:_MAX_INLINE_FILE_BYTES].decode("utf-8", errors="replace")
        return head, True
    try:
        return target.read_text(encoding="utf-8"), False
    except UnicodeDecodeError:
        return target.read_bytes()[:_MAX_INLINE_FILE_BYTES].decode("utf-8", errors="replace"), True
