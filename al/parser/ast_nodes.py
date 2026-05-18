"""AST dataclasses for agent-lang v0.7.

Public contract — consumed by codegen, runtime, and external tools.
Modify with caution; bumping the AST shape requires a parser version bump
and migration note (see docs/ARCHITECTURE.md § 3.1).

Design notes:
- All nodes carry a ``loc: Loc`` (1-indexed line/col) for editor mapping.
- ``FieldValue`` is a sealed family of variants distinguished by class.
- ``StepItem`` likewise — RefStep / ParallelStep / EachStep / IfStep / ReturnStep.
- v0.6 adds ``set`` as a Definition.kind, plus ``ReferenceList`` for
  multi-value reference fields (``tools:``, ``skills:``, ``extensions:``,
  ``use:`` with list form).
- v0.7 adds ``TypedAnnotation`` for ``input:`` / ``output:`` values
  (``T(description)`` form), ``ImportDecl`` for top-level cross-file
  imports, and ``ReturnStep`` for flow-explicit output references.
  See ``docs/al-spec.md`` § 4.12 (I/O grammar), § 4.13 (multi-file),
  § 4.6 (return).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Literal, Union


# ---------------------------------------------------------------------------
# Source location
# ---------------------------------------------------------------------------


@dataclass
class Loc:
    """1-indexed source location span. ``end_*`` are optional."""

    line: int
    col: int
    end_line: int | None = None
    end_col: int | None = None


# ---------------------------------------------------------------------------
# FieldValue family
# ---------------------------------------------------------------------------


@dataclass
class InlineText:
    """A single-line value after a ``key:`` (e.g. ``intent: top news``)."""

    text: str
    loc: Loc


@dataclass
class TypedAnnotation:
    """v0.7 value for ``input:`` / ``output:`` fields.

    Form ``T(description)``: ``type_ann`` is the textual Python type
    annotation (``str``, ``list[str]``, ``dict[str, int]`` etc.) and
    ``description`` is the optional natural-language hint between the
    parentheses (``article urls``, ``title->body, English``). Both are
    stored as raw strings — type validity is checked by a separate
    pass (see ``al.parser.validate.validate_typed_annotations``), not at
    parse time, so legacy v0.6 free-English values still parse (with
    ``description=None`` and ``type_ann`` carrying the whole line).

    The serializer round-trips by writing ``type_ann`` + (if description)
    ``(description)``. See spec § 4.12.
    """

    type_ann: str
    description: str | None
    loc: Loc


@dataclass
class BlockScalar:
    """Multi-line ``|`` literal (e.g. ``prompt:`` body, ``code.body:`` body).

    Text is dedented to the minimum common indent of its body, same rule
    as YAML literal blocks.
    """

    text: str
    loc: Loc


@dataclass
class FieldGroup:
    """Nested key:value block (e.g. structured ``output:``)."""

    fields: list["Field"]
    loc: Loc


@dataclass
class StepList:
    """Ordered list of step items (only valid in ``steps:`` field)."""

    items: list["StepItem"]
    loc: Loc


@dataclass
class Reference:
    """A single bare-name reference to another top-level definition.

    Used for ``fallback:`` and single-value ``use:``.
    """

    name: str
    loc: Loc


@dataclass
class ReferenceList:
    """A ``- name`` list of bare references.

    Used for ``tools:``, ``skills:``, ``extensions:`` and multi-value
    ``use:`` (v0.6 new).
    """

    names: list[str]
    loc: Loc


FieldValue = Union[
    InlineText,
    TypedAnnotation,
    BlockScalar,
    FieldGroup,
    StepList,
    Reference,
    ReferenceList,
]


# ---------------------------------------------------------------------------
# StepItem family
# ---------------------------------------------------------------------------


@dataclass
class RefStep:
    """A bare-name step reference (``- fetch_sources``)."""

    name: str
    loc: Loc


@dataclass
class ParallelStep:
    """``- parallel:`` block — children run concurrently."""

    items: list["StepItem"]
    loc: Loc


@dataclass
class EachStep:
    """``- each <binding>:`` block — children run once per element."""

    binding: str
    items: list["StepItem"]
    loc: Loc


@dataclass
class IfStep:
    """``- if <cond>: ... else: ...`` block."""

    cond: str
    then: list["StepItem"]
    else_: list["StepItem"] | None
    loc: Loc


@dataclass
class ReturnStep:
    """v0.7: ``- return <ref>`` — flow's explicit output.

    ``target`` is the bare name of a previously-listed step (RefStep,
    or any node referenced earlier in this flow). Semantically marks
    that step's return value as the flow's overall output. Must be the
    last item in ``steps:`` and at most one ReturnStep per flow.
    """

    target: str
    loc: Loc


StepItem = Union[RefStep, ParallelStep, EachStep, IfStep, ReturnStep]


# ---------------------------------------------------------------------------
# Top level
# ---------------------------------------------------------------------------


@dataclass
class Field:
    """``name: value`` pair inside a Definition. Order is preserved."""

    name: str
    value: FieldValue
    loc: Loc


@dataclass
class Definition:
    """A top-level ``flow|agent|code|set|preamble <name>:`` definition.

    v0.6 added ``"set"`` as a valid kind.
    v0.7 (Phase 1.AL.2) added ``"preamble"`` to express module-level Python
    (imports, classes, constants, type aliases) as context for the LLM —
    preambles are NOT injected into the workdir during the benchmark
    pipeline; the original stripped Python already contains them. See
    ``docs/preamble-design.md`` for rationale.
    """

    kind: Literal["flow", "code", "agent", "set", "preamble"]
    name: str
    fields: list[Field] = field(default_factory=list)
    loc: Loc = field(default_factory=lambda: Loc(1, 1))


@dataclass
class ImportDecl:
    """v0.7: top-level ``import X`` or ``from X import Y, Z`` declaration.

    Lives in ``Program.imports`` (not ``Program.defs``) — imports are
    not Definition nodes; they're a separate top-level category that
    must appear before the first Definition. See spec § 4.13.

    For ``import foo`` / ``import foo as bar``:
        kind="import", module="foo", names=[], alias=None|"bar"
    For ``from foo import x, y``:
        kind="from", module="foo", names=["x","y"], alias=None
    """

    kind: Literal["import", "from"]
    module: str
    names: list[str] = field(default_factory=list)
    alias: str | None = None
    loc: Loc = field(default_factory=lambda: Loc(1, 1))


@dataclass
class Program:
    """Root AST node — a list of top-level definitions in source order.

    v0.7: ``imports`` carries top-level ``import``/``from`` declarations
    appearing before any Definition. Empty list = v0.6-compatible single
    file with no cross-file references.
    """

    defs: list[Definition] = field(default_factory=list)
    imports: list[ImportDecl] = field(default_factory=list)
    loc: Loc = field(default_factory=lambda: Loc(1, 1))


# ---------------------------------------------------------------------------
# Field-name → expected FieldValue type table (used by parser dispatch)
# ---------------------------------------------------------------------------

#: Map field name to the FieldValue subclass(es) the parser will produce
#: when given that field. Where two are listed, the parser disambiguates
#: by trailing-line shape (see docs/design/parser.md § 4).
FIELD_VALUE_HINTS: dict[str, tuple[type, ...]] = {
    "intent": (InlineText,),
    "schedule": (InlineText,),
    # v0.7.1 (Codex co-iter round 1): ``target:`` on code nodes says
    # exactly which ``<relpath>::<qualname>`` to patch. When present,
    # ``body:`` may contain just statements (no ``def`` line) — inject
    # reconstructs the signature from the stripped Python.
    "target": (InlineText,),
    # v0.7: inline I/O values are TypedAnnotation, not InlineText. Legacy
    # free-English values (v0.6) parse as TypedAnnotation with
    # description=None and type_ann carrying the raw text — the parser
    # is lenient at parse time; strict Python-type validation is in
    # ``al.parser.validate.validate_typed_annotations``.
    "input": (TypedAnnotation, FieldGroup),
    "output": (TypedAnnotation, FieldGroup),
    "prompt": (BlockScalar,),
    "body": (BlockScalar,),
    "memory": (BlockScalar,),
    "steps": (StepList,),
    "fallback": (Reference,),
    "use": (Reference, ReferenceList),
    "tools": (ReferenceList,),
    "skills": (ReferenceList,),
    "extensions": (ReferenceList,),
    # Phase 1.AL.2: preamble fields
    "source": (InlineText,),  # optional file-path hint on preamble
    # Phase 1.AL-LOOP H4 (Round 2): structured imports field on preamble.
    # BlockScalar carrying raw ``import`` / ``from ... import ...`` lines.
    # Lets the LLM see imports as a discrete unit separated from class /
    # constants and lets the skeleton shrink by extracting imports out of
    # the preamble ``body:`` block.
    "imports": (BlockScalar,),
    # Phase 1.AL-LOOP H5 (Round 3): structured constants field on preamble.
    # BlockScalar carrying module-level value assignments whose target is a
    # simple Name (``__all__ = (...)``, ``PI = 3.14``, ``X: int = 1``).
    # Tuple-unpack assignments and attribute / subscript assignments stay
    # in ``body:`` because they're often computation, not pure constants.
    "constants": (BlockScalar,),
}

#: The ordered key sequence used by the canonical serializer.
CANONICAL_FIELD_ORDER: tuple[str, ...] = (
    "intent",
    "schedule",
    "target",     # v0.7.1: code node's <relpath>::<qualname> target
    "source",     # Phase 1.AL.2: preamble's file-path hint, near top
    "imports",    # Phase 1.AL-LOOP H4: preamble structured imports
    "constants",  # Phase 1.AL-LOOP H5: preamble structured constants
    "input",
    "output",
    "use",
    "tools",
    "skills",
    "extensions",
    "prompt",
    "body",
    "memory",
    "steps",
    "fallback",
)


#: Which fields each declarator-kind allows.
#: Used by serializer + new fairness tests as a single source of truth.
ALLOWED_FIELDS_BY_KIND: dict[str, set[str]] = {
    "flow": {"intent", "schedule", "input", "output", "steps"},
    "code": {"intent", "target", "input", "output", "body"},
    "agent": {"intent", "input", "output", "prompt", "fallback", "use"},
    "set": {"intent", "tools", "skills", "extensions", "memory"},
    # Phase 1.AL.2: preamble takes optional `source:` hint and
    # required `body:` (raw Python). It is shown to the LLM as
    # module-level context but never injected by the benchmark pipeline.
    # Phase 1.AL-LOOP H4 (Round 2): `imports:` is an optional structured
    # block scalar that holds the file's import lines, hoisted out of
    # the body so LLM sees them as a separate unit.
    # Phase 1.AL-LOOP H5 (Round 3): `constants:` is an optional structured
    # block scalar that holds module-level value assignments (simple
    # ``NAME = value`` / ``NAME: type = value``) — hoisted out of body
    # too, so the body conveys class / docstring only.
    "preamble": {"source", "imports", "constants", "body"},
}
