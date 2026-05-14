"""Codegen package — agent-lang AST → executable Python.

Public API:
    emit_python(program: Program) -> str

The output is a single Python module string. v0.6 骨架 emits a runnable
shell with stubbed orchestrator imports; the real orchestrator wires up
in 阶段 ② (see docs/PROJECT_PLAN.md).

Submodules:
    emit_python.py   top-level dispatcher (this is the public surface)
    emit_flow.py     flow → orchestrator call
    emit_code.py     code → Python function literal
    emit_agent.py    agent → goose-style call stub
    emit_set.py      set → SetDefinition literal
"""

from al.codegen.emit_python import emit_python

__all__ = ["emit_python"]
