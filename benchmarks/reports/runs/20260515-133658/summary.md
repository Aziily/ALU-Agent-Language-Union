# Benchmark Run — 20260515-133658

**Projects**: 3  **k**: 1  **Max iterations per cell**: 3  **LLM tokens total**: 519,158

## Headline numbers

| 指标 | Baseline | agent-lang | Δ |
|---|---|---|---|
| **per-test pass% (final iter — commit0-aligned)** | **83.4%** | **59.4%** | -23.9 pp |
| per-test pass% (best iter — strongest signal) | 86.9% | 69.8% | -17.1 pp |
| binary all-pass% (per-cell, n=3) | 0.0% | 0.0% | -0.0 pp |
| pass^1 (any of 1) | 0.0% | 0.0% | — |
| pass^1 (all of 1) | 0.0% | 0.0% | — |

**往返税 (per-test, commit0-aligned)** = baseline_per_test% - al_per_test% = **23.9 pp**

**往返税 (binary all-pass)** = baseline_pass% - al_pass% = **0.0 pp**  →  tie

## Iter convergence (how many cells passed at which iter idx)

| pipeline | iter 0 | iter 1 | iter 2 | never |
|---|---|---|---|---|
| baseline  | 0 | 0 | 0 | 3 |
| al | 0 | 0 | 0 | 3 |

## Per-project pass^1

| repo | baseline_passes | al_passes | k |
|---|---|---|---|
| cachetools | 0/1 | 0/1 | 1 |
| voluptuous | 0/1 | 0/1 | 1 |
| deprecated | 0/1 | 0/1 | 1 |
