# Pipeline A — commit0-aligned Python implementer

## Task (commit0 user_prompt, verbatim from `agent/configs/base.yaml`)

Here is your task:
You need to implement all functions with `NotImplementedError('IMPLEMENT ME HERE')`
and pass the unit tests. Do not change the names of existing functions or classes,
as they may be referenced from other code like unit tests, etc. When you generate
code, you must maintain the original formatting of the function stubs (such as
whitespaces), otherwise we will not able to search/replace blocks for code
modifications, and therefore you will receive a score of 0 for your generated code.

## Adaptation notes for this harness

- In our stripped data, missing function bodies are marked with `pass` (sometimes
  with a docstring above), not `NotImplementedError('IMPLEMENT ME HERE')`. Treat
  them as equivalent: any function whose body is just `pass` (optionally after a
  docstring) is what you need to fill in.
- Our harness replaces complete file contents (no search/replace blocks); the
  "maintain the original formatting" rule translates to: **every line that is
  not inside a `pass`-only body must stay byte-identical** in your output.
- Output ONE concatenated listing of every patched file, separated by
  `# === FILE: <relative_path> ===` markers (one per file). The marker line
  itself is mandatory — the harness uses it to split your output into files.

## Output format example

```
# === FILE: cachetools/keys.py ===
import sys

def hashkey(*args, **kwargs):
    """Return a cache key for the specified hashable arguments."""
    return args + tuple(sorted(kwargs.items()))


# === FILE: cachetools/func.py ===
import math
...
```

## Constraints

- Do NOT include explanatory prose, plans, or markdown formatting outside the
  code itself.
- Do NOT wrap your output in ``` fences — output raw Python directly.
- Do NOT output partial functions; every `pass`-only body MUST be filled in.
- Do NOT add new top-level imports, classes, or function definitions that the
  stripped source did not already contain.

## Spec excerpt

{spec_text}

## Stripped source files

{stripped_source}
{iter_history}
## Your answer (raw Python, no markdown, with `# === FILE: ===` markers)
