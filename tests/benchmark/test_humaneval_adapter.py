"""Tests for benchmarks.adapters.humaneval (Phase F adapter)."""

from __future__ import annotations

from pathlib import Path

import pytest

from benchmarks.adapters import humaneval


# ---------------------------------------------------------------------------
# Dataset loading
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def first_3_problems():
    return humaneval.list_problems(limit=3)


def test_load_problems_returns_dataclasses(first_3_problems):
    assert len(first_3_problems) == 3
    p0 = first_3_problems[0]
    assert p0.task_id == "HumanEval/0"
    assert p0.entry_point == "has_close_elements"
    assert "def has_close_elements" in p0.prompt
    assert "def check" in p0.test


def test_problem_name_is_filesystem_safe(first_3_problems):
    for p in first_3_problems:
        assert "/" not in p.name
        assert p.name.startswith("humaneval_")


def test_full_dataset_has_164_problems():
    problems = humaneval.list_problems()
    assert len(problems) == 164


# ---------------------------------------------------------------------------
# Workdir setup + stripping
# ---------------------------------------------------------------------------


def test_setup_workdir_writes_stripped_solution(tmp_path, first_3_problems):
    p = first_3_problems[0]
    workdir = humaneval.setup_workdir(p, tmp_path / p.name)
    sol = workdir / "solution.py"
    assert sol.exists()
    src = sol.read_text()
    # Prompt is preserved (function signature + docstring)
    assert "def has_close_elements" in src
    # Body is `pass` (stripped)
    assert src.rstrip().endswith("    pass")
    # No canonical solution leaked
    assert "abs(numbers[i] - numbers[j])" not in src


def test_collect_stripped_files(tmp_path, first_3_problems):
    p = first_3_problems[0]
    workdir = humaneval.setup_workdir(p, tmp_path / p.name)
    files = humaneval.collect_stripped_files(workdir)
    assert set(files.keys()) == {"solution.py"}
    assert "def has_close_elements" in files["solution.py"]


def test_load_spec_returns_prompt(first_3_problems):
    p = first_3_problems[0]
    spec = humaneval.load_spec(p)
    assert spec == p.prompt
    assert "Check if in given list of numbers" in spec


# ---------------------------------------------------------------------------
# Test execution
# ---------------------------------------------------------------------------


def test_run_tests_stripped_solution_fails(tmp_path, first_3_problems):
    """A workdir with only `pass` as body should FAIL the test."""
    p = first_3_problems[0]
    workdir = humaneval.setup_workdir(p, tmp_path / p.name)
    result = humaneval.run_tests(p, workdir)
    assert result.total == 1
    assert result.passed == 0
    assert result.failed == 1
    assert result.all_passed is False


def test_run_tests_canonical_solution_passes(tmp_path, first_3_problems):
    """Replacing the body with the canonical solution should PASS the test."""
    p = first_3_problems[0]
    workdir = humaneval.setup_workdir(p, tmp_path / p.name)
    sol = workdir / "solution.py"
    # Replace `pass` with the canonical solution.
    canonical = p.prompt
    if not canonical.endswith("\n"):
        canonical += "\n"
    canonical += p.canonical_solution
    sol.write_text(canonical)
    result = humaneval.run_tests(p, workdir)
    assert result.total == 1
    assert result.passed == 1
    assert result.failed == 0
    assert result.all_passed is True


def test_run_tests_timeout(tmp_path, first_3_problems):
    """A solution that hangs should time out cleanly (not crash the harness)."""
    p = first_3_problems[0]
    workdir = humaneval.setup_workdir(p, tmp_path / p.name)
    sol = workdir / "solution.py"
    # Replace body with infinite loop.
    hung = p.prompt
    if not hung.endswith("\n"):
        hung += "\n"
    hung += "    while True:\n        pass\n"
    sol.write_text(hung)
    # Use a very short timeout.
    result = humaneval.run_tests(p, workdir, timeout=2)
    assert result.passed == 0
    assert result.failed == 1
    # Adapter records the reason
    assert "timeout" in result.raw_stdout.lower()


def test_run_tests_missing_solution_skipped(tmp_path, first_3_problems):
    """If solution.py doesn't exist, return a failure result, don't crash."""
    p = first_3_problems[0]
    workdir = tmp_path / p.name
    workdir.mkdir(parents=True)
    result = humaneval.run_tests(p, workdir)
    assert result.passed == 0
    assert "solution.py missing" in result.raw_stdout


def test_run_tests_returns_test_result_with_project_attr(tmp_path, first_3_problems):
    """run_tests returns a TestResult — verify the .project attr is set so
    runner.run_pipeline can slot it into its bookkeeping."""
    p = first_3_problems[0]
    workdir = humaneval.setup_workdir(p, tmp_path / p.name)
    result = humaneval.run_tests(p, workdir)
    assert result.project.name == p.name
    assert result.project.path == workdir
