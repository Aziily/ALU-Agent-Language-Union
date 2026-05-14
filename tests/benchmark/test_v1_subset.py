"""Tests for benchmarks.harness.V1_SUBSET.

Smoke: V1_SUBSET 必须含 5 个项目，每个名字必须是合法 commit0 split。
"""

from __future__ import annotations

from benchmarks.harness.V1_SUBSET import V1_SUBSET, get_v1_subset
from benchmarks.harness.commit0_adapter import SINGLE_REPO_SPLITS


def test_v1_subset_has_16_entries():
    """Phase 1.H'.B (D-ε): expanded to full commit0 lite split."""
    assert len(V1_SUBSET) == 16


def test_v1_subset_entries_are_unique():
    assert len(set(V1_SUBSET)) == len(V1_SUBSET)


def test_v1_subset_entries_are_valid_commit0_splits():
    """Every name in V1_SUBSET must be a known commit0 split name."""
    for name in V1_SUBSET:
        assert name in SINGLE_REPO_SPLITS, (
            f"{name!r} not in SINGLE_REPO_SPLITS; "
            f"did commit0 rename it?"
        )


def test_get_v1_subset_returns_same_tuple():
    assert get_v1_subset() == V1_SUBSET


def test_v1_subset_diversity():
    """Sanity check: the 5 represent different commit0 categories.

    This is a fragile test by design — if V1_SUBSET changes, update the
    rationale doc + this test together.
    """
    expected = {
        "cachetools", "wcwidth", "voluptuous", "deprecated", "portalocker",
        "pyjwt", "chardet", "parsel", "cookiecutter", "tinydb",
        "simpy", "marshmallow", "imapclient", "minitorch", "babel", "jinja",
    }
    assert set(V1_SUBSET) == expected, (
        f"V1_SUBSET changed without updating rationale; got {V1_SUBSET}"
    )
