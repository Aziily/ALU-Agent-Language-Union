"""Tests for benchmarks.harness.runner.

End-to-end with mocks: 1 fake project + MockLLMClient + stub run_tests.
Verifies report files are written and summary numbers compute correctly.
"""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import patch

import pytest

from al.llm import MockLLMClient
from benchmarks.harness.commit0_adapter import ProjectRef, TestResult
from benchmarks.harness.runner import run_pipeline


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


def _make_fake_project(tmp_path: Path, name: str = "fakelib") -> ProjectRef:
    """Build a single-file 'stripped' fake repo under tmp_path."""
    proj_dir = tmp_path / "repos" / name
    proj_dir.mkdir(parents=True)
    (proj_dir / f"{name}.py").write_text(
        "def double(x):\n"
        "    \"\"\"Return x doubled.\"\"\"\n"
        "    pass\n"
    )
    (proj_dir / "README.md").write_text(
        "# fakelib\n\nProvides one function `double(x)` returning x*2.\n"
    )
    return ProjectRef(name=name, path=proj_dir,
                      spec_path=proj_dir / "README.md")


def _make_fake_skeleton(skeletons_dir: Path, name: str = "fakelib") -> None:
    skeletons_dir.mkdir(parents=True, exist_ok=True)
    (skeletons_dir / f"{name}.al").write_text(
        f"code double:\n"
        f"  intent: double the integer input\n"
        f"  body: |\n"
        f"    def double(x):\n"
        f"        pass\n"
    )


def _stub_run_tests(passed: int = 1, failed: int = 0):
    """Build a stub that returns TestResult with given pass/fail counts."""
    def _fn(project, py_dir):
        return TestResult(
            project=project,
            total=passed + failed,
            passed=passed,
            failed=failed,
            duration_sec=0.01,
        )
    return _fn


def _stub_loader(project: ProjectRef):
    """Project loader that always returns the given ProjectRef."""
    def _fn(name, repos_base):
        if name == project.name:
            return project
        raise FileNotFoundError(name)
    return _fn


# ---------------------------------------------------------------------------
# Smoke
# ---------------------------------------------------------------------------


def test_run_pipeline_writes_summary_files(tmp_path):
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")
    llm = MockLLMClient(
        default=(
            # python_implementer expected output
            "# === FILE: fakelib.py ===\n"
            "def double(x):\n"
            "    return x * 2\n"
        ),
    )
    out_dir = run_pipeline(
        llm=llm,
        run_tests_fn=_stub_run_tests(passed=1),
        project_loader_fn=_stub_loader(project),
        n_projects=1,
        k_repeats=2,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    assert (out_dir / "summary.md").exists()
    assert (out_dir / "run.json").exists()
    assert (out_dir / "pass_at_k.json").exists()
    assert (out_dir / "per_repo" / "fakelib.json").exists()
    # raw transcripts written (won't be committed due to .gitignore)
    assert (out_dir / "raw" / "fakelib-k0-baseline.txt").exists()
    assert (out_dir / "raw" / "fakelib-k0-al.txt").exists()


def test_run_pipeline_summary_md_contains_tax_number(tmp_path):
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")
    llm = MockLLMClient(default="# === FILE: fakelib.py ===\ndef double(x):\n    return x*2\n")
    out_dir = run_pipeline(
        llm=llm,
        run_tests_fn=_stub_run_tests(passed=1),
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=2,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    md = (out_dir / "summary.md").read_text()
    assert "往返税" in md
    assert "tax_pp" in md or "pp" in md  # the pp suffix
    assert "fakelib" in md
    assert "Baseline" in md and "agent-lang" in md


def test_run_pipeline_per_repo_json_shape(tmp_path):
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")
    llm = MockLLMClient(default="# === FILE: fakelib.py ===\ndef double(x):\n    return x*2\n")
    out_dir = run_pipeline(
        llm=llm,
        run_tests_fn=_stub_run_tests(),
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=3,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    per = json.loads((out_dir / "per_repo" / "fakelib.json").read_text())
    assert per["project"] == "fakelib"
    assert len(per["baseline"]) == 3
    assert len(per["al"]) == 3
    assert all(r["pipeline"] == "baseline" for r in per["baseline"])
    assert all(r["pipeline"] == "al" for r in per["al"])


def test_run_pipeline_pass_at_k_zero_baseline_failures(tmp_path):
    """All tests pass → pass^k = 1.0 for both pipelines, tax_pp = 0."""
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")
    llm = MockLLMClient(default="# === FILE: fakelib.py ===\ndef double(x):\n    return x*2\n")
    out_dir = run_pipeline(
        llm=llm,
        run_tests_fn=_stub_run_tests(passed=1),
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=3,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    pak = json.loads((out_dir / "pass_at_k.json").read_text())
    assert pak["baseline"]["pass_at_1"] == 1.0
    assert pak["al"]["pass_at_1"] == 1.0
    run = json.loads((out_dir / "run.json").read_text())
    assert run["tax_pp"] == 0.0


def test_run_pipeline_missing_skeleton_records_error(tmp_path):
    project = _make_fake_project(tmp_path)
    # skeletons dir empty (no fakelib.al)
    llm = MockLLMClient(default="anything")
    out_dir = run_pipeline(
        llm=llm,
        run_tests_fn=_stub_run_tests(),
        project_loader_fn=_stub_loader(project),
        project_names=["fakelib"],
        n_projects=1, k_repeats=1,
        skeletons_dir=tmp_path / "missing",
        out_dir=tmp_path / "report",
    )
    run = json.loads((out_dir / "run.json").read_text())
    errors = [r for r in run["results"] if "skeleton missing" in r["error"]]
    assert len(errors) == 1


def test_run_pipeline_missing_project_records_error(tmp_path):
    _make_fake_skeleton(tmp_path / "skeletons")
    llm = MockLLMClient(default="anything")

    def _failing_loader(name, repos_base):
        raise FileNotFoundError(name)

    out_dir = run_pipeline(
        llm=llm,
        run_tests_fn=_stub_run_tests(),
        project_loader_fn=_failing_loader,
        n_projects=1, k_repeats=1,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    run = json.loads((out_dir / "run.json").read_text())
    errors = [r for r in run["results"] if "not setup" in r["error"]]
    assert len(errors) == 1


def test_run_pipeline_token_counting(tmp_path):
    """LLM tokens accumulate across all runs."""
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")

    # MockLLMClient returns 0 tokens; patch the completion to fake some
    def llm_with_tokens(prompt, **kw):
        from al.llm.base import CompletionResult
        return CompletionResult(text="# === FILE: fakelib.py ===\ndef double(x):\n    return x*2\n",
                                prompt_tokens=100, completion_tokens=50, model="mock")

    class FakeLLM:
        def complete(self, prompt, **kw):
            return llm_with_tokens(prompt, **kw)

    out_dir = run_pipeline(
        llm=FakeLLM(),
        run_tests_fn=_stub_run_tests(),
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=2,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    run = json.loads((out_dir / "run.json").read_text())
    # 2 k × 2 pipelines × 150 tokens = 600
    assert run["total_llm_tokens"] == 600
