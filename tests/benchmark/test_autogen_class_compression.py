"""H6 (Phase 1.AL-LOOP Round 4) — autogen compresses stripped class
methods in preamble class definitions to ``def m(args): ...``.

Rationale: in the preamble's class body, methods whose implementation
has been stripped to ``pass`` get filled by a separate
``code <Class>__<method>`` node downstream. Duplicating the
"signature + docstring + pass" in the preamble + the docstring + body
in the code node is wasteful and confusing. H6 replaces stripped
method bodies with the Ellipsis literal (``...``) and drops the
docstring — the docstring is preserved verbatim in the matching
code-node.

These tests guard against accidental regression of the compression
logic and against accidental compression of non-stripped helper
methods (which the LLM needs to see the body of).
"""

from __future__ import annotations

import ast

import pytest

from benchmarks.skeletons._autogen import (
    _compress_stripped_class_methods,
    _is_stripped,
)


def _cls(src: str) -> ast.ClassDef:
    """Parse a top-level class definition from a source snippet."""
    mod = ast.parse(src)
    cls = next(n for n in mod.body if isinstance(n, ast.ClassDef))
    return cls


def test_stripped_method_compressed_to_ellipsis():
    """A method with body ``[pass]`` (possibly after docstring) becomes
    a single-line ``def m(args): ...`` after compression."""
    src = (
        "class Schema:\n"
        "    def _compile_dict(self, schema):\n"
        '        """Compile a dict schema."""\n'
        "        pass\n"
    )
    compressed = _compress_stripped_class_methods(_cls(src))
    out = ast.unparse(compressed)
    # Body should be ellipsis; the original docstring + pass are gone
    assert "..." in out
    assert "Compile a dict schema" not in out
    assert "pass" not in out
    # Signature preserved
    assert "def _compile_dict(self, schema):" in out


def test_non_stripped_method_left_intact():
    """A method with a real body keeps its full body unchanged."""
    src = (
        "class Schema:\n"
        "    def __init__(self, schema, required=False):\n"
        "        self.schema = schema\n"
        "        self.required = required\n"
    )
    compressed = _compress_stripped_class_methods(_cls(src))
    out = ast.unparse(compressed)
    assert "self.schema = schema" in out
    assert "self.required = required" in out
    # Should NOT have ellipsis injected
    assert "..." not in out


def test_mixed_stripped_and_real_methods():
    """In a class with both stripped and real methods, only the stripped
    ones get compressed; the real ones stay verbatim."""
    src = (
        "class C:\n"
        "    def real(self):\n"
        "        return 1\n"
        "    def stub(self):\n"
        '        """do something."""\n'
        "        pass\n"
        "    def helper(self, x):\n"
        "        return x + 1\n"
    )
    compressed = _compress_stripped_class_methods(_cls(src))
    out = ast.unparse(compressed)
    # Real methods kept
    assert "return 1" in out
    assert "return x + 1" in out
    # Stub compressed; its docstring should be gone
    assert "do something" not in out
    # Ellipsis present for the stripped one
    assert out.count("...") == 1


def test_async_stripped_method_also_compressed():
    """AsyncFunctionDef stripped bodies should also be compressed."""
    src = (
        "class C:\n"
        "    async def fetch(self, url):\n"
        '        """Fetch the URL."""\n'
        "        pass\n"
    )
    compressed = _compress_stripped_class_methods(_cls(src))
    out = ast.unparse(compressed)
    assert "async def fetch(self, url):" in out
    assert "..." in out
    assert "Fetch the URL" not in out


def test_decorators_preserved_on_stripped_method():
    """A stripped method's decorators must survive compression — the LLM
    needs to know about ``@classmethod`` / ``@property`` etc."""
    src = (
        "class C:\n"
        "    @classmethod\n"
        "    def infer(cls, data):\n"
        '        """Build from data."""\n'
        "        pass\n"
    )
    compressed = _compress_stripped_class_methods(_cls(src))
    out = ast.unparse(compressed)
    assert "@classmethod" in out
    assert "def infer(cls, data):" in out
    assert "..." in out


def test_class_with_no_stripped_methods_unchanged():
    """A class whose methods all have real bodies — compression is a
    no-op (no ellipsis injected)."""
    src = (
        "class FullClass:\n"
        "    def a(self):\n"
        "        return 1\n"
        "    def b(self):\n"
        "        return 2\n"
    )
    original_out = ast.unparse(_cls(src))
    compressed = _compress_stripped_class_methods(_cls(src))
    compressed_out = ast.unparse(compressed)
    assert original_out == compressed_out


def test_class_with_only_pass_body_not_touched():
    """``class Empty: pass`` is a valid empty class (not a stripped
    method case). Compression should not interfere with it."""
    src = (
        "class Empty:\n"
        "    pass\n"
    )
    compressed = _compress_stripped_class_methods(_cls(src))
    out = ast.unparse(compressed)
    assert "class Empty:" in out
    assert "pass" in out
    # No ellipsis should have been inserted because there were no methods
    assert "..." not in out


def test_caller_tree_not_mutated():
    """The compression function returns a NEW ClassDef — the caller's
    original tree must remain unchanged."""
    src = (
        "class C:\n"
        "    def stub(self):\n"
        "        pass\n"
    )
    original = _cls(src)
    original_out_before = ast.unparse(original)
    _ = _compress_stripped_class_methods(original)
    original_out_after = ast.unparse(original)
    assert original_out_before == original_out_after
