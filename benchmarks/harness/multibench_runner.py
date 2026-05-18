"""Per-problem benchmark runner for Phase F.

Drives A/B/C three-pipeline cells over a per-problem benchmark (HumanEval /
MBPP), reusing the existing implementer agents from ``benchmarks.agents``.
Output shape mirrors ``benchmarks.harness.runner`` — same RunSummary +
per_repo / raw / summary.md layout — so Phase G figure generation can read
both commit0 and multi-bench reports uniformly.

The key difference from commit0's runner: each "project" is a single-file
problem; we synthesize a ProjectRef wrapper around the adapter's
ProblemRef so the existing per-cell loops work unchanged.

Public entry: :func:`run_multibench_pipeline`.
"""

from __future__ import annotations

import json
import shutil
import sys
from dataclasses import asdict
from datetime import datetime
from pathlib import Path
from typing import Callable, Protocol

from al.llm import LLMClient
from benchmarks.agents import (
    run_al_greenfield_implementer,
    run_al_implementer,
    run_python_implementer,
)
from benchmarks.harness.commit0_adapter import ProjectRef, TestResult
from benchmarks.harness.inject import (
    InjectReport,
    inject_filled_al,
    inject_python_files,
)
from benchmarks.harness.runner import (
    MAX_FEEDBACK_TEST_OUTPUT_CHARS,
    MAX_ITERATIONS,
    PipelineRunResult,
    RunSummary,
    _compute_summary_metrics,
    _iter_outcome_dict,
    _save_raw,
    _truncate_tail,
    _write_summary_files,
)


class BenchmarkAdapter(Protocol):
    """Minimal protocol every per-problem benchmark adapter implements."""

    def list_problems(self, *, limit: int | None = None): ...
    def setup_workdir(self, problem, workdir: Path) -> Path: ...
    def load_spec(self, problem) -> str: ...
    def collect_stripped_files(self, workdir: Path) -> dict[str, str]: ...
    def run_tests(self, problem, workdir: Path, *, skip_install: bool, timeout: int) -> TestResult: ...


