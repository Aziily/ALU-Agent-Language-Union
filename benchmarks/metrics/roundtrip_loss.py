"""Roundtrip tax — agent-lang pipeline vs native Python baseline.

Per docs/design/benchmark.md § 1:

    roundtrip_tax_pp = baseline_pass_pct - al_pipeline_pass_pct

Positive values ⇒ pipeline lost something. Threshold guidance:
    > 15 pp  → reconsider whether agent-lang should be the source of truth
    < 3 pp   → benchmark saturated, look at building a tougher one
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class RoundtripReport:
    """Comparison of two pipeline runs (baseline vs agent-lang)."""

    baseline_pass_pct: float
    al_pass_pct: float
    tax_pp: float                 # baseline - al, in percentage points
    n_projects: int
    note: str = ""


def compute(
    baseline_results: list[bool],
    al_results: list[bool],
    *,
    note: str = "",
) -> RoundtripReport:
    """Compute roundtrip tax from two parallel pass/fail vectors.

    Args:
        baseline_results: pass/fail for each project under native baseline.
        al_results: pass/fail for each project under the agent-lang pipeline.
        note: free-form annotation (model name, run params, ...).

    Both lists must be aligned (same project order, same length).
    """
    if len(baseline_results) != len(al_results):
        raise ValueError(
            f"length mismatch: baseline={len(baseline_results)} al={len(al_results)}"
        )
    n = len(baseline_results)
    if n == 0:
        return RoundtripReport(0.0, 0.0, 0.0, 0, note=note)
    bp = 100.0 * sum(baseline_results) / n
    ap = 100.0 * sum(al_results) / n
    return RoundtripReport(
        baseline_pass_pct=bp,
        al_pass_pct=ap,
        tax_pp=bp - ap,
        n_projects=n,
        note=note,
    )
