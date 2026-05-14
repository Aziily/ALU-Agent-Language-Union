"""Emit Python for a ``code`` node.

The ``body:`` BlockScalar is the function body. We wrap it in a function
named after the node so flows can call it as ``code_<name>(...)`` (or
plain ``<name>(...)`` if no clash).

Heuristic: if the body already declares a ``def <name>(...)`` at the top,
we keep it verbatim; otherwise we wrap the snippet in a function header
that takes a single ``input`` argument (per spec § 4.5).
"""

from __future__ import annotations

import re

from al.parser.ast_nodes import Definition, BlockScalar


def emit_code_node(d: Definition) -> str:
    """Return Python source for a ``code`` definition."""
    intent = _field_text(d, "intent") or ""
    body = _field_block(d, "body") or ""

    header = f"# code: {d.name}\n# intent: {intent}\n"
    if _looks_like_function_def(body, d.name):
        return header + body.rstrip() + "\n"

    # wrap as function taking ``input`` arg
    indented_body = "\n".join("    " + ln if ln else "" for ln in body.splitlines())
    return (
        header
        + f"def {d.name}(input=None):\n"
        + (indented_body or "    pass")
        + "\n"
    )


def _field_text(d: Definition, name: str) -> str | None:
    """Return the InlineText.text for ``name`` field if present."""
    for f in d.fields:
        if f.name == name and hasattr(f.value, "text"):
            return f.value.text  # type: ignore[union-attr]
    return None


def _field_block(d: Definition, name: str) -> str | None:
    """Return BlockScalar.text for ``name`` field if present."""
    for f in d.fields:
        if f.name == name and isinstance(f.value, BlockScalar):
            return f.value.text
    return None


def _looks_like_function_def(body: str, name: str) -> bool:
    """True if ``body`` already opens with ``def <name>(``."""
    pat = re.compile(rf"^\s*def\s+{re.escape(name)}\s*\(", re.MULTILINE)
    return bool(pat.search(body))
