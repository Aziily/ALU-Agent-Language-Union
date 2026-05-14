"""Tests for benchmarks.harness.commit0_adapter.

覆盖：
- 纯逻辑：split enumeration, default paths, spec PDF lookup, pytest output parse
- 数据 dataclass：ProjectRef.src_files / test_count, SkeletonRepo.from_project,
  TestResult.all_passed
- subprocess shim：commit0_available（要求 commit0 装好）

带 @pytest.mark.slow 的 integration tests 走真 commit0 setup（用最小 split），
缺省 ``pytest -m "not slow"`` 跳过。
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from unittest.mock import patch

import pytest

from benchmarks.harness.commit0_adapter import (
    AGGREGATE_SPLITS,
    PER_REPO_PYTEST_ARGS,
    ProjectRef,
    SINGLE_REPO_SPLITS,
    SkeletonRepo,
    TestResult,
    _default_repos_dir,
    _find_spec_pdf,
    _parse_pytest_output,
    commit0_available,
    commit0_root,
    list_projects,
    run_tests,
)


# ---------------------------------------------------------------------------
# SINGLE_REPO_SPLITS / AGGREGATE_SPLITS
# ---------------------------------------------------------------------------


def test_single_repo_splits_count():
    """commit0 CLI lists 56 single-repo splits (sep 2024 snapshot)."""
    assert len(SINGLE_REPO_SPLITS) == 56
    assert "wcwidth" in SINGLE_REPO_SPLITS
    assert "simpy" in SINGLE_REPO_SPLITS
    assert "tinydb" in SINGLE_REPO_SPLITS


def test_aggregate_splits():
    assert "all" in AGGREGATE_SPLITS
    assert "lite" in AGGREGATE_SPLITS


def test_no_duplicate_splits():
    """No name should appear twice in SINGLE_REPO_SPLITS."""
    assert len(set(SINGLE_REPO_SPLITS)) == len(SINGLE_REPO_SPLITS)


# ---------------------------------------------------------------------------
# Path helpers
# ---------------------------------------------------------------------------


def test_commit0_root_points_to_submodule():
    root = commit0_root()
    assert root.name == "commit0"
    assert root.parent.name == "thirdparty"


def test_default_repos_dir_is_sister_to_submodule():
    repos = _default_repos_dir()
    assert repos.name == "commit0_repos"
    assert repos.parent.name == "thirdparty"


# ---------------------------------------------------------------------------
# list_projects
# ---------------------------------------------------------------------------


def test_list_projects_returns_all_splits(tmp_path):
    """list_projects() yields a ProjectRef per SINGLE_REPO_SPLITS entry."""
    projects = list(list_projects(base_dir=tmp_path))
    assert len(projects) == len(SINGLE_REPO_SPLITS)
    names = {p.name for p in projects}
    assert names == set(SINGLE_REPO_SPLITS)


def test_list_projects_path_under_base_dir(tmp_path):
    projects = list(list_projects(base_dir=tmp_path))
    for p in projects:
        assert p.path.parent == tmp_path


def test_list_projects_creates_base_dir(tmp_path):
    target = tmp_path / "nested" / "repos"
    assert not target.exists()
    list(list_projects(base_dir=target))
    assert target.exists()


# ---------------------------------------------------------------------------
# _find_spec_pdf
# ---------------------------------------------------------------------------


def test_find_spec_pdf_prefers_pdf(tmp_path):
    (tmp_path / "spec.pdf").write_bytes(b"%PDF-1.4")
    (tmp_path / "README.md").write_text("# repo")
    out = _find_spec_pdf(tmp_path)
    assert out is not None
    assert out.suffix == ".pdf"


def test_find_spec_pdf_falls_back_to_readme(tmp_path):
    (tmp_path / "README.md").write_text("# repo")
    out = _find_spec_pdf(tmp_path)
    assert out is not None
    assert out.name == "README.md"


def test_find_spec_pdf_none_when_empty(tmp_path):
    assert _find_spec_pdf(tmp_path) is None


def test_find_spec_pdf_nonexistent_dir():
    assert _find_spec_pdf(Path("/nonexistent/path/123")) is None


# ---------------------------------------------------------------------------
# ProjectRef
# ---------------------------------------------------------------------------


def test_project_ref_src_files_empty_when_not_setup():
    p = ProjectRef(name="x", path=Path("/nonexistent"))
    assert p.src_files == []


def test_project_ref_src_files_excludes_tests(tmp_path):
    (tmp_path / "pkg").mkdir()
    (tmp_path / "pkg" / "__init__.py").write_text("")
    (tmp_path / "pkg" / "main.py").write_text("def f(): pass")
    (tmp_path / "tests").mkdir()
    (tmp_path / "tests" / "test_main.py").write_text("def test_f(): pass")
    p = ProjectRef(name="x", path=tmp_path)
    files = p.src_files
    names = [f.name for f in files]
    assert "main.py" in names
    assert "test_main.py" not in names


def test_project_ref_test_count(tmp_path):
    (tmp_path / "tests").mkdir()
    (tmp_path / "tests" / "test_a.py").write_text(
        "def test_one(): pass\n"
        "def test_two():\n    pass\n"
        "def helper(): pass\n"
    )
    p = ProjectRef(name="x", path=tmp_path)
    assert p.test_count == 2


# ---------------------------------------------------------------------------
# SkeletonRepo.from_project
# ---------------------------------------------------------------------------


def test_skeleton_repo_from_project(tmp_path):
    (tmp_path / "main.py").write_text("def f(): raise NotImplementedError")
    (tmp_path / "spec.pdf").write_bytes(b"%PDF-1.4 fake")
    p = ProjectRef(name="x", path=tmp_path, spec_path=tmp_path / "spec.pdf")
    skel = SkeletonRepo.from_project(p, tmp_path)
    assert skel.project is p
    assert skel.workdir == tmp_path
    assert "%PDF" in skel.spec_text
    assert any(f.name == "main.py" for f in skel.python_files)


# ---------------------------------------------------------------------------
# TestResult.all_passed
# ---------------------------------------------------------------------------


def test_test_result_all_passed_true():
    r = TestResult(project=ProjectRef("x", Path(".")), total=3, passed=3)
    assert r.all_passed


def test_test_result_all_passed_false_when_failed():
    r = TestResult(project=ProjectRef("x", Path(".")), total=3, passed=2, failed=1)
    assert not r.all_passed


def test_test_result_all_passed_false_when_no_tests():
    r = TestResult(project=ProjectRef("x", Path(".")), total=0)
    assert not r.all_passed


# ---------------------------------------------------------------------------
# _parse_pytest_output
# ---------------------------------------------------------------------------


def _fake_cp(stdout: str, returncode: int = 0, stderr: str = "") -> subprocess.CompletedProcess:
    return subprocess.CompletedProcess(
        args=["commit0", "test"],
        returncode=returncode,
        stdout=stdout,
        stderr=stderr,
    )


def test_parse_pytest_all_pass():
    out = "...\n==================== 5 passed in 0.34s ====================\n"
    r = _parse_pytest_output(ProjectRef("x", Path(".")), _fake_cp(out))
    assert r.total == 5
    assert r.passed == 5
    assert r.failed == 0
    assert r.duration_sec == pytest.approx(0.34)
    assert r.all_passed


def test_parse_pytest_mixed():
    out = "...\n==== 3 passed, 1 failed, 1 skipped in 1.20s ====\n"
    r = _parse_pytest_output(ProjectRef("x", Path(".")), _fake_cp(out, returncode=1))
    assert r.passed == 3
    assert r.failed == 1
    assert r.skipped == 1
    assert r.total == 5
    assert not r.all_passed


def test_parse_pytest_captures_failures():
    out = (
        "FAILED tests/foo.py::test_bar - AssertionError: ...\n"
        "FAILED tests/foo.py::test_baz - ValueError\n"
        "==== 1 passed, 2 failed in 0.50s ====\n"
    )
    r = _parse_pytest_output(ProjectRef("x", Path(".")), _fake_cp(out, returncode=1))
    assert len(r.failures) == 2
    assert "test_bar" in r.failures[0]


def test_parse_pytest_no_summary_falls_back_to_exit_code():
    """When pytest output is unparseable, still record raw output + exit code."""
    out = "garbled output without summary"
    r = _parse_pytest_output(ProjectRef("x", Path(".")), _fake_cp(out, returncode=2))
    assert r.total == 0   # couldn't parse
    assert r.exit_code == 2
    assert r.raw_stdout == out
    assert not r.all_passed


# ---------------------------------------------------------------------------
# run_tests pytest invocation shape
# ---------------------------------------------------------------------------


def test_run_tests_invokes_bare_pytest_for_default_repos(tmp_path):
    """Phase 1.H'.F.2: runner must use bare `pytest` (no path arg) so each
    repo's pytest config (pyproject/setup.cfg) drives test discovery.

    Hardcoding ``pytest tests/`` silently dropped data for repos like
    voluptuous (tests in voluptuous/tests/), portalocker (portalocker_tests/),
    and chardet (test.py at root via setup.cfg python_files=test.py).
    """
    target = tmp_path / "fake_repo"
    target.mkdir()
    captured = []

    def fake_run(cmd, **kwargs):
        captured.append(cmd)
        return subprocess.CompletedProcess(
            args=cmd, returncode=0, stdout="==== 1 passed in 0.01s ====\n", stderr="",
        )

    with patch("subprocess.run", side_effect=fake_run):
        run_tests(ProjectRef("cachetools", target), target)

    # cmd[0] = pip install, cmd[1] = pytest. Verify pytest has NO "tests/" arg.
    assert len(captured) == 2
    pytest_cmd = captured[1]
    assert pytest_cmd[0] == "pytest"
    assert "tests/" not in pytest_cmd
    assert "tests" not in pytest_cmd  # also no bare "tests"


def test_run_tests_applies_per_repo_pytest_args(tmp_path):
    """parsel needs `--assert=plain --ignore=setup.py` per commit0 dataset."""
    target = tmp_path / "fake_parsel"
    target.mkdir()
    captured = []

    def fake_run(cmd, **kwargs):
        captured.append(cmd)
        return subprocess.CompletedProcess(
            args=cmd, returncode=0, stdout="==== 0 passed in 0.01s ====\n", stderr="",
        )

    with patch("subprocess.run", side_effect=fake_run):
        run_tests(ProjectRef("parsel", target), target)

    pytest_cmd = captured[1]
    assert "--assert=plain" in pytest_cmd
    assert "--ignore=setup.py" in pytest_cmd


def test_per_repo_pytest_args_registry_well_formed():
    """The registry must map repo-names → list[str] (subprocess-safe)."""
    for repo, args in PER_REPO_PYTEST_ARGS.items():
        assert isinstance(repo, str) and repo, repo
        assert isinstance(args, list), repo
        assert all(isinstance(a, str) for a in args), repo


# ---------------------------------------------------------------------------
# commit0_available (lightweight subprocess shim test)
# ---------------------------------------------------------------------------


def test_commit0_available_when_installed():
    """commit0 has been pip-installed in Phase 1.A, so this returns True."""
    assert commit0_available() is True


def test_commit0_available_when_missing():
    """Simulate commit0 not installed → return False (no crash)."""
    with patch("benchmarks.harness.commit0_adapter._run_commit0",
               side_effect=FileNotFoundError):
        assert commit0_available() is False


# ---------------------------------------------------------------------------
# Integration tests — real commit0 setup. opt-in via -m slow.
# ---------------------------------------------------------------------------


@pytest.mark.slow
def test_setup_split_wcwidth_smoke(tmp_path):
    """End-to-end: setup wcwidth (small lib) and verify directory shape."""
    from benchmarks.harness.commit0_adapter import setup_split

    base = setup_split("wcwidth", base_dir=tmp_path)
    assert base.exists()
    assert (base / "wcwidth").exists() or any(base.iterdir()), \
        f"setup_split didn't materialize anything under {base}"
