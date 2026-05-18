"""Emit Python for an ``agent`` node.

The agent function delegates to the runtime ``agent_call`` helper, which
in 阶段 ② becomes the goose subprocess bridge.
"""

from __future__ import annotations

from al.parser.ast_nodes import (
    Definition,
    BlockScalar,
    FieldGroup,
    Reference,
    ReferenceList,
    InlineText,
)


def emit_agent_node(d: Definition) -> str:
    """Return Python source for an ``agent`` definition.

    Layout:

        def agent_<name>(input=None):
            return agent_call(...)
        agent_<name>.__al_output__ = "<output spec>"

    ``__al_output__`` 上挂的字符串描述被 ``runtime.agent_bridge``
    用于 mock 模式下合成占位输出（详见 design doc § 6.1）。
    """
    intent = _text(d, "intent")
    prompt = _block(d, "prompt") or ""
    fallback = _ref(d, "fallback")
    uses = _use_list(d)
    output_spec = _output_spec(d)

    header = f"# agent: {d.name}\n# intent: {intent}\n"
    body = (
        f"def agent_{d.name}(input=None):\n"
        f"    return agent_call(\n"
        f"        name={d.name!r},\n"
        f"        intent={intent!r},\n"
        f"        prompt={_triple_quote(prompt)},\n"
        f"        use={uses!r},\n"
        f"        fallback={fallback!r},\n"
        f"        input=input,\n"
        f"    )\n"
        f"agent_{d.name}.__al_output__ = {output_spec!r}\n"
    )
    return header + body


# ---------------------------------------------------------------------------
# Field accessors
# ---------------------------------------------------------------------------


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


def _ref(d: Definition, name: str) -> str | None:
    for f in d.fields:
        if f.name == name and isinstance(f.value, Reference):
            return f.value.name
    return None


def _use_list(d: Definition) -> list[str]:
    """Normalize the ``use:`` field to a list of set names."""
    for f in d.fields:
        if f.name != "use":
            continue
        if isinstance(f.value, Reference):
            return [f.value.name]
        if isinstance(f.value, ReferenceList):
            return list(f.value.names)
    return []


def _output_spec(d: Definition) -> str:
    """Render ``output:`` as a single string for mock synthesis.

    InlineText → its text verbatim (legacy v0.6).
    TypedAnnotation → ``type_ann`` (description dropped for mock keyword sniff).
    FieldGroup → "{ k1: v1, k2: v2 }" style (just enough for MockBridge
    keyword sniffing to hit "dict-shaped").
    Missing → "".
    """
    from al.parser.ast_nodes import TypedAnnotation  # local import to avoid cycle
    for f in d.fields:
        if f.name != "output":
            continue
        v = f.value
        if isinstance(v, InlineText):
            return v.text
        if isinstance(v, TypedAnnotation):
            return v.type_ann
        if isinstance(v, FieldGroup):
            parts = []
            for sub in v.fields:
                if isinstance(sub.value, InlineText):
                    sub_text = sub.value.text
                elif isinstance(sub.value, TypedAnnotation):
                    sub_text = sub.value.type_ann
                else:
                    sub_text = ""
                parts.append(f"{sub.name}: {sub_text}")
            return "{ " + ", ".join(parts) + " }"
    return ""


def _triple_quote(text: str) -> str:
    """Format ``text`` as a triple-quoted Python string literal.

    Escapes any embedded triple-quotes by switching delimiters.
    """
    if '"""' not in text:
        return '"""' + text + '"""'
    return "'''" + text.replace("'''", "''\\'") + "'''"
