"""Tests for benchmarks.webui.metrics."""

from __future__ import annotations

import pytest

from benchmarks.webui.metrics import (
    Stats,
    aggregate_per_test,
    compare_runs,
    error_counts,
    inject_summary,
    per_repo_summary,
    per_test_rate,
    tokens_by_pipeline,
)


# ---------------------------------------------------------------------------
# per_test_rate
# ---------------------------------------------------------------------------


def test_per_test_rate_normal():
    assert per_test_rate({"test_total": 10, "test_passing": 7}) == 70.0


def test_per_test_rate_zero_total_safe():
    assert per_test_rate({"test_total": 0, "test_passing": 0}) == 0.0
    assert per_test_rate({}) == 0.0


def test_per_test_rate_full():
    assert per_test_rate({"test_total": 5, "test_passing": 5}) == 100.0


# ---------------------------------------------------------------------------
# aggregate_per_test
# ---------------------------------------------------------------------------


def test_aggregate_per_test_empty():
    s = aggregate_per_test([])
    assert s == Stats(0.0, 0.0, 0.0, 0)


def test_aggregate_per_test_with_pipeline_filter():
    results = [
        {"pipeline": "baseline", "test_total": 10, "test_passing": 8},
        {"pipeline": "baseline", "test_total": 10, "test_passing": 6},
        {"pipeline": "al", "test_total": 10, "test_passing": 9},
    ]
    s = aggregate_per_test(results, "baseline")
    assert s.n == 2
    assert s.mean_pct == 70.0


def test_aggregate_per_test_skips_zero_total():
    """test_total=0 cells (e.g. install failed) excluded from aggregate."""
    results = [
        {"pipeline": "baseline", "test_total": 10, "test_passing": 8},
        {"pipeline": "baseline", "test_total": 0, "test_passing": 0},
    ]
    s = aggregate_per_test(results)
    assert s.n == 1  # only the first counted
    assert s.mean_pct == 80.0


# ---------------------------------------------------------------------------
# tokens_by_pipeline / error_counts
# ---------------------------------------------------------------------------


def test_tokens_by_pipeline():
    results = [
        {"pipeline": "baseline", "llm_total_tokens": 100},
        {"pipeline": "baseline", "llm_total_tokens": 200},
        {"pipeline": "al", "llm_total_tokens": 50},
    ]
    assert tokens_by_pipeline(results) == {"baseline": 300, "al": 50}


def test_error_counts():
    results = [
        {"pipeline": "baseline", "error": "syntax err"},
        {"pipeline": "baseline", "error": ""},
        {"pipeline": "al", "error": "lex err"},
        {"pipeline": "al", "error": ""},
    ]
    assert error_counts(results) == {"baseline": 1, "al": 1}


# ---------------------------------------------------------------------------
# inject_summary / per_repo_summary
# ---------------------------------------------------------------------------


def test_inject_summary():
    results = [
        {"project": "a", "pipeline": "baseline", "inject_injected": 2},
        {"project": "a", "pipeline": "baseline", "inject_injected": 3},
        {"project": "a", "pipeline": "al", "inject_injected": 10},
    ]
    s = inject_summary(results)
    assert s["a"]["baseline"] == [2, 3]
    assert s["a"]["al"] == [10]


def test_per_repo_summary():
    pr = {
        "project": "x",
        "baseline": [
            {"test_total": 10, "test_passing": 8, "llm_total_tokens": 100, "error": ""},
            {"test_total": 10, "test_passing": 7, "llm_total_tokens": 100, "error": "x"},
        ],
        "al": [
            {"test_total": 10, "test_passing": 9, "llm_total_tokens": 50, "error": ""},
        ],
    }
    s = per_repo_summary(pr)
    assert s["baseline"]["n_runs"] == 2
    assert s["baseline"]["total_tests"] == 20
    assert s["baseline"]["total_passing"] == 15
    assert s["baseline"]["pass_pct"] == 75.0
    assert s["baseline"]["n_errors"] == 1
    assert s["baseline"]["tokens"] == 200
    assert s["al"]["pass_pct"] == 90.0


# ---------------------------------------------------------------------------
# compare_runs
# ---------------------------------------------------------------------------


def test_compare_runs_intersection():
    run_a = {"results": [
        {"project": "p1", "pipeline": "baseline", "k_iter": 0, "test_total": 10, "test_passing": 5},
        {"project": "p1", "pipeline": "al", "k_iter": 0, "test_total": 10, "test_passing": 7},
        {"project": "p2", "pipeline": "baseline", "k_iter": 0, "test_total": 10, "test_passing": 8},
    ]}
    run_b = {"results": [
        {"project": "p1", "pipeline": "baseline", "k_iter": 0, "test_total": 10, "test_passing": 8},
        {"project": "p1", "pipeline": "al", "k_iter": 0, "test_total": 10, "test_passing": 9},
        {"project": "p3", "pipeline": "baseline", "k_iter": 0, "test_total": 10, "test_passing": 6},
    ]}
    c = compare_runs(run_a, run_b)
    assert c["common_repos"] == ["p1"]
    assert c["a_only"] == ["p2"]
    assert c["b_only"] == ["p3"]
    p1 = c["per_repo"]["p1"]
    assert p1["baseline_a_pct"] == 50.0
    assert p1["baseline_b_pct"] == 80.0
    assert p1["baseline_delta"] == 30.0
