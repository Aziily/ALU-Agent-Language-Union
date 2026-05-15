"""Phase 1.H'.F.2 — BL vs AL fairness symmetry assertions.

These tests encode the locked fairness rules from the plan:

  | invariant                                  | BL  | AL |
  |---|---|---|
  | task prompt has commit0 user_prompt core   | ✓  | ✓ |
  | iter history section appears when iter>0   | ✓  | ✓ |
  | authoring guide                            | ✗  | ✓ |
  | max_tokens default                          | 12288 | 12288 |
  | iter loop max iterations                    | 3   | 3   |
  | feedback channel: pytest stdout (8KB tail)  | ✓   | ✓   |

If any of these symmetry rules drift apart, the BL/AL comparison stops
being apples-to-apples and the published numbers become non-meaningful.
The whole point of Phase 1.H'.F.2 is to keep these aligned, so these
tests are guardrails — any future change that breaks them must be
explicit in the plan / commit log.
"""

from __future__ import annotations

import inspect

from al.llm import MockLLMClient
from al.llm.base import CompletionResult
from benchmarks.agents.python_implementer import run_python_implementer
from benchmarks.agents.al_implementer import run_al_implementer


# ---------------------------------------------------------------------------
# Core commit0 instructions appear in BOTH prompts
# ---------------------------------------------------------------------------

# Core semantic phrases of commit0/agent/configs/base.yaml::user_prompt.
# BL embeds them verbatim. AL re-casts the same instructions in agent-lang
# vocabulary (per plan D-κ), so we only assert the semantic core — not
# exact verbatim — appears in both. If you change either prompt's wording,
# make sure both communicate these same intentions or BL/AL become
# semantically asymmetric.
_COMMIT0_SEMANTIC_PHRASES_BOTH = [
    # all stub bodies must be filled
    "implement all",
    # don't rename anything
    "Do not change the names of existing functions",
    # preserve formatting / structure
    "maintain the original formatting",
    # tests are the success criterion
    "pass the unit tests",
]

# BL alone gets to keep the literal commit0 wording (it's the canonical
# baseline by spec).
_COMMIT0_VERBATIM_BL = [
    "implement all functions with",
    "NotImplementedError('IMPLEMENT ME HERE')",
]


def _capture_bl_prompt(*, iter_idx=0, previous_filled=None, previous_test_output=None) -> str:
    captured = {}

    def grab(prompt, **kw):
        captured["p"] = prompt
        return CompletionResult(
            text="# === FILE: x.py ===\ndef x(): pass\n",
            prompt_tokens=0, completion_tokens=0, model="mock",
        )

    class FakeLLM:
        def complete(self, prompt, **kw):
            return grab(prompt, **kw)

    run_python_implementer(
        spec_text="SPEC", stripped_files={"x.py": "def x(): pass\n"},
        llm=FakeLLM(),
        previous_filled=previous_filled,
        previous_test_output=previous_test_output,
        iter_idx=iter_idx,
    )
    return captured["p"]


_MINIMAL_AL_SKELETON = (
    "flow demo:\n"
    "  steps:\n"
    "    - run\n"
    "\n\n"
    "code run:\n"
    "  body: |\n"
    "    def run():\n"
    "        pass\n"
)


def _capture_al_prompt(*, iter_idx=0, previous_filled=None, previous_test_output=None) -> str:
    captured = {}

    def grab(prompt, **kw):
        captured["p"] = prompt
        return CompletionResult(
            text=_MINIMAL_AL_SKELETON, prompt_tokens=0, completion_tokens=0,
            model="mock",
        )

    class FakeLLM:
        def complete(self, prompt, **kw):
            return grab(prompt, **kw)

    run_al_implementer(
        spec_text="SPEC", skeleton_text=_MINIMAL_AL_SKELETON,
        llm=FakeLLM(),
        guide_text="GUIDE-CONTENT-MARKER",
        previous_filled=previous_filled,
        previous_test_output=previous_test_output,
        iter_idx=iter_idx,
    )
    return captured["p"]


