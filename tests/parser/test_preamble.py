"""Phase 1.AL.2 — `preamble` keyword parser + serializer tests.

`preamble` is the 5th top-level declarator (added after flow / code /
agent / set). It carries module-level Python (imports, classes,
constants, type aliases) as context the LLM sees alongside `code` node
bodies. The benchmark pipeline's inject step skips preamble defs — the
underlying stripped Python repo already has those declarations.

Design rationale: see docs/preamble-design.md.
"""

from __future__ import annotations

import pytest

from al.parser import parse, ParseError, LexError
from al.parser.ast_nodes import (
    ALLOWED_FIELDS_BY_KIND,
    BlockScalar,
    Definition,
    InlineText,
)
from al.parser.serializer import serialize
from al.parser.tokenizer import DECLARATORS


# ---------------------------------------------------------------------------
# Tokenizer / declarator registration
# ---------------------------------------------------------------------------


def test_preamble_is_in_DECLARATORS():
    """``preamble`` is a recognized top-level declarator."""
    assert "preamble" in DECLARATORS


def test_allowed_fields_for_preamble():
    """preamble accepts only `source` (optional) and `body` (required)."""
    assert ALLOWED_FIELDS_BY_KIND["preamble"] == {"source", "body"}


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------


def test_parse_minimal_preamble():
    """Bare preamble with just a body block."""
    src = (
        "preamble cachetools_keys:\n"
        "  body: |\n"
        "    import sys\n"
        "    _kwmark = (object(),)\n"
    )
    prog = parse(src)
    assert len(prog.defs) == 1
    d = prog.defs[0]
    assert d.kind == "preamble"
    assert d.name == "cachetools_keys"
    body_field = next(f for f in d.fields if f.name == "body")
    assert isinstance(body_field.value, BlockScalar)
    assert "import sys" in body_field.value.text
    assert "_kwmark = (object(),)" in body_field.value.text


def test_parse_preamble_with_source_hint():
    """``source: cachetools/keys.py`` field hints which file the preamble
    describes (used by the benchmark prompt + autogen to group preambles
    with the matching code-node group)."""
    src = (
        "preamble cachetools_keys:\n"
        "  source: cachetools/keys.py\n"
        "  body: |\n"
        "    _kwmark = (object(),)\n"
    )
    prog = parse(src)
    d = prog.defs[0]
    source_field = next(f for f in d.fields if f.name == "source")
    assert isinstance(source_field.value, InlineText)
    assert source_field.value.text == "cachetools/keys.py"


def test_parse_multiple_preambles_in_one_file():
    """Multiple preambles per .al — one per source file is the convention."""
    src = (
        "preamble keys:\n"
        "  source: cachetools/keys.py\n"
        "  body: |\n"
        "    _kwmark = (object(),)\n"
        "\n\n"
        "preamble func:\n"
        "  source: cachetools/func.py\n"
        "  body: |\n"
        "    import math\n"
    )
    prog = parse(src)
    preambles = [d for d in prog.defs if d.kind == "preamble"]
    assert len(preambles) == 2
    assert preambles[0].name == "keys"
    assert preambles[1].name == "func"


def test_parse_preamble_mixed_with_other_kinds():
    """preamble + flow + code can co-exist in one file."""
    src = (
        "preamble lib:\n"
        "  body: |\n"
        "    import sys\n"
        "\n\n"
        "flow main:\n"
        "  steps:\n"
        "    - work\n"
        "\n\n"
        "code work:\n"
        "  body: |\n"
        "    def work():\n"
        "        return 1\n"
    )
    prog = parse(src)
    kinds = [d.kind for d in prog.defs]
    assert kinds == ["preamble", "flow", "code"]


# ---------------------------------------------------------------------------
# Serializer — preambles emitted FIRST
# ---------------------------------------------------------------------------


def test_serializer_emits_preambles_first():
    """Even if author writes code first then preamble after, the serializer
    canonicalizes by emitting preambles at the top."""
    src = (
        "code work:\n"
        "  body: |\n"
        "    def work():\n"
        "        return 1\n"
        "\n\n"
        "preamble lib:\n"
        "  body: |\n"
        "    X = 1\n"
    )
    prog = parse(src)
    out = serialize(prog)
    assert out.index("preamble lib:") < out.index("code work:")


def test_serializer_preserves_preamble_relative_order():
    """Two preambles keep their source-order among themselves."""
    src = (
        "preamble a:\n"
        "  body: |\n"
        "    X = 1\n"
        "\n\n"
        "preamble b:\n"
        "  body: |\n"
        "    Y = 2\n"
    )
    out = serialize(parse(src))
    assert out.index("preamble a:") < out.index("preamble b:")


# ---------------------------------------------------------------------------
# Roundtrip — parse / serialize / parse equivalence
# ---------------------------------------------------------------------------


def test_roundtrip_preamble_only():
    src = (
        "preamble x:\n"
        "  source: pkg/x.py\n"
        "  body: |\n"
        "    import os\n"
        "    PI = 3.14\n"
    )
    p1 = parse(src)
    p2 = parse(serialize(p1))
    assert len(p2.defs) == 1
    assert p2.defs[0].kind == "preamble"
    assert p2.defs[0].name == "x"
    body2 = next(f for f in p2.defs[0].fields if f.name == "body").value
    assert "PI = 3.14" in body2.text


def test_roundtrip_mixed_preamble_flow_code():
    """Full-shape roundtrip: preamble + flow + code stays consistent."""
    src = (
        "preamble lib:\n"
        "  source: pkg/__init__.py\n"
        "  body: |\n"
        "    __all__ = ('main',)\n"
        "\n\n"
        "flow main_flow:\n"
        "  steps:\n"
        "    - main\n"
        "\n\n"
        "code main:\n"
        "  body: |\n"
        "    def main():\n"
        "        return 0\n"
    )
    p1 = parse(src)
    rt = serialize(p1)
    p2 = parse(rt)
    assert [d.kind for d in p2.defs] == ["preamble", "flow", "code"]
    assert [d.name for d in p2.defs] == ["lib", "main_flow", "main"]


# ---------------------------------------------------------------------------
# Preamble body holds arbitrary Python (no AL re-tokenization)
# ---------------------------------------------------------------------------


def test_preamble_body_holds_class_definition():
    """A whole class definition inside preamble body — module-level Python
    that was previously inexpressible in agent-lang."""
    src = (
        "preamble x:\n"
        "  body: |\n"
        "    class _HashedTuple(tuple):\n"
        "        __hashvalue = None\n"
        "        def __hash__(self, hash=tuple.__hash__):\n"
        "            return hash(self)\n"
        "\n"
        "    _kwmark = (_HashedTuple,)\n"
    )
    prog = parse(src)
    body = next(f for f in prog.defs[0].fields if f.name == "body").value
    assert "class _HashedTuple(tuple):" in body.text
    assert "_kwmark = (_HashedTuple,)" in body.text


def test_preamble_body_holds_imports():
    """import / from-import statements inside preamble body."""
    src = (
        "preamble x:\n"
        "  body: |\n"
        "    from __future__ import annotations\n"
        "    import sys\n"
        "    from typing import Union, Optional\n"
    )
    prog = parse(src)
    body = next(f for f in prog.defs[0].fields if f.name == "body").value
    assert "from __future__ import annotations" in body.text
    assert "from typing import Union, Optional" in body.text
