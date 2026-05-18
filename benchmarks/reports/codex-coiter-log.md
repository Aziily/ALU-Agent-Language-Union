# AL Codex Co-Iteration Log

Phase B — Claude↔Codex 4-round loop to evolve AL beyond v0.7 parity.

**Codex thread**: `019e39ad-2d79-7e32-9e91-b518fc79a8d6`
**Model**: `gpt-5.4` with `model_reasoning_effort: xhigh`
**Validation**: cachetools k=1 × {baseline, al, al_greenfield} per round
**Stop**: C > A by ≥1 pp for 2 consecutive rounds, OR 4 rounds without progress, OR Codex score ≥ 8/10 + verdict `ready`

---

## Round 0 — Preflight (Codex initial review)

**Date**: 2026-05-18 afternoon
**Codex score**: 6/10
**Codex verdict**: `almost`
**Codex top-3 ranked ideas**:

### 1. Targeted Body (chosen for Round 1)

> Add `target: path.py::qualname` and allow `body:` to contain only function
> statements, not a full `def`. AL inject/codegen recovers the exact
> signature/decorators from the stripped Python target.
>
> **Mechanism**: Removes signature copying, wrong function names, wrong
> defaults, and ambiguous injection. Makes AL strictly easier than Python
> baseline: model writes only implementation statements.
>
> **Impl sketch**: `benchmarks/harness/inject.py`, `al/codegen/emit_code.py`,
> `validate.py`, spec. ~150 LOC.
>
> **Validation signal**: cachetools test_func.py decorator tests; inject_skipped == 0.
>
> **Risk**: Body-only code may hide when a function needs decorator-level edits.

### 2. Patch Mode

> Iteration semantics: after iter 0, emitted AL may be partial; omitted nodes
> keep prior bodies. Syntax `---PATCH: path.al---` or `mode: patch`.
>
> **Mechanism**: Attacks the observed best→final regression on Pipeline C.
> Stable node IDs let the LLM preserve known-good functions while only
> rewriting failing ones; Python baseline cannot do this cleanly.
>
> **Risk**: Early bad nodes can persist unless feedback causes replacement.

### 3. Coverage Contract

> Require each `code` node to declare `target:`; validator checks every
> stripped `NotImplementedError` stub has exactly one AL node.
>
> **Mechanism**: Turns "complete implementation" from prompt text into a
> checkable language invariant.

### Lower-ranked (4-6): Structured Params, Uses Lint, Examples

---

## Claude's choice for Round 1: **Targeted Body**

