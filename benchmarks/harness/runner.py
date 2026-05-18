"""Phase 1.G runner — orchestrates baseline + agent-lang pipelines.

Main entry: :func:`run_pipeline`. Walks every project in V1_SUBSET ×
k_repeats × 2 pipelines (A baseline, B agent-lang scaffolded), writes
per-step results to ``benchmarks/reports/runs/<timestamp>/``.

Key design: ``run_pipeline`` accepts an ``llm: LLMClient`` and a
``run_tests`` callable for dependency injection — tests use MockLLMClient
and a stub that doesn't actually subprocess into commit0. CLI usage in
``__main__`` constructs real ``OpenAICompatClient`` + ``run_tests`` from
``commit0_adapter``.

Pipeline A flow (per project, per k):
    1. Copy stripped repo → workdir_a
    2. Collect stripped *.py files into a dict
    3. Run python_implementer LLM
    4. inject_python_files(workdir_a, filled_files)
    5. run_tests on workdir_a → TestResult

Pipeline B flow:
    1. Copy stripped repo → workdir_b
    2. Read hand-written agent-lang skeleton from benchmarks/skeletons/
    3. Run al_implementer LLM
    4. inject_filled_al(workdir_b, filled_text)
    5. run_tests on workdir_b → TestResult

Output: see ``docs/design/benchmark.md`` § 8 for report layout.
"""

from __future__ import annotations

import json
import shutil
import sys
from dataclasses import asdict, dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Callable, Iterable

from benchmarks.agents import (
    ALGreenfieldResult,
    ALImplementerResult,
    PythonImplementerResult,
    run_al_greenfield_implementer,
    run_al_implementer,
    run_python_implementer,
)
from benchmarks.harness.V1_SUBSET import V1_SUBSET
from benchmarks.harness.commit0_adapter import (
    ProjectRef,
    TestResult,
    _default_repos_dir,
    list_projects,
)
from benchmarks.harness.inject import (
    InjectReport,
    inject_filled_al,
    inject_python_files,
)
from benchmarks.metrics.pass_at_k import compute as compute_pass_at_k
from benchmarks.metrics.roundtrip_loss import compute as compute_roundtrip_tax
from al.llm import LLMClient


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class PipelineRunResult:
    """One project × k × {A, B} cell of the result matrix.

    Phase 1.H'.F.2: cell now runs a multi-iter test-driven loop. The
    top-level test_passing / test_total / etc. reflect the FINAL iter
    (which may be iter 0 if pass on first try, or iter 2 if we used the
    full budget). ``iter_outcomes`` records each iter's metrics so the
    decision report and WebUI can show convergence patterns.
    """

    project: str
    k_iter: int
    pipeline: str  # "baseline" or "al"
    test_passed: bool
    test_total: int = 0
    test_passing: int = 0
    test_passing_with_xfail: int = 0  # Phase 1.H'.F.2: commit0-aligned numerator
    test_failing: int = 0
    duration_sec: float = 0.0
    llm_total_tokens: int = 0
    implementer_ok: bool = False
    inject_injected: int = 0
    inject_skipped: int = 0
    error: str = ""
    # Phase 1.H'.F.2: multi-iter loop bookkeeping.
    n_iterations: int = 0  # how many iters actually ran (1..MAX_ITERATIONS)
    final_iter_idx: int = -1  # which iter passed (-1 = never passed)
    iter_outcomes: list[dict] = field(default_factory=list)
    """Each item is {iter, test_passing, test_passing_with_xfail, test_total,
       tokens, implementer_ok, inject_injected, inject_skipped, duration_sec,
       json_report_ok, error}. Used by WebUI + decision report."""
    # Phase 1.AL-LOOP round 0.2: track BEST iter alongside final, so
    # mid-run regression (LLM over-edits in iter 2 from a working iter 1)
    # doesn't lose signal. final_iter_idx still reflects what commit0
    # would record (last iter); best_iter_idx + best_iter_passing_with_xfail
    # give the strongest signal seen.
    best_iter_idx: int = -1  # which iter had the best pass count (-1 = no iter had test_total>0)
    best_iter_passing_with_xfail: int = 0
    best_iter_pass_pct: float = 0.0  # 100 * best_iter_passing_with_xfail / test_total of that iter


@dataclass
class RunSummary:
    """Aggregated outcome of one full benchmark run."""

    timestamp: str
    n_projects: int
    k_repeats: int
    results: list[PipelineRunResult] = field(default_factory=list)
    tax_pp: float = 0.0
    baseline_pass_pct: float = 0.0  # binary all-pass-or-not, per-cell average
    al_pass_pct: float = 0.0
    # Phase 1.H'.F.2: commit0-aligned per-test pass rate.
    # `(sum_passing_with_xfail / sum_total)` aggregated across all cells.
    # This is the metric commit0's official ``evaluate.py`` reports:
    #   passed_rate = (status["passed"] + status["xfail"]) / sum(status.values())
    baseline_per_test_pct: float = 0.0
    al_per_test_pct: float = 0.0
    per_test_tax_pp: float = 0.0  # baseline - al on per-test metric
    # Phase 1.AL-LOOP 0.2: same metric but using each cell's BEST iter
    # instead of its final iter — recovers signal lost to mid-run regression.
    baseline_best_iter_pct: float = 0.0
    al_best_iter_pct: float = 0.0
    best_iter_tax_pp: float = 0.0
    pass_at_1_baseline: float = 0.0
    pass_at_1_al: float = 0.0
    pass_at_k_baseline: float = 0.0
    pass_at_k_al: float = 0.0
    total_llm_tokens: int = 0
    # Phase 1.H'.F.2: iter convergence stats — how many cells pass on which iter.
    iter_convergence_baseline: dict = field(default_factory=dict)
    iter_convergence_al: dict = field(default_factory=dict)
    # v0.7 Phase 5c: Pipeline C metrics. Same shapes as baseline/al fields
    # above; zero when al_greenfield wasn't run.
    al_greenfield_pass_pct: float = 0.0
    al_greenfield_per_test_pct: float = 0.0
    al_greenfield_best_iter_pct: float = 0.0
    pass_at_1_al_greenfield: float = 0.0
    pass_at_k_al_greenfield: float = 0.0
    iter_convergence_al_greenfield: dict = field(default_factory=dict)
    # Pipeline-C-specific deltas (positive = baseline ahead, negative = C ahead).
    per_test_tax_pp_al_greenfield: float = 0.0


