"""Pipeline C — greenfield agent-lang implementer (v0.7).

Given stripped Python files + spec + authoring guide, the LLM produces
ONE OR MORE .al files (separated by ``---FILE: <relpath>---`` markers).
We parse each, link via the resolver, run strict TypedAnnotation
validation, and ast-check every code body — surfacing any greenfield
errors back to the next iter.

Pipeline B (skeleton-based) ↔ Pipeline C (greenfield) symmetry:

| Pipeline B                       | Pipeline C                         |
|----------------------------------|------------------------------------|
| Input = spec + hand .al skeleton | Input = spec + stripped Python     |
| Output = filled .al text         | Output = ``---FILE: ...---`` blocks|
| Inject = inject_filled_al        | Inject = inject_filled_al per file |
| Single .al                       | Multi-file via v0.7 resolver       |

The implementer here returns the LLM's raw text + a parsed list of
``GreenfieldFile(path, al_text, program)`` plus diagnostics. The caller
(``runner._run_al_greenfield_cell``) is responsible for injecting each
file back into the workdir.
"""

from __future__ import annotations

import ast
import re
from dataclasses import dataclass, field
from pathlib import Path

from al.llm import CompletionResult, LLMClient
from al.parser import LexError, ParseError, parse
from al.parser.ast_nodes import BlockScalar, Program
from al.parser.resolver import (
    ImportCycleError,
    ModuleGraph,
    ModuleNotFoundError,
    resolve_from_text,
)
from al.parser.validate import (
    ValidationIssue,
    validate_typed_annotations,
)


PROMPT_PATH = Path(__file__).parent / "al_greenfield_prompt.md"
GUIDE_PATH = (
    Path(__file__).resolve().parents[2] / "docs" / "authoring-al.md"
)


# Marker recognized at the start of every emitted file block.
# Example: ``---FILE: cachetools/lru.al---``
_FILE_MARKER_RE = re.compile(
    r"^---FILE:\s*(?P<path>[^\s]+\.al)\s*---\s*$",
    re.MULTILINE,
)


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class GreenfieldFile:
    """One .al emitted by the LLM."""

    relpath: str
    """Project-relative path to the .al (e.g. ``cachetools/lru.al``)."""

    al_text: str
    """Raw .al source as emitted."""

    program: Program | None = None
    """Parsed Program; None if parse failed."""

    parse_error: str = ""

    body_errors: dict[str, str] = field(default_factory=dict)
    """``{node_name: error_message}`` for any code body that didn't ast.parse."""

    validation_issues: list[ValidationIssue] = field(default_factory=list)
    """Strict TypedAnnotation issues (warning-level — non-fatal)."""

    @property
    def ok(self) -> bool:
        return (
            self.program is not None
            and not self.parse_error
            and not self.body_errors
        )


@dataclass
class ALGreenfieldResult:
    """Output of one run_al_greenfield_implementer call."""

    files: list[GreenfieldFile] = field(default_factory=list)
    raw_completion: CompletionResult | None = None
    prompt_used: str = ""
    parse_overall_ok: bool = False
    """True if every file parsed; False if any file failed."""
    resolver_error: str = ""
    """Set when the multi-file linkage (imports / cycles) failed."""
    graph: ModuleGraph | None = None
    """Linked ModuleGraph when resolver succeeded; None otherwise."""

    @property
    def total_tokens(self) -> int:
        return self.raw_completion.total_tokens if self.raw_completion else 0

    @property
    def all_files_clean(self) -> bool:
        """True iff every file parsed AND every body is valid Python AND the
        cross-file resolver linked successfully."""
        return (
            self.parse_overall_ok
            and not self.resolver_error
            and all(f.ok for f in self.files)
        )


# ---------------------------------------------------------------------------
# Public entry
# ---------------------------------------------------------------------------


MAX_FEEDBACK_TEST_OUTPUT_CHARS = 8 * 1024


def run_al_greenfield_implementer(
    *,
    spec_text: str,
    stripped_files: dict[str, str],
    llm: LLMClient,
    guide_text: str | None = None,
    previous_filled: str | None = None,
    previous_test_output: str | None = None,
    iter_idx: int = 0,
    temperature: float = 0.0,
    max_tokens: int = 16384,
) -> ALGreenfieldResult:
    """Run pipeline C — greenfield agent-lang implementer.

    Args:
        spec_text: Project spec / README excerpt.
        stripped_files: ``{relpath: source}`` of every non-test, non-build
            Python file in the project (commit0 stripped — bodies are
            NotImplementedError stubs). This is the SAME input shape
            Pipeline A receives, ensuring BL/C symmetry.
        llm: LLMClient.
        guide_text: Authoring guide; defaults to docs/authoring-al.md.
        previous_filled: Last iter's raw greenfield output (for feedback).
        previous_test_output: Last iter's pytest stdout (tail-truncated).
        iter_idx: 0-indexed iteration.
        temperature, max_tokens: passed to llm.complete. Default
            max_tokens=16384 (greenfield can be larger than skeleton).

    Returns:
        ALGreenfieldResult with parsed files, resolver graph, and any
        diagnostics. Caller injects each file's code-node bodies into
        the workdir via inject_filled_al.
    """
    guide = guide_text if guide_text is not None else _load_guide()
    prompt = _build_prompt(
        guide=guide,
        spec_text=spec_text,
        stripped_files=stripped_files,
        previous_filled=previous_filled,
        previous_test_output=previous_test_output,
        iter_idx=iter_idx,
    )
    completion = llm.complete(
        prompt, max_tokens=max_tokens, temperature=temperature,
    )

    result = ALGreenfieldResult(
        raw_completion=completion,
        prompt_used=prompt,
    )
    result.files = _split_files(completion.text)
    _validate_files(result)
    _link_files(result)
    return result