Reasoning:
1. **Language-fundamental** — changes what `body:` MEANS, not just constraints around it. User said "聚焦于语言基础部分" (focus on language fundamentals).
2. **Direct attack on the v0.7 neutrality** — the v0.7 typed I/O is decorative because the body still has to declare its own signature. Targeted Body makes `target:` the load-bearing contract.
3. **Smallest physical change for the LLM** — the model writes less code → fewer surface-area bugs. Pipeline C currently makes the LLM copy each function's `def fifo_cache(maxsize=128, typed=False):` line from the stripped Python — wasted tokens + chance to mistranscribe defaults/decorators.
4. **Removes inject ambiguity** — `target:` says exactly which `.py::qualname` to patch, replacing the heuristic `<Class>__<method>` dunder mapping.
5. **Risk is low** — additive (existing skeletons that don't use `target:` keep current behavior).

Patch Mode is interesting but attacks a methodology issue (mid-run regression), not a language design gap. Coverage Contract requires Targeted Body to be useful (since it uses `target:`). Targeted Body unlocks both as follow-ups.

---

## Round 1 — Targeted Body implemented + cachetools pilot

**Date**: 2026-05-18 evening
**Implementation**: ~4 files touched (~250 LOC + 9 new tests)
- `al/parser/ast_nodes.py` — add `target` to `FIELD_VALUE_HINTS` + `ALLOWED_FIELDS_BY_KIND["code"]` + `CANONICAL_FIELD_ORDER`
- `benchmarks/harness/inject.py` — new `_synthesize_def_for_target` + `_get_target` + `_body_has_def` + `_find_func_by_qualname` (~140 LOC); inject_filled_al gates on target+no-def
- `benchmarks/agents/al_greenfield_prompt.md` — few-shot example evolves to `target:` + body-without-def pattern
- `docs/al-spec.md` — new §4.14 documenting Targeted Body
- `tests/benchmark/test_inject_targeted_body.py` — 9 tests covering top-level, defaults, decorators, class method, legacy coexistence, failure modes

**Full suite**: 363 tests pass (was 354; +9 new).

### Pilot — `cachetools k=1 × baseline/al/al_greenfield`

| pipeline | iter 0 | iter 1 | iter 2 (final) | best | tokens | inject |
|---|---|---|---|---|---|---|
| baseline (A) | 83.3% | 80.5% ⚠ | 83.3% | 83.3% | 37k | 2/2 |
| al-skeleton (B) | 83.3% | 83.3% | **86.0%** | 86.0% | 75k | 11/11 |
| al-greenfield (C) | 80.5% | 83.3% | 83.3% | 83.3% | 56k | 10/10 |

**Δ vs A**: B +2.8pp, C +0.0pp.

### LLM adoption of `target:` field

- **10 / 10 code nodes** in C's output carried a `target:` field — full adoption
- **`keys.al`** (4 simple functions): LLM wrote bodies **without** `def` line ✓ — Targeted Body fully exercised
- **`func.al`** (6 decorator factories): LLM wrote `target:` AND a full `def name(...):` body — *partial* adoption, mixed-mode

Mixed-mode is interesting: LLM trusts Targeted Body for simple top-level functions but defaults back to writing `def` for complex decorator factories where it needs the function-as-value scope. Not a bug — both modes work — but a signal for round 2 (maybe the prompt should give a decorator-style few-shot too).

### Variance caveat

All three pipelines dropped ~12pp from historical (cachetools usually 95.8%/96.3%/95.8% — see [v0.7-pilot-decision.md](v0.7-pilot-decision.md)). gpt-5.4 at temp=0 is not deterministic; proxy may have been in a different state today. **Today's numbers are internally consistent (same model, same time window) but the absolute level is suspect.** The B > A > C pattern is unusual — historically C tracked A.

### Stability win — iter trace

Targeted Body's per-iter trace is FLATTER than baseline:
- A trace: 83 → 80.5 (regression) → 83.3 (recover)
- C trace: 80.5 → 83.3 → 83.3 (held)

Locked signatures may give the LLM less surface to break across iters. Worth tracking through future rounds.

### Round 1 verdict (Claude's call)

- **Improvement**: NO — C did not strictly exceed A on cachetools today.
- **Neutrality acceptable**: YES — Targeted Body is foundational (Patch Mode and Coverage Contract both build on `target:`), the LLM adopted it cleanly, iter stability improved, tests all green.
- **Action**: COMMIT and continue. Ask Codex to weigh: keep iterating from current state, or pivot to a different idea given the variance?

---

## Round 2 — Codex picked Patch Mode (#2 ranked) over Coverage Contract

**Codex round 2 reasoning** (after seeing Round 1 result):

> Coverage Contract is unlikely to move this specific k=1 cell if C already
> emitted 10/10 targets. Patch Mode attacks the observed benchmark pathology:
> full rewrites churn working functions. It gives AL a structural advantage
> Python baseline lacks: stable target-addressed edits across iterations.

**Implementation**: `---PATCH: <relpath>---` file marker. When LLM emits
PATCH at iter > 0, the harness merges its code-node fragments onto the
prior iter's parsed Program by `target:` qualname (or node name fallback).
Nodes not mentioned in the patch keep their previous bodies.

Files touched:
- `benchmarks/agents/al_greenfield_implementer.py` — `_FILE_MARKER_RE`
  regex extended to capture `FILE|PATCH`; `_merge_patch_into_prev()`
  function (~50 LOC); `_validate_files()` does the merge when `mode='patch'`;
  `GreenfieldFile` gets `mode` + `merged_al_text` + `effective_al_text`
  property. Prompt's iter-history section documents PATCH for iter > 0.
- `benchmarks/harness/runner.py` — `_run_al_greenfield_cell` keeps a
  `prev_files: dict[str, Program]` across iters; passes it to implementer;
  injects `effective_al_text` (post-merge for patches).
- `tests/agents/test_al_greenfield_patch.py` — 8 new tests for splitter
  recognizing both markers, merger by target / by name fallback / append,
  end-to-end patch round-trip, prior-state requirement, full-mode at
  iter > 0 still works.

Full suite: 371 tests pass (was 363; +8 patch tests).

### Pilot — `cachetools k=1` (same proxy, same time, Round 2)

| pipeline | iter 0 | iter 1 | iter 2 (final) | best | tokens |
|---|---|---|---|---|---|
| baseline (A) | 83.3% | **95.8%** | **83.3% ⚠ regress** | 95.8% | 36k |
| al-skel (B) | 80.5% | 83.3% | 86.0% | 86.0% | 74k |
| al-greenfield (C, Patch Mode) | 83.3% | 83.3% | **95.8% (held)** | 95.8% | 53k |

**Final-iter comparison** (commit0-official scoring):
- **C - A = +12.6 pp** ✅ strict improvement
- C - B = +9.8 pp

**Best-iter comparison**:
- C - A = +0.0 pp (parity — both reached 95.8%, but A regressed)
- C - B = +9.8 pp

**LLM Patch Mode adoption**:
- Iter > 0 raw output contained **3 `---PATCH:`** + 2 `---FILE:` markers
- Model correctly used PATCH for narrow fixes and FILE for full rewrites

### Round 2 verdict (Claude's call)

- **Improvement**: **YES** on final-iter, **TIE** on best-iter
- **Iter stability**: dramatic — C held its iter-1 high through iter 2, while A regressed by 12.5 pp
- **Action**: COMMIT, send to Codex for round 3 direction. Strong signal that Patch Mode delivered exactly what Codex predicted ("stable target-addressed edits across iterations").

> The convergence gate I set requires "C > A by ≥1 pp for 2 consecutive
> rounds". Round 1 was parity. Round 2 is +12.6 pp on final-iter. To
> trigger loop-exit, Round 3 must also be > A. If yes → ramp up; if no →
> 4 rounds and write final report.

---

## Round 3 — Codex picked Uses Lint (#5 ranked)

**Codex round 2 reply** (after seeing the +12.6pp result):

> Coverage Contract is useful, but cachetools already showed full
> `target:` coverage. Patch Mode preserves working code; Uses Lint
> makes each patch less likely to introduce a bogus dependency.

**Implementation**: New `uses:` ReferenceList field on `code` nodes.
`validate_uses(program)` AST-walks each body's free Load names; rejects
ones not in (uses, preamble symbols, top-level imports, builtins).
Warnings surface to next iter via `previous_validation_warnings`.

Files touched:
- `al/parser/ast_nodes.py` — add `uses` to FIELD_VALUE_HINTS,
  ALLOWED_FIELDS_BY_KIND["code"], CANONICAL_FIELD_ORDER
- `al/parser/parser.py` — REFERENCE_LIST_FIELDS gets `uses`
- `al/parser/validate.py` — `validate_uses` (~180 LOC) with full
  scope tracker (function args + for-targets + with-targets + comprehensions
  + try-except-import boundaries + Lambda + Global/Nonlocal)
- `benchmarks/agents/al_greenfield_implementer.py` — runs `validate_uses`,
  surfaces issues via `previous_validation_warnings`; prompt template
  documents `uses:` and gets a warnings-feedback section for iter > 0
- `benchmarks/harness/runner.py` — collects warnings per iter, passes
  to next call
- `docs/al-spec.md` — new §4.15 documenting Uses Lint
- `tests/parser/test_validate_uses.py` — 11 tests for clean cases
  (builtins / preamble / top-level imports / explicit uses / self / for-target)
  + failure cases (undeclared helper / module attr root / multiple / uses silences)

Full suite: 382 tests pass (was 371; +11).

### Pilot — `cachetools k=1` (same proxy, same time, Round 3)

| pipeline | iter 0 | iter 1 | iter 2 (final) | best | tokens | inject |
|---|---|---|---|---|---|---|
| baseline (A) | 83.3% | 74.0% ⚠ | 80.5% | 83.3% | 37k | 2/2 |
| al-skel (B) | 83.3% | 83.3% | 83.3% | 83.3% | 74k | 11/11 |
| al-greenfield (C) | 83.3% | 74.0% ⚠ | 80.5% | 83.3% | 54k | 10/11 |

**Final-iter comparison**:
- C - A = +0.0 pp (parity)
- C - B = -2.8 pp

**Best-iter comparison**: all tied at 83.3%.

### LLM adoption of `uses:` field — ZERO

- `target:` count: **11** (full adoption, unchanged from R2)
- `uses:` count: **0** ❌ — LLM completely ignored the new field
- `---PATCH:` markers in iter > 0: **2** (Patch Mode still used)
- `---FILE:` markers in iter > 0: **0**

The prompt section introducing `uses:` was too soft — the LLM kept emitting code without explicit dependency declarations. Since `uses:` was empty, the validator's warnings WERE generated (against undeclared names visible in preamble — which it correctly tolerated), but they didn't translate into LLM behavior change because no actual undeclared-name failures showed up.

### Round 3 verdict (Claude's call)

- **Improvement**: NO — C tied A, both 80.5% final.
- **Adoption**: ZERO for `uses:`, prompt change wasn't directive enough.
- **Variance**: TODAY's run had everyone at 80-83%, vs R2 where everyone reached 95.8% best. Same proxy, same time-window, same model — high variance is real.
- **Action**: COMMIT (the language feature is in for future use, even if the LLM didn't reach for it today). Ask Codex for Round 4 strategy given the high variance.

> Round 1 parity, Round 2 +12.6pp, Round 3 parity. The 2-consecutive-rounds convergence gate is NOT met. One round remains.

---

## Round 4 — Codex picked Methodology Pivot (Codex score 4/10 on R3)

**Codex round 3 reply** (after seeing R3's parity):

> Uses Lint was a good validator, but not load-bearing: `uses:` adoption
> was 0, warnings did not enter the loop, and C exactly tracked A. In a
> single cachetools k=1 cell, another cooperative syntax feature is
> unlikely to show clean signal. Stop language changes for this loop.
> Run k=3 on v0.7.3 = Targeted Body + Patch Mode + Uses Lint and compare
> final-iter C vs A. The only proven load-bearing feature so far is Patch
> Mode, and its effect is stability across iterations, so variance
> estimation is now higher leverage than adding syntax.

### Variance run — `cachetools k=3 × {baseline, al-skel, al-greenfield}` (9 cells, ~498k tokens)

Per-cell paired (best-iter):

| k | A baseline | C greenfield | Δ |
|---|---|---|---|
| 0 | 83.7% | 83.7% | 0.0 pp |
| 1 | 83.7% | **95.8%** | **+12.1 pp** |
| 2 | 95.8% | 83.3% | **-12.6 pp** |
| **mean** | 87.8% | 87.6% | **-0.2 pp** |

Variance dominates. R2's +12.6 pp was a real cell observation but one tail of a high-variance distribution. **Mean over 3 cells: parity within noise.**

Aggregated headline (final-iter):
- A baseline mean: 86.8% (range 83.3-93.5)
- B al-skeleton mean: 88.2% (range 83.3-95.3)
- C al-greenfield mean: 87.4% (range 83.3-95.8)
- **C - A = +0.6 pp** (not significant at n=3)

### Final verdict (Claude's call, end of loop)

- **Convergence gate**: NOT met (no 2-consecutive C > A rounds).
- **Loss-free**: YES — averaged over k=3 cachetools, Pipeline C tracks baseline within ±0.5 pp.
- **Improvement**: not proven on single-project k=3. Per-cell swings ±12 pp; effect washes out.
- **Structural advantage**: Patch Mode is real but only triggers when LLM happens to over-edit (~33% of cells today).
- **User goal "loss-free / micro-loss / improvement"**: ✅ in "loss-free / micro-loss" zone.

Final report: [v0.8-final-decision.md](v0.8-final-decision.md). Loop terminates.
