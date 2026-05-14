"""Phase 1.H'.F.2 — tests for the runner's per-cell multi-iteration loop.

Covers ``_run_baseline_cell`` and ``_run_al_cell``:
- Iter loop breaks early when test passes on iter 0
- Iter loop runs up to MAX_ITERATIONS when test keeps failing
- ``previous_filled`` + ``previous_test_output`` are forwarded to next iter
- ``iter_outcomes`` records every iter, in order
- ``final_iter_idx`` reflects which iter passed (-1 if never passed)
- LLM failure mid-loop is caught + recorded as a failed iter, loop breaks
"""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import patch

import pytest

from al.llm import MockLLMClient
from al.llm.base import CompletionResult
from benchmarks.harness.commit0_adapter import ProjectRef, TestResult
from benchmarks.harness.runner import MAX_ITERATIONS, run_pipeline


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


def _make_fake_project(tmp_path: Path, name: str = "fakelib") -> ProjectRef:
    proj_dir = tmp_path / "repos" / name
    proj_dir.mkdir(parents=True)
    (proj_dir / f"{name}.py").write_text(
        "def double(x):\n"
        "    \"\"\"Return x doubled.\"\"\"\n"
        "    pass\n"
    )
    (proj_dir / "README.md").write_text("# fakelib\n")
    return ProjectRef(name=name, path=proj_dir,
                      spec_path=proj_dir / "README.md")


def _make_fake_skeleton(skeletons_dir: Path, name: str = "fakelib") -> None:
    skeletons_dir.mkdir(parents=True, exist_ok=True)
    (skeletons_dir / f"{name}.al").write_text(
        "flow fakelib_lib:\n"
        "  steps:\n"
        "    - double\n"
        "\n\n"
        "code double:\n"
        "  body: |\n"
        "    def double(x):\n"
        "        pass\n"
    )


def _stub_loader(project: ProjectRef):
    def _fn(name, repos_base):
        if name == project.name:
            return project
        raise FileNotFoundError(name)
    return _fn


def _passing_test_fn(project, py_dir):
    return TestResult(project=project, total=1, passed=1, duration_sec=0.01)


def _failing_test_fn(project, py_dir):
    return TestResult(
        project=project, total=1, passed=0, failed=1,
        raw_stdout="==== 0 passed, 1 failed in 0.1s ====\nFAILED test_x::test_x",
        duration_sec=0.01,
    )


def _llm_canned(text: str):
    """Build an LLM that always returns the same text — for both BL and AL."""
    return MockLLMClient(default=text)


def _bl_canned():
    return _llm_canned(
        "# === FILE: fakelib.py ===\n"
        "def double(x):\n"
        "    return x * 2\n"
    )


# ---------------------------------------------------------------------------
# Iter loop short-circuits when test passes
# ---------------------------------------------------------------------------


