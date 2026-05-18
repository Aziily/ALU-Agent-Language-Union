# AL — agent-lang (`.al` extension)

> Editor-first DSL for stripped-Python completion. Focused workspace for
> verifying the language paradigm via the commit0 benchmark. Runtime /
> editor / orchestrator are explicitly out of scope here.

## Quick map

```
/AL/
├── al/                            ← the language itself
│   ├── parser/                    tokenizer · parser · serializer · AST
│   ├── codegen/                   emit Python from AST
│   └── llm/                       LLM client adapters (Claude Code via gateway)
├── benchmarks/                    ← commit0-based empirical proof
│   ├── agents/                    two implementer pipelines + prompts
│   │   ├── python_implementer.py  baseline (LLM fills stripped .py directly)
│   │   ├── al_implementer.py      pipeline B (LLM fills `body:` blocks in .al)
│   │   ├── python_prompt.md       BL prompt (commit0 user_prompt verbatim)
│   │   └── al_prompt.md           AL prompt (same task, agent-lang vocab)
│   ├── harness/                   runner + commit0 adapter + inject
│   ├── metrics/                   pass@k + roundtrip-tax
│   ├── skeletons/                 16 .al files (1 per commit0 lite repo) + autogen tool
│   ├── reports/runs/<ts>/         per-run output (summary.md, decision*.md, per_repo/)
│   └── webui/                     Flask result browser (basic; IDE version deferred)
├── tests/                         ~260 tests (parser + benchmark + LLM + UI)
├── examples/daily_news.al         language-syntax stress fixture
├── docs/
│   ├── al-spec.md                 language specification
│   ├── authoring-al.md            LLM authoring guide (embedded in prompts)
│   ├── preamble-design.md         design rationale for `preamble` keyword
│   ├── parser.md                  parser internals
│   ├── set-node.md                `set` keyword design rationale
│   └── benchmark.md               benchmark protocol
├── thirdparty/commit0/            commit0 submodule (eval framework)
├── Dockerfile.benchmark           container for ./benchmark.sh
├── benchmark.sh                   ./benchmark.sh --n-projects 16 --k-repeats 3
└── pyproject.toml                 package: `al` (top-level)
```

## Status (2026-05-15)

- **253/253 unit tests ✅** (parser + codegen + benchmark + LLM + WebUI;
  +12 preamble parser, +2 inject-preamble-skip, +2 fairness vs Phase 1.H'.F.2)
- **5 declarators**: `flow`, `code`, `agent`, `set`, **`preamble`** (new this phase)
- **16 hand-designed + auto-generated `.al` skeletons** (full commit0 lite split)
- **commit0-aligned benchmark pipeline**: bare `pytest --json-report`,
  3-iteration test-driven feedback loop, `(passed + xfail) / total` metric
  matching `commit0/harness/evaluate.py` exactly.

## Running

```bash
# Install
pip install -e .[test]
pip install pytest-json-report pytest-cov       # used by harness

# Tests
pytest tests/ -q                                # 262 ✅

# Re-generate a skeleton from a stripped commit0 repo
python -m benchmarks.skeletons._autogen cachetools src/cachetools

# Benchmark — HOST mode (Round 0.4, fast, OpenAI-compatible HTTP):
./benchmark.sh --host --k-repeats 1 --project-names cachetools   # smoke
./benchmark.sh --host --n-projects 16 --k-repeats 3              # full

# Benchmark — Docker mode (Anthropic-format via claude -p):
./benchmark.sh --n-projects 16 --k-repeats 3

# WebUI to inspect results
pip install flask>=3
python -m benchmarks.webui                      # http://127.0.0.1:8765
```

### Local proxy status (2026-05-15)

- `http://127.0.0.1:9000` — **WORKING** OpenAI-compatible proxy. Set
  `LLM_API_KEY` (see local notes — **do NOT commit the real key**) +
  model `gpt-5.4`. This is what `--host` mode uses. Configure via `.env`
  (which is `.gitignore`d):
  ```
  LLM_API_KEY=<your-proxy-token>
  LLM_BASE_URL=http://127.0.0.1:9000/v1
  LLM_MODEL=gpt-5.4
  ```
- `http://127.0.0.1:8787` — **BROKEN** Anthropic-format proxy. Diagnosed
  via `/private/tmp/opencc.log`: the proxy correctly translates
  Anthropic→OpenAI format but uses a hardcoded upstream key
  `<redacted — see ~/Downloads/proxy/opencc/ config>` that :9000 rejects
  (401). To fix: edit the proxy's config in `~/Downloads/proxy/opencc/`
  to use the same `LLM_API_KEY` then restart. Until fixed, use `--host`
  mode (not the Docker `--use-claude-code` path).

## Why `preamble`?

Phase 1.H'.F.2 (commit0 multi-iter run, gpt-5.4) found that on the
cleanest BL/AL comparison (cachetools, 645 tests × k=3):

> **Baseline 100.0% / Agent-lang 86.7% (+13.3 pp BL lead)**

Root cause: the agent-lang skeleton could only express function bodies.
Module-level Python — `class _HashedTuple`, `_kwmark = (_HashedTuple,)`,
imports, type aliases — was **invisible to the LLM**. The LLM in the
AL path reinvented those symbols from scratch (badly), broke unit tests.

`preamble` is the fifth declarator added in Phase 1.AL to fix this.
See `docs/preamble-design.md` for the full rationale + example.

```al
preamble cachetools_keys:
  source: cachetools/keys.py
  body: |
    """Key functions for memoizing decorators."""
    __all__ = ('hashkey', ...)

    class _HashedTuple(tuple):
        """..."""
        __hashvalue = None
        def __hash__(self, hash=tuple.__hash__):
            if (h := self.__hashvalue) is None:
                self.__hashvalue = h = hash(self)
            return h

    _kwmark = (_HashedTuple,)


code hashkey:
  body: |
    def hashkey(*args, **kwargs):
        """Return a cache key for the specified hashable arguments."""
        if kwargs:
            return _HashedTuple(args + sum(sorted(kwargs.items()), _kwmark))
        return _HashedTuple(args)
```

The LLM writing `hashkey`'s body now has `_HashedTuple` and `_kwmark`
in scope. Inject step skips preamble defs (the stripped repo already
contains the module-level decls — preamble is purely LLM-facing context).

## Latest benchmark snapshot (pre-preamble — Phase 1.H'.F.2)

`benchmarks/reports/runs/20260513-160432/decision_v2.md`

| metric | Baseline | Agent-lang | Δ |
|---|---|---|---|
| per-test pass% (12 repos) | 72.4% | 41.5% | +30.9 pp |
| cachetools 645 tests × k=3 | **100.0%** | **86.7%** | +13.3 pp |
| LLM tokens consumed | 5.99M | 4.80M | AL −20% |
| LLM-call errors | 10/36 | 8/36 | AL −20% |

Expected with preamble (next re-run, blocked on budget top-up):

- cachetools AL → 95%+ (LLM can correctly reference `_HashedTuple` / `_kwmark`)
- voluptuous AL → non-zero (no longer collection-fails on missing `Self`-like symbols)
- parsel AL → non-zero

## Deferred (separate plans)

- **IDE-like WebUI** showing side-by-side skeleton ↔ filled .al ↔
  test result. Plan: separate.
- **Runtime layer** (`agent_call` / `flow_call` / `SetDefinition`) —
  Phase 2; only after AL design is empirically proven viable.
