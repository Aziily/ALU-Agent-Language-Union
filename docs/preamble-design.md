# `preamble` keyword — Phase 1.AL design rationale

## Problem

Phase 1.H'.F.2 (commit0-aligned multi-iter benchmark on gpt-5.4) produced
the first apples-to-apples BL/AL comparison on 5 repos where both
pipelines collected tests. The biggest concrete number:

> **cachetools, 645 tests × k=3: Baseline 100.0% / Agent-lang 86.7% (+13.3 pp BL lead).**
> AL also scored 0% on parsel and voluptuous where BL recovered to 81.8% / 73.8%
> via the iter loop.

Root-cause analysis (see `benchmarks/reports/runs/20260513-160432/decision_v2.md`):

The agent-lang skeleton **could not express module-level Python**.
The baseline pipeline's LLM saw the stripped `.py` file in full:
```python
class _HashedTuple(tuple):
    """..."""
    __hashvalue = None
    def __hash__(self, hash=tuple.__hash__): ...

_kwmark = (_HashedTuple,)

def hashkey(*args, **kwargs):
    """Return a cache key for the specified hashable arguments."""
    pass        # ← only this is stripped
```

The agent-lang pipeline's LLM only saw:
```al
code hashkey:
  body: |
    def hashkey(*args, **kwargs):
        """Return a cache key for the specified hashable arguments."""
        pass
```

So when the AL pipeline's LLM wrote the body, it didn't know
`_HashedTuple` or `_kwmark` existed. It reinvented `_kwmark` as a
function attribute, returned a plain `tuple` instead of `_HashedTuple`,
and forgot to `sorted(kwargs.items())`. The unit tests caught all
of those.

Verified across 4 repos by the failure-analysis audit:

| repo | module-level info AL was missing | observed effect |
|---|---|---|
| cachetools | `class _HashedTuple`, `_kwmark` | AL 86.7% vs BL 100% |
| voluptuous | `PREVENT_EXTRA`, `Schemable`, marker classes | AL 0% (no tests collected) |
| parsel | `from cssselect import FunctionalPseudoElement`, `class TranslatorMixin` | AL 0% (type-hint imports missing) |
| pyjwt | (nothing critical — functions are self-contained) | AL 100% (AL won here) |

Conclusion: the language could express "function bodies" cleanly but
nothing else. Real Python files are not just function bodies.

## Decision: add a `preamble` keyword

Per locked decision D-α (single keyword, vs splitting into
`imports` / `constants` / `classes` or making preamble pure prompt-only
"context"), we add **one** new top-level declarator:

```al
preamble <name>:
  source: <relative_path>     # optional — hint to which source file this matches
  body: |
    <verbatim Python source>
```

Trade-offs considered:

| option | pro | con | chosen? |
|---|---|---|---|
| Single `preamble` keyword | one new keyword; body is just Python (no language re-invention); maximally expressive | mixes import / class / constants into one block (less granular highlighting) | ✅ |
| Split: `imports` + `constants` + `classes` | granular IDE highlighting; spec mirrors Python AST structure | 3× the parser work; spec bloat; what about type aliases / `__all__` / module docstrings? | ❌ |
| `context` (LLM-only, not part of language) | doesn't add semantics to the language | weak signal — the IDE / parser / inject couldn't reason about it | ❌ |

## Semantics

A `preamble` declaration:

1. **Has a name** like every other top-level definition (`flow` / `code`
   / `agent` / `set`). Convention: name it after the file stem
   (`cachetools_keys` for `cachetools/keys.py`). Multiple preambles per
   `.al` are fine — one per source file is typical.

2. **Optional `source:`** field: relative path to the file the preamble
   describes. Used by the benchmark `_autogen.py` and by future IDE
   tooling that wants to navigate "preamble → its source file".

3. **Required `body:`** field: a block scalar holding the verbatim
   Python source. The parser does NOT re-tokenize the body — it's
   treated as opaque Python text (same as a `code` node body).

4. **Prompt path**: the benchmark `al_implementer` shows the preamble
   text to the LLM as module-level context **alongside** the `code`
   node stubs. So when the LLM writes a code node's body, it knows
   the imports / classes / constants in scope.

