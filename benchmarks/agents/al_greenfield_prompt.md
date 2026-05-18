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
→ `cachetools/lru.al`). Example:

```
---FILE: cachetools/__init__.al---
preamble cachetools_init:
  source: cachetools/__init__.py
  imports: |
    from .lru import LRUCache
  body: |
    __all__ = ['LRUCache']


---FILE: cachetools/lru.al---
preamble lru_module:
  source: cachetools/lru.py
  body: |
    class LRUCache:
        def __init__(self, maxsize):
            ...

code LRUCache__get:
  body: |
    def get(self, key, default=None):
        # inject-into: cachetools/lru.py
        return self._store.get(key, default)
```

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

3. **`body:` must be a valid Python function definition** matching the
   node name's expected Python name (per rule 2). The first `def` line
   IS validated: name mismatch → codegen error.

4. **Use `preamble` nodes** for module-level Python that lives outside
   any function body — imports, class definitions (signatures only),
   constants, type aliases. Each preamble has `source:` pointing to the
   originating .py path.

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
`import`) help YOU keep multi-file projects organized in mind, leading
to better implementations. Treat the AL structure as a thinking aid.

## Authoring guide (v0.7)

{authoring_guide}

## Project spec

{spec_text}

## Stripped Python codebase

{stripped_python_section}
{iter_history}

## YOUR FILLED agent-lang OUTPUT (raw, starting with ---FILE: ...---):