def test_bl_prompt_contains_commit0_verbatim_phrases():
    """BL embeds commit0 user_prompt verbatim (per plan D-κ)."""
    p = _capture_bl_prompt()
    for phrase in _COMMIT0_VERBATIM_BL:
        assert phrase in p, f"BL prompt missing commit0 verbatim phrase: {phrase!r}"


def test_both_prompts_contain_commit0_semantic_phrases():
    """BL + AL both communicate the same core task intentions."""
    bl = _capture_bl_prompt()
    al = _capture_al_prompt()
    for phrase in _COMMIT0_SEMANTIC_PHRASES_BOTH:
        assert phrase in bl, f"BL prompt missing semantic phrase: {phrase!r}"
        assert phrase in al, f"AL prompt missing semantic phrase: {phrase!r}"


# ---------------------------------------------------------------------------
# Iter feedback section appears symmetrically
# ---------------------------------------------------------------------------


def test_iter0_no_previous_attempt_section_in_either():
    bl = _capture_bl_prompt(iter_idx=0)
    al = _capture_al_prompt(iter_idx=0)
    assert "Previous attempt" not in bl
    assert "Previous attempt" not in al


def test_iter_gt0_both_pipelines_include_feedback_section():
    bl = _capture_bl_prompt(
        iter_idx=1,
        previous_filled={"x.py": "def x(): return 1\n"},
        previous_test_output="==== 1 failed ====",
    )
    al = _capture_al_prompt(
        iter_idx=1,
        previous_filled=_MINIMAL_AL_SKELETON,
        previous_test_output="==== 1 failed ====",
    )
    # Both must show iteration index in label
    assert "Previous attempt (iter 0)" in bl
    assert "Previous attempt (iter 0)" in al
    # Both must show the test output in the feedback section
    assert "1 failed" in bl
    assert "1 failed" in al


# ---------------------------------------------------------------------------
# Authoring guide ONLY in AL
# ---------------------------------------------------------------------------


def test_authoring_guide_only_in_al_prompt():
    bl = _capture_bl_prompt()
    al = _capture_al_prompt()
    # Marker we passed in via guide_text on the AL side
    assert "GUIDE-CONTENT-MARKER" not in bl
    assert "GUIDE-CONTENT-MARKER" in al


# ---------------------------------------------------------------------------
# Signature symmetry: same kw-only feedback params on both implementers
# ---------------------------------------------------------------------------


def test_implementer_signatures_share_feedback_params():
    bl_sig = inspect.signature(run_python_implementer)
    al_sig = inspect.signature(run_al_implementer)
    required = {"previous_filled", "previous_test_output", "iter_idx",
                "temperature", "max_tokens"}
    bl_params = set(bl_sig.parameters)
    al_params = set(al_sig.parameters)
    missing_bl = required - bl_params
    missing_al = required - al_params
    assert not missing_bl, f"BL implementer missing params: {missing_bl}"
    assert not missing_al, f"AL implementer missing params: {missing_al}"


def test_implementer_max_tokens_defaults_equal():
    """Both implementers must default to the same max_tokens (12288 per H'.A)."""
    bl_default = inspect.signature(run_python_implementer).parameters["max_tokens"].default
    al_default = inspect.signature(run_al_implementer).parameters["max_tokens"].default
    assert bl_default == al_default == 12288


# ---------------------------------------------------------------------------
# Runner uses the same iter loop driver for both pipelines
# ---------------------------------------------------------------------------


def test_runner_has_both_cell_runners_and_shared_max_iterations():
    """Sanity: ``benchmarks/harness/runner.py`` exposes per-pipeline cell
    runners that share the MAX_ITERATIONS budget."""
    from benchmarks.harness import runner
    assert hasattr(runner, "_run_baseline_cell")
    assert hasattr(runner, "_run_al_cell")
    assert hasattr(runner, "MAX_ITERATIONS")
    assert runner.MAX_ITERATIONS == 3  # commit0 default


