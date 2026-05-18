"""v0.7 parser tests: TypedAnnotation, ImportDecl, ReturnStep."""

from __future__ import annotations

import pytest

from al.parser.ast_nodes import (
    Definition,
    Field,
    FieldGroup,
    ImportDecl,
    InlineText,
    ReturnStep,
    RefStep,
    StepList,
    TypedAnnotation,
)
from al.parser.errors import ParseError
from al.parser.parser import parse
from al.parser.serializer import serialize


# ---------------------------------------------------------------------------
# TypedAnnotation
# ---------------------------------------------------------------------------


def test_io_inline_type_only_no_description():
    src = "code f:\n  input: list[str]\n  body: |\n    def f(x): return x\n"
    prog = parse(src)
    d = prog.defs[0]
    inp = next(f for f in d.fields if f.name == "input")
    assert isinstance(inp.value, TypedAnnotation)
    assert inp.value.type_ann == "list[str]"
    assert inp.value.description is None


def test_io_inline_type_with_description():
    src = (
        "code f:\n"
        "  input: list[str](article urls)\n"
        "  output: dict[str, str](title->body, English text)\n"
        "  body: |\n"
        "    def f(x): return x\n"
    )
    prog = parse(src)
    d = prog.defs[0]
    inp = next(f for f in d.fields if f.name == "input")
    out = next(f for f in d.fields if f.name == "output")
    assert isinstance(inp.value, TypedAnnotation)
    assert inp.value.type_ann == "list[str]"
    assert inp.value.description == "article urls"
    assert isinstance(out.value, TypedAnnotation)
    assert out.value.type_ann == "dict[str, str]"
    assert out.value.description == "title->body, English text"


def test_io_inline_nested_parens_in_type():
    """``dict[str, tuple[int, str]](payload)`` — outer paren is description."""
    src = (
        "code f:\n"
        "  input: dict[str, tuple[int, str]](payload)\n"
        "  body: |\n"
        "    def f(x): return x\n"
    )
    prog = parse(src)
    d = prog.defs[0]
    inp = next(f for f in d.fields if f.name == "input")
    assert isinstance(inp.value, TypedAnnotation)
    assert inp.value.type_ann == "dict[str, tuple[int, str]]"
    assert inp.value.description == "payload"


def test_io_legacy_free_english_still_parses():
    """v0.6 ``input: raw HTML`` → TypedAnnotation with no description."""
    src = (
        "code f:\n"
        "  input: raw HTML\n"
        "  body: |\n"
        "    def f(x): return x\n"
    )
    prog = parse(src)
    d = prog.defs[0]
    inp = next(f for f in d.fields if f.name == "input")
    assert isinstance(inp.value, TypedAnnotation)
    assert inp.value.type_ann == "raw HTML"
    assert inp.value.description is None


def test_io_nested_fieldgroup_unaffected():
    """Nested ``output: { title: str, body: str }`` still uses FieldGroup."""
    src = (
        "code f:\n"
        "  output:\n"
        "    title: str\n"
        "    body: str\n"
        "  body: |\n"
        "    def f(x): return x\n"
    )
    prog = parse(src)
    d = prog.defs[0]
    out = next(f for f in d.fields if f.name == "output")
    assert isinstance(out.value, FieldGroup)
    assert len(out.value.fields) == 2
    assert out.value.fields[0].name == "title"
    # Nested values stay InlineText for now (v0.7.0 limitation; see ast_nodes.py).
    assert isinstance(out.value.fields[0].value, InlineText)


def test_io_typed_annotation_serializer_roundtrip():
    src = (
        "code f:\n"
        "  input: list[str](article urls)\n"
        "  body: |\n"
        "    def f(x): return x\n"
    )
    prog = parse(src)
    ser = serialize(prog)
    assert "input: list[str](article urls)" in ser
    # And re-parsing the serialized form gives identical AST shape.
    prog2 = parse(ser)
    inp = next(f for f in prog2.defs[0].fields if f.name == "input")
    assert inp.value.type_ann == "list[str]"
    assert inp.value.description == "article urls"


def test_io_typed_annotation_intent_unchanged():
    """``intent:`` is NOT in TYPED_ANNOTATION_FIELDS — stays InlineText."""
    src = "code f:\n  intent: do thing(s)\n  body: |\n    def f(): pass\n"
    prog = parse(src)
    intent = next(f for f in prog.defs[0].fields if f.name == "intent")
    assert isinstance(intent.value, InlineText)
    assert intent.value.text == "do thing(s)"


# ---------------------------------------------------------------------------
# ImportDecl
# ---------------------------------------------------------------------------


def test_import_simple():
    src = "import utils\n\ncode f:\n  body: |\n    def f(): pass\n"
    prog = parse(src)
    assert len(prog.imports) == 1
    imp = prog.imports[0]
    assert imp.kind == "import"
    assert imp.module == "utils"
    assert imp.names == []
    assert imp.alias is None


def test_import_with_alias():
    src = "import data_models as dm\n\ncode f:\n  body: |\n    def f(): pass\n"
    prog = parse(src)
    imp = prog.imports[0]
    assert imp.kind == "import"
    assert imp.module == "data_models"
    assert imp.alias == "dm"


def test_import_dotted_path():
    src = "import pkg.sub.mod\n\ncode f:\n  body: |\n    def f(): pass\n"
    prog = parse(src)
    imp = prog.imports[0]
    assert imp.module == "pkg.sub.mod"


