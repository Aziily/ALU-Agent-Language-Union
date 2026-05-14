"""Emit Python for a ``flow`` node — wraps an orchestrator call.

The generated function builds a JSON-able description of the flow
structure and calls ``flow_call`` from the runtime, which handles
parallel / each / if execution semantics.

[TODO] 阶段 ② will replace the literal-dict serialization here with a
direct StepList passthrough once the runtime stabilizes.
"""

from __future__ import annotations

from dataclasses import asdict

from al.parser.ast_nodes import (
    Definition,
    StepList,
    InlineText,
    Reference,
)


def emit_flow_node(d: Definition) -> str:
    """Return Python source for a ``flow`` definition."""
    intent = _text(d, "intent")
    schedule = _text(d, "schedule")
    steps = _steps_repr(d)

    return (
        f"# flow: {d.name}\n"
        f"# intent: {intent}\n"
        f"def flow_{d.name}(input=None):\n"
        f"    return flow_call(\n"
        f"        name={d.name!r},\n"
        f"        intent={intent!r},\n"
        f"        schedule={schedule!r},\n"
        f"        steps={steps},\n"
        f"        input=input,\n"
        f"    )\n"
    )


def _text(d: Definition, name: str) -> str:
    for f in d.fields:
        if f.name == name and isinstance(f.value, InlineText):
            return f.value.text
    return ""


def _steps_repr(d: Definition) -> str:
    """Serialize the ``steps:`` StepList as a plain ``repr``-able literal.

    [UPGRADE] direct StepList passthrough planned for 阶段 ②.
    """
    for f in d.fields:
        if f.name == "steps" and isinstance(f.value, StepList):
            return repr([_step_to_dict(s) for s in f.value.items])
    return "[]"


def _step_to_dict(s) -> dict:
    """Recursively convert a StepItem to a JSON-friendly dict."""
    from al.parser.ast_nodes import RefStep, ParallelStep, EachStep, IfStep

    if isinstance(s, RefStep):
        return {"kind": "ref", "name": s.name}
    if isinstance(s, ParallelStep):
        return {"kind": "parallel", "items": [_step_to_dict(c) for c in s.items]}
    if isinstance(s, EachStep):
        return {
            "kind": "each",
            "binding": s.binding,
            "items": [_step_to_dict(c) for c in s.items],
        }
    if isinstance(s, IfStep):
        return {
            "kind": "if",
            "cond": s.cond,
            "then": [_step_to_dict(c) for c in s.then],
            "else": [_step_to_dict(c) for c in s.else_] if s.else_ else None,
        }
    raise TypeError(f"unknown StepItem: {type(s).__name__}")
