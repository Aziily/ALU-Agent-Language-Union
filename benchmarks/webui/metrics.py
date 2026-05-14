"""Aggregate metrics for the benchmark WebUI.

The binary "all tests pass per run" metric in summary.md is useless for
our case (most runs have partial pass rates). This module computes
**per-test pass rate** = passing / total per cell, then aggregates
across (repo × k × pipeline).

All functions take plain dicts/lists (not dataclasses) for forward
compatibility with new fields in run.json.
"""

from __future__ import annotations

import statistics
from dataclasses import dataclass


@dataclass
class Stats:
    """Aggregate stats for one pipeline across many cells."""

    mean_pct: float = 0.0
    median_pct: float = 0.0
    std_pct: float = 0.0
    n: int = 0


def per_test_rate(result: dict) -> float:
    """Cell-level per-test pass rate; safe div by zero."""
    total = result.get("test_total", 0)
    if total <= 0:
        return 0.0
    return 100.0 * result.get("test_passing", 0) / total


def aggregate_per_test(results: list[dict], pipeline: str | None = None) -> Stats:
    """Aggregate per-test rates across cells, optionally filtered by pipeline."""
    if pipeline is not None:
        results = [r for r in results if r.get("pipeline") == pipeline]
    rates = [per_test_rate(r) for r in results if r.get("test_total", 0) > 0]
    if not rates:
        return Stats(0.0, 0.0, 0.0, 0)
    return Stats(
        mean_pct=statistics.mean(rates),
        median_pct=statistics.median(rates),
        std_pct=statistics.stdev(rates) if len(rates) > 1 else 0.0,
        n=len(rates),
    )


def tokens_by_pipeline(results: list[dict]) -> dict[str, int]:
    """Sum llm_total_tokens grouped by pipeline."""
    out: dict[str, int] = {}
    for r in results:
        pipe = r.get("pipeline", "?")
        out[pipe] = out.get(pipe, 0) + r.get("llm_total_tokens", 0)
    return out


def error_counts(results: list[dict]) -> dict[str, int]:
    """Count non-empty `error` strings per pipeline."""
    out: dict[str, int] = {}
    for r in results:
        pipe = r.get("pipeline", "?")
        if r.get("error", "").strip():
            out[pipe] = out.get(pipe, 0) + 1
        else:
            out.setdefault(pipe, 0)
    return out


def inject_summary(results: list[dict]) -> dict[str, dict[str, list[int]]]:
    """{repo: {pipeline: [inject_injected per k]}}."""
    out: dict[str, dict[str, list[int]]] = {}
    for r in results:
        proj = r.get("project", "?")
        pipe = r.get("pipeline", "?")
        out.setdefault(proj, {}).setdefault(pipe, []).append(r.get("inject_injected", 0))
    return out


def per_repo_summary(per_repo_data: dict) -> dict[str, dict]:
    """For one project's per_repo.json, compute aggregate per pipeline.

    Returns {"baseline": {...}, "al": {...}} each with:
      total_tests, total_passing, pass_pct, n_errors, tokens, runs
    """
    out: dict[str, dict] = {}
    for pipeline in ("baseline", "al"):
        rs = per_repo_data.get(pipeline, [])
        total_t = sum(r.get("test_total", 0) for r in rs)
        total_p = sum(r.get("test_passing", 0) for r in rs)
        out[pipeline] = {
            "n_runs": len(rs),
            "total_tests": total_t,
            "total_passing": total_p,
            "pass_pct": 100.0 * total_p / total_t if total_t > 0 else 0.0,
            "n_errors": sum(1 for r in rs if r.get("error", "").strip()),
            "tokens": sum(r.get("llm_total_tokens", 0) for r in rs),
        }
    return out


def compare_runs(run_a: dict, run_b: dict) -> dict:
    """Pair two runs by repo; report deltas.

    Aligns on intersection of repos appearing in both run.json's results.
    """
    a_results = run_a.get("results", [])
    b_results = run_b.get("results", [])
    repos_a = {r.get("project") for r in a_results if r.get("k_iter", -1) >= 0}
    repos_b = {r.get("project") for r in b_results if r.get("k_iter", -1) >= 0}
    common = sorted(repos_a & repos_b)

    a_aggr = {p: aggregate_per_test([r for r in a_results if r.get("project") == p and r.get("pipeline") == "baseline"])
              for p in common}
    a_aggr_al = {p: aggregate_per_test([r for r in a_results if r.get("project") == p and r.get("pipeline") == "al"])
                 for p in common}
    b_aggr = {p: aggregate_per_test([r for r in b_results if r.get("project") == p and r.get("pipeline") == "baseline"])
              for p in common}
    b_aggr_al = {p: aggregate_per_test([r for r in b_results if r.get("project") == p and r.get("pipeline") == "al"])
                 for p in common}

    return {
        "common_repos": common,
        "a_only": sorted(repos_a - repos_b),
        "b_only": sorted(repos_b - repos_a),
        "per_repo": {
            p: {
                "baseline_a_pct": a_aggr[p].mean_pct,
                "baseline_b_pct": b_aggr[p].mean_pct,
                "al_a_pct": a_aggr_al[p].mean_pct,
                "al_b_pct": b_aggr_al[p].mean_pct,
                "baseline_delta": b_aggr[p].mean_pct - a_aggr[p].mean_pct,
                "al_delta": b_aggr_al[p].mean_pct - a_aggr_al[p].mean_pct,
            }
            for p in common
        },
    }