# ---------------------------------------------------------------------------
# Public entry
# ---------------------------------------------------------------------------


SKELETONS_DIR = Path(__file__).resolve().parents[1] / "skeletons"


def run_pipeline(
    *,
    llm: LLMClient,
    run_tests_fn: Callable[[ProjectRef, Path], TestResult],
    project_loader_fn: Callable[[str, Path], ProjectRef] | None = None,
    n_projects: int = 5,
    k_repeats: int = 5,
    out_dir: Path | None = None,
    skeletons_dir: Path = SKELETONS_DIR,
    repos_base: Path | None = None,
    project_names: Iterable[str] | None = None,
    parallel_cells: int = 1,
    pipelines: tuple[str, ...] = ("baseline", "al"),
) -> Path:
    """Run the full benchmark and write reports. Return report dir.

    Args:
        llm: LLMClient used by both implementers.
        run_tests_fn: callable returning a TestResult given (ProjectRef, py_dir).
            Tests inject a stub; CLI uses commit0_adapter.run_tests.
        project_loader_fn: optional ``(project_name, repos_base) -> ProjectRef``.
            Defaults to picking from ``list_projects()``.
        n_projects: take the first N from V1_SUBSET (or project_names).
        k_repeats: independent runs per (project × pipeline).
        out_dir: report directory; defaults to
            ``benchmarks/reports/runs/<timestamp>/``.
        skeletons_dir: where hand-written agent-lang skeletons live.
        repos_base: where commit0 setup'd the repos to. Defaults to
            ``thirdparty/commit0_repos/``.
        project_names: override V1_SUBSET (for partial runs / smoke tests).
        parallel_cells: when > 1, run independent ``(project, k, pipeline)``
            cells concurrently via a ThreadPoolExecutor. Each cell makes
            its own LLM calls + pytest subprocesses; cells don't share
            state so parallelism is safe. The LLM client is reused across
            threads (httpx is thread-safe). Defaults to 1 (sequential).
        pipelines: which pipelines to include in this run. Valid names:
            ``"baseline"`` (Pipeline A), ``"al"`` (Pipeline B,
            skeleton-based), ``"al_greenfield"`` (Pipeline C, v0.7
            greenfield AL authoring). Default ``("baseline", "al")``
            preserves the v0.6 cell matrix.
    """
    valid_pipelines = {"baseline", "al", "al_greenfield"}
    for p in pipelines:
        if p not in valid_pipelines:
            raise ValueError(
                f"unknown pipeline {p!r}; must be one of {sorted(valid_pipelines)}"
            )
    # al_greenfield needs a skeleton-less path; baseline + al keep their
    # existing skeleton-required behavior. (Pipeline C doesn't use the
    # skeleton, only stripped Python.)
    ts = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    out_dir = out_dir or _default_report_dir(ts)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "per_repo").mkdir(exist_ok=True)
    (out_dir / "raw").mkdir(exist_ok=True)
    repos_base = repos_base or _default_repos_dir()

    names = list(project_names) if project_names is not None else list(V1_SUBSET[:n_projects])
    loader = project_loader_fn or _default_project_loader

    summary = RunSummary(timestamp=ts, n_projects=len(names), k_repeats=k_repeats)

    # 1. Materialise per-repo metadata (project ref, skeleton, spec, stripped files)
    repo_meta: dict[str, dict] = {}
    for project_name in names:
        try:
            project = loader(project_name, repos_base)
        except FileNotFoundError as e:
            summary.results.append(
                PipelineRunResult(
                    project=project_name, k_iter=-1, pipeline="setup",
                    test_passed=False, error=f"project not setup: {e}",
                )
            )
            continue

        # Pipeline B needs a skeleton; A and C don't. If only C is
        # requested, missing skeleton is fine — fall through with empty
        # skeleton_text.
        skeleton_path = skeletons_dir / f"{project_name}.al"
        if "al" in pipelines and not skeleton_path.exists():
            summary.results.append(
                PipelineRunResult(
                    project=project_name, k_iter=-1, pipeline="setup",
                    test_passed=False,
                    error=f"hand-written skeleton missing: {skeleton_path}",
                )
            )
            continue
        skeleton_text = (
            skeleton_path.read_text(encoding="utf-8")
            if skeleton_path.exists() else ""
        )
        repo_meta[project_name] = {
            "project": project,
            "skeleton_text": skeleton_text,
            "spec_text": _load_spec(project.path),
            "stripped_files": _collect_stripped_files(project.path),
        }

    # 2. Build the cell work list: every (project, k, pipeline) triple
    #    from the ``pipelines`` argument.
    Cell = tuple  # (name, k, pipeline)
    cells: list[Cell] = []
    for project_name in repo_meta:
        for k in range(k_repeats):
            for p in pipelines:
                cells.append((project_name, k, p))

    def _execute_cell(triple: Cell) -> PipelineRunResult:
        name, k, pipeline = triple
        m = repo_meta[name]
        if pipeline == "baseline":
            return _run_baseline_cell(
                project=m["project"], project_name=name, k=k,
                spec_text=m["spec_text"], stripped_files=m["stripped_files"],
                llm=llm, run_tests_fn=run_tests_fn, out_dir=out_dir,
            )
        if pipeline == "al":
            return _run_al_cell(
                project=m["project"], project_name=name, k=k,
                spec_text=m["spec_text"], skeleton_text=m["skeleton_text"],
                llm=llm, run_tests_fn=run_tests_fn, out_dir=out_dir,
            )
        if pipeline == "al_greenfield":
            return _run_al_greenfield_cell(
                project=m["project"], project_name=name, k=k,
                spec_text=m["spec_text"],
                stripped_files=m["stripped_files"],
                llm=llm, run_tests_fn=run_tests_fn, out_dir=out_dir,
            )
        raise AssertionError(f"unknown pipeline: {pipeline!r}")

    # 3. Run cells — sequentially if parallel_cells <= 1, else thread pool.
    cell_results: list[tuple[Cell, PipelineRunResult]] = []
    if parallel_cells <= 1:
        for triple in cells:
            cell_results.append((triple, _execute_cell(triple)))
    else:
        from concurrent.futures import ThreadPoolExecutor, as_completed
        print(
            f"  [runner] launching {len(cells)} cells with parallel_cells={parallel_cells}",
            file=sys.stderr, flush=True,
        )
        with ThreadPoolExecutor(max_workers=parallel_cells) as ex:
            future_to_triple = {ex.submit(_execute_cell, t): t for t in cells}
            for fut in as_completed(future_to_triple):
                triple = future_to_triple[fut]
                try:
                    res = fut.result()
                except Exception as e:
                    name, k, pipeline = triple
                    res = PipelineRunResult(
                        project=name, k_iter=k, pipeline=pipeline,
                        test_passed=False,
                        error=f"cell crashed: {e!r}",
                    )
                cell_results.append((triple, res))

    # 4. Stable order: by (project, k, pipeline) — pipeline order
    # baseline → al → al_greenfield for readable summaries.
    _pipeline_rank = {"baseline": 0, "al": 1, "al_greenfield": 2}
    cell_results.sort(
        key=lambda x: (
            list(repo_meta).index(x[0][0]),
            x[0][1],
            _pipeline_rank.get(x[0][2], 99),
        )
    )
    for triple, res in cell_results:
        summary.results.append(res)

    # 5. Write per-repo aggregate JSON (always created so the file layout
    # matches the sequential path).
    for project_name in repo_meta:
        per_repo_data: dict = {"project": project_name}
        for pipeline_name in pipelines:
            per_repo_data[pipeline_name] = [
                asdict(r) for (t, r) in cell_results
                if t[0] == project_name and t[2] == pipeline_name
            ]
        (out_dir / "per_repo" / f"{project_name}.json").write_text(
            json.dumps(per_repo_data, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    _compute_summary_metrics(summary)
    _write_summary_files(out_dir, summary)
    return out_dir


# ---------------------------------------------------------------------------
# Per-cell iter loop (Phase 1.H'.F.2 — commit0-aligned)
# ---------------------------------------------------------------------------

#: Max iterations per cell. commit0's base.yaml ``max_iteration: 3``.
MAX_ITERATIONS = 3

#: Max chars of pytest stdout fed back to the next iter. Tail-truncated.
MAX_FEEDBACK_TEST_OUTPUT_CHARS = 8 * 1024


def _truncate_tail(text: str, max_chars: int = MAX_FEEDBACK_TEST_OUTPUT_CHARS) -> str:
    """Keep the LAST ``max_chars`` chars — pytest summary is at the tail."""
    if not text:
        return ""
    if len(text) <= max_chars:
        return text
    return f"...(truncated {len(text) - max_chars} chars from head)...\n" + text[-max_chars:]


def _compute_best_iter(iter_outcomes: list[dict]) -> tuple[int, int, float]:
    """Return ``(best_iter_idx, best_passing_with_xfail, best_pass_pct)``.

    "Best" is the iter with the highest ``passing_with_xfail`` count
    among iters that actually collected at least 1 test. Ties: earliest
    iter wins (most efficient).

    Returns ``(-1, 0, 0.0)`` if no iter had ``test_total > 0``.
    """
    best_idx = -1
    best_count = -1
    best_pct = 0.0
    for o in iter_outcomes:
        tot = o.get("test_total", 0)
        if tot <= 0:
            continue
        passed = o.get("test_passing_with_xfail", 0)
        if passed > best_count:
            best_count = passed
            best_idx = o.get("iter", -1)
            best_pct = 100.0 * passed / tot
    if best_idx < 0:
        return -1, 0, 0.0
    return best_idx, best_count, best_pct


def _iter_outcome_dict(
    iter_idx: int,
    test: TestResult | None,
    tokens: int,
    implementer_ok: bool,
    inject_report: InjectReport,
    error: str = "",
) -> dict:
    """Compact dict representation of one iter's outcome — stored in
    ``PipelineRunResult.iter_outcomes`` for WebUI + decision report."""
    return {
        "iter": iter_idx,
        "test_passing": getattr(test, "passed", 0) if test else 0,
        "test_passing_with_xfail": getattr(test, "passed_with_xfail", 0) if test else 0,
        "test_total": getattr(test, "total", 0) if test else 0,
        "test_failing": getattr(test, "failed", 0) if test else 0,
        "duration_sec": getattr(test, "duration_sec", 0.0) if test else 0.0,
        "tokens": tokens,
        "implementer_ok": implementer_ok,
        "inject_injected": len(inject_report.injected),
        "inject_skipped": len(inject_report.skipped),
        "json_report_ok": getattr(test, "json_report_ok", False) if test else False,
        "error": error,
    }


def _run_baseline_cell(
    *,
    project: ProjectRef,
    project_name: str,
    k: int,
    spec_text: str,
    stripped_files: dict[str, str],
    llm: LLMClient,
    run_tests_fn: Callable[[ProjectRef, Path], TestResult],
    out_dir: Path,
) -> PipelineRunResult:
    """Run one (project, k, baseline) cell through MAX_ITERATIONS of
    test-driven feedback. Breaks early when pytest reports all-pass.
    """
    workdir = out_dir / "workdirs" / f"{project_name}-k{k}-baseline"
    _copy_repo(project.path, workdir)

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
    # Tracks every file ever injected into ``workdir`` across iters; used
    # by ``_revert_files`` between iters to restore pristine content
    # without rebuilding ``.egg-info`` / pip-install side effects.
    injected_files_so_far: set[str] = set()

    for iter_idx in range(MAX_ITERATIONS):
        print(f"  [{project_name}] k={k} baseline iter={iter_idx} ...",
              file=sys.stderr, flush=True)
        try:
            py_res = run_python_implementer(
                spec_text=spec_text, stripped_files=stripped_files, llm=llm,
                previous_filled=last_filled,
                previous_test_output=last_test_output,
                iter_idx=iter_idx,
            )
        except Exception as e:
            # LLM-side failure (gateway 503, timeout, JSON parse, ...).
            # Record the failed iter and break — feeding more retries
            # without a model swap isn't useful at this layer; the
            # ClaudeCodeClient already retried + swapped models.
            iter_outcomes.append(_iter_outcome_dict(
                iter_idx, final_test, 0, False, InjectReport(),
                error=f"LLM call failed: {e!r}",
            ))
            print(f"    ⚠ baseline iter {iter_idx} LLM failed: {e!r}",
                  file=sys.stderr, flush=True)
            break

        last_py_res = py_res
        last_prompt = py_res.prompt_used
        last_completion_text = py_res.raw_completion.text if py_res.raw_completion else ""
        total_tokens += py_res.total_tokens
        # Restore previously-injected files to their pristine state so
        # this iter's inject lands on a clean stripped baseline (commit0's
        # eval script does `git reset --hard <base> && git apply patch`
        # per iter; ``_revert_files`` emulates that without wiping the
        # pip-install metadata under ``.egg-info``).
        if iter_idx > 0 and injected_files_so_far:
            _revert_files(project.path, workdir, injected_files_so_far)
        inject = inject_python_files(workdir, py_res.files)
        injected_files_so_far.update(py_res.files.keys())
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

    # Always save the LAST raw prompt/completion (per-iter raw save would
    # be noisy; the iter_outcomes captures per-iter metrics).
    if last_py_res is not None:
        _save_raw(out_dir / "raw", project_name, k, "baseline",
                  prompt=last_prompt, completion=last_completion_text)

    # Build PipelineRunResult from the FINAL iter (or all-error fallback).
    best_iter_idx, best_passing_x, best_pct = _compute_best_iter(iter_outcomes)
    if final_test is None:
        # All iters failed at the LLM call before any test ran.
        return PipelineRunResult(
            project=project_name, k_iter=k, pipeline="baseline",
            test_passed=False, error="all iterations failed at LLM call",
            llm_total_tokens=total_tokens,
            n_iterations=len(iter_outcomes),
            iter_outcomes=iter_outcomes,
            final_iter_idx=-1,
            best_iter_idx=best_iter_idx,
            best_iter_passing_with_xfail=best_passing_x,
            best_iter_pass_pct=best_pct,
        )
    return PipelineRunResult(
        project=project_name, k_iter=k, pipeline="baseline",
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
        best_iter_idx=best_iter_idx,
        best_iter_passing_with_xfail=best_passing_x,
        best_iter_pass_pct=best_pct,
    )


def _run_al_cell(
    *,
    project: ProjectRef,
    project_name: str,
    k: int,
    spec_text: str,
    skeleton_text: str,
    llm: LLMClient,
    run_tests_fn: Callable[[ProjectRef, Path], TestResult],
    out_dir: Path,
) -> PipelineRunResult:
    """Same shape as ``_run_baseline_cell`` but driving the al
    implementer. BL/AL symmetry is asserted by tests in
    ``tests/benchmark/test_fairness.py``.
    """
    workdir = out_dir / "workdirs" / f"{project_name}-k{k}-al"
    _copy_repo(project.path, workdir)

    last_filled: str | None = None
    last_test_output: str | None = None
    iter_outcomes: list[dict] = []
    final_test: TestResult | None = None
    final_inject = InjectReport()
    total_tokens = 0
    final_impl_ok = False
    final_impl_error = ""
    final_iter_idx = -1
    last_al_res = None
    last_prompt = ""
    last_completion_text = ""
    # See _run_baseline_cell for the same tracking-set rationale.
    injected_files_so_far: set[str] = set()

    for iter_idx in range(MAX_ITERATIONS):
        print(f"  [{project_name}] k={k} al iter={iter_idx} ...",
              file=sys.stderr, flush=True)
        try:
            al_res = run_al_implementer(
                spec_text=spec_text, skeleton_text=skeleton_text, llm=llm,
                previous_filled=last_filled,
                previous_test_output=last_test_output,
                iter_idx=iter_idx,
            )
        except Exception as e:
            iter_outcomes.append(_iter_outcome_dict(
                iter_idx, final_test, 0, False, InjectReport(),
                error=f"LLM call failed: {e!r}",
            ))
            print(f"    ⚠ al iter {iter_idx} LLM failed: {e!r}",
                  file=sys.stderr, flush=True)
            break

        last_al_res = al_res
        last_prompt = al_res.prompt_used
        last_completion_text = al_res.raw_completion.text if al_res.raw_completion else ""
        total_tokens += al_res.total_tokens
        # Revert previously-injected files, preserve pip-install state.
        if iter_idx > 0 and injected_files_so_far:
            _revert_files(project.path, workdir, injected_files_so_far)
        if al_res.al_parse_ok:
            inject = inject_filled_al(workdir, al_res.filled_al)
            # ``inject_filled_al`` reports files_modified as ALREADY
            # workdir-relative path strings (see inject.py line 247:
            # ``return target_file.relative_to(workdir)``). Use them
            # directly — DO NOT call ``.resolve()`` here, which would
            # turn the relative path into ``<CWD>/<rel>`` and break
            # the .relative_to(workdir) translation, leaving
            # ``injected_files_so_far`` empty and silently disabling
            # ``_revert_files`` for every iter > 0. That's the bug that
            # made every AL cell look like "iter 0 worked, iter 1+ did
            # nothing" in run 20260515-213540.
            for rel_str in inject.files_modified:
                injected_files_so_far.add(rel_str)
        else:
            inject = InjectReport()
        test = run_tests_fn(project, workdir, skip_install=(iter_idx > 0))
        final_test = test
        final_inject = inject
        final_impl_ok = al_res.al_parse_ok and al_res.all_bodies_valid
        final_impl_error = al_res.al_parse_error
        iter_outcomes.append(_iter_outcome_dict(
            iter_idx, test, al_res.total_tokens, final_impl_ok, inject,
            error=al_res.al_parse_error,
        ))
        if test.all_passed:
            final_iter_idx = iter_idx
            break
        last_filled = al_res.filled_al
        last_test_output = _truncate_tail(test.raw_stdout)

    if last_al_res is not None:
        _save_raw(out_dir / "raw", project_name, k, "al",
                  prompt=last_prompt, completion=last_completion_text)

    best_iter_idx, best_passing_x, best_pct = _compute_best_iter(iter_outcomes)
    if final_test is None:
        return PipelineRunResult(
            project=project_name, k_iter=k, pipeline="al",
            test_passed=False, error="all iterations failed at LLM call",
            llm_total_tokens=total_tokens,
            n_iterations=len(iter_outcomes),
            iter_outcomes=iter_outcomes,
            final_iter_idx=-1,
            best_iter_idx=best_iter_idx,
            best_iter_passing_with_xfail=best_passing_x,
            best_iter_pass_pct=best_pct,
        )
    return PipelineRunResult(
        project=project_name, k_iter=k, pipeline="al",
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
        best_iter_idx=best_iter_idx,
        best_iter_passing_with_xfail=best_passing_x,
        best_iter_pass_pct=best_pct,
        n_iterations=len(iter_outcomes),
        iter_outcomes=iter_outcomes,
        final_iter_idx=final_iter_idx,
    )


def _run_al_greenfield_cell(
    *,
    project: ProjectRef,
    project_name: str,
    k: int,
    spec_text: str,
    stripped_files: dict[str, str],
    llm: LLMClient,
    run_tests_fn: Callable[[ProjectRef, Path], TestResult],
    out_dir: Path,
) -> PipelineRunResult:
    """v0.7 Pipeline C — greenfield AL authoring.

    Same shape as ``_run_al_cell`` but driving the greenfield
    implementer (no skeleton; LLM authors .al from stripped Python).
    Each iter:
      1. Run :func:`run_al_greenfield_implementer` → ALGreenfieldResult
         with one or more GreenfieldFile blocks.
      2. For each file that parsed cleanly, call ``inject_filled_al``
         on its al_text. We aggregate the InjectReports across files
         into one combined report for the iter.
      3. Run pytest on the workdir.
      4. On failure, feed back the raw LLM output + pytest stdout to
         the next iter.
    """
    workdir = out_dir / "workdirs" / f"{project_name}-k{k}-al_greenfield"
    _copy_repo(project.path, workdir)

    last_filled: str | None = None
    last_test_output: str | None = None
    iter_outcomes: list[dict] = []
    final_test: TestResult | None = None
    final_inject = InjectReport()
    total_tokens = 0
    final_impl_ok = False
    final_impl_error = ""
    final_iter_idx = -1
    last_gf_res: ALGreenfieldResult | None = None
    last_prompt = ""
    last_completion_text = ""
    injected_files_so_far: set[str] = set()

    for iter_idx in range(MAX_ITERATIONS):
        print(f"  [{project_name}] k={k} al_greenfield iter={iter_idx} ...",
              file=sys.stderr, flush=True)
        try:
            gf_res = run_al_greenfield_implementer(
                spec_text=spec_text, stripped_files=stripped_files,
                llm=llm,
                previous_filled=last_filled,
                previous_test_output=last_test_output,
                iter_idx=iter_idx,
            )
        except Exception as e:
            iter_outcomes.append(_iter_outcome_dict(
                iter_idx, final_test, 0, False, InjectReport(),
                error=f"LLM call failed: {e!r}",
            ))
            print(f"    ⚠ al_greenfield iter {iter_idx} LLM failed: {e!r}",
                  file=sys.stderr, flush=True)
            break

        last_gf_res = gf_res
        last_prompt = gf_res.prompt_used
        last_completion_text = (
            gf_res.raw_completion.text if gf_res.raw_completion else ""
        )
        total_tokens += gf_res.total_tokens

        if iter_idx > 0 and injected_files_so_far:
            _revert_files(project.path, workdir, injected_files_so_far)

        # Inject every file that parsed cleanly. Aggregate reports.
        combined_inject = InjectReport()
        any_injected = False
        for gf in gf_res.files:
            if gf.program is None or gf.parse_error:
                continue
            inj = inject_filled_al(workdir, gf.al_text)
            combined_inject.injected.extend(inj.injected)
            for k_, v_ in inj.skipped.items():
                combined_inject.skipped[k_] = v_
            combined_inject.files_modified.update(inj.files_modified)
            any_injected = any_injected or bool(inj.injected)
            for rel_str in inj.files_modified:
                injected_files_so_far.add(rel_str)

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

    if last_gf_res is not None:
        _save_raw(out_dir / "raw", project_name, k, "al_greenfield",
                  prompt=last_prompt, completion=last_completion_text)

    best_iter_idx, best_passing_x, best_pct = _compute_best_iter(iter_outcomes)
    if final_test is None:
        return PipelineRunResult(
            project=project_name, k_iter=k, pipeline="al_greenfield",
            test_passed=False, error="all iterations failed at LLM call",
            llm_total_tokens=total_tokens,
            n_iterations=len(iter_outcomes),
            iter_outcomes=iter_outcomes,
            final_iter_idx=-1,
            best_iter_idx=best_iter_idx,
            best_iter_passing_with_xfail=best_passing_x,
            best_iter_pass_pct=best_pct,
        )
    return PipelineRunResult(
        project=project_name, k_iter=k, pipeline="al_greenfield",
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
        best_iter_idx=best_iter_idx,
        best_iter_passing_with_xfail=best_passing_x,
        best_iter_pass_pct=best_pct,
        n_iterations=len(iter_outcomes),
        iter_outcomes=iter_outcomes,
        final_iter_idx=final_iter_idx,
    )


def _reset_workdir(src: Path, dst: Path) -> None:
    """Wipe ``dst`` and re-copy ``src``. Heavy reset; only used at cell
    start now — between iters we use the lighter ``_revert_files``."""
    if dst.exists():
        shutil.rmtree(dst)
    _copy_repo(src, dst)


def _revert_files(src: Path, dst: Path, rel_paths: set[str]) -> None:
    """Restore ``rel_paths`` in ``dst`` from their pristine versions in ``src``.

    Used between iters in place of the old ``_reset_workdir``: each iter's
    inject should land on a stripped (pristine) state, but rebuilding the
    entire workdir wipes ``.egg-info`` / pip metadata and forces a slow
    re-install. By restoring only the files the previous iter touched,
    we preserve the pip-install side effects (5-30s saved per iter on
    big repos) without compromising correctness.

    Files that exist in ``dst`` but not in ``src`` (e.g. ``.pytest-report.json``
    from the prior pytest run) are NOT removed — they'll get overwritten
    or simply ignored by the next pytest invocation.
    """
    for rel in rel_paths:
        sp = src / rel
        dp = dst / rel
        if sp.exists():
            dp.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(sp, dp)
        else:
            # Was created by inject and didn't exist in pristine — drop it.
            if dp.exists():
                try:
                    dp.unlink()
                except OSError:
                    pass


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _default_report_dir(timestamp: str) -> Path:
    here = Path(__file__).resolve()
    return here.parents[2] / "benchmarks" / "reports" / "runs" / timestamp


def _default_project_loader(project_name: str, repos_base: Path) -> ProjectRef:
    for p in list_projects(base_dir=repos_base):
        if p.name == project_name:
            if not p.path.exists():
                raise FileNotFoundError(
                    f"{project_name!r}: setup_split() not run yet. "
                    f"Expected at {p.path}"
                )
            return p
    raise FileNotFoundError(f"unknown project: {project_name!r}")


def _load_spec(project_dir: Path) -> str:
    """Best-effort spec text: spec.pdf.bz2 (skip — binary) → README → empty."""
    for cand_name in ("README.rst", "README.md", "README.txt"):
        cand = project_dir / cand_name
        if cand.exists():
            try:
                return cand.read_text(encoding="utf-8", errors="replace")
            except OSError:
                pass
    return ""


_BUILD_FILES = {
    "setup.py", "setup.cfg", "conftest.py",
    "_version.py", "version.py", "__about__.py",
}


def _collect_stripped_files(project_dir: Path) -> dict[str, str]:
    """Return {rel_path: source} for every non-test, non-build .py under project_dir.

    Excludes:
        - tests/ test_*.py — never under-implementation
        - __pycache__, .git, build, dist, docs, bin — noise
        - setup.py, setup.cfg, conftest.py, _version.py — packaging files
          that LLMs sometimes "fix" and break (the stripped commit0 repos
          have working build files; the agent must not rewrite them)
    """
    out: dict[str, str] = {}
    for p in project_dir.rglob("*.py"):
        parts = p.parts
        if any(x in parts for x in ("tests", "test", "__pycache__", ".git",
                                     "build", "dist", "docs", "bin")):
            continue
        if p.name in _BUILD_FILES:
            continue
        rel = p.relative_to(project_dir).as_posix()
        try:
            out[rel] = p.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
    return out


def _copy_repo(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst, ignore=shutil.ignore_patterns(
        ".git", "__pycache__", ".pytest_cache", ".mypy_cache",
    ))


def _record_result(
    project: str,
    k: int,
    pipeline: str,
    test: TestResult,
    *,
    implementer_ok: bool,
    llm_tokens: int,
    inject_report: InjectReport,
    impl_error: str,
) -> PipelineRunResult:
    return PipelineRunResult(
        project=project,
        k_iter=k,
        pipeline=pipeline,
        test_passed=test.all_passed,
        test_total=test.total,
        test_passing=test.passed,
        test_failing=test.failed + test.errored,
        duration_sec=test.duration_sec,
        llm_total_tokens=llm_tokens,
        implementer_ok=implementer_ok,
        inject_injected=len(inject_report.injected),
        inject_skipped=len(inject_report.skipped),
        error=impl_error,
    )


def _save_raw(
    raw_dir: Path,
    project: str,
    k: int,
    pipeline: str,
    *,
    prompt: str,
    completion: str,
) -> None:
    fn = raw_dir / f"{project}-k{k}-{pipeline}.txt"
    fn.write_text(
        f"=== PROMPT ({len(prompt)} chars) ===\n{prompt}\n\n"
        f"=== COMPLETION ({len(completion)} chars) ===\n{completion}\n",
        encoding="utf-8",
    )


def _compute_summary_metrics(summary: RunSummary) -> None:
    by_project_baseline: dict[str, list[bool]] = {}
    by_project_al: dict[str, list[bool]] = {}
    by_project_alg: dict[str, list[bool]] = {}
    for r in summary.results:
        if r.k_iter < 0:
            continue
        if r.pipeline == "baseline":
            by_project_baseline.setdefault(r.project, []).append(r.test_passed)
        elif r.pipeline == "al":
            by_project_al.setdefault(r.project, []).append(r.test_passed)
        elif r.pipeline == "al_greenfield":
            by_project_alg.setdefault(r.project, []).append(r.test_passed)
        summary.total_llm_tokens += r.llm_total_tokens

    pa1_b = compute_pass_at_k(list(by_project_baseline.values()), k=summary.k_repeats)
    pa1_a = compute_pass_at_k(list(by_project_al.values()), k=summary.k_repeats)
    summary.pass_at_1_baseline = pa1_b.pass_at_1
    summary.pass_at_1_al = pa1_a.pass_at_1
    summary.pass_at_k_baseline = pa1_b.pass_at_k
    summary.pass_at_k_al = pa1_a.pass_at_k
    if by_project_alg:
        pa1_alg = compute_pass_at_k(list(by_project_alg.values()), k=summary.k_repeats)
        summary.pass_at_1_al_greenfield = pa1_alg.pass_at_1
        summary.pass_at_k_al_greenfield = pa1_alg.pass_at_k

    # Roundtrip tax over individual runs (not aggregated by project)
    bl_results = [r.test_passed for r in summary.results if r.pipeline == "baseline" and r.k_iter >= 0]
    al_results = [r.test_passed for r in summary.results if r.pipeline == "al" and r.k_iter >= 0]
    tax = compute_roundtrip_tax(bl_results, al_results)
    summary.tax_pp = tax.tax_pp
    summary.baseline_pass_pct = tax.baseline_pass_pct
    summary.al_pass_pct = tax.al_pass_pct

    # Phase 1.H'.F.2: commit0-aligned per-test pass rate:
    #   (sum_passing_with_xfail / sum_total) across all valid cells
    # If no cell has tests, percentage is 0 (not NaN).
    def _per_test_pct(pipeline: str) -> float:
        total = sum(r.test_total for r in summary.results
                    if r.pipeline == pipeline and r.k_iter >= 0)
        passed = sum(r.test_passing_with_xfail for r in summary.results
                     if r.pipeline == pipeline and r.k_iter >= 0)
        return (100.0 * passed / total) if total else 0.0

    summary.baseline_per_test_pct = _per_test_pct("baseline")
    summary.al_per_test_pct = _per_test_pct("al")
    summary.al_greenfield_per_test_pct = _per_test_pct("al_greenfield")
    summary.per_test_tax_pp = (
        summary.baseline_per_test_pct - summary.al_per_test_pct
    )
    summary.per_test_tax_pp_al_greenfield = (
        summary.baseline_per_test_pct - summary.al_greenfield_per_test_pct
    )

    # Round 0.2: best-iter aggregate.
    # For each cell, find its best iter (max test_passing_with_xfail);
    # sum those numerators over sum of that iter's test_total. This
    # ignores cells where no iter had collected any tests.
    def _best_iter_pct(pipeline: str) -> float:
        total = 0
        passed = 0
        for r in summary.results:
            if r.pipeline != pipeline or r.k_iter < 0:
                continue
            best_idx = r.best_iter_idx
            if best_idx < 0:
                continue
            # Find that iter's outcome and use its test_total
            for o in r.iter_outcomes:
                if o.get("iter") == best_idx and o.get("test_total", 0) > 0:
                    total += o["test_total"]
                    passed += r.best_iter_passing_with_xfail
                    break
        return (100.0 * passed / total) if total else 0.0

    summary.baseline_best_iter_pct = _best_iter_pct("baseline")
    summary.al_best_iter_pct = _best_iter_pct("al")
    summary.al_greenfield_best_iter_pct = _best_iter_pct("al_greenfield")
    summary.best_iter_tax_pp = (
        summary.baseline_best_iter_pct - summary.al_best_iter_pct
    )

    # Iter convergence histogram: for each pipeline, how many cells passed
    # on which iter idx (or -1 = never).
    def _iter_hist(pipeline: str) -> dict:
        hist: dict[str, int] = {}
        for r in summary.results:
            if r.pipeline != pipeline or r.k_iter < 0:
                continue
            key = (
                f"iter_{r.final_iter_idx}"
                if r.final_iter_idx >= 0 else "never_passed"
            )
            hist[key] = hist.get(key, 0) + 1
        return hist

    summary.iter_convergence_baseline = _iter_hist("baseline")
    summary.iter_convergence_al = _iter_hist("al")
    summary.iter_convergence_al_greenfield = _iter_hist("al_greenfield")

    # v0.7: binary all-pass% for al_greenfield. Mirrors how compute_roundtrip_tax
    # reports for AL — we just don't use the tax struct since that's pairwise.
    alg_results = [
        r.test_passed for r in summary.results
        if r.pipeline == "al_greenfield" and r.k_iter >= 0
    ]
    if alg_results:
        summary.al_greenfield_pass_pct = (
            100.0 * sum(alg_results) / len(alg_results)
        )


def _write_summary_files(out_dir: Path, summary: RunSummary) -> None:
    # run.json — full raw
    (out_dir / "run.json").write_text(
        json.dumps(asdict(summary), indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    # pass_at_k.json
    (out_dir / "pass_at_k.json").write_text(
        json.dumps({
            "k": summary.k_repeats,
            "n_projects": summary.n_projects,
            "baseline": {
                "pass_at_1": summary.pass_at_1_baseline,
                "pass_at_k": summary.pass_at_k_baseline,
            },
            "al": {
                "pass_at_1": summary.pass_at_1_al,
                "pass_at_k": summary.pass_at_k_al,
            },
        }, indent=2),
        encoding="utf-8",
    )
    # summary.md
    (out_dir / "summary.md").write_text(_format_summary_md(summary), encoding="utf-8")


def _format_summary_md(s: RunSummary) -> str:
    direction = (
        "agent-lang ↑ (gain)" if s.tax_pp < 0
        else "agent-lang ↓ (loss)" if s.tax_pp > 0
        else "tie"
    )
    has_alg = (
        s.al_greenfield_per_test_pct > 0
        or s.al_greenfield_pass_pct > 0
        or any(r.pipeline == "al_greenfield" for r in s.results)
    )
    alg_col = (
        f" | {s.al_greenfield_per_test_pct:.1f}%"
        if has_alg else ""
    )
    alg_header = " | agent-lang (greenfield)" if has_alg else ""

    headline_rows = [
        "| **per-test pass% (final iter)** | "
        f"**{s.baseline_per_test_pct:.1f}%** | "
        f"**{s.al_per_test_pct:.1f}%** | "
        f"{-s.per_test_tax_pp:+.1f} pp"
        + (f" | **{s.al_greenfield_per_test_pct:.1f}%** | "
           f"{-s.per_test_tax_pp_al_greenfield:+.1f} pp" if has_alg else "")
        + " |",
        "| per-test pass% (best iter) | "
        f"{s.baseline_best_iter_pct:.1f}% | "
        f"{s.al_best_iter_pct:.1f}% | "
        f"{-s.best_iter_tax_pp:+.1f} pp"
        + (f" | {s.al_greenfield_best_iter_pct:.1f}% | "
           f"{s.baseline_best_iter_pct - s.al_greenfield_best_iter_pct:+.1f} pp"
           if has_alg else "")
        + " |",
        f"| binary all-pass% (per-cell) | "
        f"{s.baseline_pass_pct:.1f}% | {s.al_pass_pct:.1f}% | "
        f"{-s.tax_pp:+.1f} pp"
        + (f" | {s.al_greenfield_pass_pct:.1f}% | "
           f"{s.baseline_pass_pct - s.al_greenfield_pass_pct:+.1f} pp"
           if has_alg else "")
        + " |",
        f"| pass^1 (any of {s.k_repeats}) | "
        f"{s.pass_at_1_baseline:.1%} | {s.pass_at_1_al:.1%} | —"
        + (f" | {s.pass_at_1_al_greenfield:.1%} | —" if has_alg else "")
        + " |",
        f"| pass^{s.k_repeats} (all of {s.k_repeats}) | "
        f"{s.pass_at_k_baseline:.1%} | {s.pass_at_k_al:.1%} | —"
        + (f" | {s.pass_at_k_al_greenfield:.1%} | —" if has_alg else "")
        + " |",
    ]
    headline_header = (
        "| 指标 | Baseline | agent-lang | Δ"
        + (" | agent-lang (greenfield) | Δ_C" if has_alg else "")
        + " |\n"
        + "|---|---|---|---"
        + ("|---|---" if has_alg else "")
        + "|\n"
    )
    headline_table = headline_header + "\n".join(headline_rows)

    iter_rows = [
        f"| baseline  | {s.iter_convergence_baseline.get('iter_0', 0)} | "
        f"{s.iter_convergence_baseline.get('iter_1', 0)} | "
        f"{s.iter_convergence_baseline.get('iter_2', 0)} | "
        f"{s.iter_convergence_baseline.get('never_passed', 0)} |",
        f"| al | {s.iter_convergence_al.get('iter_0', 0)} | "
        f"{s.iter_convergence_al.get('iter_1', 0)} | "
        f"{s.iter_convergence_al.get('iter_2', 0)} | "
        f"{s.iter_convergence_al.get('never_passed', 0)} |",
    ]
    if has_alg:
        iter_rows.append(
            f"| al_greenfield | "
            f"{s.iter_convergence_al_greenfield.get('iter_0', 0)} | "
            f"{s.iter_convergence_al_greenfield.get('iter_1', 0)} | "
            f"{s.iter_convergence_al_greenfield.get('iter_2', 0)} | "
            f"{s.iter_convergence_al_greenfield.get('never_passed', 0)} |"
        )

    return (
        f"# Benchmark Run — {s.timestamp}\n\n"
        f"**Projects**: {s.n_projects}  **k**: {s.k_repeats}  "
        f"**Max iterations per cell**: {MAX_ITERATIONS}  "
        f"**LLM tokens total**: {s.total_llm_tokens:,}\n\n"
        f"## Headline numbers\n\n"
        + headline_table + "\n\n"
        f"**往返税 (per-test, commit0-aligned)** = "
        f"baseline_per_test% - al_per_test% = "
        f"**{s.per_test_tax_pp:.1f} pp**\n\n"
        f"**往返税 (binary all-pass)** = "
        f"baseline_pass% - al_pass% = "
        f"**{s.tax_pp:.1f} pp**  →  {direction}\n\n"
        f"## Iter convergence (how many cells passed at which iter idx)\n\n"
        f"| pipeline | iter 0 | iter 1 | iter 2 | never |\n"
        f"|---|---|---|---|---|\n"
        + "\n".join(iter_rows)
        + "\n\n## Per-project pass^1\n\n"
        + _per_repo_table(s)
    )


def _per_repo_table(s: RunSummary) -> str:
    """Build a per-repo pass table whose columns adapt to which pipelines
    actually ran in this summary."""
    has_alg = any(r.pipeline == "al_greenfield" for r in s.results)
    header = (
        "| repo | baseline | al"
        + (" | al_greenfield" if has_alg else "")
        + f" | k |\n"
        "|---|---|---"
        + ("|---" if has_alg else "")
        + "|---|\n"
    )
    return header + "\n".join(_per_repo_lines(s)) + "\n"


def _per_repo_lines(s: RunSummary) -> list[str]:
    has_alg = any(r.pipeline == "al_greenfield" for r in s.results)
    pipelines = ["baseline", "al"] + (["al_greenfield"] if has_alg else [])
    by_proj: dict[str, dict[str, list[bool]]] = {}
    for r in s.results:
        if r.k_iter < 0:
            continue
        by_proj.setdefault(r.project, {p: [] for p in pipelines})
        if r.pipeline in by_proj[r.project]:
            by_proj[r.project][r.pipeline].append(r.test_passed)
    lines = []
    for proj, d in by_proj.items():
        cells = [
            f"{sum(d[p])}/{len(d[p])}" for p in pipelines
        ]
        lines.append(f"| {proj} | " + " | ".join(cells) + f" | {s.k_repeats} |")
    return lines
