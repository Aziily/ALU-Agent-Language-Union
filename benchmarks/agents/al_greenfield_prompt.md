# Pipeline C — agent-lang GREENFIELD implementer prompt (v0.7)

## Task

You're given a stripped Python codebase: every function body has been
replaced with `raise NotImplementedError('IMPLEMENT ME HERE')` (commit0
convention). Your job is to **author a complete agent-lang (v0.7)
project from scratch** that, when transpiled back to Python, fills in
all those stubs correctly and passes the unit tests.

Unlike Pipeline B (skeleton-based), there is **no pre-existing .al
skeleton**. You design the AL files yourself: one .al per Python module,
mirroring the project's directory structure.

You will be given:

1. The agent-lang **authoring guide** (how the language works in v0.7).
2. The project **spec** (README / docs excerpt).
3. The **stripped Python codebase** — every `.py` file's full source
   (with `NotImplementedError` stubs as bodies).

Your job: **emit one or more .al files** that, after AL-to-Python
codegen + injection, fill in all those stubs with correct Python so the
tests pass.

## Output format — one or more .al files

Emit each file using a `---FILE: <relative_path>.al---` separator. The
relative path mirrors the corresponding .py file (e.g. `cachetools/lru.py`
→ `cachetools/lru.al`).

### Worked example — v0.7.1 with Targeted Body

This example shows the **full v0.7.1 vocabulary**: `intent:` on every
node, structured `input:` / `output:` with `T(description)` form, AND
the new **`target:` + body-without-def** pattern (Codex co-iter
round 1). With `target:` set, your `body:` contains **just the
function-body statements** — no `def` line, no parameter list, no
docstring re-statement. The harness reads the original signature
(arguments, defaults, decorators) from the stripped Python file and
slots your statements in as the function body.

```
---FILE: cachetools/__init__.al---
from .lru import LRUCache

preamble cachetools_init:
  intent: package entry — re-export the public LRUCache class
  source: cachetools/__init__.py
  body: |
    __all__ = ['LRUCache']


---FILE: cachetools/lru.al---
preamble lru_module:
  intent: LRU cache class with size-bounded fifo eviction
  source: cachetools/lru.py
  body: |
    from collections import OrderedDict

    class LRUCache:
        def __init__(self, maxsize):
            self._store = OrderedDict()
            self._maxsize = maxsize


code LRUCache__get:
  intent: lookup key, return default on miss, refresh LRU order on hit
  target: cachetools/lru.py::LRUCache.get
  input: tuple[Any, Any](key, default=None)
  output: Any(stored value or default)
  body: |
    if key not in self._store:
        return default
    self._store.move_to_end(key)
    return self._store[key]


code LRUCache__set:
  intent: insert or update, evicting LRU when at capacity
  target: cachetools/lru.py::LRUCache.set
  input: tuple[Any, Any](key, value)
  output: None
  body: |
    if key in self._store:
        self._store.move_to_end(key)
    elif len(self._store) >= self._maxsize:
        self._store.popitem(last=False)
    self._store[key] = value
```

**Why `target:` matters**: the original Python's `def get(self, key,
default=None):` line is verbatim correct — defaults, parameter names,
decorators, type hints. Re-stating it in your `body:` is wasted
tokens and a chance to mistranscribe. With `target:`, you write only
the implementation logic; the harness keeps the signature exact.

**Format**: `target: <relpath>::<qualname>` where
- `<relpath>` matches the stripped Python file (e.g.
  `src/cachetools/keys.py`).
- `<qualname>` is the dotted path to the function: top-level
  `hashkey`, class method `LRUCache.get`, nested
  `Outer.Inner.method`. Standard Python `__qualname__` semantics.

**Why `intent:` + typed `input:` / `output:` matter**: they force you
to commit to each function's contract BEFORE writing the body. The
contract becomes a sanity check — if your `body:` doesn't return what
`output:` claims, you'll catch the mismatch yourself.

### `uses:` — explicit dependency declaration (v0.7.3)

Each `code` node may declare a `uses:` list of external names its
body depends on:

```
code ttl_cache:
  target: src/cachetools/func.py::ttl_cache
  uses:
    - cached
    - TTLCache
    - _UnboundTTLCache
    - keys
    - RLock
  body: |
    ...
