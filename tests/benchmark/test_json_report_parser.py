"""Tests for Phase 1.H'.F.2 pytest-json-report parsing path.

These cover the structured-first parser in
``benchmarks/harness/commit0_adapter.py::_parse_pytest_json_report``,
plus the fallback orchestration in ``_parse_pytest_result``.

Why we need this: the legacy regex-on-stdout parser drops xfail/xpass
information and gets confused by collection errors. pytest-json-report
gives us a JSON object with per-test outcomes that we can count
exactly the way commit0 does in ``commit0/harness/evaluate.py``.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

import pytest

from benchmarks.harness.commit0_adapter import (
    ProjectRef,
    TestResult,
    _parse_pytest_json_report,
    _parse_pytest_result,
)


def _fake_cp(stdout="", stderr="", returncode=0) -> subprocess.CompletedProcess:
    return subprocess.CompletedProcess(
        args=["pytest"], returncode=returncode, stdout=stdout, stderr=stderr,
    )


# ---------------------------------------------------------------------------
# _parse_pytest_json_report — happy paths
# ---------------------------------------------------------------------------


def test_json_report_basic_pass_fail_counts():
    """Standard summary: passed + failed + skipped."""
    data = {
        "duration": 1.5,
        "exitcode": 1,
        "summary": {"passed": 7, "failed": 3, "skipped": 1, "total": 11},
        "tests": [],
    }
    r = _parse_pytest_json_report(ProjectRef("x", Path(".")), _fake_cp(returncode=1), data)
    assert r.passed == 7
    assert r.failed == 3
    assert r.skipped == 1
    assert r.total == 11
    assert r.duration_sec == 1.5
    assert r.json_report_ok is True


def test_json_report_xfail_counted_in_passed_with_xfail():
    """commit0 counts xfail as success — verify ``passed_with_xfail`` field."""
    data = {
        "summary": {"passed": 10, "failed": 2, "xfailed": 3, "total": 15},
        "tests": [],
    }
    r = _parse_pytest_json_report(ProjectRef("x", Path(".")), _fake_cp(), data)
    assert r.passed == 10
    assert r.xfailed == 3
    assert r.passed_with_xfail == 13   # 10 + 3
    assert r.failed == 2


def test_json_report_xpassed_recorded_separately():
    """xpassed = test marked xfail but unexpectedly passed. Not added to
    ``passed_with_xfail`` (commit0 ignores it)."""
    data = {
        "summary": {"passed": 5, "xpassed": 2, "total": 7},
        "tests": [],
    }
    r = _parse_pytest_json_report(ProjectRef("x", Path(".")), _fake_cp(), data)
    assert r.xpassed == 2
    assert r.passed_with_xfail == 5  # only passed + xfailed (xfailed=0)


def test_json_report_collection_errors_from_collectors():
    """Failed collector outcomes → ``collection_errors`` count."""
    data = {
        "summary": {"passed": 0, "total": 0},
        "tests": [],
        "collectors": [
            {"nodeid": "test_foo.py", "outcome": "passed"},
            {"nodeid": "test_bar.py", "outcome": "failed", "longrepr": "ImportError"},
            {"nodeid": "test_baz.py", "outcome": "failed", "longrepr": "syntax err"},
        ],
    }
    r = _parse_pytest_json_report(ProjectRef("x", Path(".")), _fake_cp(returncode=2), data)
    assert r.collection_errors == 2


def test_json_report_failures_list_captured():
    """Per-test failure node-ids are recorded for debugging."""
    data = {
        "summary": {"passed": 1, "failed": 2, "total": 3},
        "tests": [
            {"nodeid": "test_foo.py::test_pass", "outcome": "passed"},
            {"nodeid": "test_foo.py::test_a", "outcome": "failed"},
            {"nodeid": "test_foo.py::test_b", "outcome": "failed"},
        ],
    }
    r = _parse_pytest_json_report(ProjectRef("x", Path(".")), _fake_cp(returncode=1), data)
    assert r.failures == ["test_foo.py::test_a", "test_foo.py::test_b"]


def test_json_report_failure_list_truncated_at_50():
    """Don't blow up memory on a 10k-failure run."""
    tests = [
        {"nodeid": f"test_x.py::test_{i}", "outcome": "failed"}
        for i in range(200)
    ]
    data = {"summary": {"failed": 200, "total": 200}, "tests": tests}
    r = _parse_pytest_json_report(ProjectRef("x", Path(".")), _fake_cp(returncode=1), data)
    assert len(r.failures) == 50


def test_json_report_zero_tests_collected():
    """Empty test run is still a valid parse, not an error."""
    data = {"summary": {"total": 0}, "tests": []}
    r = _parse_pytest_json_report(ProjectRef("x", Path(".")), _fake_cp(), data)
    assert r.total == 0
    assert r.passed == 0
    assert r.json_report_ok is True
    assert r.all_passed is False  # all_passed requires total > 0


# ---------------------------------------------------------------------------
# _parse_pytest_result — JSON-first, regex fallback
# ---------------------------------------------------------------------------


def test_parse_uses_json_when_report_file_exists(tmp_path):
    """If .pytest-report.json is on disk, use it (ignore regex)."""
    report = {
        "summary": {"passed": 42, "failed": 0, "total": 42},
        "tests": [],
    }
    fp = tmp_path / ".pytest-report.json"
    fp.write_text(json.dumps(report))
    # stdout deliberately says "5 passed" — should be IGNORED since json-report
    # is preferred.
    cp = _fake_cp(stdout="==== 5 passed in 0.1s ====\n")
    r = _parse_pytest_result(ProjectRef("x", tmp_path), cp, fp)
    assert r.passed == 42  # from json, not from stdout regex
    assert r.json_report_ok is True


def test_parse_falls_back_to_regex_when_no_json_file(tmp_path):
    """No report.json → use the legacy parser."""
    fp = tmp_path / ".pytest-report.json"  # doesn't exist
    cp = _fake_cp(stdout="==== 5 passed in 0.1s ====\n")
    r = _parse_pytest_result(ProjectRef("x", tmp_path), cp, fp)
    assert r.passed == 5
    assert r.json_report_ok is False  # fallback path


def test_parse_falls_back_when_json_corrupted(tmp_path):
    """Corrupted JSON → don't crash, use regex."""
    fp = tmp_path / ".pytest-report.json"
    fp.write_text("not valid json{{{")
    cp = _fake_cp(stdout="==== 3 passed, 1 failed in 0.1s ====\n", returncode=1)
    r = _parse_pytest_result(ProjectRef("x", tmp_path), cp, fp)
    assert r.passed == 3
    assert r.failed == 1
    assert r.json_report_ok is False


def test_passed_with_xfail_default_equals_passed():
    """For legacy regex-parse results without xfail info,
    passed_with_xfail == passed."""
    t = TestResult(project=ProjectRef("x", Path(".")), passed=7, xfailed=0)
    assert t.passed_with_xfail == 7
