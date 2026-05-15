"""Parser exception types.

All parser errors carry (line, col) for editor mapping. CLI renders with
source context.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class _SrcError(Exception):
    """Base for source-level errors with location."""

    message: str
    line: int
    col: int

    def __str__(self) -> str:  # pragma: no cover - trivial
        return f"[{self.line}:{self.col}] {self.message}"


class LexError(_SrcError):
    """Tokenizer-level error (e.g. illegal character, tab usage)."""


class ParseError(_SrcError):
    """Parser-level error (unexpected token, missing field, etc.)."""

    expected: str | None = None  # populated by parser when applicable