5. **Inject path**: `inject_filled_al` **skips** preamble defs entirely.
   The original stripped repo on disk already contains the module-level
   Python; we don't need to re-write it. Preambles are a
   prompt-context concept, not a code-generation concept.

6. **Serializer**: preambles are emitted FIRST in canonical output
   (preserving their relative order among themselves), then everything
   else in source order. This matches the layout of a real Python
   file (imports + module-level structure at the top).

## What goes IN the preamble body

Use preamble for **module-level Python that is NOT a function body**:

- `import` / `from … import …`
- `class Foo(...)` definitions (with methods — stripped methods that
  the LLM should fill get a separate `code Foo__method` node, and the
  class body in the preamble shows them with `pass`)
- module-level constants (`_kwmark = (...)`, `PREVENT_EXTRA = 0`)
- type aliases (`Schemable = Union[...]`)
- module docstring + `__all__`
- conditional top-level blocks (`try: import accelerated except ImportError: …`)

Use `code` (NOT preamble) for **function bodies the LLM has to fill**.

## What stays OUT of the preamble body

- Top-level function definitions that have stripped bodies (those become
  `code <name>` nodes — the LLM's actual job).
- Anything the harness expects to *inject* — preambles aren't injected.

If a Python file has _both_ a class with stripped methods AND a
module-level constant, the natural layout is:

```al
preamble my_module:
  source: pkg/my_module.py
  body: |
    """Module docstring."""
    MY_CONSTANT = 42

    class MyClass:
        """The class — its stripped methods get separate code nodes below."""
        def __init__(self):
            pass       # ← stripped; matched by code MyClass__init below
        def do_thing(self):
            pass       # ← stripped; matched by code MyClass__do_thing below


code MyClass__init:
  body: |
    def __init__(self):
        self.x = 0

code MyClass__do_thing:
  body: |
    def do_thing(self):
        return self.x
```

The duplication of the class signature (in preamble) with the method
body (in code node) is *intentional* — the preamble shows the LLM the
class structure; the code node is what gets injected. The
`inject_filled_al` step finds the matching `def __init__` inside
`MyClass` in the stripped repo and replaces only that method's body.

## Why not just dump the whole stripped `.py` into a comment

Three reasons:

1. **Token efficiency**: the LLM's prompt budget is precious. Preamble
   lets us put module-level scaffolding in once and refer to it from
   many code-node bodies. Dumping the whole file as a comment would
   duplicate it for every node.

2. **Structural clarity**: agent-lang's value proposition is that the
   *structure* of a program is first-class (flows, code nodes, sets).
   Preamble keeps that structure visible — the LLM sees "here's the
   module context, here are the named work units (code nodes), here's
   the orchestration (flow)" instead of "here's a wall of Python".

3. **Future IDE**: a graphical editor wants to know "show me the
   module-level context for this file" as a navigable concept, not as
   a free-form comment in some random `code` body. `preamble` gives
   that concept a name.

## Verification

- `tests/parser/test_preamble.py` — 12 tests covering parse / serialize
  / roundtrip / mixed-with-other-kinds
- `tests/benchmark/test_inject_preamble_skip.py` — 2 tests asserting
  the inject path never writes preamble content to the workdir
- `tests/benchmark/test_fairness.py::test_al_prompt_includes_preamble_body_text`
  — asserts the LLM prompt for an AL skeleton WITH preamble actually
  contains the preamble body text (the operational definition of
  "fair comparison after Phase 1.AL")

Empirical verification: a re-run of the commit0 benchmark on the
regenerated skeletons (`benchmarks/skeletons/*.al` — each now has 1-43
preamble blocks) is the next step. Blocked on traxnode budget top-up.

## Decision log

- **D-α** (Phase 1.AL.2) — single `preamble` keyword. Locked.
- **D-β** (Phase 1.AL.1) — heavy reorg `src/al/* → al/*`. Locked.
- **D-γ** (Phase 1.AL.7-deferred) — IDE-like WebUI deferred to a
  separate plan (not in this Phase).
