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
