"""CLI entry for the benchmark runner.

Usage:
    python -m benchmarks.harness --mock --n-projects 2 --k-repeats 2
    python -m benchmarks.harness --real --n-projects 5 --k-repeats 5
    python -m benchmarks.harness --use-claude-code --n-projects 16 --k-repeats 3

Real mode uses :class:`al.llm.OpenAICompatClient` (an OpenAI-compatible
HTTP client) configured via .env. Default resolution order for env vars:
``LLM_API_KEY`` > ``OPENAI_API_KEY`` > ``YUNWU_API_KEY`` (same for
``_BASE_URL`` / ``_MODEL``).

``--use-claude-code`` mode uses :class:`al.llm.ClaudeCodeClient`
(wraps the ``claude -p`` subprocess CLI) for Anthropic-format gateways.

Mock mode uses MockLLMClient + a stub run_tests (everything 'passes')
just to validate plumbing end-to-end without LLM cost.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from al.llm import (
    ClaudeCodeClient,
    MockLLMClient,
    OpenAICompatClient,
    load_api_config,
)
from al.llm.claude_code import ClaudeCodeConfig
from benchmarks.harness.commit0_adapter import (
    ProjectRef,
    TestResult,
    list_projects,
    run_tests as real_run_tests,
    setup_split,
)
from benchmarks.harness.runner import run_pipeline
from benchmarks.harness.V1_SUBSET import V1_SUBSET


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="benchmarks.harness",
        description="Phase 1 benchmark — agent-lang scaffolded vibe coding vs direct",
    )
    parser.add_argument("--real", action="store_true",
                        help="use real OpenAICompatClient + commit0 test runner")
    parser.add_argument("--mock", action="store_true",
                        help="use MockLLMClient + stub run_tests (default)")
    parser.add_argument("--use-claude-code", action="store_true",
                        help="use Claude Code CLI (subprocess `claude -p`) as LLM "
                             "backend — requires ANTHROPIC_* env vars. "
                             "Intended for the Docker container scenario.")
    parser.add_argument("--n-projects", type=int, default=len(V1_SUBSET))
    parser.add_argument("--k-repeats", type=int, default=5)
    parser.add_argument("--project-names", type=str, default=None,
                        help="comma-separated subset of V1_SUBSET to run (e.g. "
                             "'cachetools,wcwidth'). Overrides --n-projects.")
    parser.add_argument("--out-dir", type=Path, default=None)
    parser.add_argument("--temperature", type=float, default=0.0)
    parser.add_argument("--setup-only", action="store_true",
                        help="just run commit0 setup for V1_SUBSET, then exit")
    parser.add_argument("--parallel-cells", type=int, default=1,
                        help="run independent (project, k, pipeline) cells in "
                             "a thread pool with N workers. Defaults to 1 "
                             "(sequential). Set to 4-8 for big runs.")
    args = parser.parse_args(argv)

    if args.setup_only:
        return _do_setup_only()

    use_claude_code = args.use_claude_code
    use_real = args.real and not args.mock and not use_claude_code

    if use_claude_code:
        import os as _os
        # Phase 1.H'.F.2: build a model pool from env. Goes down sporadically
        # on traxnode but adjacent variants in the same family rarely down
        # together. Override via CLAUDE_CODE_MODEL_POOL (comma-separated).
        # Empty → no pool, fall back to env var.
        #
        # Known sibling pairs (head = preferred, tail = failover):
        #   - gpt-5.4 / gpt-5.5            (current default, "openai 自营" group)
        #   - gemini-3-flash / -preview    (legacy "gemini 自营" group)
        pool_env = _os.environ.get("CLAUDE_CODE_MODEL_POOL", "")
        if pool_env.strip():
            model_pool = [m.strip() for m in pool_env.split(",") if m.strip()]
        else:
            env_model = _os.environ.get("ANTHROPIC_DEFAULT_OPUS_MODEL", "")
            # Auto-pair env_model with a known sibling for resilience.
            _SIBLING_PAIRS = {
                "gpt-5.4": "gpt-5.5",
                "gpt-5.5": "gpt-5.4",
                "gemini-3-flash": "gemini-3-flash-preview",
                "gemini-3-flash-preview": "gemini-3-flash",
            }
            sibling = _SIBLING_PAIRS.get(env_model)
            if sibling:
                model_pool = [env_model, sibling]
            elif env_model:
                model_pool = [env_model]
            else:
                model_pool = []
        try:
            llm = ClaudeCodeClient(ClaudeCodeConfig(model_pool=model_pool))
        except RuntimeError as e:
            print(f"error: {e}", file=sys.stderr)
            return 1
        run_tests_fn = real_run_tests
        base = (
            "<env ANTHROPIC_BASE_URL>"
            if "ANTHROPIC_BASE_URL" not in _os.environ
            else _os.environ["ANTHROPIC_BASE_URL"]
        )
        pool_str = ",".join(model_pool) if model_pool else _os.environ.get("ANTHROPIC_DEFAULT_OPUS_MODEL", "?")
        print(f"running CLAUDE-CODE: gateway @ {base} model_pool=[{pool_str}]",
              file=sys.stderr)
    elif use_real:
        cfg = load_api_config()
        try:
            cfg.assert_has_key()
        except RuntimeError as e:
            print(f"error: {e}", file=sys.stderr)
            return 1
        llm = OpenAICompatClient(cfg)
        run_tests_fn = real_run_tests
        print(f"running REAL: {cfg.base_url} model={cfg.model}", file=sys.stderr)
    else:
        llm = MockLLMClient(default=(
            "# === FILE: <see workdir> ===\n"
            "# stub baseline output\n"
            "pass\n"
        ))
        run_tests_fn = _stub_run_tests
        print("running MOCK: no LLM cost, fake test results", file=sys.stderr)

    project_names = None
    if args.project_names:
        project_names = [n.strip() for n in args.project_names.split(",") if n.strip()]

    out_dir = run_pipeline(
        llm=llm,
        run_tests_fn=run_tests_fn,
        n_projects=args.n_projects,
        k_repeats=args.k_repeats,
        out_dir=args.out_dir,
        project_names=project_names,
        parallel_cells=args.parallel_cells,
    )
    print(f"\nReport written: {out_dir}", file=sys.stderr)
    summary = (out_dir / "summary.md").read_text()
    print(summary)
    return 0


def _stub_run_tests(project: ProjectRef, py_dir: Path) -> TestResult:
    """Mock test runner — claims 1 test passing. Used in --mock mode."""
    return TestResult(
        project=project, total=1, passed=1, failed=0,
        duration_sec=0.0,
    )


def _do_setup_only() -> int:
    """Run commit0 setup for every V1_SUBSET project. Idempotent."""
    for name in V1_SUBSET:
        print(f"setting up {name}...", file=sys.stderr)
        try:
            setup_split(name)
        except RuntimeError as e:
            print(f"  FAIL: {e}", file=sys.stderr)
            return 1
        print(f"  ok", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
