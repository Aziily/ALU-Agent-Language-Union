"""Tokenizer unit tests."""

from al.parser.tokenizer import tokenize


def test_tokenize_basic_definition():
    """A flow with intent + steps tokenizes into the expected DECL/IDENT/etc."""
    src = "flow root:\n  intent: hi\n  steps:\n    - greet\n"
    toks = tokenize(src)
    kinds = [t.kind for t in toks]
    assert "DECL" in kinds
    assert "IDENT" in kinds
    assert "INLINE_VALUE" in kinds
    assert "LIST_ITEM_DASH" in kinds
    # ends with EOF
    assert toks[-1].kind == "EOF"


def test_tokenize_block_scalar():
    """Block scalar body is captured + dedented."""
    src = "code c:\n  body: |\n    x = 1\n    return x\n"
    toks = tokenize(src)
    bodies = [t for t in toks if t.kind == "BLOCK_SCALAR_BODY"]
    assert len(bodies) == 1
    assert "x = 1" in bodies[0].text
    assert "return x" in bodies[0].text
    # ensure no leading 4-space indent left
    assert not bodies[0].text.startswith("    ")


def test_tokenize_set_node_keyword():
    """``set`` is recognized as a top-level declarator."""
    src = "set kit:\n  intent: bundle\n  tools:\n    - a\n    - b\n"
    toks = tokenize(src)
    decls = [t for t in toks if t.kind == "DECL"]
    assert decls[0].text == "set"
