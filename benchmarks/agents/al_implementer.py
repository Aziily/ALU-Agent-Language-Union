"""Pipeline B — agent-lang implementer.

Fill the ``body:`` field of every ``code`` node in an agent-lang skeleton.
The LLM receives (authoring_guide + spec + skeleton) and outputs a complete
filled agent-lang source. We then parse it + verify each code body is
valid Python.
"""

from __future__ import annotations

import ast
from dataclasses import dataclass, field
from pathlib import Path

from al.llm import CompletionResult, LLMClient
from al.parser import parse, ParseError, LexError


PROMPT_PATH = Path(__file__).parent / "al_prompt.md"
GUIDE_PATH = (
    Path(__file__).resolve().parents[2]
    / "docs" / "authoring-al.md"
)


@dataclass
class ALImplementerResult:
    """Output of one al_implementer run."""

    filled_al: str = ""
    raw_completion: CompletionResult | None = None
    al_parse_ok: bool = False
    al_parse_error: str = ""
    body_validation: dict[str, str] = field(default_factory=dict)
    """{node_name: error_message_or_empty_string}"""
    prompt_used: str = ""

    @property
    def total_tokens(self) -> int:
        return self.raw_completion.total_tokens if self.raw_completion else 0

    @property
    def all_bodies_valid(self) -> bool:
        return all(err == "" for err in self.body_validation.values())


# ---------------------------------------------------------------------------
# Public entry
# ---------------------------------------------------------------------------


#: Max chars of previous test output to feed back. Same as BL (8 KB).
MAX_FEEDBACK_TEST_OUTPUT_CHARS = 8 * 1024


def run_al_implementer(
    *,
    spec_text: str,
    skeleton_text: str,
    llm: LLMClient,
    guide_text: str | None = None,
    previous_filled: str | None = None,
    previous_test_output: str | None = None,
    iter_idx: int = 0,
    temperature: float = 0.0,
    max_tokens: int = 12288,
) -> ALImplementerResult:
    """Run pipeline B — agent-lang implementer.

    Phase 1.H'.F.2: now supports multi-iteration test-driven feedback.
    When ``iter_idx > 0``, ``previous_filled`` (the .al text from
    last iter) and ``previous_test_output`` (pytest stdout) are spliced
    into the prompt under a ``## Previous attempt`` section so the LLM
    can self-correct — symmetric with the python_implementer path so
    BL/AL share the same feedback mechanism.

    Args:
        spec_text: Project spec / README excerpt.
        skeleton_text: agent-lang source with stubbed `body:` fields.
        llm: LLMClient used to call the backend.
        guide_text: Authoring guide text. Defaults to the canonical
            ``docs/guides/authoring-agent-lang.md``.
        previous_filled: Optional last-iter filled .al text.
        previous_test_output: Optional pytest stdout from last iter
            (tail-truncated to 8 KB).
        iter_idx: 0-indexed iteration. 0 → no feedback section.
        temperature: passed to ``llm.complete``.
        max_tokens: completion length budget (Phase 1.H'.A: synced with
            python_implementer to keep BL/AL comparison fair).

    Returns:
        ALImplementerResult.
    """
    guide = guide_text if guide_text is not None else _load_guide()
    prompt = _build_prompt(
        guide=guide,
        spec_text=spec_text,
        skeleton_text=skeleton_text,
        previous_filled=previous_filled,
        previous_test_output=previous_test_output,
        iter_idx=iter_idx,
    )
    completion = llm.complete(
        prompt,
        max_tokens=max_tokens,
        temperature=temperature,
    )

    result = ALImplementerResult(
        raw_completion=completion,
        prompt_used=prompt,
    )
    result.filled_al = _strip_fences(completion.text).strip()
    _validate(result)
    return result


# ---------------------------------------------------------------------------
# Prompt assembly
# ---------------------------------------------------------------------------


def _build_prompt(
    *,
    guide: str,
    spec_text: str,
    skeleton_text: str,
    previous_filled: str | None = None,
    previous_test_output: str | None = None,
    iter_idx: int = 0,
) -> str:
    template = PROMPT_PATH.read_text(encoding="utf-8")
    iter_history = _format_iter_history(
        iter_idx, previous_filled, previous_test_output
    )
    return (
        template
        .replace("{authoring_guide}", guide)
        .replace("{spec_text}", spec_text)
        .replace("{skeleton_text}", skeleton_text)
        .replace("{iter_history}", iter_history)
    )


def _format_iter_history(
    iter_idx: int,
    previous_filled: str | None,
    previous_test_output: str | None,
) -> str:
    """Build the ``## Previous attempt`` block. Empty when iter_idx=0."""
    if iter_idx <= 0:
        return ""
    parts = [
        "",
        f"## Previous attempt (iter {iter_idx - 1})",
        "",
        "Your previous attempt produced this .al source, which did "
        "not fully pass the test suite. Read the pytest output below, "
        "identify the problems in your code-node bodies, and emit a "
        "corrected full .al.",
        "",
    ]
    if previous_filled:
        parts.append("### Previous filled .al")
        parts.append("")
        parts.append("```")
        parts.append(previous_filled.rstrip())
        parts.append("```")
        parts.append("")
    if previous_test_output:
        truncated = _truncate_tail(
            previous_test_output, MAX_FEEDBACK_TEST_OUTPUT_CHARS
        )
        parts.append("### Pytest output from previous attempt")
        parts.append("(tail-truncated to ~8 KB if longer)")
        parts.append("")
        parts.append("```")
        parts.append(truncated)
        parts.append("```")
        parts.append("")
    parts.append(
        "### Now: emit a corrected full .al source. Same rules: keep"
        " every non-body line byte-identical with the skeleton; only the"
        " body of each `code` node may change."
    )
    parts.append("")
    return "\n".join(parts)


def _truncate_tail(text: str, max_chars: int) -> str:
    """Keep the LAST ``max_chars`` chars. Pytest's summary + failure
    details are at the end of stdout."""
    if len(text) <= max_chars:
        return text
    return f"...(truncated {len(text) - max_chars} chars from head)...\n" + text[-max_chars:]


def _load_guide() -> str:
    return GUIDE_PATH.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# Output validation
# ---------------------------------------------------------------------------


def _strip_fences(text: str) -> str:
    """Strip leading/trailing ```text or ```al fences if present."""
    text = text.strip()
    if text.startswith("```"):
        nl = text.find("\n")
        if nl != -1:
            text = text[nl + 1:]
    if text.rstrip().endswith("```"):
        text = text.rstrip()[: -len("```")]
    return text


def _validate(result: ALImplementerResult) -> None:
    """Parse the filled agent-lang and check each code body is valid Python.

    Sets ``al_parse_ok`` / ``al_parse_error`` and populates
    ``body_validation`` mapping ``{node_name: "" | error_message}``.
    """
    try:
        program = parse(result.filled_al)
    except (ParseError, LexError) as e:
        result.al_parse_ok = False
        result.al_parse_error = str(e)
        return
    result.al_parse_ok = True

    from al.parser.ast_nodes import BlockScalar
    for d in program.defs:
        if d.kind != "code":
            continue
        body_field = next(
            (f for f in d.fields if f.name == "body"
             and isinstance(f.value, BlockScalar)),
            None,
        )
        if body_field is None:
            result.body_validation[d.name] = "missing body field"
            continue
        try:
            ast.parse(body_field.value.text, filename=f"<{d.name}>")
            result.body_validation[d.name] = ""
        except SyntaxError as e:
            result.body_validation[d.name] = str(e)