# ---------------------------------------------------------------------------
# Prompt assembly
# ---------------------------------------------------------------------------


def _build_prompt(
    *,
    guide: str,
    spec_text: str,
    stripped_files: dict[str, str],
    previous_filled: str | None,
    previous_test_output: str | None,
    iter_idx: int,
) -> str:
    template = PROMPT_PATH.read_text(encoding="utf-8")
    stripped_section = _render_stripped_files(stripped_files)
    iter_history = _format_iter_history(
        iter_idx, previous_filled, previous_test_output
    )
    return (
        template
        .replace("{authoring_guide}", guide)
        .replace("{spec_text}", spec_text)
        .replace("{stripped_python_section}", stripped_section)
        .replace("{iter_history}", iter_history)
    )


def _render_stripped_files(files: dict[str, str]) -> str:
    """Format the stripped Python files as a series of ``=== <path> ===``
    sections. Order: sorted by path, for stability across iters.
    """
    parts: list[str] = []
    for rel in sorted(files):
        parts.append(f"### `{rel}`")
        parts.append("")
        parts.append("```python")
        parts.append(files[rel].rstrip())
        parts.append("```")
        parts.append("")
    return "\n".join(parts)


def _format_iter_history(
    iter_idx: int,
    previous_filled: str | None,
    previous_test_output: str | None,
) -> str:
    if iter_idx <= 0:
        return ""
    parts = [
        "",
        f"## Previous attempt (iter {iter_idx - 1})",
        "",
        "Your previous attempt produced this multi-file .al output, which "
        "did not fully pass the test suite. Read the pytest output below, "
        "identify the bugs, and emit a corrected full output.",
        "",
    ]
    if previous_filled:
        parts.append("### Previous .al output")
        parts.append("")
        parts.append("```")
        parts.append(previous_filled.rstrip())
        parts.append("```")
        parts.append("")
    if previous_test_output:
        parts.append("### Pytest output (tail-truncated to ~8 KB)")
        parts.append("")
        parts.append("```")
        parts.append(_truncate_tail(previous_test_output))
        parts.append("```")
        parts.append("")
    parts.append(
        "### Now: emit a corrected multi-file output. Same rules: "
        "``---FILE: <path>---`` markers, one .al per .py, no new files."
    )
    parts.append("")
    return "\n".join(parts)


def _truncate_tail(text: str, max_chars: int = MAX_FEEDBACK_TEST_OUTPUT_CHARS) -> str:
    if len(text) <= max_chars:
        return text
    return f"...(truncated {len(text) - max_chars} chars from head)...\n" + text[-max_chars:]


def _load_guide() -> str:
    return GUIDE_PATH.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# Output splitting + validation
# ---------------------------------------------------------------------------


def _split_files(raw_text: str) -> list[GreenfieldFile]:
    """Split LLM output into files at ``---FILE: <path>---`` markers.

    Tolerates leading prose (skipped); first marker starts file 0.
    Markers must appear at the start of a line (regex uses MULTILINE).
    """
    text = raw_text.replace("\r\n", "\n")
    matches = list(_FILE_MARKER_RE.finditer(text))
    if not matches:
        # No file markers — treat the entire output as one anonymous file.
        return [GreenfieldFile(relpath="<unnamed>.al", al_text=text.strip())]
    out: list[GreenfieldFile] = []
    for i, m in enumerate(matches):
        path = m.group("path")
        body_start = m.end()
        body_end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        body = text[body_start:body_end].strip()
        out.append(GreenfieldFile(relpath=path, al_text=body))
    return out


def _validate_files(result: ALGreenfieldResult) -> None:
    """Parse each file + ast-check every code body. Sets per-file errors."""
    any_failed = False
    for f in result.files:
        try:
            f.program = parse(f.al_text)
        except (ParseError, LexError) as e:
            f.parse_error = str(e)
            any_failed = True
            continue

        # ast.parse every code body to flag SyntaxErrors before injection.
        for d in f.program.defs:
            if d.kind != "code":
                continue
            body_field = next(
                (fld for fld in d.fields if fld.name == "body"
                 and isinstance(fld.value, BlockScalar)),
                None,
            )
            if body_field is None:
                f.body_errors[d.name] = "missing body field"
                continue
            try:
                ast.parse(body_field.value.text, filename=f.relpath)
            except SyntaxError as e:
                f.body_errors[d.name] = str(e)

        # Strict TypedAnnotation validation — warnings, non-fatal.
        f.validation_issues = validate_typed_annotations(f.program)

    result.parse_overall_ok = not any_failed and bool(result.files)


def _link_files(result: ALGreenfieldResult) -> None:
    """Run the v0.7 resolver across the parsed files to catch missing
    imports / cycles. Skipped if any file failed to parse.

    Chooses the root somewhat heuristically: ``main.al`` if present,
    else the first emitted file. For multi-file projects without a
    clear root, callers should examine result.files individually.
    """
    if not result.parse_overall_ok:
        return
    files_by_module = {_relpath_to_module(f.relpath): f.al_text for f in result.files}
    if not files_by_module:
        return
    root_name = "main" if "main" in files_by_module else next(iter(files_by_module))
    try:
        result.graph = resolve_from_text(
            files_by_module[root_name], root_name, files_by_module
        )
    except (ModuleNotFoundError, ImportCycleError) as e:
        result.resolver_error = f"{type(e).__name__}: {e}"


def _relpath_to_module(relpath: str) -> str:
    """``cachetools/lru.al`` → ``cachetools.lru``."""
    base = relpath.removesuffix(".al")
    return base.replace("/", ".")
