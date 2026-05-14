"""Roundtrip tests — parse → serialize → parse must yield equal AST."""

from dataclasses import asdict
from pathlib import Path

from al.parser import parse, serialize


def _ast_eq(a, b) -> bool:
    """Compare two ASTs structurally, ignoring loc."""
    da, db = asdict(a), asdict(b)
    _scrub_loc(da)
    _scrub_loc(db)
    return da == db


def _scrub_loc(obj):
    if isinstance(obj, dict):
        obj.pop("loc", None)
        for v in obj.values():
            _scrub_loc(v)
    elif isinstance(obj, list):
        for v in obj:
            _scrub_loc(v)


def test_roundtrip_minimal():
    src = (Path(__file__).resolve().parents[1] / "fixtures" / "minimal.al").read_text()
    a1 = parse(src)
    s1 = serialize(a1)
    a2 = parse(s1)
    assert _ast_eq(a1, a2)


def test_roundtrip_with_set():
    src = (Path(__file__).resolve().parents[1] / "fixtures" / "with_set.al").read_text()
    a1 = parse(src)
    s1 = serialize(a1)
    a2 = parse(s1)
    assert _ast_eq(a1, a2)


def test_roundtrip_full_demo():
    examples_dir = Path(__file__).resolve().parents[2] / "examples"
    src = (examples_dir / "daily_news.al").read_text()
    a1 = parse(src)
    s1 = serialize(a1)
    a2 = parse(s1)
    assert _ast_eq(a1, a2)