```

The harness AST-walks your `body:` for free names (anything not local,
not a builtin, not declared in a preamble's imports / constants /
body). Any name that isn't in `uses:` either is a typo, a hallucinated
helper, or a missing import — these surface as validation warnings
fed back to your next iter.

You don't NEED to declare names already visible in a `preamble`
(imports, top-level class/function defs, constants). Use `uses:` for
names you import from sibling .al files or names the harness should
trust are real.

## Strict rules

1. **One `.al` per `.py` file** with the same relative path (drop the
   `.py`, append `.al`). Use the `# inject-into: <relpath>` comment in
   any `code` body if the file mapping is ambiguous.

2. **`code` node naming**:
   - top-level function `<name>` → `code <name>:`
   - class method `<Class>.<method>` → `code <Class>__<method>:` (dunder
     separator; method body keeps `def <method>(self, ...):` without
     the `Class.` prefix)
   - private class method `<Class>._<method>` → `code <Class>___<method>:`
     (triple-underscore for the leading `_`)

3. **`body:` rules**:
   - If the `code` node has a `target:` field (**v0.7.1, preferred**),
     the `body:` contains only the function-body statements — no `def`
     line, no parameter list, no docstring re-statement. The harness
     synthesizes the signature from the stripped Python.
   - Otherwise the `body:` must be a valid Python function definition
     matching the node name's expected Python name (per rule 2). The
     first `def` line IS validated: name mismatch → codegen error.

4. **Use `preamble` nodes** for module-level Python that lives outside
   any function body — imports, class definitions (signatures only),
   constants, type aliases. Each preamble has `source:` pointing to the
   originating .py path.

   **CRITICAL**: do NOT put the functions you're supposed to implement
   inside a `preamble` body. `preamble` is module-level *non-function*
   context (preamble body is shown to the LLM but NOT injected into the
   .py file). Every function that needs to be filled MUST live in its
   own `code <name>:` node with a matching `target:`. If the spec lists
   one function (e.g. HumanEval / MBPP), that function goes in exactly
   ONE `code` node, never in `preamble`.

5. **`input:` / `output:`** (v0.7): use Python type annotations with
   optional natural-language description in parens. Examples:
   - `input: list[str](article urls)`
   - `output: dict[str, int](word counts)`
   - `output: tuple[bool, str](success, message)`
   Free-English alone is rejected by strict validation. If you don't
   know the precise type, `Any(<description>)` is acceptable.

6. **Cross-file references** (v0.7): if the AL file uses something
   defined in another AL file, declare it at the top:
   - `import other_module` (or `import other_module as om`)
   - `from utils import normalize, parse_date`
   These translate 1:1 to the same Python imports at codegen.

7. **Original file structure preserved**: do NOT invent new files. The
   set of emitted `---FILE: <path>---` blocks MUST be a subset of the
   stripped Python's file list (you can OMIT files that have no
   `NotImplementedError` stubs, but cannot ADD new ones).

8. **No prose, no markdown fences around the AL blocks**. The first
   line of your output must be `---FILE: <first_path>.al---`.

## Why agent-lang instead of writing Python directly?

You're testing a hypothesis: structured AL nodes (one `code` per
function, `preamble` for module-level context, explicit cross-file
`import`, **typed `input:`/`output:`, and one-line `intent:`**) help
YOU keep multi-file projects organized in mind, leading to better
implementations. Treat the AL structure as a thinking aid.

**The key v0.7 thinking aids — use them on every code/preamble node:**

- `intent:` — one plain-English sentence per node, summarizing what it
  does. Forces you to articulate the goal before coding.
- `input:` / `output:` — Python type annotation `T` with optional
  `(description)`. Forces you to commit to the function's contract.
  When the body's actual signature / return value disagrees with what
  `input:` and `output:` claim, you'll spot the bug yourself.
- top-level `import` / `from X import Y` — explicit cross-file
  declarations at the file head. Forces you to think about module
  boundaries instead of stuffing everything in one file.

## Authoring guide (v0.7)

{authoring_guide}

## Project spec

{spec_text}

## Stripped Python codebase

{stripped_python_section}
{iter_history}

## YOUR FILLED agent-lang OUTPUT (raw, starting with ---FILE: ...---):
