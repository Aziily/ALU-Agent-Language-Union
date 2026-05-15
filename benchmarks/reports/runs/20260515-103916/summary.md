# Benchmark Run — 20260515-103916

**Projects**: 5  **k**: 1  **Max iterations per cell**: 3  **LLM tokens total**: 422,348

## Headline numbers

| 指标 | Baseline | agent-lang | Δ |
|---|---|---|---|
| **per-test pass% (commit0-aligned)** | **73.2%** | **71.8%** | -1.4 pp |
| binary all-pass% (per-cell, n=5) | 20.0% | 20.0% | -0.0 pp |
| pass^1 (any of 1) | 20.0% | 20.0% | — |
| pass^1 (all of 1) | 20.0% | 20.0% | — |

**往返税 (per-test, commit0-aligned)** = baseline_per_test% - al_per_test% = **1.4 pp**

**往返税 (binary all-pass)** = baseline_pass% - al_pass% = **0.0 pp**  →  tie

## Iter convergence (how many cells passed at which iter idx)

| pipeline | iter 0 | iter 1 | iter 2 | never |
|---|---|---|---|---|
| baseline  | 1 | 0 | 0 | 4 |
| al | 1 | 0 | 0 | 4 |

## Per-project pass^1

| repo | baseline_passes | al_passes | k |
|---|---|---|---|
| cachetools | 0/1 | 0/1 | 1 |
| wcwidth | 0/1 | 0/1 | 1 |
| voluptuous | 0/1 | 0/1 | 1 |
| deprecated | 0/1 | 0/1 | 1 |
| pyjwt | 1/1 | 1/1 | 1 |
