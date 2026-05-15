"""Commit0 adapter — subprocess wrapper around the ``commit0`` CLI.

Phase ①.1.A 状态：可用。包装 ``commit0 setup`` / ``commit0 get-tests`` /
``commit0 test`` 三条命令，本机执行（``backend: local`` 默认）。

Why subprocess: 不重新实现 commit0 的测试隔离 / dataset 下载 / repo
clone。commit0 已经做对了，我们只关心 (skeleton, py_dir) → pass/fail。

Reference protocol from ``docs/design/benchmark.md``:
    1. ``list_projects()``  enumerate available split names
    2. ``setup_split(...)`` materialize repos under workdir
    3. ``load_skeleton(p, workdir)`` produce a SkeletonRepo for one project
    4. ``run_tests(p, py_dir)`` run pytest, return TestResult
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


# ---------------------------------------------------------------------------
# Data classes (interface stable since Phase ①.0)
# ---------------------------------------------------------------------------


@dataclass
class ProjectRef:
    """Pointer to a Commit0 project (one Python library / repo)."""

    name: str
    path: Path
    spec_path: Path | None = None

    @property
    def src_files(self) -> list[Path]:
        """List Python files under the project src/ tree. Empty if not set up."""
        if not self.path.exists():
            return []
        # Common layouts: <repo>/<pkg>/*.py or <repo>/src/<pkg>/*.py
        out: list[Path] = []
        for candidate in self.path.rglob("*.py"):
            # Skip tests + build artifacts
            parts = candidate.parts
            if any(p in {"tests", "test", "build", "dist", "__pycache__", ".git"} for p in parts):
                continue
            out.append(candidate)
        return out

    @property
    def test_count(self) -> int:
        """Number of test functions (rough — `def test_` occurrences)."""
        n = 0
        for p in self.path.rglob("test_*.py"):
            try:
                n += len(re.findall(r"^\s*def\s+test_", p.read_text(encoding="utf-8"), re.MULTILINE))
            except (OSError, UnicodeDecodeError):
                continue
        return n


@dataclass
class SkeletonRepo:
    """A materialized starter repo (stripped to skeletons) ready for pipelines."""

    project: ProjectRef
    workdir: Path
    spec_text: str = ""
    python_files: list[Path] = field(default_factory=list)

    @classmethod
    def from_project(cls, project: ProjectRef, workdir: Path) -> "SkeletonRepo":
        """Build skeleton view of an already-setup project."""
        spec = ""
        if project.spec_path and project.spec_path.exists():
            spec = project.spec_path.read_text(encoding="utf-8", errors="replace")
        return cls(
            project=project,
            workdir=workdir,
            spec_text=spec,
            python_files=project.src_files,
        )


@dataclass
class TestResult:
    """Pytest outcome via ``commit0 test``. Roundtrip tax computed across runs."""

    # Tell pytest not to try collecting this dataclass as a test class.
    __test__ = False

    project: ProjectRef
    total: int = 0
    passed: int = 0
    failed: int = 0
    errored: int = 0
    skipped: int = 0
    # Phase 1.H'.F.2: commit0-aligned fields (parsed from
    # pytest-json-report report.json when available).
    xfailed: int = 0  # tests marked xfail that did fail (commit0 counts as pass)
    xpassed: int = 0  # tests marked xfail that unexpectedly passed
    collection_errors: int = 0  # outcome="error" — distinct from "failed"
    json_report_ok: bool = False  # True if report.json was parsed cleanly
    duration_sec: float = 0.0
    failures: list[str] = field(default_factory=list)
    raw_stdout: str = ""
    raw_stderr: str = ""
    exit_code: int = 0

    @property
    def all_passed(self) -> bool:
        """True iff at least 1 test ran AND none failed/errored."""
        return self.total > 0 and self.failed == 0 and self.errored == 0

    @property
    def passed_with_xfail(self) -> int:
        """commit0's pass-rate numerator: passed + xfail.

        Aligns with ``commit0/harness/evaluate.py:139``:
            passed = (status["passed"] + status["xfail"]) / sum(status.values())
        """
        return self.passed + self.xfailed


# ---------------------------------------------------------------------------
# Known split names (from ``commit0 setup --help`` enumeration)
# ---------------------------------------------------------------------------


#: All single-repo splits supported by ``commit0 setup``. Each maps to one
#: Python library that gets cloned + stripped under base_dir/<name>.
SINGLE_REPO_SPLITS: tuple[str, ...] = (
    "statsmodels", "python-progressbar", "xarray", "imbalanced-learn",
    "web3.py", "scrapy", "seaborn", "pypdf", "pexpect", "pytest", "pylint",
    "joblib", "dulwich", "virtualenv", "minitorch", "networkx", "requests",
    "sphinx", "jedi", "moviepy", "loguru", "paramiko", "geopandas",
    "bitstring", "fastapi", "chardet", "tornado", "python-prompt-toolkit",
    "attrs", "PyBoy", "pydantic", "filesystem_spec", "tlslite-ng", "graphene",
    "mimesis", "babel", "dnspython", "portalocker", "cookiecutter", "pyjwt",
    "python-rsa", "more-itertools", "simpy", "click", "fabric", "jinja",
    "flask", "sqlparse", "marshmallow", "imapclient", "tinydb", "cachetools",
    "voluptuous", "parsel", "wcwidth", "deprecated",
)

#: Aggregate splits (multi-repo).
AGGREGATE_SPLITS: tuple[str, ...] = ("all", "lite")


# ---------------------------------------------------------------------------
# Subprocess helpers
# ---------------------------------------------------------------------------


def _run_commit0(
    args: list[str],
    *,
    cwd: Path | None = None,
    check: bool = False,
    capture: bool = True,
    timeout: float | None = None,
) -> subprocess.CompletedProcess:
    """Invoke ``commit0 <args>`` as subprocess."""
    cmd = ["commit0", *args]
    return subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        check=check,
        capture_output=capture,
        text=True,
        timeout=timeout,
    )


def commit0_available() -> bool:
    """Return True iff ``commit0`` CLI is on PATH and prints --help."""
    try:
        r = _run_commit0(["--help"], timeout=15)
        return r.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


# ---------------------------------------------------------------------------
# list_projects
# ---------------------------------------------------------------------------


def list_projects(base_dir: Path | None = None) -> Iterable[ProjectRef]:
    """Enumerate Commit0 projects available to setup.

    Returns:
        ProjectRef per split, with ``path = base_dir/<name>``. ``path`` may
        not exist yet if the split hasn't been ``setup_split``-ed.

    Args:
        base_dir: Where ``commit0 setup`` would write repos. Defaults to
            ``thirdparty/commit0_repos/`` (sister to the submodule).
    """
    base_dir = base_dir or _default_repos_dir()
    base_dir.mkdir(parents=True, exist_ok=True)
    for name in SINGLE_REPO_SPLITS:
        path = base_dir / name
        spec = _find_spec_pdf(path) if path.exists() else None
        yield ProjectRef(name=name, path=path, spec_path=spec)


# ---------------------------------------------------------------------------
# setup_split
# ---------------------------------------------------------------------------


def setup_split(
    split: str,
    base_dir: Path | None = None,
    *,
    config_file: Path | None = None,
    dataset_name: str = "wentingzhao/commit0_combined",
) -> Path:
    """Run ``commit0 setup <split> --base-dir <base_dir>``.

    Returns the absolute ``base_dir`` used. The actual repos appear under
    ``base_dir/<repo_name>``.

    Raises:
        RuntimeError if the subprocess returns non-zero.
    """
    base_dir = (base_dir or _default_repos_dir()).resolve()
    base_dir.mkdir(parents=True, exist_ok=True)

    args = [
        "setup", split,
        "--base-dir", str(base_dir),
        "--dataset-name", dataset_name,
    ]
    if config_file is not None:
        args += ["--commit0-config-file", str(config_file.resolve())]

    r = _run_commit0(args, timeout=600)
    if r.returncode != 0:
        raise RuntimeError(
            f"commit0 setup {split!r} failed (exit {r.returncode}):\n"
            f"stdout:\n{r.stdout}\nstderr:\n{r.stderr}"
        )
    return base_dir


# ---------------------------------------------------------------------------
# load_skeleton
# ---------------------------------------------------------------------------


def load_skeleton(project: ProjectRef, workdir: Path) -> SkeletonRepo:
    """Copy ``project`` into ``workdir`` and build a SkeletonRepo view.

    The source ``project.path`` is what ``setup_split`` produced; we copy
    it so pipelines can mutate ``workdir`` without contaminating the
    canonical setup. ``workdir`` must not exist (we create it).
    """
    if not project.path.exists():
        raise FileNotFoundError(
            f"project {project.name!r} not yet set up at {project.path}. "
            f"Call setup_split() first."
        )
    if workdir.exists():
        shutil.rmtree(workdir)
    shutil.copytree(project.path, workdir, ignore=shutil.ignore_patterns(
        ".git", "__pycache__", ".pytest_cache", ".mypy_cache",
    ))

    # Re-anchor the project pointer to the workdir copy
    copied = ProjectRef(
        name=project.name,
        path=workdir,
        spec_path=_find_spec_pdf(workdir),
    )
    return SkeletonRepo.from_project(copied, workdir)


# ---------------------------------------------------------------------------
# run_tests
# ---------------------------------------------------------------------------


# commit0 dataset ships per-instance `test_cmd` strings (mostly bare
# ``pytest``; parsel needs special flags). We mirror that exactly so
# each repo's own pyproject.toml / setup.cfg / pytest.ini drives test
# discovery — hardcoding ``pytest tests/`` was a Phase 1.H bug that
# silently dropped data for any repo whose test root differs from
# ``tests/`` (voluptuous → ``voluptuous/tests/``; portalocker →
# ``portalocker_tests/``; chardet → ``test.py`` at root via
# ``python_files = test.py``).
PER_REPO_PYTEST_ARGS: dict[str, list[str]] = {
    # parsel: dataset says `pytest --assert=plain --ignore=setup.py`
    "parsel": ["--assert=plain", "--ignore=setup.py"],
}


def run_tests(
    project: ProjectRef,
    py_dir: Path | None = None,
    *,
    branch: str | None = None,  # unused — kept for backward compat
    timeout: int = 600,
    backend: str = "local",  # unused — direct pytest below
    config_file: Path | None = None,  # unused
    skip_install: bool = False,
) -> TestResult:
    """Run the project's pytest suite directly in ``py_dir``.

    We bypass ``commit0 test``'s git/docker workflow (which requires the
    impl code to be committed to a branch in the canonical commit0 repo)
    and instead:

      1. (optional) ``pip install -e .`` inside py_dir so the package is
         importable under its real name (e.g. ``import cachetools``).
         Skipped when ``skip_install=True`` — useful after the first iter
         of a cell, since the editable install metadata under
         ``<pkg>.egg-info`` survives file-level revert and pytest can
         still import the package without re-running pip (saves
         5-30s per iter on big repos).
      2. bare ``pytest -v --tb=short --no-header -q`` (no path arg) so
         the repo's own pytest config drives test discovery — matches
         what commit0's dataset specifies in its per-instance ``test_cmd``
         field.

    This is functionally equivalent to commit0 test's ``--backend local``
    path but works on an arbitrary py_dir (the runner's workdir copy)
    instead of forcing a git branch dance.
    """
    target = py_dir or project.path
    if not target.exists():
        raise FileNotFoundError(f"test target dir does not exist: {target}")

    install: subprocess.CompletedProcess | None = None
    if not skip_install:
        # 1. Install package (so `import <pkg>` works in pytest).
        install = subprocess.run(
            ["pip", "install", "-e", ".", "--quiet", "--no-deps"],
            cwd=str(target),
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
        )
        # If install fails we still try pytest — sometimes the package is
        # already importable via PYTHONPATH or the failure is in optional deps.

    # 2. pytest — NO path arg; let each repo's pytest config find tests.
    #
    # Phase 1.H'.F.2 commit0 alignment:
    #   --json-report --json-report-file=.pytest-report.json   structured output
    #   --continue-on-collection-errors                        don't kill repo
    #                                                           on a single
    #                                                           ImportError
    # We still keep the regex parser as a fallback in case pytest-json-report
    # isn't installed.
    extra = PER_REPO_PYTEST_ARGS.get(project.name, [])
    json_report_path = target / ".pytest-report.json"
    if json_report_path.exists():
        try:
            json_report_path.unlink()
        except OSError:
            pass
    pytest_args = [
        "pytest",
        *extra,
        "--json-report",
        "--json-report-file=.pytest-report.json",
        "--continue-on-collection-errors",
        "-v", "--tb=short", "--no-header",
        "-q",
    ]
    r = subprocess.run(
        pytest_args,
        cwd=str(target),
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
    )
    # Compose stdout for parser (include install stderr for debugging if
    # pytest produced nothing).
    fallback_stdout = install.stdout if install else ""
    fallback_stderr = install.stderr if install else ""
    combined = subprocess.CompletedProcess(
        args=pytest_args,
        returncode=r.returncode,
        stdout=r.stdout or fallback_stdout,
        stderr=r.stderr or fallback_stderr,
    )
    return _parse_pytest_result(project, combined, json_report_path)


def _parse_pytest_result(
    project: "ProjectRef",
    r: subprocess.CompletedProcess,
    json_report_path: Path,
) -> "TestResult":
    """Parse a pytest run. Prefer pytest-json-report; fallback to regex.

    Phase 1.H'.F.2: structured-first parser. If ``.pytest-report.json`` is
    present and decodes cleanly, count outcomes per-test (passed / failed /
    xfail / xpassed / error / skipped). This matches commit0's
    ``commit0/harness/evaluate.py`` aggregation exactly. Otherwise fall
    back to the legacy summary-line regex parser.
    """
    if json_report_path.exists():
        try:
            data = json.loads(json_report_path.read_text(encoding="utf-8"))
            return _parse_pytest_json_report(project, r, data)
        except (json.JSONDecodeError, OSError, KeyError, TypeError):
            # Corrupted report or unexpected shape — fall through.
            pass
    return _parse_pytest_output(project, r)


def _parse_pytest_json_report(
    project: "ProjectRef",
    r: subprocess.CompletedProcess,
    data: dict,
) -> "TestResult":
    """Parse ``.pytest-report.json`` (pytest-json-report plugin output).

    Schema (per https://pypi.org/project/pytest-json-report/):
        {
          "created": <timestamp>,
          "duration": <float>,
          "exitcode": <int>,
          "summary": {
              "passed": N, "failed": N, "error": N, "skipped": N,
              "xfailed": N, "xpassed": N, "total": N, ...
          },
          "tests": [
              {"nodeid": "...", "outcome": "passed"|"failed"|"xfailed"
                                |"xpassed"|"skipped"|"error", ...},
              ...
          ],
          "collectors": [{"nodeid": ..., "outcome": ..., "longrepr": ...}, ...]
        }
    """
    summary = data.get("summary") or {}
    tests = data.get("tests") or []
    duration = float(data.get("duration") or 0.0)

    passed = int(summary.get("passed") or 0)
    failed = int(summary.get("failed") or 0)
    errored = int(summary.get("error") or 0)
    skipped = int(summary.get("skipped") or 0)
    xfailed = int(summary.get("xfailed") or 0)
    xpassed = int(summary.get("xpassed") or 0)
    total = int(summary.get("total") or (passed + failed + errored + skipped + xfailed + xpassed))

    # Per-test failures list (for debugging in WebUI / decision report).
    failures = [
        t.get("nodeid", "?")
        for t in tests
        if t.get("outcome") in ("failed", "error")
    ][:50]

    # Collection errors (test file failed to import) show up in
    # ``collectors`` with outcome="failed". commit0 counts these too.
    collection_errors = sum(
        1 for c in (data.get("collectors") or [])
        if c.get("outcome") == "failed"
    )

    return TestResult(
        project=project,
        total=total,
        passed=passed,
        failed=failed,
        errored=errored,
        skipped=skipped,
        xfailed=xfailed,
        xpassed=xpassed,
        collection_errors=collection_errors,
        json_report_ok=True,
        duration_sec=duration,
        failures=failures,
        raw_stdout=r.stdout,
        raw_stderr=r.stderr,
        exit_code=r.returncode,
    )


_SUMMARY_LINE_RE = re.compile(r"==.*?in\s+([\d.]+)s")
_PASSED_RE = re.compile(r"(\d+)\s+passed")
_FAILED_RE = re.compile(r"(\d+)\s+failed")
_ERRORED_RE = re.compile(r"(\d+)\s+error")
_SKIPPED_RE = re.compile(r"(\d+)\s+skipped")


def _parse_pytest_output(
    project: ProjectRef,
    r: subprocess.CompletedProcess,
) -> TestResult:
    """Best-effort pytest result parser from commit0 stdout.

    Two-step parse:
      1. Find the line containing ``in <X>s`` between ``==`` (pytest summary).
      2. On that line, search each count keyword separately.

    Falls back to exit-code-only result if no summary line matches.
    """
    result = TestResult(
        project=project,
        exit_code=r.returncode,
        raw_stdout=r.stdout,
        raw_stderr=r.stderr,
    )

    summary_line: str | None = None
    duration: float = 0.0
    for line in r.stdout.splitlines():
        m = _SUMMARY_LINE_RE.search(line)
        if m:
            summary_line = line
            duration = float(m.group(1))
    if summary_line is not None:
        def _grab(rx: re.Pattern[str]) -> int:
            mm = rx.search(summary_line)  # type: ignore[arg-type]
            return int(mm.group(1)) if mm else 0
        passed = _grab(_PASSED_RE)
        failed = _grab(_FAILED_RE)
        errored = _grab(_ERRORED_RE)
        skipped = _grab(_SKIPPED_RE)
        result.passed = passed
        result.failed = failed
        result.errored = errored
        result.skipped = skipped
        result.total = passed + failed + errored + skipped
        result.duration_sec = duration

    for line in r.stdout.splitlines():
        if line.startswith("FAILED "):
            result.failures.append(line[len("FAILED "):].strip())

    return result


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def commit0_root() -> Path:
    """Absolute path to ``thirdparty/commit0/`` (the submodule)."""
    here = Path(__file__).resolve()
    return here.parents[2] / "thirdparty" / "commit0"


def _default_repos_dir() -> Path:
    """Where ``commit0 setup`` materializes repos (sister to submodule)."""
    here = Path(__file__).resolve()
    return here.parents[2] / "thirdparty" / "commit0_repos"


def _find_spec_pdf(project_dir: Path) -> Path | None:
    """Locate the per-project spec PDF / docstring file, if any.

    commit0 ships spec as PDF (newer) or README/docstring (older).
    Look in priority order: spec*.pdf → README.md → docs/.
    """
    if not project_dir.exists():
        return None
    for pat in ("spec*.pdf", "SPEC*.pdf"):
        for cand in project_dir.glob(f"**/{pat}"):
            return cand
    for pat in ("README.md", "README.rst", "README.txt"):
        cand = project_dir / pat
        if cand.exists():
            return cand
    return None
