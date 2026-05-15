"""Pipeline A — direct Python implementer.

Fill stripped Python function bodies given the project spec, return the
full patched source(s). See benchmarks/agents/python_prompt.md.

The LLM is asked to emit files in a strict `# === FILE: <path> ===` format
so the runner can write each file back. We parse + validate the output
before reporting success.
"""

from __future__ import annotations

import ast
import re
from dataclasses import dataclass, field
from pathlib import Path

from al.llm import CompletionResult, LLMClient


PROMPT_PATH = Path(__file__).parent / "python_prompt.md"


@dataclass
class PythonImplementerResult:
    """Output of one python_implementer run."""

    files: dict[str, str] = field(default_factory=dict)
    """{relative_path: full_python_source}"""

    raw_completion: CompletionResult | None = None
    parse_ok: bool = False
    parse_error: str = ""
    prompt_used: str = ""

    @property
    def total_tokens(self) -> int:
        return self.raw_completion.total_tokens if self.raw_completion else 0


# ---------------------------------------------------------------------------
# Public entry
# ---------------------------------------------------------------------------


#: Max chars of previous test output to feed back into the next iter prompt.
#: 8 KB matches what aider-style loops typically afford; longer outputs are
#: tail-truncated.
MAX_FEEDBACK_TEST_OUTPUT_CHARS = 8 * 1024


def run_python_implementer(
    *,
    spec_text: str,
    stripped_files: dict[str, str],
    llm: LLMClient,
    previous_filled: dict[str, str] | None = None,
    previous_test_output: str | None = None,
    iter_idx: int = 0,
    temperature: float = 0.0,
    max_tokens: int = 12288,  # Phase 1.H'.A: synced with al_implementer
) -> PythonImplementerResult:
    """Run pipeline A — direct Python implementer.

    Phase 1.H'.F.2: now supports multi-iteration test-driven feedback. When
    ``iter_idx > 0``, ``previous_filled`` and ``previous_test_output`` are
    spliced into the prompt under a ``## Previous attempt`` section so the
    LLM can see what it produced last time + how pytest reacted.

    Args:
        spec_text: Project specification (README excerpt etc.).
        stripped_files: ``{relative_path: stripped_python}``. Order
            preserved; concatenated into the prompt with file markers.
        llm: LLMClient used to call the backend.
        previous_filled: Optional ``{relative_path: full_python}`` from
            the previous iter. Required if ``iter_idx > 0`` and used to
            seed the LLM's understanding of its prior output.
        previous_test_output: Optional pytest stdout from the previous
            iter. Truncated to ``MAX_FEEDBACK_TEST_OUTPUT_CHARS`` (tail).
        iter_idx: Which iteration this is (0-indexed). When 0 the prompt
            has no feedback section. When >0 it appends the feedback.
        temperature: passed through to ``llm.complete``.
        max_tokens: completion length budget.

    Returns:
        PythonImplementerResult. ``files`` is non-empty even on partial
        parse; ``parse_ok`` indicates whether all files ast.parse cleanly.
    """
    prompt = _build_prompt(
        spec_text=spec_text,
        stripped_files=stripped_files,
        previous_filled=previous_filled,
        previous_test_output=previous_test_output,
        iter_idx=iter_idx,
    )
    completion = llm.complete(
        prompt,
        max_tokens=max_tokens,
        temperature=temperature,
    )

    result = PythonImplementerResult(
        raw_completion=completion,
        prompt_used=prompt,
    )
    result.files = _split_file_markers(completion.text, stripped_files)
    result.parse_ok, result.parse_error = _validate_all_parse(result.files)
    return result


# ---------------------------------------------------------------------------
# Prompt assembly
# ---------------------------------------------------------------------------


