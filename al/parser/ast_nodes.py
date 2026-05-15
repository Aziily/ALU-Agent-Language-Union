"""AST dataclasses for agent-lang v0.6.

Public contract — consumed by codegen, runtime, and external tools.
Modify with caution; bumping the AST shape requires a parser version bump
and migration note (see docs/ARCHITECTURE.md § 3.1).

Design notes:
- All nodes carry a ``loc: Loc`` (1-indexed line/col) for editor mapping.
- ``FieldValue`` is a sealed family of variants distinguished by class.
- ``StepItem`` likewise — RefStep / ParallelStep / EachStep / IfStep.
- v0.6 adds ``set`` as a Definition.kind, plus ``ReferenceList`` for
  multi-value reference fields (``tools:``, ``skills:``, ``extensions:``,
  ``use:`` with list form).
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


StepItem = Union[RefStep, ParallelStep, EachStep, IfStep]


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
class Program:
    """Root AST node — a list of top-level definitions in source order."""

    defs: list[Definition] = field(default_factory=list)
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
    "input": (InlineText, FieldGroup),
    "output": (InlineText, FieldGroup),
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
    "code": {"intent", "input", "output", "body"},
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