def run_multibench_pipeline(
    *,
    adapter,
    llm: LLMClient,
    n_problems: int = 30,
    k_repeats: int = 3,
    pipelines: tuple[str, ...] = ("baseline", "al_greenfield"),
    out_dir: Path,
    parallel_cells: int = 1,
    bench_name: str | None = None,
) -> Path:
    """Drive A / al_greenfield (and optionally B) over ``n_problems`` problems
    × ``k_repeats``. Each cell is one (problem, k, pipeline) triple.

    Note: Pipeline B (al-skeleton) is excluded by default for per-problem
    benchmarks since there's no hand-written .al skeleton per problem.
    Caller may include "al" if they generate skeletons programmatically.
    """
    bench_name = bench_name or getattr(adapter, "__name__", "multibench").rsplit(".", 1)[-1]
    ts = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "per_repo").mkdir(exist_ok=True)
    (out_dir / "raw").mkdir(exist_ok=True)

    problems = adapter.list_problems(limit=n_problems)
    summary = RunSummary(timestamp=ts, n_projects=len(problems), k_repeats=k_repeats)

    # Build cells.
    cells = [
        (problem, k, pipe)
        for problem in problems
        for k in range(k_repeats)
        for pipe in pipelines
    ]

    def _execute_cell(triple):
        problem, k, pipeline = triple
        workdir = out_dir / "workdirs" / f"{problem.name}-k{k}-{pipeline}"
        if workdir.exists():
            shutil.rmtree(workdir)
        adapter.setup_workdir(problem, workdir)
        spec_text = adapter.load_spec(problem)
        stripped_files = adapter.collect_stripped_files(workdir)

        project = ProjectRef(
            name=problem.name, path=workdir, spec_path=workdir / "<inline>",
        )

        # Wrap adapter.run_tests as the runner expects.
        def run_tests_fn(_proj, py_dir, *, skip_install=False):
            return adapter.run_tests(problem, py_dir, skip_install=skip_install, timeout=30)

        if pipeline == "baseline":
            return _run_baseline_cell_multibench(
                adapter=adapter, problem=problem, project=project,
                project_name=problem.name, k=k,
                spec_text=spec_text, stripped_files=stripped_files,
                llm=llm, run_tests_fn=run_tests_fn, out_dir=out_dir,
            )
        if pipeline == "al_greenfield":
            return _run_al_greenfield_cell_multibench(
                adapter=adapter, problem=problem, project=project,
                project_name=problem.name, k=k,
                spec_text=spec_text, stripped_files=stripped_files,
                llm=llm, run_tests_fn=run_tests_fn, out_dir=out_dir,
            )
        raise AssertionError(f"unsupported pipeline for multibench: {pipeline}")

    # Execute cells (sequential or threaded).
    cell_results: list = []
    if parallel_cells <= 1:
        for triple in cells:
            cell_results.append((triple, _execute_cell(triple)))
    else:
        from concurrent.futures import ThreadPoolExecutor, as_completed
        print(f"  [multibench:{bench_name}] launching {len(cells)} cells "
              f"with parallel_cells={parallel_cells}",
              file=sys.stderr, flush=True)
        with ThreadPoolExecutor(max_workers=parallel_cells) as ex:
            future_to_triple = {ex.submit(_execute_cell, t): t for t in cells}
            for fut in as_completed(future_to_triple):
                triple = future_to_triple[fut]
                try:
                    res = fut.result()
                except Exception as e:
                    problem, k, pipeline = triple
                    res = PipelineRunResult(
                        project=problem.name, k_iter=k, pipeline=pipeline,
                        test_passed=False, error=f"cell crashed: {e!r}",
                    )
                cell_results.append((triple, res))

    cell_results.sort(key=lambda x: (x[0][0].name, x[0][1], x[0][2]))
    for _, res in cell_results:
        summary.results.append(res)

    # Per-problem JSON (each problem.name keyed)
    for problem in problems:
        rows = {}
        for pipe in pipelines:
            rows[pipe] = [
                asdict(r) for (t, r) in cell_results
                if t[0].name == problem.name and t[2] == pipe
            ]
        (out_dir / "per_repo" / f"{problem.name}.json").write_text(
            json.dumps({"project": problem.name, **rows}, indent=2),
            encoding="utf-8",
        )

    # Per-pipeline aggregate stats. We DON'T call _compute_summary_metrics
    # because it hardcodes baseline-vs-al-skeleton roundtrip tax that
    # doesn't apply when Pipeline B is absent. Compute minimal stats here.
    _compute_multibench_summary(summary, pipelines)
    _write_multibench_summary_files(out_dir, summary, bench_name, pipelines)
    return out_dir


def _compute_multibench_summary(summary: RunSummary, pipelines: tuple[str, ...]) -> None:
    """Per-pipeline mean / median / pass% over all cells. Doesn't require
    every pipeline to be present — just summarizes whichever ran."""
    for r in summary.results:
        if r.k_iter < 0:
            continue
        summary.total_llm_tokens += r.llm_total_tokens
    # Reuse runner's per-test pct + best-iter pct logic for the pipelines that ran.
    def _per_test_pct(pipeline: str) -> float:
        total = sum(r.test_total for r in summary.results
                    if r.pipeline == pipeline and r.k_iter >= 0)
        passed = sum(r.test_passing_with_xfail for r in summary.results
                     if r.pipeline == pipeline and r.k_iter >= 0)
        return (100.0 * passed / total) if total else 0.0
    if "baseline" in pipelines:
        summary.baseline_per_test_pct = _per_test_pct("baseline")
    if "al" in pipelines:
        summary.al_per_test_pct = _per_test_pct("al")
    if "al_greenfield" in pipelines:
        summary.al_greenfield_per_test_pct = _per_test_pct("al_greenfield")
    # Best-iter
    def _best_iter_pct(pipeline: str) -> float:
        total = 0; passed = 0
        for r in summary.results:
            if r.pipeline != pipeline or r.k_iter < 0:
                continue
            if r.best_iter_idx < 0:
                continue
            for o in r.iter_outcomes:
                if o.get("iter") == r.best_iter_idx and o.get("test_total", 0) > 0:
                    total += o["test_total"]
                    passed += r.best_iter_passing_with_xfail
                    break
        return (100.0 * passed / total) if total else 0.0
    if "baseline" in pipelines:
        summary.baseline_best_iter_pct = _best_iter_pct("baseline")
    if "al_greenfield" in pipelines:
        summary.al_greenfield_best_iter_pct = _best_iter_pct("al_greenfield")
    # Binary all-pass% per pipeline (cell-level)
    for pipe in pipelines:
        results = [r.test_passed for r in summary.results
                   if r.pipeline == pipe and r.k_iter >= 0]
        if not results:
            continue
        pct = 100.0 * sum(results) / len(results)
        if pipe == "baseline":
            summary.baseline_pass_pct = pct
        elif pipe == "al":
            summary.al_pass_pct = pct
        elif pipe == "al_greenfield":
            summary.al_greenfield_pass_pct = pct


