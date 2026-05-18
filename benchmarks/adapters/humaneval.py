"""HumanEval benchmark adapter for Phase F.

Loads the 164 problems from HuggingFace ``openai_humaneval`` and exposes
the same operations the commit0 adapter does, so ``runner.run_pipeline``
can drive HumanEval cells through the same A/B/C three-pipeline machinery.

Per-problem flow:
  1. Read prompt + entry_point + test from the dataset.
  2. setup_workdir writes ``solution.py = prompt + "    pass\\n"`` —
     this is the stripped state the LLM (or AL pipeline) sees.
  3. Pipeline A / B / C fills it.
  4. run_tests writes a runner: ``<solution.py> + test_body + check(entry_point)``
     to ``solution_test.py`` and execs via subprocess; exit 0 = pass.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

from benchmarks.harness.commit0_adapter import TestResult


@dataclass
class HumanEvalProblem:
    """One HumanEval problem. ``task_id`` doubles as the project name in
    ``runner.run_pipeline`` (cells are keyed by ``project.name``)."""

    task_id: str
    """e.g. ``HumanEval/0`` → we sanitize to ``humaneval_0`` for filesystem."""

    prompt: str
    """Function signature + docstring + helper imports."""

    entry_point: str
    """The function name the tests will call."""

    test: str
    """The ``check(candidate)`` test body."""

    canonical_solution: str
    """Reference impl — only for analysis, never injected."""

    @property
    def name(self) -> str:
        """Filesystem-safe project name."""
        return self.task_id.replace("/", "_").lower()

    @property
    def path(self) -> Path:
        """Synthetic — the workdir created by setup_workdir below."""
        return Path(f"<humaneval:{self.name}>")  # placeholder; set by setup_workdir

    @property
    def spec_path(self) -> Path:
        return Path("<humaneval-spec>")


def list_problems(*, limit: int | None = None) -> list[HumanEvalProblem]:
    """Load HumanEval dataset. Returns the first ``limit`` problems if set,
    else all 164. Cached via HuggingFace datasets default cache."""
    from datasets import load_dataset
    ds = load_dataset("openai_humaneval")["test"]
    out: list[HumanEvalProblem] = []
    for i, row in enumerate(ds):
        if limit is not None and i >= limit:
            break
        out.append(HumanEvalProblem(
            task_id=row["task_id"],
            prompt=row["prompt"],
            entry_point=row["entry_point"],
            test=row["test"],
            canonical_solution=row["canonical_solution"],
        ))
    return out


def setup_workdir(problem: HumanEvalProblem, workdir: Path) -> Path:
    """Create a stripped workdir containing ``solution.py`` with the prompt
    + a ``pass`` body. Returns the workdir path. Idempotent.
    """
    workdir.mkdir(parents=True, exist_ok=True)
    solution_path = workdir / "solution.py"
    stub_body = problem.prompt
    if not stub_body.endswith("\n"):
        stub_body += "\n"
    stub_body += "    pass\n"
    solution_path.write_text(stub_body, encoding="utf-8")
    return workdir


def load_spec(problem: HumanEvalProblem) -> str:
    """Return the problem's spec text — for HumanEval, the prompt itself
    (function signature + docstring) IS the spec."""
    return problem.prompt


def collect_stripped_files(workdir: Path) -> dict[str, str]:
    """Return ``{relpath: source}`` for files the LLM should see + fill.

    For HumanEval there's exactly one file: ``solution.py``.
    """
    sol = workdir / "solution.py"
    if not sol.exists():
        return {}
    return {"solution.py": sol.read_text(encoding="utf-8")}


def run_tests(
    problem: HumanEvalProblem, workdir: Path,
    *, skip_install: bool = False, timeout: int = 30,
) -> TestResult:
    """Execute the problem's test via subprocess. Returns a TestResult shaped
    like commit0's: total=1, passed=1 iff exit 0.

    Builds a temp ``solution_test.py`` = ``solution.py`` source + test +
    ``check(<entry_point>)`` then ``python solution_test.py``.
    """
    from benchmarks.harness.commit0_adapter import ProjectRef
    sol_path = workdir / "solution.py"
    if not sol_path.exists():
        return _fail(problem, "solution.py missing", workdir)
    sol_src = sol_path.read_text(encoding="utf-8")
    test_runner_path = workdir / "_solution_test.py"
    test_runner_path.write_text(
        sol_src + "\n\n" + problem.test + f"\n\ncheck({problem.entry_point})\n",
        encoding="utf-8",
    )
    try:
        # Resolve to absolute — when workdir is relative and we pass
        # cwd=workdir, Python would interpret the test_runner_path
        # relative to cwd (i.e. workdir + workdir + filename).
        result = subprocess.run(
            [sys.executable, str(test_runner_path.resolve())],
            cwd=str(workdir.resolve()),
            capture_output=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return _fail(problem, f"timeout after {timeout}s", workdir)
    except Exception as e:
        return _fail(problem, f"subprocess error: {e!r}", workdir)
    passed = result.returncode == 0
    # Synthetic ProjectRef so the result slots into the commit0 TestResult shape.
    ref = ProjectRef(name=problem.name, path=workdir, spec_path=workdir / "<inline>")
    # ``all_passed`` and ``passed_with_xfail`` are @property — derived from
    # passed/failed/xfailed below. Don't pass them as kwargs.
    return TestResult(
        project=ref,
        total=1,
        passed=1 if passed else 0,
        failed=0 if passed else 1,
        duration_sec=0.0,
        json_report_ok=True,
        raw_stdout=(result.stdout or b"").decode("utf-8", errors="replace") +
                   (result.stderr or b"").decode("utf-8", errors="replace"),
        exit_code=result.returncode,
    )


def _fail(problem: HumanEvalProblem, reason: str, workdir: Path) -> TestResult:
    from benchmarks.harness.commit0_adapter import ProjectRef
    ref = ProjectRef(name=problem.name, path=workdir, spec_path=workdir / "<inline>")
    return TestResult(
        project=ref,
        total=1, passed=0, failed=1,
        duration_sec=0.0, json_report_ok=False,
        raw_stdout=f"<adapter error> {reason}",
    )
