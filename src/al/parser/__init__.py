"""Parser package — source ⇄ AST for agent-lang v0.6.

Public API:
    parse(source: str)     -> Program          AST root
    serialize(ast: Program) -> str              canonical .al text
    tokenize(source: str)  -> list[Token]      token stream (advanced)

The AST shape is defined in :mod:`al.parser.ast_nodes` and is the
public contract consumed by codegen, runtime, and any tools.

Internals:
    tokenizer.py   indent-aware line-oriented tokenizer
    parser.py      hand-written recursive descent
    serializer.py  AST → text (canonical formatting)
    ast_nodes.py   dataclass AST definitions
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
    InlineText,
    BlockScalar,
    FieldGroup,
    StepList,
    Reference,
    ReferenceList,
    RefStep,
    ParallelStep,
    EachStep,
    IfStep,
    Loc,
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
    "InlineText",
    "BlockScalar",
    "FieldGroup",
    "StepList",
    "Reference",
    "ReferenceList",
    "RefStep",
    "ParallelStep",
    "EachStep",
    "IfStep",
    "Loc",
]
