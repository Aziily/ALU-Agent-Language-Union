"""Emit Python for a ``set`` node — agent equipment bundle.

Output is a module-level ``SetDefinition`` literal that agents reference
via ``use=[...]`` in :mod:`al.codegen.emit_agent`.
"""

from __future__ import annotations

from al.parser.ast_nodes import (
    Definition,
    BlockScalar,
    InlineText,
    ReferenceList,
)


def emit_set_node(d: Definition) -> str:
    """Return Python source for a ``set`` definition."""
    intent = _text(d, "intent")
    tools = _ref_list(d, "tools")
    skills = _ref_list(d, "skills")
    extensions = _ref_list(d, "extensions")
    memory_text = _block(d, "memory") or ""

    return (
        f"# set: {d.name}\n"
        f"# intent: {intent}\n"
        f"{d.name.upper()} = SetDefinition(\n"
        f"    name={d.name!r},\n"
        f"    intent={intent!r},\n"
        f"    tools={tools!r},\n"
        f"    skills={skills!r},\n"
        f"    extensions={extensions!r},\n"
        f"    memory_yaml={memory_text!r},\n"
        f")\n"
    )


def _text(d: Definition, name: str) -> str:
    for f in d.fields:
        if f.name == name and isinstance(f.value, InlineText):
            return f.value.text
    return ""


def _block(d: Definition, name: str) -> str | None:
    for f in d.fields:
        if f.name == name and isinstance(f.value, BlockScalar):
            return f.value.text
    return None


def _ref_list(d: Definition, name: str) -> list[str]:
    for f in d.fields:
        if f.name == name and isinstance(f.value, ReferenceList):
            return list(f.value.names)
    return []
