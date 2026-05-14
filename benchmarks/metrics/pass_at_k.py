"""pass^k metric — fraction of independent runs that all pass.

Per benchmark eval report § 2(c): the single most important metric for
evaluating an inherently-stochastic agent-lang pipeline.

    pass^k = fraction of (project) where k independent runs ALL pass

Higher is better; ``pass^k / pass^1`` measures stability decay.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class PassAtKReport:
    """Aggregated pass^k stats for one benchmark run."""

    k: int
    n_projects: int
    pass_at_1: float          # any single run passes
    pass_at_k: float          # all k runs pass
    stability_ratio: float    # pass_at_k / pass_at_1


def compute(
    per_project_results: list[list[bool]],
    k: int,
) -> PassAtKReport:
    """Compute pass^k from a list of [k pass/fail] for each project.

    Args:
        per_project_results: ``[[pass_run1, pass_run2, ...], ...]``,
            one list per project, each of length k.
        k: number of repeats.

    Returns a :class:`PassAtKReport`.
    """
    if not per_project_results:
        return PassAtKReport(k=k, n_projects=0, pass_at_1=0.0, pass_at_k=0.0, stability_ratio=0.0)

    n = len(per_project_results)
    p1 = sum(any(runs) for runs in per_project_results) / n
    pk = sum(all(runs) for runs in per_project_results) / n
    ratio = pk / p1 if p1 > 0 else 0.0
    return PassAtKReport(k=k, n_projects=n, pass_at_1=p1, pass_at_k=pk, stability_ratio=ratio)
