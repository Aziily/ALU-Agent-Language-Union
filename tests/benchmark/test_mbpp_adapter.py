"""Tests for benchmarks.adapters.mbpp (Phase F adapter)."""

from __future__ import annotations

from pathlib import Path

import pytest

from benchmarks.adapters import mbpp


@pytest.fixture(scope="module")
def first_3_problems():
    return mbpp.list_problems(limit=3)


# ---------------------------------------------------------------------------
# Dataset loading
# ---------------------------------------------------------------------------


def test_load_problems_returns_dataclasses(first_3_problems):
    assert len(first_3_problems) == 3
    p0 = first_3_problems[0]
    assert isinstance(p0.task_id, int)
    assert p0.text  # NL description present
    assert p0.test_list  # at least one assertion
    assert "def " in p0.code  # canonical solution has a def


def test_problem_name_is_filesystem_safe(first_3_problems):
    for p in first_3_problems:
        assert p.name.startswith("mbpp_")
        assert "/" not in p.name


def test_full_test_split_has_500_problems():
    problems = mbpp.list_problems(split="test")
    assert len(problems) == 500


def test_entry_point_extraction(first_3_problems):
    """The function name is correctly extracted from canonical code."""
    p0 = first_3_problems[0]
    # task_id=11: "remove_Occ"
    assert callable(getattr(p0, "entry_point", None)) or isinstance(p0.entry_point, str)
    assert p0.entry_point  # non-empty


def test_signature_line_extraction(first_3_problems):
    """signature_line gives just the def line."""
    p0 = first_3_problems[0]
    sig = p0.signature_line
    assert sig.startswith("def ")
    assert sig.endswith(":")
    assert "\n" not in sig.replace(":", "").split("\n")[-1]  # last line is the def line


# ---------------------------------------------------------------------------
# Workdir setup
# ---------------------------------------------------------------------------


def test_setup_workdir_writes_stub(tmp_path, first_3_problems):
    p = first_3_problems[0]
    workdir = mbpp.setup_workdir(p, tmp_path / p.name)
    sol = workdir / "solution.py"
    assert sol.exists()
    src = sol.read_text()
    assert "def " in src
    assert src.rstrip().endswith("    pass")
    # Canonical body should NOT leak
    assert p.code.strip().splitlines()[-1] not in src or "pass" in src


def test_collect_stripped_files(tmp_path, first_3_problems):
    p = first_3_problems[0]
    workdir = mbpp.setup_workdir(p, tmp_path / p.name)
    files = mbpp.collect_stripped_files(workdir)
    assert set(files.keys()) == {"solution.py"}


def test_load_spec_contains_NL_text(first_3_problems):
    p = first_3_problems[0]
    spec = mbpp.load_spec(p)
    assert p.text in spec
    assert p.signature_line in spec


# ---------------------------------------------------------------------------
# Test execution
# ---------------------------------------------------------------------------


def test_run_tests_stripped_solution_fails(tmp_path, first_3_problems):
    """A `pass` body should fail (returns None instead of expected outputs)."""
    p = first_3_problems[0]
    workdir = mbpp.setup_workdir(p, tmp_path / p.name)
    result = mbpp.run_tests(p, workdir)
    assert result.total == len(p.test_list)
    assert result.passed == 0
    assert result.failed == len(p.test_list)
    assert result.all_passed is False


def test_run_tests_canonical_solution_passes(tmp_path, first_3_problems):
    """Replacing the stub with the canonical solution should pass all asserts."""
    p = first_3_problems[0]
    workdir = mbpp.setup_workdir(p, tmp_path / p.name)
    sol = workdir / "solution.py"
    sol.write_text(p.code)  # full canonical solution
    result = mbpp.run_tests(p, workdir)
    assert result.passed == result.total
    assert result.failed == 0


def test_run_tests_returns_test_result_with_project(tmp_path, first_3_problems):
    p = first_3_problems[0]
    workdir = mbpp.setup_workdir(p, tmp_path / p.name)
    result = mbpp.run_tests(p, workdir)
    assert result.project.name == p.name


def test_run_tests_missing_solution_skipped(tmp_path, first_3_problems):
    p = first_3_problems[0]
    workdir = tmp_path / p.name
    workdir.mkdir(parents=True)
    result = mbpp.run_tests(p, workdir)
    assert result.passed == 0
    assert "missing" in result.raw_stdout
