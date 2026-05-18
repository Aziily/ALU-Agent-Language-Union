"""v0.7.3 Codex co-iter round 3 — validate_uses tests."""

from __future__ import annotations

from al.parser.parser import parse
from al.parser.validate import validate_uses


def _has(issues, name_in_message: str) -> bool:
    return any(name_in_message in i.message for i in issues)


# ---------------------------------------------------------------------------
# Clean cases
# ---------------------------------------------------------------------------


def test_body_uses_only_builtins_clean():
    src = (
        "code f:\n"
        "  body: |\n"
        "    def f(x):\n"
        "        return list(reversed(x))\n"
    )
    issues = validate_uses(parse(src))
    assert issues == []


def test_body_uses_preamble_constants_clean():
    src = (
        "preamble m:\n"
        "  constants: |\n"
        "    PI = 3.14\n"
        "  body: |\n"
        "    pass\n"
        "\n"
        "code area:\n"
        "  body: |\n"
        "    def area(r):\n"
        "        return PI * r * r\n"
    )
    issues = validate_uses(parse(src))
    assert issues == []


def test_body_uses_preamble_import_clean():
    src = (
        "preamble m:\n"
        "  imports: |\n"
        "    import math\n"
        "  body: |\n"
        "    pass\n"
        "\n"
        "code sq:\n"
        "  body: |\n"
        "    def sq(x):\n"
        "        return math.sqrt(x)\n"
    )
    issues = validate_uses(parse(src))
    assert issues == []


def test_body_uses_top_level_import_clean():
    src = (
        "from helpers import normalize\n"
        "\n"
        "code clean:\n"
        "  body: |\n"
        "    def clean(s):\n"
        "        return normalize(s)\n"
    )
    issues = validate_uses(parse(src))
    assert issues == []


def test_body_uses_explicit_uses_list_clean():
    src = (
        "code wrap:\n"
        "  uses:\n"
        "    - mystery_helper\n"
        "  body: |\n"
        "    def wrap(x):\n"
        "        return mystery_helper(x)\n"
    )
    issues = validate_uses(parse(src))
    assert issues == []


def test_class_method_self_is_clean():
    """``self`` and ``cls`` are always-OK names."""
    src = (
        "code Cache_get:\n"
        "  body: |\n"
        "    def get(self, key):\n"
        "        return self._store.get(key)\n"
    )
    issues = validate_uses(parse(src))
    assert issues == []


def test_for_loop_target_is_local():
    src = (
        "code sum_squares:\n"
        "  body: |\n"
        "    def sum_squares(xs):\n"
        "        total = 0\n"
        "        for i in xs:\n"
        "            total += i * i\n"
        "        return total\n"
    )
    issues = validate_uses(parse(src))
    assert issues == []


# ---------------------------------------------------------------------------
# Failure cases — undeclared name → warning
# ---------------------------------------------------------------------------


def test_undeclared_helper_flagged():
    src = (
        "code wrap:\n"
        "  body: |\n"
        "    def wrap(x):\n"
        "        return mystery_helper(x)\n"
    )
    issues = validate_uses(parse(src))
    assert len(issues) == 1
    assert issues[0].code == "uses-undeclared"
    assert "mystery_helper" in issues[0].message
    assert issues[0].node_name == "wrap"


def test_undeclared_module_attribute_flagged():
    """``math.sqrt`` — root ``math`` must be visible."""
    src = (
        "code sq:\n"
        "  body: |\n"
        "    def sq(x):\n"
        "        return math.sqrt(x)\n"
    )
    issues = validate_uses(parse(src))
    assert any("math" in i.message for i in issues)


def test_multiple_undeclared_names_flagged():
    src = (
        "code use_many:\n"
        "  body: |\n"
        "    def use_many(x):\n"
        "        return foo(bar(baz(x)))\n"
    )
    issues = validate_uses(parse(src))
    # At least foo, bar, baz are all flagged.
    flagged = {i.message for i in issues}
    assert any("foo" in m for m in flagged)
    assert any("bar" in m for m in flagged)
    assert any("baz" in m for m in flagged)


def test_uses_decl_silences_specific_name():
    src = (
        "code wrap:\n"
        "  uses:\n"
        "    - mystery_helper\n"
        "  body: |\n"
        "    def wrap(x):\n"
        "        return mystery_helper(x) + other_thing(x)\n"
    )
    issues = validate_uses(parse(src))
    # mystery_helper is declared, other_thing is not
    assert not any("mystery_helper" in i.message for i in issues)
    assert any("other_thing" in i.message for i in issues)
