# Benchmark Run — 20260515-103426

**Projects**: 1  **k**: 1  **Max iterations per cell**: 3  **LLM tokens total**: 105,744

## Headline numbers

| 指标 | Baseline | agent-lang | Δ |
|---|---|---|---|
| **per-test pass% (commit0-aligned)** | **92.1%** | **95.3%** | +3.3 pp |
| binary all-pass% (per-cell, n=1) | 0.0% | 0.0% | -0.0 pp |
| pass^1 (any of 1) | 0.0% | 0.0% | — |
| pass^1 (all of 1) | 0.0% | 0.0% | — |

**往返税 (per-test, commit0-aligned)** = baseline_per_test% - al_per_test% = **-3.3 pp**

**往返税 (binary all-pass)** = baseline_pass% - al_pass% = **0.0 pp**  →  tie

## Iter convergence (how many cells passed at which iter idx)

| pipeline | iter 0 | iter 1 | iter 2 | never |
|---|---|---|---|---|
| baseline  | 0 | 0 | 0 | 1 |
| al | 0 | 0 | 0 | 1 |

## Per-project pass^1

| repo | baseline_passes | al_passes | k |
|---|---|---|---|
| cachetools | 0/1 | 0/1 | 1 |
