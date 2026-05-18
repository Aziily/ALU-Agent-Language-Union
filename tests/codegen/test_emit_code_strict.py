"""v0.7 Phase 3b: emit_code_node strict def-name validation."""

from __future__ import annotations

import pytest

from al.codegen.emit_code import CodegenError, emit_code_node
from al.parser.parser import parse


def _first_code(src: str):
    return parse(src).defs[0]


def test_matching_def_name_emits_verbatim():
    src = (
        "code parse_url:\n"
        "  body: |\n"
        "    def parse_url(s):\n"
        "        return s.lower()\n"
    )
    out = emit_code_node(_first_code(src))
    assert "def parse_url(s):" in out
    assert "return s.lower()" in out


def test_no_def_wraps_body_as_function():
    src = (
        "code identity:\n"
        "  body: |\n"
        "    return input\n"
    )
    out = emit_code_node(_first_code(src))
    assert "def identity(input=None):" in out


def test_mismatched_def_name_raises_codegenerror():
    """Greenfield safety: LLM wrote ``def parse_urls(...)`` for node
    ``parse_url`` — must fail loudly, not silent wrap."""
    src = (
        "code parse_url:\n"
        "  body: |\n"
        "    def parse_urls(s):\n"
        "        return s.lower()\n"
    )
    with pytest.raises(CodegenError, match="parse_url"):
        emit_code_node(_first_code(src))


def test_class_method_dunder_name_accepted():
    """``Schema__compile`` node with ``def compile(self, ...)`` body."""
    src = (
        "code Schema__compile:\n"
        "  body: |\n"
        "    def compile(self, schema):\n"
        "        return schema\n"
    )
    out = emit_code_node(_first_code(src))
    assert "def compile(self, schema):" in out


def test_class_method_private_dunder():
    """``Schema___compile_dict`` (private) maps to ``_compile_dict``."""
    src = (
        "code Schema___compile_dict:\n"
        "  body: |\n"
        "    def _compile_dict(self, s):\n"
        "        return s\n"
    )
    out = emit_code_node(_first_code(src))
    assert "def _compile_dict(self, s):" in out


def test_strict_false_falls_back_to_legacy():
    """``strict=False`` keeps the v0.6 wrap-anyway behavior."""
    src = (
        "code foo:\n"
        "  body: |\n"
        "    def bar():\n"
        "        return 1\n"
    )
    # Default (strict): raise
    with pytest.raises(CodegenError):
        emit_code_node(_first_code(src))
    # Lenient: emit as-is (the v0.6 silent-failure path).
    out = emit_code_node(_first_code(src), strict=False)
    assert "def bar():" in out
