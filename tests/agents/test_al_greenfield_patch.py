"""v0.7.2 Codex round 2 — Patch Mode tests."""

from __future__ import annotations

from al.llm import MockLLMClient
from al.parser.parser import parse
from benchmarks.agents.al_greenfield_implementer import (
    _split_files,
    _merge_patch_into_prev,
    run_al_greenfield_implementer,
)


# ---------------------------------------------------------------------------
# Splitter recognizes both FILE and PATCH markers
# ---------------------------------------------------------------------------


def test_split_recognizes_patch_marker():
    raw = (
        "---PATCH: main.al---\n"
        "code f:\n  target: main.py::f\n  body: |\n    return 1\n"
    )
    files = _split_files(raw)
    assert len(files) == 1
    assert files[0].mode == "patch"
    assert files[0].relpath == "main.al"


def test_split_mixed_file_and_patch():
    raw = (
        "---FILE: a.al---\n"
        "code fa:\n  target: a.py::fa\n  body: |\n    return 1\n"
        "\n---PATCH: b.al---\n"
        "code fb:\n  target: b.py::fb\n  body: |\n    return 2\n"
    )
    files = _split_files(raw)
    assert [f.mode for f in files] == ["full", "patch"]


# ---------------------------------------------------------------------------
# Merger replaces by target qualname
# ---------------------------------------------------------------------------


def test_merge_replaces_node_with_matching_target():
    prev = parse(
        "code f1:\n  target: x.py::f1\n  body: |\n    def f1(): return 1\n\n"
        "code f2:\n  target: x.py::f2\n  body: |\n    def f2(): return 2\n"
    )
    patch = parse(
        "code f1:\n  target: x.py::f1\n  body: |\n    def f1(): return 99\n"
    )
    merged, replaced = _merge_patch_into_prev(patch, prev)
    assert replaced == ["x.py::f1"]
    # f1 swapped, f2 preserved
    assert len(merged.defs) == 2
    f1_body = next(
        f for d in merged.defs if d.name == "f1" for f in d.fields if f.name == "body"
    )
    assert "return 99" in f1_body.value.text
    f2_body = next(
        f for d in merged.defs if d.name == "f2" for f in d.fields if f.name == "body"
    )
    assert "return 2" in f2_body.value.text


def test_merge_appends_new_target():
    prev = parse(
        "code old:\n  target: x.py::old\n  body: |\n    def old(): return 1\n"
    )
    patch = parse(
        "code new_one:\n  target: x.py::new_one\n  body: |\n    def new_one(): return 2\n"
    )
    merged, replaced = _merge_patch_into_prev(patch, prev)
    assert len(merged.defs) == 2
    assert replaced == ["+x.py::new_one"]


def test_merge_falls_back_to_name_when_no_target():
    """If patch's code node has no ``target:``, match by node name."""
    prev = parse(
        "code my_fn:\n  body: |\n    def my_fn(): return 1\n"
    )
    patch = parse(
        "code my_fn:\n  body: |\n    def my_fn(): return 99\n"
    )
    merged, _ = _merge_patch_into_prev(patch, prev)
    assert len(merged.defs) == 1
    body = next(
        f for d in merged.defs for f in d.fields if f.name == "body"
    )
    assert "return 99" in body.value.text


# ---------------------------------------------------------------------------
# End-to-end via implementer
# ---------------------------------------------------------------------------


def test_patch_mode_falls_back_to_full_when_no_prior_state():
    """v0.7.3+ behavior change: when iter > 0 has ---PATCH: but no prior
    file in prev_files, fall back to mode='full' (LLM intent is clear).
    Was the root cause of Phase C catastrophic regression on
    deprecated/portalocker — fixed by relaxing the strict-reject."""
    canned = (
        "---PATCH: main.al---\n"
        "code f:\n  target: main.py::f\n  body: |\n    return 1\n"
    )
    llm = MockLLMClient(default=canned)
    r = run_al_greenfield_implementer(
        spec_text="", stripped_files={"main.py": "def f(): pass\n"},
        llm=llm, guide_text="(mock guide)",
        prev_files={},
        iter_idx=1,
    )
    f = r.files[0]
    assert not f.parse_error  # no more rejection
    assert f.mode == "full"  # silently downgraded


def test_patch_mode_merges_with_prior_state():
    """Iter > 0 with prior parsed Program → merged AL used for inject."""
    # Round 0 — full file
    initial_text = (
        "code f1:\n  target: main.py::f1\n  body: |\n    def f1(): return 1\n\n"
        "code f2:\n  target: main.py::f2\n  body: |\n    def f2(): return 'bug'\n"
    )
    prev = parse(initial_text)
    # Round 1 — patch only f2
    canned_patch = (
        "---PATCH: main.al---\n"
        "code f2:\n  target: main.py::f2\n  body: |\n    def f2(): return 'fixed'\n"
    )
    llm = MockLLMClient(default=canned_patch)
    r = run_al_greenfield_implementer(
        spec_text="", stripped_files={"main.py": "def f1(): pass\ndef f2(): pass\n"},
        llm=llm, guide_text="(mock guide)",
        prev_files={"main.al": prev},
        iter_idx=1,
    )
    f = r.files[0]
    assert not f.parse_error
    assert f.mode == "patch"
    # Merged program has BOTH functions; f1 preserved, f2 updated.
    assert len(f.program.defs) == 2
    eff = f.effective_al_text
    assert "return 1" in eff  # f1 preserved
    assert "return 'fixed'" in eff  # f2 updated
    assert "return 'bug'" not in eff  # old f2 gone


def test_full_mode_iter1_still_works():
    """`---FILE:` at iter > 0 still does full replacement (back-compat)."""
    prev = parse(
        "code f:\n  target: main.py::f\n  body: |\n    def f(): return 1\n"
    )
    canned = (
        "---FILE: main.al---\n"
        "code f:\n  target: main.py::f\n  body: |\n    def f(): return 99\n"
    )
    llm = MockLLMClient(default=canned)
    r = run_al_greenfield_implementer(
        spec_text="", stripped_files={"main.py": "def f(): pass\n"},
        llm=llm, guide_text="(mock guide)",
        prev_files={"main.al": prev},
        iter_idx=1,
    )
    f = r.files[0]
    assert not f.parse_error
    assert f.mode == "full"
    # effective_al_text == al_text for full mode (no merge)
    assert f.effective_al_text == f.al_text
