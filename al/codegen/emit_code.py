"""Emit Python for a ``code`` node.

The ``body:`` BlockScalar is the function body. We wrap it in a function
named after the node so flows can call it as ``code_<name>(...)`` (or
plain ``<name>(...)`` if no clash).

Heuristic: if the body already declares a ``def <name>(...)`` at the top,
we keep it verbatim; otherwise we wrap the snippet in a function header
that takes a single ``input`` argument (per spec § 4.5).

v0.7 hardening (Phase 3b): if the body contains a ``def`` line whose
name does NOT match ``node.name`` (after accounting for the
``<Class>__<method>`` dunder convention), raise :class:`CodegenError`
instead of silently wrapping. The old behavior produced syntactically
valid but semantically dead nested-def code when an LLM wrote the wrong
function name — Pipeline C (greenfield) is far more exposed to this
than Pipeline B (skeleton-based), where the LLM mostly copies the
header verbatim.
"""

from __future__ import annotations

import re

from al.parser.ast_nodes import Definition, BlockScalar


class CodegenError(Exception):
    """Raised when a code node's body cannot be safely emitted.

    Examples:
      - Body has ``def foo(...)`` but node name is ``bar``.
      - Body is a decorator stack with no ``def`` underneath.

    These are LLM-output bugs that the caller should surface as an
    inject-skipped + feedback-to-next-iter signal, not silently mask.
    """


# Matches the first ``def <name>(`` after optional decorators / blank lines.
# Captures the function name in group 1. Multi-line so '^' matches line starts.
_FIRST_DEF_RE = re.compile(r"^\s*def\s+([A-Za-z_]\w*)\s*\(", re.MULTILINE)


def emit_code_node(d: Definition, *, strict: bool = True) -> str:
    """Return Python source for a ``code`` definition.

    With ``strict=True`` (default, v0.7), a name mismatch between the
    body's first ``def`` and the node name raises CodegenError. Set
    ``strict=False`` to fall back to the v0.6 wrap-everything behavior
    (useful for tests of legacy paths).
    """
    intent = _field_text(d, "intent") or ""
    body = _field_block(d, "body") or ""

    header = f"# code: {d.name}\n# intent: {intent}\n"
    found_name = _first_def_name(body)
    expected = _expected_python_name(d.name)

    if found_name is None:
        # No def — wrap as a function taking ``input``.
        indented_body = "\n".join("    " + ln if ln else "" for ln in body.splitlines())
        return (
            header
            + f"def {d.name}(input=None):\n"
            + (indented_body or "    pass")
            + "\n"
        )

    if found_name == expected:
        return header + body.rstrip() + "\n"

    # Name mismatch.
    if strict:
        raise CodegenError(
            f"code node {d.name!r} body declares ``def {found_name}(...)`` "
            f"but the expected Python name is {expected!r}. Either rename "
            f"the node to match, or fix the function name in the body. "
            f"(node {d.name!r}, line {d.loc.line})"
        )
    # Lenient (v0.6 behavior): still keep body verbatim and let inject /
    # external tooling sort it out. This was the silent-failure path.
    return header + body.rstrip() + "\n"


def _expected_python_name(node_name: str) -> str:
    """Translate node name into the expected Python function name.

    ``foo`` → ``foo``
    ``Class__method`` → ``method`` (class-method dunder convention)
    ``Class___method`` → ``_method`` (private class-method, e.g. Schema___compile_dict)
    """
    if "__" in node_name:
        # Split on the FIRST '__' — everything after is the method name.
        parts = node_name.split("__", 1)
        if len(parts) == 2 and parts[0] and parts[1]:
            return parts[1]
    return node_name


def _first_def_name(body: str) -> str | None:
    """Find the name in the FIRST ``def <name>(...)`` line of ``body``.

    Returns None if no def found.
    """
    m = _FIRST_DEF_RE.search(body)
    return m.group(1) if m else None


def _field_text(d: Definition, name: str) -> str | None:
    """Return the .text attribute for ``name`` field if present.

    Works for InlineText (legacy) and TypedAnnotation (v0.7) since both
    have a ``.text``-like attribute we can pull. For TypedAnnotation we
    use ``type_ann`` (description dropped at codegen — comments-only).
    """
    from al.parser.ast_nodes import InlineText, TypedAnnotation
    for f in d.fields:
        if f.name != name:
            continue
        if isinstance(f.value, InlineText):
            return f.value.text
        if isinstance(f.value, TypedAnnotation):
            return f.value.type_ann
    return None


def _field_block(d: Definition, name: str) -> str | None:
    """Return BlockScalar.text for ``name`` field if present."""
    for f in d.fields:
        if f.name == name and isinstance(f.value, BlockScalar):
            return f.value.text
    return None


def _looks_like_function_def(body: str, name: str) -> bool:
    """Back-compat helper: True if ``body`` opens with ``def <name>(``.

    Kept for any external caller that imported it before v0.7; the
    main path no longer relies on it.
    """
    pat = re.compile(rf"^\s*def\s+{re.escape(name)}\s*\(", re.MULTILINE)
    return bool(pat.search(body))
