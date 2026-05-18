"""Tests for the v0.7 strict TypedAnnotation validator."""

from __future__ import annotations

from al.parser.parser import parse
from al.parser.validate import validate_typed_annotations


def _has(issues, code: str) -> bool:
    return any(i.code == code for i in issues)


def test_valid_simple_type_passes():
    src = (
        "code f:\n"
        "  input: str\n"
        "  output: list[str]\n"
        "  body: |\n"
        "    def f(x): return [x]\n"
    )
    assert validate_typed_annotations(parse(src)) == []


def test_valid_type_with_description_passes():
    src = (
        "code f:\n"
        "  input: list[str](article urls)\n"
        "  output: dict[str, int](counts)\n"
        "  body: |\n"
        "    def f(x): return {}\n"
    )
    assert validate_typed_annotations(parse(src)) == []


def test_valid_complex_nested_type():
    src = (
        "code f:\n"
        "  input: dict[str, list[tuple[int, str]]](nested)\n"
        "  output: tuple[bool, dict[str, int]]\n"
        "  body: |\n"
        "    def f(x): return (True, {})\n"
    )
    assert validate_typed_annotations(parse(src)) == []


def test_pipe_union_type_pep604():
    src = (
        "code f:\n"
        "  input: str | None\n"
        "  body: |\n"
        "    def f(x): return x\n"
    )
    assert validate_typed_annotations(parse(src)) == []


def test_legacy_free_english_flagged():
    src = (
        "code f:\n"
        "  input: raw HTML\n"
        "  output: top 10 items, ordered\n"
        "  body: |\n"
        "    def f(x): return x\n"
    )
    issues = validate_typed_annotations(parse(src))
    # Both input and output flagged.
    assert len(issues) == 2
    assert all(i.code == "io-not-python-type" for i in issues)


def test_dotted_attribute_type_passes():
    src = (
        "from data_models import Article\n\n"
        "code f:\n"
        "  output: data_models.Article(parsed)\n"
        "  body: |\n"
        "    def f(x): return None\n"
    )
    assert validate_typed_annotations(parse(src)) == []


def test_pascal_case_class_passes():
    src = (
        "code f:\n"
        "  output: Article(parsed article)\n"
        "  body: |\n"
        "    def f(x): return None\n"
    )
    assert validate_typed_annotations(parse(src)) == []


def test_nested_fieldgroup_validates_each_subfield():
    src = (
        "code f:\n"
        "  output:\n"
        "    title: str\n"
        "    body: raw text\n"
        "    published_at: datetime\n"
        "  body: |\n"
        "    def f(x): return {}\n"
    )
    issues = validate_typed_annotations(parse(src))
    # Only ``body: raw text`` is invalid.
    assert len(issues) == 1
    assert "body" in issues[0].message
    assert issues[0].code == "io-not-python-type"


def test_issue_carries_location_and_node_name():
    src = (
        "code parse_url:\n"
        "  input: bad type here\n"
        "  body: |\n"
        "    def parse_url(x): return x\n"
    )
    issues = validate_typed_annotations(parse(src))
    assert len(issues) == 1
    assert issues[0].node_name == "parse_url"
    assert issues[0].line >= 1


def test_skeleton_files_have_no_strict_violations():
    """The 16 hand-written skeletons + daily_news.al should ALMOST all be
    clean (skeletons have no inline I/O; daily_news uses some free
    English that v0.7 flags). Use this to count, not to assert zero."""
    from pathlib import Path
    files = list(Path("benchmarks/skeletons").glob("*.al"))
    for f in files:
        issues = validate_typed_annotations(parse(f.read_text()))
        assert issues == [], f"{f}: {issues}"
