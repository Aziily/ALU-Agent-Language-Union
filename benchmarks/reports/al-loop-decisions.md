# Phase 1.AL-LOOP decision log

> Append-only narrative of the autonomous design-iteration loop. Each
> round records: hypothesis tried, preview metrics, accept/reject
> decision, rationale.

## Round 0 — preflight (2026-05-15)

Infrastructure fixes that gate the loop:

- **0.1 OpenAICompatClient retry/backoff** — added `max_retries=3`,
  `retry_backoff_sec=5.0` exponential. Retries on HTTP 408/425/429/5xx
  and `httpx.TimeoutException`/`NetworkError`. Non-transient 4xx
  raises immediately. 6 new unit tests, suite still fast (19 tests in
  0.19s).
- **0.2 best_iter tracking** — `PipelineRunResult` gains
  `best_iter_idx` / `best_iter_passing_with_xfail` /
  `best_iter_pass_pct`. `RunSummary` gains
  `baseline_best_iter_pct` / `al_best_iter_pct` / `best_iter_tax_pp`.
  `summary.md` now shows both final-iter (commit0-aligned) AND
  best-iter (strongest signal) rows. Lets us see what would have been
  the score if the LLM hadn't over-edited in iter 2.
- **0.3 wcwidth pytest plugins** — installed `pytest-json-report` and
  `pytest-cov` on the host. Smoke confirmed wcwidth now collects
  tests (37 failed + 1 passed = 38 collected, vs 0/0 before).
- **0.4 benchmark.sh `--host` flag** — bypass Docker; run benchmark
  directly on host via `--real` mode (OpenAICompatClient → :9000 →
  gpt-5.4). Smoke: cachetools k=1 BL 83.3% / AL 95.3% final, BL 95.8%
  / AL 95.3% best.
- **0.5 README proxy block note** — documented :8787 proxy as broken
  (hardcoded stale upstream key in proxy config; fix requires editing
  sandboxed `~/Downloads/proxy/opencc/`). Loop uses :9000 directly.
  State file `.al-iter-state.json` + this decisions log created.

## Round 0.6 — baseline locked (commit `bb3b7c7`)

Preview metrics (3 repos × k=1, run `20260515-130905`):

| pipeline | final iter | best iter | tokens |
|---|---|---|---|
| baseline | **89.9%** | 93.1% | 539k |
| agent-lang | **63.6%** | 64.9% | (see breakdown) |
| **tax_pp_final** | **26.3** | 28.2 | — |

Per-repo:
- cachetools: BL 95.8% / AL 83.3% — single-cell variance (earlier runs had AL > BL)
- deprecated: BL 89.5% / AL 39.2% — BL had 99.4% at iter 1 then regressed
- voluptuous: BL 81.9% / AL 0.0% — AL inject only collected 1/149 tests (worth investigating in a future hypothesis)

Large validation: deferred until queue has ≥2 accepted hypotheses.

## Round 1 — H2 preserve-working-code prompt — **REJECTED**

**Hypothesis**: add explicit instruction to both `python_prompt.md`
and `al_prompt.md` iter-feedback block: "many tests in pytest output
already passed; do not break that working code when emitting iter k.
Over-editing has caused regressions where iter k-1 passed more tests
than iter k."

**Diff**: 1 commit `5ab7409`, modifies both implementers' `_format_iter_history()`.

**Preview run `20260515-133658`** (3 repos × k=1):

| metric | baseline | H2 | Δ vs baseline |
|---|---|---|---|
| AL final | 63.6% | **59.4%** | **−4.2pp ❌** |
| BL final | 89.9% | 83.4% | −6.5pp |
| AL best | 64.9% | **69.8%** | +4.9pp ✓ (helped at peak iter) |
| BL best | 93.1% | 86.9% | −6.2pp |
| tax_pp_final | 26.3 | 23.9 | -2.4 (closed) |
| tax_pp_best | 28.2 | **17.1** | **−11.1pp** (much closer) |

Per-repo (AL final %):
- cachetools: 83.3 → 80.5  (−2.8pp)
- deprecated: 39.2 → 33.3  (−5.9pp)
- voluptuous: 0.0 → 0.0    (unchanged, still inject failure)

**Decision**: REJECTED. Per locked policy (D-π auto-revert, D-σ
fitness = final-iter), AL TOTAL Δ = −4.2pp misses the −2pp acceptance
threshold. Best-iter improved noticeably (+4.9pp AL, −11.1pp tax),
suggesting the instruction DOES help the LLM find better iters; but
final-iter (which commit0 records) still regresses on average.

**Reverted**: `383632f`.

**Hypothesis added to rejected list** with note: "useful for best-iter
signal but final-iter ambiguous under k=1 variance; may revisit at
k=3 validation tier".

## Round 2 prep — H7 marked done in preflight

H7 (tox.ini-aware pytest) was effectively addressed by installing
`pytest-json-report` + `pytest-cov` globally on the host (round 0.3).
Skipping to H4.

---

## Hypothesis queue summary (priority order)

1. **H2 preserve-working-code prompt** — add explicit instruction to
   the AL prompt: "if iter k-1 produced output that passed N tests,
   keep those passing tests' code unchanged in iter k." Addresses the
   regression observed on deprecated (BL 99.4% → 63.2%).
2. **H3 best_iter** — already implemented in 0.2 (validate it's
   recorded correctly).
3. **H7 tox.ini-aware pytest** — write a workdir-local `pytest.ini`
   that pre-empts the repo's hardcoded options. Currently best-effort
   via host-side pytest-cov + pytest-json-report install.
4. **H4 `imports:` keyword** — make module-level imports first-class
   in agent-lang, not raw Python in preamble body. Reduces line count
   AND lets LLM reason about imports as structured data.
5. **H5 `constant:` keyword** — same for module-level constants.
6. **H6 `class:` declarator** — explicit class skeleton; methods
   linked via `Class__method` naming. Replaces the awkward "class
   body in preamble + duplicate method in code-node" pattern.
7. **H11 show test imports** — pass the `from foo import bar` lines
   from each test file into the AL/BL prompt so LLM knows what must
   exist post-inject.
8. **H9 previous-al in feedback** — pass the previous iter's filled
   `.al` to the AL implementer in iter > 0 (symmetric with BL).
9. **H8 topological sort** — order skeleton's code nodes by import
   dependencies (matches commit0 default config).
10. **H10 max_iter 5** — only if data shows iter 2 still climbing on
    most repos.

---

## Format for round entries (apply from Round 1 onwards)

```markdown
## Round N — H<id> <name>

**Hypothesis**: <one sentence>

**Diff**: <commit subject + short summary of file changes>

**Preview metrics** (3 repos × k=1):
| metric | baseline (prev best) | this hypothesis | Δ |
|---|---|---|---|
| ... | ... | ... | ... |

**Decision**: accepted / rejected (rationale)

**Validation metrics** (only if accepted, 16 × k=3):
| ... |
```
