"""MBPP benchmark adapter for Phase F.

Loads the 500 problems from HuggingFace ``mbpp`` test split and adapts
them to the same operations the commit0 / HumanEval adapters provide.

Per-problem flow:
  1. Read text (NL spec) + code (canonical solution) + test_list (asserts).
  2. ast-parse ``code`` to find the function name + signature line.
  3. ``setup_workdir`` writes ``solution.py = <signature> + "    pass"`` —
     the LLM sees the signature + the NL text becomes the "spec".
  4. ``run_tests`` writes the test runner: ``solution.py + test_setup_code +
     ASSERT_LINES`` and execs via subprocess; exit 0 = pass.
"""

from __future__ import annotations

import ast
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

from benchmarks.harness.commit0_adapter import TestResult


@dataclass
class MBPPProblem:
    """One MBPP problem. ``task_id`` is an integer; we sanitize to
    ``mbpp_<id>`` for filesystem use."""

    task_id: int
    text: str
    code: str
    """Canonical solution — full def with body. We parse this to find the
    function name and signature for the stub."""
    test_list: list[str]
    test_setup_code: str = ""

    @property
    def name(self) -> str:
        return f"mbpp_{self.task_id}"

    @property
    def path(self) -> Path:
        return Path(f"<mbpp:{self.name}>")

    @property
    def spec_path(self) -> Path:
        return Path("<mbpp-spec>")

    @property
    def entry_point(self) -> str:
        """The function name — extracted from the canonical ``code``."""
        for node in ast.parse(self.code).body:
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                return node.name
        raise ValueError(f"MBPP problem {self.task_id}: no function in canonical code")

    @property
    def signature_line(self) -> str:
        """Just the ``def name(args):`` line (possibly with decorators)
        from the canonical solution — used to seed the stub."""
        tree = ast.parse(self.code)
        for node in tree.body:
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                # Reconstruct via ast.unparse — easier than slicing source.
                head_args = ast.unparse(ast.arguments(
                    posonlyargs=node.args.posonlyargs,
                    args=node.args.args,
                    vararg=node.args.vararg,
                    kwonlyargs=node.args.kwonlyargs,
                    kw_defaults=node.args.kw_defaults,
                    kwarg=node.args.kwarg,
                    defaults=node.args.defaults,
                ))
                deco_lines = ""
                for d in node.decorator_list:
                    deco_lines += "@" + ast.unparse(d) + "\n"
                async_kw = "async " if isinstance(node, ast.AsyncFunctionDef) else ""
                ret_ann = ""
                if node.returns is not None:
                    ret_ann = " -> " + ast.unparse(node.returns)
                return (
                    deco_lines
                    + f"{async_kw}def {node.name}({head_args}){ret_ann}:"
                )
        raise ValueError(f"MBPP problem {self.task_id}: no function in canonical code")


def list_problems(
    *, split: str = "test", limit: int | None = None,
) -> list[MBPPProblem]:
    """Load MBPP. Default ``split="test"`` (500 problems). Returns first
    ``limit`` if set, else all."""
    from datasets import load_dataset
    ds = load_dataset("mbpp")[split]
    out: list[MBPPProblem] = []
    for i, row in enumerate(ds):
        if limit is not None and i >= limit:
            break
        out.append(MBPPProblem(
            task_id=row["task_id"],
            text=row["text"],
            code=row["code"],
            test_list=list(row["test_list"]),
            test_setup_code=row.get("test_setup_code") or "",
        ))
    return out


def setup_workdir(problem: MBPPProblem, workdir: Path) -> Path:
    """Create stripped workdir. ``solution.py = signature + "    pass"``."""
    workdir.mkdir(parents=True, exist_ok=True)
    solution_path = workdir / "solution.py"
    stub = problem.signature_line + "\n    pass\n"
    solution_path.write_text(stub, encoding="utf-8")
    return workdir


def load_spec(problem: MBPPProblem) -> str:
    """The MBPP NL description + canonical signature. The LLM sees this
    as the function contract."""
    return (
        f"# Task: {problem.text}\n"
        f"#\n"
        f"# Signature:\n"
        f"# {problem.signature_line}\n"
        f"#\n"
        f"# Sample assertions:\n"
        + "\n".join(f"# {t}" for t in problem.test_list[:3])
    )


def collect_stripped_files(workdir: Path) -> dict[str, str]:
    sol = workdir / "solution.py"
    if not sol.exists():
        return {}
    return {"solution.py": sol.read_text(encoding="utf-8")}


def run_tests(
    problem: MBPPProblem, workdir: Path,
    *, skip_install: bool = False, timeout: int = 30,
) -> TestResult:
    """Execute MBPP tests. Concatenates solution + test_setup_code +
    test_list and runs via subprocess. Total = len(test_list); passed =
    number of asserts that ran without AssertionError."""
    from benchmarks.harness.commit0_adapter import ProjectRef
    sol_path = workdir / "solution.py"
    if not sol_path.exists():
        return _fail(problem, "solution.py missing", workdir)
    sol_src = sol_path.read_text(encoding="utf-8")

    # Build test runner. Each assert in its own try/except so we count
    # per-assert pass/fail rather than first-fail-stops-all.
    setup_block = problem.test_setup_code or ""
    assertions = []
    for i, t in enumerate(problem.test_list):
        assertions.append(
            f"try:\n"
            f"    {t.strip()}\n"
            f"    print('PASS_{i}')\n"
            f"except AssertionError:\n"
            f"    print('FAIL_{i}')\n"
            f"except Exception as e:\n"
            f"    print('ERR_{i}', repr(e))\n"
        )
    test_runner_path = workdir / "_solution_test.py"
    test_runner_path.write_text(
        sol_src + "\n\n" + setup_block + "\n\n" + "\n".join(assertions),
        encoding="utf-8",
    )

    try:
        # Resolve to absolute (see humaneval.py for rationale).
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

    out = (result.stdout or b"").decode("utf-8", errors="replace")
    err = (result.stderr or b"").decode("utf-8", errors="replace")
    total = len(problem.test_list)
    passed = out.count("PASS_")
    failed = out.count("FAIL_") + out.count("ERR_")

    ref = ProjectRef(name=problem.name, path=workdir, spec_path=workdir / "<inline>")
    return TestResult(
        project=ref,
        total=total,
        passed=passed,
        failed=failed,
        duration_sec=0.0,
        json_report_ok=True,
        raw_stdout=out + err,
        exit_code=result.returncode,
    )


def _fail(problem: MBPPProblem, reason: str, workdir: Path) -> TestResult:
    from benchmarks.harness.commit0_adapter import ProjectRef
    ref = ProjectRef(name=problem.name, path=workdir, spec_path=workdir / "<inline>")
    return TestResult(
        project=ref,
        total=len(problem.test_list) or 1, passed=0,
        failed=len(problem.test_list) or 1,
        duration_sec=0.0, json_report_ok=False,
        raw_stdout=f"<adapter error> {reason}",
    )
