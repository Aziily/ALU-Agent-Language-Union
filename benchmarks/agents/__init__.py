"""Benchmark implementer agents (Phase 1.F + v0.7 Phase 5).

Three LLM-driven agents for the commit0 实证 pipeline:

  - python_implementer    Pipeline A: fill Python skeleton given spec
  - al_implementer        Pipeline B: fill agent-lang skeleton (hand-written)
  - al_greenfield_implementer  Pipeline C: AUTHOR agent-lang from scratch
                                given stripped Python + spec (v0.7)

All three share the same LLMClient + temperature for fair comparison.
"""

from __future__ import annotations

from benchmarks.agents.python_implementer import (
    PythonImplementerResult,
    run_python_implementer,
)
from benchmarks.agents.al_implementer import (
    ALImplementerResult,
    run_al_implementer,
)
from benchmarks.agents.al_greenfield_implementer import (
    ALGreenfieldResult,
    GreenfieldFile,
    run_al_greenfield_implementer,
)


__all__ = [
    "ALImplementerResult",
    "ALGreenfieldResult",
    "GreenfieldFile",
    "PythonImplementerResult",
    "run_al_implementer",
    "run_al_greenfield_implementer",
    "run_python_implementer",
]