def _build_prompt(
    *,
    spec_text: str,
    stripped_files: dict[str, str],
    previous_filled: dict[str, str] | None = None,
    previous_test_output: str | None = None,
    iter_idx: int = 0,
) -> str:
    """Substitute {spec_text}, {stripped_source}, and {iter_history} into the
    prompt template.

    ``{iter_history}`` is empty when iter_idx == 0 (initial attempt) and
    contains the previous filled files + truncated test output when > 0.
    """
    template = PROMPT_PATH.read_text(encoding="utf-8")
    stripped_block = _format_stripped_block(stripped_files)
    iter_history = _format_iter_history(
        iter_idx, previous_filled, previous_test_output
    )
    # Use simple .replace() to avoid mistaking literal braces in code as format keys
    return (
        template
        .replace("{spec_text}", spec_text)
        .replace("{stripped_source}", stripped_block)
        .replace("{iter_history}", iter_history)
    )


def _format_stripped_block(stripped_files: dict[str, str]) -> str:
    """Concatenate stripped files with `# === FILE: ===` markers."""
    parts = []
    for rel_path, source in stripped_files.items():
        parts.append(f"# === FILE: {rel_path} ===\n{source.rstrip()}\n")
    return "\n".join(parts)


def _format_iter_history(
    iter_idx: int,
    previous_filled: dict[str, str] | None,
    previous_test_output: str | None,
) -> str:
    """Build the ``## Previous attempt`` block. Empty string when iter_idx=0."""
    if iter_idx <= 0:
        return ""
    parts = [
        "",
        f"## Previous attempt (iter {iter_idx - 1})",
        "",
        "Your previous attempt produced this code, which did not fully pass "
        "the test suite. Use the test output below to identify and fix the "
        "problems, then emit a corrected full version.",
        "",
    ]
    if previous_filled:
        parts.append("### Previous filled files")
        parts.append("")
        for rel_path, source in previous_filled.items():
            parts.append(f"# === FILE: {rel_path} ===")
            parts.append(source.rstrip())
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
    parts.append("### Now: emit a corrected full version with `# === FILE: ===` markers.")
    parts.append("")
    return "\n".join(parts)


def _truncate_tail(text: str, max_chars: int) -> str:
    """Keep the LAST ``max_chars`` chars of ``text``. Pytest summary +
    failure details are at the END of stdout, so tail-truncation
    preserves the actionable info."""
    if len(text) <= max_chars:
        return text
    return f"...(truncated {len(text) - max_chars} chars from head)...\n" + text[-max_chars:]


# ---------------------------------------------------------------------------
# Output parsing
# ---------------------------------------------------------------------------


_FILE_MARKER_RE = re.compile(r"^#\s*===\s*FILE:\s*(\S+?)\s*===\s*$", re.MULTILINE)


def _split_file_markers(
    completion_text: str,
    stripped_files: dict[str, str],
) -> dict[str, str]:
    """Split LLM output by `# === FILE: path ===` markers.

    If LLM forgot markers AND there's only one stripped file, treat the
    entire output as that file's content (lenient).

    Returns ``{relative_path: source}``. Empty if parse fails entirely.
    """
    # Strip leading prose / markdown fences (some LLMs add ```python despite the rule)
    text = _strip_code_fences(completion_text).strip()

    matches = list(_FILE_MARKER_RE.finditer(text))
    if not matches:
        if len(stripped_files) == 1:
            # Lenient single-file case
            only_path = next(iter(stripped_files))
            return {only_path: text}
        return {}

    files: dict[str, str] = {}
    for idx, m in enumerate(matches):
        path = m.group(1)
        start = m.end()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        body = text[start:end].strip("\n")
        files[path] = body
    return files


def _strip_code_fences(text: str) -> str:
    """Remove leading/trailing ```python / ``` fences if present."""
    text = text.strip()
    if text.startswith("```"):
        first_newline = text.find("\n")
        if first_newline != -1:
            text = text[first_newline + 1:]
    if text.rstrip().endswith("```"):
        text = text.rstrip()[: -len("```")]
    return text


def _validate_all_parse(files: dict[str, str]) -> tuple[bool, str]:
    """Return (all_ok, first_error_message). Empty dict = not OK."""
    if not files:
        return False, "no files produced (LLM may have forgotten file markers)"
    for path, source in files.items():
        try:
            ast.parse(source, filename=path)
        except SyntaxError as e:
            return False, f"{path}: {e}"
    return True, ""
