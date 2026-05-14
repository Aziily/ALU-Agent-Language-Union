"""V1 subset = full commit0 `lite` split (16 repos).

Phase 1.H'.B (D-ε decision): expanded from 5 hand-vetted repos to all
16 of commit0's official `lite` split, aligning the experiment with
commit0's canonical small benchmark.

Source-of-truth: ``thirdparty/commit0/commit0/harness/constants.py:87-104``
(SPLIT_LITE constant). This file just hardcodes that list locally so
the runner can iterate without a commit0 import dependency.

Skeletons:
  6 hand-designed: cachetools, wcwidth, voluptuous, deprecated,
                   portalocker, pyjwt
  10 auto-generated via benchmarks/skeletons/_autogen.py from each
                   repo's stripped Python AST: chardet, parsel,
                   cookiecutter, tinydb, simpy, marshmallow, imapclient,
                   minitorch, babel, jinja

Per Phase 1.H'.A fairness decisions, skeletons contain ONLY flow + steps
+ code-node names + body-with-docstring + pass. No intent / input / output
metadata that would give AL an information advantage over BL.

To regenerate analysis: see docs/reports/v1_subset_rationale.md
"""

from __future__ import annotations


#: All 16 commit0 lite-split repos used for Phase 1.H' 实证.
V1_SUBSET: tuple[str, ...] = (
    "cachetools",     # hand-designed; 10 stripped (100% top)
    "wcwidth",        # hand-designed;  6 stripped (100% top)
    "voluptuous",     # hand-designed; 36 stripped (72% top)
    "deprecated",     # hand-designed;  6 stripped (67% top)
    "portalocker",    # hand-designed;  7 stripped (29% top)
    "pyjwt",          # hand-designed; 16 stripped (19% top) — needs cryptography
    "chardet",        # auto-generated; 13 stripped (15% top) — has 0 tests, will report 0
    "parsel",         # auto-generated; 36 stripped (25% top) — needs lxml
    "cookiecutter",   # auto-generated; 62 stripped (94% top)
    "tinydb",         # auto-generated; 48 stripped (21% top)
    "simpy",          # auto-generated; 49 stripped (6% top)
    "marshmallow",    # auto-generated; 70 stripped (46% top)
    "imapclient",     # auto-generated; 87 stripped (13% top)
    "minitorch",      # auto-generated; 116 stripped (52% top) — needs numpy
    "babel",          # auto-generated; 184 stripped (66% top) — LARGE
    "jinja",          # auto-generated; 325 stripped (39% top) — LARGEST
)


def get_v1_subset() -> tuple[str, ...]:
    """Return the V1_SUBSET tuple. Helper for runner imports."""
    return V1_SUBSET