def _write_multibench_summary_files(
    out_dir: Path, summary: RunSummary, bench_name: str,
    pipelines: tuple[str, ...],
) -> None:
    """Write run.json + summary.md adapted for per-problem benchmarks."""
    (out_dir / "run.json").write_text(
        json.dumps(asdict(summary), indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    md = f"# Multibench Run — {bench_name} — {summary.timestamp}\n\n"
    md += (
        f"**Problems**: {summary.n_projects}  "
        f"**k**: {summary.k_repeats}  "
        f"**Pipelines**: {', '.join(pipelines)}  "
        f"**LLM tokens total**: {summary.total_llm_tokens:,}\n\n"
        f"## Headline (per-test pass %)\n\n"
        f"| pipeline | best-iter | final-iter | binary all-pass% (per-cell) |\n"
        f"|---|---|---|---|\n"
    )
    for pipe in pipelines:
        if pipe == "baseline":
            md += f"| baseline | {summary.baseline_best_iter_pct:.1f}% | {summary.baseline_per_test_pct:.1f}% | {summary.baseline_pass_pct:.1f}% |\n"
        elif pipe == "al":
            md += f"| al | — | {summary.al_per_test_pct:.1f}% | {summary.al_pass_pct:.1f}% |\n"
        elif pipe == "al_greenfield":
            md += f"| al_greenfield | {summary.al_greenfield_best_iter_pct:.1f}% | {summary.al_greenfield_per_test_pct:.1f}% | {summary.al_greenfield_pass_pct:.1f}% |\n"
    # Per-problem table
    md += "\n## Per-problem pass% (final iter mean over k repeats)\n\n"
    md += "| problem | " + " | ".join(pipelines) + " |\n"
    md += "|---" * (len(pipelines) + 1) + "|\n"
    by_problem: dict = {}
    for r in summary.results:
        if r.k_iter < 0:
            continue
        by_problem.setdefault(r.project, {p: [] for p in pipelines})
        pct = 100.0 * r.test_passing_with_xfail / r.test_total if r.test_total else 0
        if r.pipeline in by_problem[r.project]:
            by_problem[r.project][r.pipeline].append(pct)
    for prob_name, by_pipe in sorted(by_problem.items()):
        cells = []
        for pipe in pipelines:
            vals = by_pipe[pipe]
            mean = sum(vals) / len(vals) if vals else 0
            cells.append(f"{mean:.1f}%")
        md += f"| {prob_name} | " + " | ".join(cells) + " |\n"
    (out_dir / "summary.md").write_text(md, encoding="utf-8")


# ---------------------------------------------------------------------------
# Per-cell loops — mirror runner._run_baseline_cell / _run_al_greenfield_cell
# ---------------------------------------------------------------------------


def _run_baseline_cell_multibench(
    *, adapter, problem, project, project_name, k,
    spec_text, stripped_files, llm, run_tests_fn, out_dir,
):
    """Same shape as commit0 baseline cell, but ``_revert_files`` is replaced
    by ``adapter.setup_workdir`` (re-create the stripped state from scratch
    between iters — fast for single-file problems)."""
    workdir = project.path  # already set up

    last_filled: dict[str, str] | None = None
    last_test_output: str | None = None
    iter_outcomes: list[dict] = []
    final_test: TestResult | None = None
    final_inject = InjectReport()
    total_tokens = 0
    final_impl_ok = False
    final_impl_error = ""
    final_iter_idx = -1
    last_py_res = None
    last_prompt = ""
    last_completion_text = ""

    for iter_idx in range(MAX_ITERATIONS):
        print(f"  [{project_name}] k={k} baseline iter={iter_idx} ...",
              file=sys.stderr, flush=True)
        if iter_idx > 0:
            # Restore stripped state — single-file problems re-setup quickly.
            adapter.setup_workdir(problem, workdir)
        try:
            py_res = run_python_implementer(
                spec_text=spec_text, stripped_files=stripped_files, llm=llm,
                previous_filled=last_filled,
                previous_test_output=last_test_output,
                iter_idx=iter_idx,
            )
        except Exception as e:
            iter_outcomes.append(_iter_outcome_dict(
                iter_idx, final_test, 0, False, InjectReport(),
                error=f"LLM call failed: {e!r}",
            ))
            break

        last_py_res = py_res
        last_prompt = py_res.prompt_used
        last_completion_text = py_res.raw_completion.text if py_res.raw_completion else ""
        total_tokens += py_res.total_tokens
        inject = inject_python_files(workdir, py_res.files)
        test = run_tests_fn(project, workdir, skip_install=(iter_idx > 0))
        final_test = test
        final_inject = inject
        final_impl_ok = py_res.parse_ok
        final_impl_error = py_res.parse_error
        iter_outcomes.append(_iter_outcome_dict(
            iter_idx, test, py_res.total_tokens, py_res.parse_ok, inject,
            error=py_res.parse_error,
        ))
        if test.all_passed:
            final_iter_idx = iter_idx
            break
        last_filled = py_res.files
        last_test_output = _truncate_tail(test.raw_stdout)

    if last_py_res is not None:
        _save_raw(out_dir / "raw", project_name, k, "baseline",
                  prompt=last_prompt, completion=last_completion_text)

    return _make_result(
        project_name=project_name, k=k, pipeline="baseline",
        final_test=final_test, final_iter_idx=final_iter_idx,
        final_inject=final_inject, total_tokens=total_tokens,
        iter_outcomes=iter_outcomes, final_impl_ok=final_impl_ok,
        final_impl_error=final_impl_error,
    )


def _run_al_greenfield_cell_multibench(
    *, adapter, problem, project, project_name, k,
    spec_text, stripped_files, llm, run_tests_fn, out_dir,
):
    workdir = project.path
    last_filled: str | None = None
    last_test_output: str | None = None
    iter_outcomes: list[dict] = []
    final_test: TestResult | None = None
    final_inject = InjectReport()
    total_tokens = 0
    final_impl_ok = False
    final_impl_error = ""
    final_iter_idx = -1
    last_gf_res = None
    last_prompt = ""
    last_completion_text = ""
    prev_files: dict = {}
    last_validation_warnings: list[str] = []

    for iter_idx in range(MAX_ITERATIONS):
        print(f"  [{project_name}] k={k} al_greenfield iter={iter_idx} ...",
              file=sys.stderr, flush=True)
        if iter_idx > 0:
            adapter.setup_workdir(problem, workdir)
        try:
            gf_res = run_al_greenfield_implementer(
                spec_text=spec_text, stripped_files=stripped_files,
                llm=llm,
                previous_filled=last_filled,
                previous_test_output=last_test_output,
                previous_validation_warnings=last_validation_warnings,
                prev_files=prev_files,
                iter_idx=iter_idx,
            )
        except Exception as e:
            iter_outcomes.append(_iter_outcome_dict(
                iter_idx, final_test, 0, False, InjectReport(),
                error=f"LLM call failed: {e!r}",
            ))
            break
        last_gf_res = gf_res
        last_prompt = gf_res.prompt_used
        last_completion_text = (
            gf_res.raw_completion.text if gf_res.raw_completion else ""
        )
        total_tokens += gf_res.total_tokens

        combined_inject = InjectReport()
        any_injected = False
        for gf in gf_res.files:
            if gf.program is None or gf.parse_error:
                continue
            inj = inject_filled_al(workdir, gf.effective_al_text)
            combined_inject.injected.extend(inj.injected)
            for k_, v_ in inj.skipped.items():
                combined_inject.skipped[k_] = v_
            combined_inject.files_modified.update(inj.files_modified)
            any_injected = any_injected or bool(inj.injected)
            prev_files[gf.relpath] = gf.program

        test = run_tests_fn(project, workdir, skip_install=(iter_idx > 0))
        final_test = test
        final_inject = combined_inject
        final_impl_ok = gf_res.all_files_clean and any_injected
        final_impl_error = "; ".join(
            f.parse_error for f in gf_res.files if f.parse_error
        ) or gf_res.resolver_error or ""
        iter_outcomes.append(_iter_outcome_dict(
            iter_idx, test, gf_res.total_tokens, final_impl_ok,
            combined_inject, error=final_impl_error,
        ))
        if test.all_passed:
            final_iter_idx = iter_idx
            break
        last_filled = last_completion_text
        last_test_output = _truncate_tail(test.raw_stdout)
        last_validation_warnings = [
            f"[{f.relpath}] {issue.code} (line {issue.line}, node {issue.node_name!r}): "
            f"{issue.message}"
            for f in gf_res.files for issue in f.validation_issues
        ][:30]

    if last_gf_res is not None:
        _save_raw(out_dir / "raw", project_name, k, "al_greenfield",
                  prompt=last_prompt, completion=last_completion_text)

    return _make_result(
        project_name=project_name, k=k, pipeline="al_greenfield",
        final_test=final_test, final_iter_idx=final_iter_idx,
        final_inject=final_inject, total_tokens=total_tokens,
        iter_outcomes=iter_outcomes, final_impl_ok=final_impl_ok,
        final_impl_error=final_impl_error,
    )


def _make_result(
    *, project_name: str, k: int, pipeline: str,
    final_test, final_iter_idx, final_inject, total_tokens,
    iter_outcomes, final_impl_ok, final_impl_error,
):
    from benchmarks.harness.runner import _compute_best_iter
    best_idx, best_x, best_pct = _compute_best_iter(iter_outcomes)
    if final_test is None:
        return PipelineRunResult(
            project=project_name, k_iter=k, pipeline=pipeline,
            test_passed=False, error="all iterations failed at LLM call",
            llm_total_tokens=total_tokens,
            n_iterations=len(iter_outcomes),
            iter_outcomes=iter_outcomes,
            final_iter_idx=-1,
            best_iter_idx=best_idx,
            best_iter_passing_with_xfail=best_x,
            best_iter_pass_pct=best_pct,
        )
    return PipelineRunResult(
        project=project_name, k_iter=k, pipeline=pipeline,
        test_passed=final_test.all_passed,
        test_total=final_test.total,
        test_passing=final_test.passed,
        test_passing_with_xfail=final_test.passed_with_xfail,
        test_failing=final_test.failed,
        duration_sec=final_test.duration_sec,
        llm_total_tokens=total_tokens,
        implementer_ok=final_impl_ok,
        inject_injected=len(final_inject.injected),
        inject_skipped=len(final_inject.skipped),
        error=final_impl_error if not final_impl_ok else "",
        n_iterations=len(iter_outcomes),
        iter_outcomes=iter_outcomes,
        final_iter_idx=final_iter_idx,
        best_iter_idx=best_idx,
        best_iter_passing_with_xfail=best_x,
        best_iter_pass_pct=best_pct,
    )