def test_from_import_single_name():
    src = "from utils import normalize\n\ncode f:\n  body: |\n    def f(): pass\n"
    prog = parse(src)
    imp = prog.imports[0]
    assert imp.kind == "from"
    assert imp.module == "utils"
    assert imp.names == ["normalize"]


def test_from_import_multiple_names():
    src = (
        "from data_models import Article, Source, Feed\n\n"
        "code f:\n  body: |\n    def f(): pass\n"
    )
    prog = parse(src)
    imp = prog.imports[0]
    assert imp.module == "data_models"
    assert imp.names == ["Article", "Source", "Feed"]


def test_multiple_imports_preserve_order():
    src = (
        "import a\n"
        "from b import x, y\n"
        "import c as cc\n\n"
        "code f:\n  body: |\n    def f(): pass\n"
    )
    prog = parse(src)
    assert len(prog.imports) == 3
    assert prog.imports[0].module == "a"
    assert prog.imports[1].module == "b"
    assert prog.imports[2].module == "c"
    assert prog.imports[2].alias == "cc"


def test_import_after_definition_rejected():
    """Imports MUST appear before the first Definition (spec § 4.13.1)."""
    src = (
        "code f:\n  body: |\n    def f(): pass\n\n"
        "import sneaky\n"
    )
    with pytest.raises(ParseError):
        parse(src)


def test_import_malformed_rejected():
    # Bare ``import`` (no module name) fails at the tokenizer (LexError);
    # malformed ``from X`` (no ``import``) fails at the parser.
    with pytest.raises(Exception):  # LexError
        parse("import\n\ncode f:\n  body: |\n    def f(): pass\n")
    with pytest.raises(ParseError):
        parse("from utils\n\ncode f:\n  body: |\n    def f(): pass\n")


def test_import_serializer_roundtrip():
    src = (
        "import a\n"
        "import b as bb\n"
        "from c import x, y\n"
        "\n"
        "code f:\n  body: |\n    def f(): pass\n"
    )
    prog = parse(src)
    ser = serialize(prog)
    assert "import a" in ser
    assert "import b as bb" in ser
    assert "from c import x, y" in ser
    prog2 = parse(ser)
    assert len(prog2.imports) == 3


def test_no_imports_legacy_v06_program():
    """A v0.6-style file with no imports parses with empty imports list."""
    src = "code f:\n  body: |\n    def f(): pass\n"
    prog = parse(src)
    assert prog.imports == []
    assert len(prog.defs) == 1


# ---------------------------------------------------------------------------
# ReturnStep
# ---------------------------------------------------------------------------


def test_return_step_basic():
    src = (
        "flow main:\n"
        "  steps:\n"
        "    - fetch\n"
        "    - process\n"
        "    - return process\n"
    )
    prog = parse(src)
    d = prog.defs[0]
    steps = next(f for f in d.fields if f.name == "steps").value
    assert isinstance(steps, StepList)
    assert len(steps.items) == 3
    assert isinstance(steps.items[-1], ReturnStep)
    assert steps.items[-1].target == "process"


def test_return_step_serializer_roundtrip():
    src = (
        "flow main:\n"
        "  steps:\n"
        "    - fetch\n"
        "    - return fetch\n"
    )
    prog = parse(src)
    ser = serialize(prog)
    assert "- return fetch" in ser
    prog2 = parse(ser)
    steps2 = next(f for f in prog2.defs[0].fields if f.name == "steps").value
    assert isinstance(steps2.items[-1], ReturnStep)


def test_return_step_invalid_target_rejected():
    """Non-identifier target should fail parsing."""
    src = (
        "flow main:\n"
        "  steps:\n"
        "    - return 123-invalid\n"
    )
    with pytest.raises(Exception):  # LexError or ParseError
        parse(src)


def test_return_step_does_not_break_other_steps():
    src = (
        "flow main:\n"
        "  steps:\n"
        "    - parallel:\n"
        "        - a\n"
        "        - b\n"
        "    - process\n"
        "    - return process\n"
    )
    prog = parse(src)
    steps = next(f for f in prog.defs[0].fields if f.name == "steps").value
    assert len(steps.items) == 3
    assert isinstance(steps.items[-1], ReturnStep)
    assert steps.items[-1].target == "process"


# ---------------------------------------------------------------------------
# Combined v0.7 features
# ---------------------------------------------------------------------------


def test_full_v07_program():
    """Imports + TypedAnnotation + ReturnStep all in one file."""
    src = (
        "from utils import normalize, parse_date\n"
        "import data_models as dm\n"
        "\n"
        "code fetch:\n"
        "  input: list[str](article urls)\n"
        "  output: list[bytes](raw HTML bodies)\n"
        "  body: |\n"
        "    def fetch(urls):\n"
        "        return [b'' for u in urls]\n"
        "\n"
        "flow main:\n"
        "  intent: pipeline\n"
        "  steps:\n"
        "    - fetch\n"
        "    - return fetch\n"
    )
    prog = parse(src)
    assert len(prog.imports) == 2
    assert prog.imports[0].kind == "from"
    assert prog.imports[1].alias == "dm"
    code = prog.defs[0]
    inp = next(f for f in code.fields if f.name == "input")
    assert isinstance(inp.value, TypedAnnotation)
    assert inp.value.type_ann == "list[str]"
    flow = prog.defs[1]
    steps = next(f for f in flow.fields if f.name == "steps").value
    assert isinstance(steps.items[-1], ReturnStep)
    # And serializer roundtrip preserves all three features.
    ser = serialize(prog)
    assert "from utils import normalize, parse_date" in ser
    assert "import data_models as dm" in ser
    assert "input: list[str](article urls)" in ser
    assert "- return fetch" in ser