def test_iter_loop_stops_after_iter0_when_test_passes(tmp_path):
    """All-pass test_fn → iter loop should break after iter 0."""
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")
    out_dir = run_pipeline(
        llm=_bl_canned(),
        run_tests_fn=_passing_test_fn,
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=1,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    per = json.loads((out_dir / "per_repo" / "fakelib.json").read_text())
    bl = per["baseline"][0]
    assert bl["n_iterations"] == 1
    assert bl["final_iter_idx"] == 0
    assert len(bl["iter_outcomes"]) == 1
    assert bl["iter_outcomes"][0]["iter"] == 0
    assert bl["test_passed"] is True


def test_iter_loop_runs_max_iters_when_test_keeps_failing(tmp_path):
    """Failing test_fn → iter loop should use the full MAX_ITERATIONS budget."""
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")
    out_dir = run_pipeline(
        llm=_bl_canned(),
        run_tests_fn=_failing_test_fn,
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=1,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    per = json.loads((out_dir / "per_repo" / "fakelib.json").read_text())
    bl = per["baseline"][0]
    assert bl["n_iterations"] == MAX_ITERATIONS
    assert bl["final_iter_idx"] == -1  # never passed
    assert len(bl["iter_outcomes"]) == MAX_ITERATIONS
    assert all(o["iter"] == i for i, o in enumerate(bl["iter_outcomes"]))
    assert bl["test_passed"] is False


def test_iter_outcomes_records_per_iter_metrics(tmp_path):
    """Each iter outcome has tokens, test counts, json_report_ok, etc."""
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")
    out_dir = run_pipeline(
        llm=_bl_canned(),
        run_tests_fn=_failing_test_fn,
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=1,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    per = json.loads((out_dir / "per_repo" / "fakelib.json").read_text())
    bl = per["baseline"][0]
    for o in bl["iter_outcomes"]:
        # Required keys
        for key in ("iter", "test_passing", "test_passing_with_xfail",
                    "test_total", "tokens", "implementer_ok",
                    "inject_injected", "inject_skipped", "duration_sec",
                    "json_report_ok"):
            assert key in o, f"missing key {key} in iter_outcome {o}"
        # Counts match the stub
        assert o["test_total"] == 1
        assert o["test_passing"] == 0
        assert o["implementer_ok"] is True  # canned output parses


# ---------------------------------------------------------------------------
# Feedback forwarding (BL)
# ---------------------------------------------------------------------------


def test_iter1_prompt_receives_previous_test_output_baseline(tmp_path):
    """Iter 1's prompt for the BL pipeline contains the iter-0 test output."""
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")

    prompts_seen: list[str] = []

    def grab(prompt, **kw):
        prompts_seen.append(prompt)
        return CompletionResult(
            text=("# === FILE: fakelib.py ===\n"
                  "def double(x):\n    return x * 2\n"),
            prompt_tokens=100, completion_tokens=10, model="mock",
        )

    class FakeLLM:
        def complete(self, prompt, **kw):
            return grab(prompt, **kw)

    run_pipeline(
        llm=FakeLLM(),
        run_tests_fn=_failing_test_fn,  # ← drives the loop to iter 1+
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=1,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    # 2 pipelines × MAX_ITERATIONS = 6 LLM calls total
    assert len(prompts_seen) == 2 * MAX_ITERATIONS

    # Prompts for baseline are the first 3 (runner calls BL before AL each k).
    bl_iter0, bl_iter1, bl_iter2 = prompts_seen[:3]
    assert "Previous attempt" not in bl_iter0  # iter 0 has no feedback
    assert "Previous attempt (iter 0)" in bl_iter1
    assert "FAILED test_x::test_x" in bl_iter1  # last test output
    assert "Previous attempt (iter 1)" in bl_iter2


def test_iter1_prompt_receives_previous_test_output_al(tmp_path):
    """Iter 1's prompt for the AL pipeline contains the iter-0 test output."""
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")

    prompts_seen: list[str] = []

    def grab(prompt, **kw):
        prompts_seen.append(prompt)
        return CompletionResult(
            text=(
                # Echo back the skeleton with a body (AL output, parseable).
                "flow fakelib_lib:\n"
                "  steps:\n"
                "    - double\n"
                "\n\n"
                "code double:\n"
                "  body: |\n"
                "    def double(x):\n"
                "        return x * 2\n"
            ),
            prompt_tokens=100, completion_tokens=10, model="mock",
        )

    class FakeLLM:
        def complete(self, prompt, **kw):
            return grab(prompt, **kw)

    run_pipeline(
        llm=FakeLLM(),
        run_tests_fn=_failing_test_fn,
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=1,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    assert len(prompts_seen) == 2 * MAX_ITERATIONS

    # AL prompts come 2nd half (after BL); iters 0,1,2.
    al_iter0, al_iter1, al_iter2 = prompts_seen[3:6]
    assert "Previous attempt" not in al_iter0
    assert "Previous attempt (iter 0)" in al_iter1
    assert "FAILED test_x::test_x" in al_iter1
    assert "Previous attempt (iter 1)" in al_iter2


# ---------------------------------------------------------------------------
# LLM failure mid-loop is captured
# ---------------------------------------------------------------------------


def test_llm_failure_in_iter1_records_and_breaks(tmp_path):
    """If LLM raises on iter 1, the loop records and stops (no iter 2)."""
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")

    call_count = {"n": 0}

    def grab(prompt, **kw):
        call_count["n"] += 1
        # Fail on the 2nd call (= iter 1 of baseline)
        if call_count["n"] == 2:
            raise RuntimeError("simulated 503")
        return CompletionResult(
            text=("# === FILE: fakelib.py ===\n"
                  "def double(x):\n    return x * 2\n"),
            prompt_tokens=100, completion_tokens=10, model="mock",
        )

    class FakeLLM:
        def complete(self, prompt, **kw):
            return grab(prompt, **kw)

    out_dir = run_pipeline(
        llm=FakeLLM(),
        run_tests_fn=_failing_test_fn,
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=1,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    per = json.loads((out_dir / "per_repo" / "fakelib.json").read_text())
    bl = per["baseline"][0]
    # iter 0 succeeded at LLM but test failed; iter 1 LLM raised → break.
    assert bl["n_iterations"] == 2
    assert "simulated 503" in bl["iter_outcomes"][1]["error"]
    # AL should still run all 3 iters because its LLM didn't fail (call #4-6 OK).
    al = per["al"][0]
    assert al["n_iterations"] == MAX_ITERATIONS


# ---------------------------------------------------------------------------
# (passed + xfail) numerator carries through
# ---------------------------------------------------------------------------


def test_passing_with_xfail_propagates_to_cell(tmp_path):
    """When a TestResult reports xfail, it should bump
    test_passing_with_xfail in PipelineRunResult."""
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")

    def with_xfail(project, py_dir):
        # 1 passed, 2 xfailed → passed_with_xfail = 3, all_passed = True
        # (because failed=0 and errored=0).
        return TestResult(
            project=project, total=3, passed=1, xfailed=2,
            duration_sec=0.02,
        )

    out_dir = run_pipeline(
        llm=_bl_canned(),
        run_tests_fn=with_xfail,
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=1,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    per = json.loads((out_dir / "per_repo" / "fakelib.json").read_text())
    bl = per["baseline"][0]
    assert bl["test_passing"] == 1
    assert bl["test_passing_with_xfail"] == 3
    assert bl["iter_outcomes"][0]["test_passing_with_xfail"] == 3
