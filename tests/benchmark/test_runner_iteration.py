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


def _passing_test_fn(project, py_dir, *, skip_install: bool = False):
    return TestResult(project=project, total=1, passed=1, duration_sec=0.01)


def _failing_test_fn(project, py_dir, *, skip_install: bool = False):
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

    def with_xfail(project, py_dir, *, skip_install: bool = False):
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


# ---------------------------------------------------------------------------
# File-level revert between iters — regression test for the AL bug fixed
# alongside the Docker redesign (commit 30fa36b+1).
#
# Before the fix, ``_run_al_cell`` populated ``injected_files_so_far`` by
# calling ``Path(rel_str).resolve().relative_to(workdir.resolve())`` — but
# ``rel_str`` is ALREADY relative-to-workdir, so ``.resolve()`` rooted it
# against CWD and ``.relative_to(workdir)`` raised ``ValueError``, which
# was swallowed by a bare except, leaving the set empty. Result: iter > 0
# ran ``_revert_files(..., set())`` (no-op) and re-injected on top of the
# iter-0-filled workdir, where every method already had a real body, so
# ``_is_stripped`` returned False and inject silently matched nothing.
# Every AL cell looked like "iter 0 worked, iter 1+ did nothing" — the
# AL feedback loop was effectively disabled.
#
# The two tests below would have caught the bug:
#
#   test_al_iter1_actually_reinjects_after_revert — asserts the iter 1+
#     inject reports a non-zero ``inject_injected`` count when the
#     iter-1 LLM output has different (but still valid) body content.
#   test_al_revert_restores_pristine_file_between_iters — direct assertion
#     on workdir file content: pristine after revert, filled after inject.
# ---------------------------------------------------------------------------


def test_al_iter1_actually_reinjects_after_revert(tmp_path):
    """Regression: iter 1+ for AL cells must report inject_injected > 0
    when the LLM emits valid filled .al — i.e. revert + re-inject must
    actually happen between iters."""
    project = _make_fake_project(tmp_path)
    _make_fake_skeleton(tmp_path / "skeletons")

    # Two different but both-valid filled .al outputs across iters.
    iter_n = {"i": 0}
    al_outputs = [
        # iter 0: returns x * 2
        "flow fakelib_lib:\n"
        "  steps:\n"
        "    - double\n"
        "\n\n"
        "code double:\n"
        "  body: |\n"
        "    def double(x):\n"
        "        return x * 2\n",
        # iter 1: returns x + x (semantically equivalent, but a different body)
        "flow fakelib_lib:\n"
        "  steps:\n"
        "    - double\n"
        "\n\n"
        "code double:\n"
        "  body: |\n"
        "    def double(x):\n"
        "        return x + x\n",
        # iter 2: returns sum((x, x))
        "flow fakelib_lib:\n"
        "  steps:\n"
        "    - double\n"
        "\n\n"
        "code double:\n"
        "  body: |\n"
        "    def double(x):\n"
        "        return sum((x, x))\n",
    ]

    class CyclingAL:
        def complete(self, prompt, **kw):
            # Distinguish BL prompts (have stripped python_implementer format)
            # from AL prompts (mention the agent-lang authoring guide).
            from al.llm.base import CompletionResult
            is_al = "agent-lang" in prompt.lower() or "skeleton" in prompt.lower()
            if is_al:
                i = iter_n["i"] % len(al_outputs)
                iter_n["i"] += 1
                txt = al_outputs[i]
            else:
                txt = ("# === FILE: fakelib.py ===\n"
                       "def double(x):\n    return x * 2\n")
            return CompletionResult(
                text=txt, prompt_tokens=100, completion_tokens=10, model="mock",
            )

    out_dir = run_pipeline(
        llm=CyclingAL(),
        run_tests_fn=_failing_test_fn,  # keep loop running through all iters
        project_loader_fn=_stub_loader(project),
        n_projects=1, k_repeats=1,
        project_names=["fakelib"],
        skeletons_dir=tmp_path / "skeletons",
        out_dir=tmp_path / "report",
    )
    per = json.loads((out_dir / "per_repo" / "fakelib.json").read_text())
    al = per["al"][0]
    # All MAX_ITERATIONS iters should have injected exactly 1 function each.
    # Before the fix, iter > 0 had inject_injected == 0 because revert was
    # a no-op and the workdir's def double() was no longer stripped.
    inj_per_iter = [o["inject_injected"] for o in al["iter_outcomes"]]
    assert inj_per_iter == [1] * MAX_ITERATIONS, (
        f"iter > 0 didn't re-inject; got {inj_per_iter}. The revert path "
        f"is broken — iter 1+ sees the iter-0 filled workdir, which has no "
        f"stripped methods left for inject_filled_al to match."
    )


def test_al_revert_restores_pristine_file_between_iters(tmp_path):
    """Direct check on workdir contents — after iter 0 the workdir's
    fakelib.py should have the LLM-filled body; after the revert at the
    start of iter 1 it should be back to pristine ``pass``."""
    from benchmarks.harness.runner import _revert_files

    project = _make_fake_project(tmp_path)
    workdir = tmp_path / "workdir"
    workdir.mkdir()
    # Seed workdir with a "filled" version (simulating post-iter-0 state).
    (workdir / "fakelib.py").write_text(
        "def double(x):\n    return x * 2\n"
    )
    assert "return x * 2" in (workdir / "fakelib.py").read_text()

    # Revert just that file from pristine.
    _revert_files(project.path, workdir, {"fakelib.py"})

    reverted = (workdir / "fakelib.py").read_text()
    assert "pass" in reverted, f"revert didn't restore pristine ``pass`` body: {reverted!r}"
    assert "return x * 2" not in reverted