def test_truncate_tail_is_shared_helper_in_runner():
    """Both pipelines must use the same tail-truncation policy for
    test_output → so feedback budgets are identical."""
    from benchmarks.harness import runner
    assert hasattr(runner, "_truncate_tail")
    assert hasattr(runner, "MAX_FEEDBACK_TEST_OUTPUT_CHARS")
    assert runner.MAX_FEEDBACK_TEST_OUTPUT_CHARS == 8 * 1024


# ---------------------------------------------------------------------------
# Phase 1.AL.7 — preamble content reaches the LLM via the AL prompt
# ---------------------------------------------------------------------------


_PREAMBLE_SKELETON = (
    "preamble cachetools_keys:\n"
    "  source: cachetools/keys.py\n"
    "  body: |\n"
    "    class _HashedTuple(tuple):\n"
    "        \"\"\"Cached-hash tuple.\"\"\"\n"
    "        __hashvalue = None\n"
    "        def __hash__(self, hash=tuple.__hash__):\n"
    "            return hash(self)\n"
    "\n"
    "    _kwmark = (_HashedTuple,)\n"
    "\n\n"
    "flow keys_group:\n"
    "  steps:\n"
    "    - hashkey\n"
    "\n\n"
    "code hashkey:\n"
    "  body: |\n"
    "    def hashkey(*args, **kwargs):\n"
    "        \"\"\"Return a cache key.\"\"\"\n"
    "        pass\n"
)


def _capture_al_prompt_with(skeleton: str) -> str:
    """Helper: run the AL implementer on the given skeleton, return the
    prompt text the LLM would have received."""
    captured = {}

    def grab(prompt, **kw):
        captured["p"] = prompt
        return CompletionResult(
            text=skeleton, prompt_tokens=0, completion_tokens=0, model="mock",
        )

    class FakeLLM:
        def complete(self, prompt, **kw):
            return grab(prompt, **kw)

    run_al_implementer(
        spec_text="SPEC", skeleton_text=skeleton,
        llm=FakeLLM(),
        guide_text="GUIDE-MARKER",
        iter_idx=0,
    )
    return captured["p"]


def test_al_prompt_includes_preamble_body_text():
    """A skeleton containing a preamble block ⇒ the LLM prompt contains
    the preamble's body text. Without this, the LLM is blind to
    module-level Python and the BL/AL comparison is structurally unfair
    (the LLM in the BL path sees the full stripped .py including class
    _HashedTuple + _kwmark, but the AL path's LLM would not)."""
    p = _capture_al_prompt_with(_PREAMBLE_SKELETON)
    assert "class _HashedTuple(tuple):" in p, \
        "preamble's class declaration must appear in the AL prompt"
    assert "_kwmark = (_HashedTuple,)" in p, \
        "preamble's module-level constant must appear in the AL prompt"
    # And the code-node body stub must also appear (the LLM still has to fill it)
    assert "def hashkey(*args, **kwargs):" in p


def test_al_prompt_surfaces_critical_module_level_symbols_for_fair_compare():
    """For a repo whose stripped Python has module-level scaffolding,
    AL's prompt (preamble + skeleton) must surface the same critical
    symbols that BL's prompt (whole stripped file) gives naturally.

    Operational definition of 'fair comparison after Phase 1.AL':
    BL sees these symbols natively in the stripped Python; AL sees them
    via the preamble block. If preamble is missing or doesn't contain
    them, AL is at a structural disadvantage and the comparison is
    invalid.
    """
    al_prompt = _capture_al_prompt_with(_PREAMBLE_SKELETON)

    # The two critical pieces of module-level info that the
    # Phase 1.H'.F.2 run on cachetools showed were missing on the AL side:
    must_have_in_al = ["_HashedTuple", "_kwmark", "tuple.__hash__"]
    for marker in must_have_in_al:
        assert marker in al_prompt, (
            f"AL prompt must surface module-level symbol {marker!r} via "
            "preamble. Without it, the LLM reinvents (badly) and the "
            "BL/AL comparison is structurally unfair."
        )
