# Claims Registry

Phase G — every load-bearing claim in the AL paper, with the supporting
experimental evidence. Updated as each phase lands; final at v1.0.

## Claim 1 — AL is a lossless wrapper over Python

**Sub-claim 1a**: AL → AL roundtrip is structurally identity.

| Evidence | File / Test | Status |
|---|---|---|
| 17 .al files (16 skeletons + daily_news.al) parse + serialize → re-parse to identical structure | `tests/parser/test_roundtrip.py`, `tests/equiv/test_python_ast_eq.py::test_every_skeleton_parse_and_serialize_roundtrip` | ✅ |
| 6 random AL programs (parametrize) roundtrip cleanly | `test_random_al_programs_roundtrip` | ✅ |
| AL → emit_python on single-function bodies preserves AST | `test_simple_addition_roundtrip`, `test_class_method_roundtrip`, `test_decorator_roundtrip`, `test_complex_body_roundtrip` | ✅ |

**Sub-claim 1b**: AL → emit_python preserves Python semantics (modulo
documented tolerances).

| Evidence | File / Test | Status |
|---|---|---|
| AST-level equivalence checker with 5 toggleable tolerances | `al/codegen/equiv.py::ast_equivalent` | ✅ |
| 10 primitive correctness tests (identical / whitespace / fn-name / var-name / constant / docstring (opt) / syntax-error / decorator-order (opt) / max-diffs / diff-path) | `tests/equiv/test_python_ast_eq.py` | ✅ |
| `al_roundtrip_equivalent()` preset for AL roundtrip use case (ignore_docstrings only) | same file | ✅ |
| Documented edge case: imapclient `\N{...}` escapes — 2/325 bodies | `_ESCAPE_SEQUENCE_TOLERATED` | ⚠️ documented |

## Claim 2 — AL is loss-free vs Python baseline on commit0-lite

**Sub-claim 2a**: Per-project parity within ±2 pp (mid-term goal).

| Project | n_cells | Phase | Baseline best% | AL-Greenfield best% | Δ | Verdict |
|---|---|---|---|---|---|---|
| cachetools | 3 | C | (Phase C re-run) | (TBD) | (TBD) | TBD |
| deprecated | 3 | C | (Phase C re-run) | (TBD) | (TBD) | TBD |
| portalocker | 3 | C | (Phase C re-run) | (TBD) | (TBD) | TBD |
| (16 projects) | 3 each | D | (TBD) | (TBD) | (TBD) | TBD |

Fill-in pending Phase C re-run + Phase D completion.

**Sub-claim 2b**: AL preserves working bodies across iters where Python
baseline cannot (structural advantage from Patch Mode).

| Evidence | Status |
|---|---|
| Phase B Round 2 cachetools: A regressed iter1→iter2 95.8% → 83.3%; C held 95.8% via PATCH | ✅ (single-cell observation) |
| Phase B Round 4 k=3: variance dominates single-cell signal; effect averages to +0.6 pp | ⚠️ noisy |

## Claim 3 — AL features are LLM-adoptable when prompted

| Feature | Prompt few-shot | Adoption % (Phase B R1/R2/R3, Phase C) | Status |
|---|---|---|---|
| `target: file::qualname` | Round 1+ | 100% / 100% / 100% / TBD | ✅ |
| `---PATCH:` marker iter > 0 | Round 2+ | partial / partial / partial | partial |
| `intent:` line per node | Round 2+ | 12-13 per file | ✅ |
| `input:` / `output:` typed | Round 2+ | 10-11 per file | ✅ |
| `uses:` list | Round 3 | 0 | ❌ (prompt too soft) |
| Top-level `from . import X` | Round 1+ | 3 per file (cachetools) | ✅ |

## Claim 4 — AL generalizes beyond commit0-lite

| Benchmark | n_problems × k | A best% | C best% | Δ | Status |
|---|---|---|---|---|---|
| HumanEval | 30 × k=3 | (TBD) | (TBD) | (TBD) | (Phase F pending) |
| MBPP | 30 × k=3 | (TBD) | (TBD) | (TBD) | (Phase F pending) |

## Claim 5 — Token cost is bounded

| Phase | Pipeline | mean tokens / cell | Verdict |
|---|---|---|---|
| Phase B | A | 35k | 1.0× ref |
| Phase B | B (skel) | 75k | 2.1× (skeleton-roundtrip tax) |
| Phase B | C (greenfield) | 56k | 1.6× |

Pipeline C is within 60% overhead vs baseline. Pipeline B's 2× overhead
is the structural roundtrip tax (LLM re-emits unchanged scaffolding).

## Limitations + non-claims (anti-claims)

1. **NOT claimed**: AL provides a pass% improvement on synth tasks. v0.7.3 is parity, not improvement.
2. **NOT claimed**: AL output is byte-identical to baseline Python — same problem, different LLM calls, will differ.
3. **NOT claimed**: AL is universally adoption-friendly — `uses:` had 0% LLM adoption, suggesting the prompt needs to be directive about specific features.
4. **NOT claimed**: AL outperforms hand-written skeletons (B > C by ~1pp on cachetools mean, but B times out on data-heavy projects like wcwidth, so B doesn't scale).
