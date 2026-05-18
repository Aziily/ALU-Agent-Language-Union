"""AST → text serializer (canonical formatting).

Roundtrip contract: ``parse(serialize(parse(x))) == parse(x)`` (AST equivalence,
not byte equivalence). See docs/design/parser.md § 5.
"""

from __future__ import annotations

from io import StringIO

from al.parser.ast_nodes import (
    Program,
    Definition,
    Field,
    ImportDecl,
    InlineText,
    TypedAnnotation,
    BlockScalar,
    FieldGroup,
    StepList,
    Reference,
    ReferenceList,
    RefStep,
    ParallelStep,
    EachStep,
    IfStep,
    ReturnStep,
    CANONICAL_FIELD_ORDER,
)


INDENT = "  "  # 2 spaces per level


def serialize(program: Program) -> str:
    """Serialize a :class:`Program` AST back to ``.al`` text.

    Phase 1.AL.2: ``preamble`` declarations are emitted FIRST (in their
    original relative order), then everything else in source order.
    Preambles are conceptually module-level context shown to the LLM;
    putting them at the top mirrors how Python ``import`` + module-level
    constants appear at the top of a real source file.
    """
    out = StringIO()
    # v0.7: imports come first, before any Definition.
    for imp in program.imports:
        _emit_import(imp, out)
    if program.imports:
        out.write("\n")
    # Stable partition: preambles in original order, then the rest.
    preambles = [d for d in program.defs if d.kind == "preamble"]
    others = [d for d in program.defs if d.kind != "preamble"]
    ordered = preambles + others
    for i, d in enumerate(ordered):
        if i > 0:
            out.write("\n\n")  # 2 blank lines between top-level defs
        _emit_definition(d, out)
    out.write("\n")  # trailing newline
    return out.getvalue()


def _emit_import(imp: ImportDecl, out: StringIO) -> None:
    """Emit one v0.7 ImportDecl as text."""
    if imp.kind == "import":
        if imp.alias:
            out.write(f"import {imp.module} as {imp.alias}\n")
        else:
            out.write(f"import {imp.module}\n")
    elif imp.kind == "from":
        out.write(f"from {imp.module} import {', '.join(imp.names)}\n")
    else:
        raise TypeError(f"unknown ImportDecl kind: {imp.kind!r}")


def _emit_definition(d: Definition, out: StringIO) -> None:
    """Emit a single top-level definition. Top-level fields are reordered
    to canonical order; nested FieldGroup keys preserve original order
    (they're user data, not part of the keyword set)."""
    out.write(f"{d.kind} {d.name}:\n")
    for f in _ordered_top_fields(d.fields):
        _emit_field(f, depth=1, out=out)


def _ordered_top_fields(fields: list[Field]) -> list[Field]:
    """Sort top-level fields by canonical order; unknown keys keep their
    relative order. **Only used at definition top level.**"""
    order = {k: i for i, k in enumerate(CANONICAL_FIELD_ORDER)}
    known = sorted(
        [f for f in fields if f.name in order],
        key=lambda f: order[f.name],
    )
    unknown = [f for f in fields if f.name not in order]
    return known + unknown


def _emit_field(f: Field, depth: int, out: StringIO) -> None:
    """Emit a single field at the given indent depth."""
    pad = INDENT * depth
    v = f.value

    if isinstance(v, InlineText):
        out.write(f"{pad}{f.name}: {v.text}\n")
        return

    if isinstance(v, TypedAnnotation):
        # v0.7: emit ``T(description)`` form; bare ``T`` when no description.
        if v.description:
            out.write(f"{pad}{f.name}: {v.type_ann}({v.description})\n")
        else:
            out.write(f"{pad}{f.name}: {v.type_ann}\n")
        return

    if isinstance(v, Reference):
        out.write(f"{pad}{f.name}: {v.name}\n")
        return

    if isinstance(v, BlockScalar):
        out.write(f"{pad}{f.name}: |\n")
        body_pad = INDENT * (depth + 1)
        for ln in v.text.splitlines() or [""]:
            if ln:
                out.write(f"{body_pad}{ln}\n")
            else:
                out.write("\n")
        return

    if isinstance(v, FieldGroup):
        out.write(f"{pad}{f.name}:\n")
        # nested groups: preserve user's original order (no canonical reordering)
        for sub in v.fields:
            _emit_field(sub, depth=depth + 1, out=out)
        return

    if isinstance(v, ReferenceList):
        out.write(f"{pad}{f.name}:\n")
        item_pad = INDENT * (depth + 1)
        for n in v.names:
            out.write(f"{item_pad}- {n}\n")
        return

    if isinstance(v, StepList):
        out.write(f"{pad}{f.name}:\n")
        for it in v.items:
            _emit_step_item(it, depth=depth + 1, out=out)
        return

    raise TypeError(f"unknown FieldValue type: {type(v).__name__}")


def _emit_step_item(it, depth: int, out: StringIO) -> None:
    """Emit one StepItem at the given indent depth."""
    pad = INDENT * depth

    if isinstance(it, RefStep):
        out.write(f"{pad}- {it.name}\n")
        return

    if isinstance(it, ParallelStep):
        out.write(f"{pad}- parallel:\n")
        for c in it.items:
            _emit_step_item(c, depth=depth + 2, out=out)
        return

    if isinstance(it, EachStep):
        out.write(f"{pad}- each {it.binding}:\n")
        for c in it.items:
            _emit_step_item(c, depth=depth + 2, out=out)
        return

    if isinstance(it, IfStep):
        out.write(f"{pad}- if {it.cond}:\n")
        for c in it.then:
            _emit_step_item(c, depth=depth + 2, out=out)
        if it.else_ is not None:
            out.write(f"{pad}  else:\n")
            for c in it.else_:
                _emit_step_item(c, depth=depth + 2, out=out)
        return

    if isinstance(it, ReturnStep):
        # v0.7: ``- return <target>`` — single-line, no colon, no nested body.
        out.write(f"{pad}- return {it.target}\n")
        return

    raise TypeError(f"unknown StepItem type: {type(it).__name__}")


__all__ = ["serialize"]
