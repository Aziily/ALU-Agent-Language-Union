"""Parser unit tests."""

from pathlib import Path

import pytest

from al.parser import (
    parse,
    Definition,
    Field,
    InlineText,
    BlockScalar,
    StepList,
    ReferenceList,
    Reference,
    RefStep,
    ParallelStep,
    EachStep,
)


FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"


def test_parse_minimal_flow():
    """A minimal flow + code parses cleanly."""
    src = (FIXTURES / "minimal.al").read_text()
    program = parse(src)
    assert len(program.defs) == 2
    flow = program.defs[0]
    assert flow.kind == "flow"
    assert flow.name == "root"
    code = program.defs[1]
    assert code.kind == "code"
    assert code.name == "greet"
    body = next(f for f in code.fields if f.name == "body")
    assert isinstance(body.value, BlockScalar)
    assert "def greet" in body.value.text


def test_parse_set_node_with_all_fields():
    """A set node parses tools/skills/extensions/memory correctly."""
    src = (FIXTURES / "with_set.al").read_text()
    program = parse(src)
    set_def = next(d for d in program.defs if d.kind == "set")
    assert set_def.name == "scraping_kit"

    fields_by_name = {f.name: f.value for f in set_def.fields}
    assert isinstance(fields_by_name["tools"], ReferenceList)
    assert fields_by_name["tools"].names == ["fetch_url", "readability_js"]
    assert fields_by_name["skills"].names == ["extract_jsonld"]
    assert fields_by_name["extensions"].names == ["mcp_playwright"]
    assert isinstance(fields_by_name["memory"], BlockScalar)
    assert "site_selectors" in fields_by_name["memory"].text


def test_parse_agent_with_use_single_and_list():
    """``use:`` accepts both bare reference and list form."""
    src = (FIXTURES / "with_set.al").read_text()
    program = parse(src)
    agents = [d for d in program.defs if d.kind == "agent"]
    assert len(agents) == 2

    a1 = next(a for a in agents if a.name == "extract_article")
    use_field = next(f for f in a1.fields if f.name == "use")
    assert isinstance(use_field.value, Reference)
    assert use_field.value.name == "scraping_kit"

    a2 = next(a for a in agents if a.name == "multi_use_agent")
    use_field2 = next(f for f in a2.fields if f.name == "use")
    assert isinstance(use_field2.value, ReferenceList)
    assert use_field2.value.names == ["scraping_kit"]


def test_parse_steps_with_parallel_and_each():
    """Nested control: parallel + each."""
    src = (
        "flow f:\n"
        "  intent: control demo\n"
        "  steps:\n"
        "    - parallel:\n"
        "        - a\n"
        "        - b\n"
        "    - each item:\n"
        "        - c\n"
    )
    program = parse(src)
    flow = program.defs[0]
    steps = next(f for f in flow.fields if f.name == "steps").value
    assert isinstance(steps, StepList)
    assert len(steps.items) == 2
    assert isinstance(steps.items[0], ParallelStep)
    assert [s.name for s in steps.items[0].items if isinstance(s, RefStep)] == ["a", "b"]
    assert isinstance(steps.items[1], EachStep)
    assert steps.items[1].binding == "item"


def test_parse_full_example_smoke():
    """The end-to-end demo file parses without raising."""
    examples_dir = Path(__file__).resolve().parents[2] / "examples"
    src = (examples_dir / "daily_news.al").read_text()
    program = parse(src)
    assert len(program.defs) > 10
    kinds = {d.kind for d in program.defs}
    assert kinds == {"flow", "code", "agent", "set"}


def test_parse_pascal_case_node_names():
    """v0.6.1: node names may be PascalCase (for commit0 projects like voluptuous)."""
    src = (
        "flow Root:\n"
        "  intent: pascal case top-level\n"
        "  steps:\n"
        "    - Email\n"
        "    - normal_name\n"
        "\n\n"
        "code Email:\n"
        "  intent: validator for email addresses\n"
        "  body: |\n"
        "    def Email(v): pass\n"
        "\n\n"
        "code normal_name:\n"
        "  intent: snake_case also works\n"
        "  body: |\n"
        "    def normal_name(v): pass\n"
    )
    program = parse(src)
    names = {d.name for d in program.defs}
    assert names == {"Root", "Email", "normal_name"}
    # Step refs preserve case
    flow = next(d for d in program.defs if d.name == "Root")
    steps_field = next(f for f in flow.fields if f.name == "steps")
    assert isinstance(steps_field.value, StepList)
    refs = [s.name for s in steps_field.value.items if isinstance(s, RefStep)]
    assert refs == ["Email", "normal_name"]
