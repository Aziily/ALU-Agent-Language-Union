"""Parser package — source ⇄ AST for agent-lang v0.7.

Public API:
    parse(source: str)     -> Program          AST root
    serialize(ast: Program) -> str              canonical .al text
    tokenize(source: str)  -> list[Token]      token stream (advanced)
    resolve_project(root)  -> ModuleGraph       v0.7 multi-file resolver

The AST shape is defined in :mod:`al.parser.ast_nodes` and is the
public contract consumed by codegen, runtime, and any tools.

Internals:
    tokenizer.py   indent-aware line-oriented tokenizer
    parser.py      hand-written recursive descent
    serializer.py  AST → text (canonical formatting)
    ast_nodes.py   dataclass AST definitions
    resolver.py    v0.7 multi-file import resolution + cycle detection
    errors.py      ParseError, LexError exceptions
"""

from al.parser.tokenizer import tokenize
from al.parser.parser import parse
from al.parser.serializer import serialize
from al.parser.errors import ParseError, LexError
from al.parser.ast_nodes import (
    Program,
    Definition,
    Field,
    ImportDecl,
    InlineText,
    TypedAnnotation,
    BlockScalar,
    FieldGroup,
    StepList,
    Reference,
    ReferenceList,
    RefStep,
    ParallelStep,
    EachStep,
    IfStep,
    ReturnStep,
    Loc,
)
from al.parser.resolver import (
    ModuleGraph,
    Module,
    ImportCycleError,
    ModuleNotFoundError,
    resolve_project,
    resolve_from_text,
)

__all__ = [
    "tokenize",
    "parse",
    "serialize",
    "ParseError",
    "LexError",
    "Program",
    "Definition",
    "Field",
    "ImportDecl",
    "InlineText",
    "TypedAnnotation",
    "BlockScalar",
    "FieldGroup",
    "StepList",
    "Reference",
    "ReferenceList",
    "RefStep",
    "ParallelStep",
    "EachStep",
    "IfStep",
    "ReturnStep",
    "Loc",
    "ModuleGraph",
    "Module",
    "ImportCycleError",
    "ModuleNotFoundError",
    "resolve_project",
    "resolve_from_text",
]
