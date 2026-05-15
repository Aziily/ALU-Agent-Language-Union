# Pipeline B — agent-lang implementer prompt (commit0-aligned)

## Task (commit0 user_prompt — re-cast for agent-lang)

Here is your task: You need to implement all stub function bodies (currently
`pass`, equivalent to commit0's `NotImplementedError('IMPLEMENT ME HERE')`)
inside an agent-lang skeleton, and pass the unit tests.
**Do not change the names of existing functions, classes, flow nodes, or
code nodes**, as they may be referenced from other code like unit tests.
When you generate code, **maintain the original formatting of the function
stubs** (such as whitespaces inside the `body:` blocks), otherwise the
harness will not be able to inject your code back into the source files
and you will receive a score of 0.

You are filling in function bodies inside an **agent-lang skeleton**. agent-lang is a small Python-orchestration DSL — see the **AUTHORING GUIDE** section below for the language reference.

You will be given:

1. The agent-lang **authoring guide** (how the language works)
2. The project **spec** (README / docs excerpt)
3. An **agent-lang skeleton** with `code` nodes whose `body:` blocks contain stubs (`pass` placeholders)

Your job: **rewrite the entire agent-lang file with all stub `body:` blocks replaced by correct Python implementations**.

## Strict rules

1. Output the **complete agent-lang source** (not a diff). Every flow / code / preamble node from the input MUST appear in the output, in the same order, with the same declarator and same name.
2. Only the **inner Python code** inside each `code` node's `body: |` block may be modified. **All other lines stay BYTE-IDENTICAL.** This explicitly includes every `preamble` node's `imports:` and `body:` blocks — those are module-level context, not editable.
3. Each `code` body MUST start with `def <node_name>(...):` (or `@decorator` then `def`). The function name MUST match the agent-lang node name UNLESS the node name uses `<Class>__<method>` form (in which case the function name is the method portion — see the "class method" pattern in the authoring guide).
4. The body must be valid Python that would `ast.parse` cleanly.
5. **Use the names already imported in the relevant preamble's `imports:` block.** The `imports:` block lists every `import` / `from ... import ...` statement that is already executed at module load time, so those names are in scope. Do NOT duplicate them inside a `code` body. If you need a new import that isn't in any preamble, add it inside the function body.
6. Follow the docstring inside the body literally — that's your spec for what the function does.

## CRITICAL — Do NOT drop any field keyword

Every `code` node header looks like:

```
code my_function:
  body: |
    def my_function(...):
        ...
```

The literal strings `code`, `body:`, and the colons after them are **mandatory keywords** — agent-lang parser will reject the file if any of them is missing or mistyped. Verify your output preserves these tokens character-for-character.

Same for `flow` declarators: `flow name:` followed by `  steps:` then `    - ref_name` list items.

If you find yourself "improving" a field name (e.g. shortening `intent:` to `:`), STOP — agent-lang parser will fail. Keep them.

## Output format

Output raw agent-lang text. **No markdown fences**, no commentary, no introduction. Start with the first line of the skeleton (typically `flow ...`).

## Worked example

INPUT skeleton:
```
flow my_lib:
  steps:
    - add_one
    - mul_two


code add_one:
  body: |
    def add_one(x):
        """Add 1 to the input integer."""
        pass


code mul_two:
  body: |
    def mul_two(x):
        """Multiply input integer by 2."""
        pass
```

CORRECT OUTPUT (note: every line outside body Python is byte-identical):
```
flow my_lib:
  steps:
    - add_one
    - mul_two


code add_one:
  body: |
    def add_one(x):
        """Add 1 to the input integer."""
        return x + 1


code mul_two:
  body: |
    def mul_two(x):
        """Multiply input integer by 2."""
        return x * 2
```

INCORRECT outputs (each will be REJECTED):

```
# WRONG — dropped the `flow` declarator keyword:
my_lib:
  steps: ...
```

```
# WRONG — dropped the `code` declarator keyword:
add_one:
  body: |
    def add_one(x): return x + 1
```

```
# WRONG — modified node name:
code add_one_func:        # node name was 'add_one', not 'add_one_func'
  body: ...
```

```
# WRONG — wrapped in markdown fence:
\`\`\`al
flow my_lib: ...
\`\`\`
```

## Class method pattern

If a node is named `<Class>__<method>` (e.g. `Lock__acquire`, `Schema___compile_dict`), the body's Python is a method definition — keep the `def <method>(self, ...):` signature WITHOUT the `Class.` prefix. The runner's inject step uses the dunder convention to find the class in the original repo.

## Decorator pattern (e.g. `@deprecated`, `@wrapt.decorator`)

For decorator implementations, the body may use `@wrapt.decorator` for transparent argument forwarding. Pattern:

```python
import wrapt

@wrapt.decorator
def my_decorator(wrapped, instance, args, kwargs):
    # do something before
    result = wrapped(*args, **kwargs)
    # do something after
    return result
```

If the decorator takes config args (e.g. `@deprecated("use foo instead")`), wrap with an outer factory:

```python
def my_decorator(reason=None, **kw):
    @wrapt.decorator
    def wrapper(wrapped, instance, args, kwargs):
        # use reason here
        return wrapped(*args, **kwargs)
    return wrapper
```

## AUTHORING GUIDE

{authoring_guide}

## SPEC

{spec_text}

## AGENT-LANG SKELETON (to fill)

{skeleton_text}
{iter_history}
## YOUR FILLED agent-lang OUTPUT (raw, no fences):
