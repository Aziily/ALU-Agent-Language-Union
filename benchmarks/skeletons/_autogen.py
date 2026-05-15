"""Auto-generate an agent-lang skeleton from a commit0 repo's stripped Python.

For each .py file under a repo's src dir, walk the AST and emit one
``code`` node per stripped (body == [pass]) top-level function or class
method. Group code nodes by source file into a `flow <stem>_group`.

This gives us a workable skeleton for the giant lite repos (jinja,
babel, minitorch, imapclient, marshmallow, simpy) where hand-design
of ~50-300 nodes would take days.

Per Phase 1.H'.A fairness decisions: no intent/input/output fields
emitted — only flow + steps + code + body with docstring + pass.

Usage:
    python -m benchmarks.skeletons._autogen <repo_name> <src_subdir>

    # examples:
    python -m benchmarks.skeletons._autogen simpy src/simpy
    python -m benchmarks.skeletons._autogen jinja src/jinja2
    python -m benchmarks.skeletons._autogen babel babel

Writes to ``benchmarks/skeletons/<repo_name>.al``.
"""

from __future__ import annotations

import ast
import re
import sys
from collections import defaultdict
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SKELETONS_DIR = Path(__file__).resolve().parent


def _is_stripped(node) -> bool:
    """True iff function body == ['pass'] optionally after a docstring."""
    body = list(node.body)
    if body and isinstance(body[0], ast.Expr) and isinstance(body[0].value, ast.Constant) \
       and isinstance(body[0].value.value, str):
        body = body[1:]
    return len(body) == 1 and isinstance(body[0], ast.Pass)


_VALID_NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _node_name_for_method(cls: str, meth: str) -> str:
    """Build agent-lang node name for a class method.

    Conventions (per Phase 1.E):
      - `Class__method` for regular methods
      - For methods with leading underscore, the underscore goes between
        Class__ and _method (e.g. `Schema___compile_dict`)
    """
    return f"{cls}__{meth}"


def _collect_stripped(src_dir: Path) -> dict[str, list[tuple[str, str, str, str]]]:
    """Return {file_stem: [(node_name, signature, docstring, kind), ...]}."""
    out: dict[str, list[tuple[str, str, str, str]]] = defaultdict(list)
    for src_file in sorted(src_dir.rglob("*.py")):
        # Skip tests / build
        if any(p in src_file.parts for p in ("tests", "test", "__pycache__")):
            continue
        try:
            tree = ast.parse(src_file.read_text(encoding="utf-8", errors="replace"))
        except SyntaxError:
            continue
        rel = src_file.relative_to(src_dir).as_posix().replace("/", "_").replace(".py", "")
        for node in tree.body:
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                if _is_stripped(node):
                    doc = _get_docstring(node)
                    if not _VALID_NAME.match(node.name):
                        continue
                    out[rel].append((node.name, ast.unparse(node.args), doc, "function"))
            elif isinstance(node, ast.ClassDef):
                if not _VALID_NAME.match(node.name):
                    continue
                for m in node.body:
                    if isinstance(m, (ast.FunctionDef, ast.AsyncFunctionDef)):
                        if _is_stripped(m):
                            if not _VALID_NAME.match(m.name):
                                continue
                            doc = _get_docstring(m)
                            nname = _node_name_for_method(node.name, m.name)
                            out[rel].append((nname, ast.unparse(m.args), doc, "method"))
    return out


def _collect_preambles(src_dir: Path) -> dict[str, tuple[str, str]]:
    """Phase 1.AL.5 — return {file_stem: (rel_path, preamble_body_text)}.

    For each .py under ``src_dir`` (excluding tests / build), extract
    the module-level Python that is NOT a stripped function/method:
      - all imports (ast.Import, ast.ImportFrom)
      - all top-level class definitions (full body — even if some methods
        are stripped, since the class itself is module-level)
      - all module-level assignments / annotated assignments (constants,
        type aliases, ``__all__``)
      - module docstring (if present at body[0])

    Returns the body text using ``ast.unparse``. Module-level
    top-level functions are EXCLUDED whether stripped or not — those
    become ``code <name>`` nodes elsewhere.
    """
    out: dict[str, tuple[str, str]] = {}
    for src_file in sorted(src_dir.rglob("*.py")):
        if any(p in src_file.parts for p in ("tests", "test", "__pycache__")):
            continue
        try:
            tree = ast.parse(src_file.read_text(encoding="utf-8", errors="replace"))
        except SyntaxError:
            continue
        rel_path = src_file.relative_to(src_dir.parent).as_posix() \
            if src_file.is_relative_to(src_dir.parent) \
            else src_file.relative_to(src_dir).as_posix()
        rel_stem = src_file.relative_to(src_dir).as_posix().replace("/", "_").replace(".py", "")

        preamble_nodes: list[ast.AST] = []
        for idx, node in enumerate(tree.body):
            # Module docstring at body[0]
            if idx == 0 and isinstance(node, ast.Expr) \
                    and isinstance(node.value, ast.Constant) \
                    and isinstance(node.value.value, str):
                preamble_nodes.append(node)
                continue
            # Module-level imports / classes / constants / type aliases /
            # conditional import blocks. Skip top-level (Async)FunctionDef
            # — those become code nodes (their bodies must not appear in
            # the preamble or we'd duplicate them).
            if isinstance(node, (ast.Import, ast.ImportFrom)):
                preamble_nodes.append(node)
            elif isinstance(node, ast.ClassDef):
                preamble_nodes.append(node)
            elif isinstance(node, (ast.Assign, ast.AnnAssign, ast.AugAssign)):
                preamble_nodes.append(node)
            elif isinstance(node, ast.If):
                # Module-level `if sys.version_info >= ...:` keep verbatim
                preamble_nodes.append(node)
            elif isinstance(node, ast.Try):
                # Conditional import blocks (`try: import x except: ...`)
                preamble_nodes.append(node)
            # else: skip FunctionDef / AsyncFunctionDef — handled in _collect_stripped

        if not preamble_nodes:
            continue
        try:
            preamble_text = "\n".join(ast.unparse(n) for n in preamble_nodes)
        except Exception:
            continue
        if not preamble_text.strip():
            continue
        out[rel_stem] = (rel_path, preamble_text)
    return out


def _get_docstring(node) -> str:
    body = node.body
    if body and isinstance(body[0], ast.Expr) and isinstance(body[0].value, ast.Constant) \
       and isinstance(body[0].value.value, str):
        return body[0].value.value
    return ""


def _format_body(node_name: str, signature: str, docstring: str, kind: str) -> str:
    """Emit the body Python source for one code node."""
    # method nodes: node_name is `Class__method`; actual def is `def method(...)`
    if kind == "method":
        fn = node_name.split("__", 1)[1]
        # method names starting with _ get encoded as Class___method, so revert
        if fn.startswith("_") and not fn.startswith("__"):
            # already correct
            pass
    else:
        fn = node_name

    lines = [f"def {fn}({signature}):"]
    if docstring:
        # Use triple-quoted docstring; escape any """ inside (very rare)
        safe_doc = docstring.replace('"""', '\\"\\"\\"')
        if "\n" in safe_doc:
            lines.append(f'    """{safe_doc}')
            lines.append('    """')
        else:
            lines.append(f'    """{safe_doc}"""')
    lines.append("    pass")
    return "\n".join(lines)


def generate_skeleton(repo: str, src_subdir: str) -> str:
    """Produce agent-lang skeleton text for one repo.

    Phase 1.AL.5: also emits ``preamble <file_stem>: body: |``
    blocks at the top, one per source file that has module-level
    Python (imports, classes, constants). The preamble gives the LLM
    the module-level context it would otherwise be blind to.
    """
    src_dir = REPO_ROOT / "thirdparty" / "commit0_repos" / repo / src_subdir
    if not src_dir.exists():
        raise FileNotFoundError(f"src dir not found: {src_dir}")
    grouped = _collect_stripped(src_dir)
    preambles = _collect_preambles(src_dir)
    if not grouped:
        raise RuntimeError(f"no stripped functions found under {src_dir}")

    out: list[str] = []

    # 1. Preambles first (module-level Python context per source file).
    for stem, (rel_path, body_text) in preambles.items():
        out.append(f"preamble {stem}:")
        out.append(f"  source: {rel_path}")
        out.append("  body: |")
        for line in body_text.splitlines():
            if line:
                out.append(f"    {line}")
            else:
                out.append("")
        out.append("")
        out.append("")

    # 2. Top-level flow with group refs
    out.append(f"flow {repo}_lib:")
    out.append("  steps:")
    for grp in grouped:
        out.append(f"    - {grp}_group")
    out.append("")
    out.append("")

    # 3. Each file → one group flow
    for grp, entries in grouped.items():
        out.append(f"flow {grp}_group:")
        out.append("  steps:")
        for (nname, _sig, _doc, _kind) in entries:
            out.append(f"    - {nname}")
        out.append("")
        out.append("")

    # 4. Each function → one code node
    for grp, entries in grouped.items():
        for (nname, sig, doc, kind) in entries:
            body = _format_body(nname, sig, doc, kind)
            out.append(f"code {nname}:")
            out.append(f"  body: |")
            for line in body.splitlines():
                out.append(f"    {line}")
            out.append("")
            out.append("")

    return "\n".join(out).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if len(args) < 2:
        print("usage: python -m benchmarks.skeletons._autogen <repo> <src_subdir>",
              file=sys.stderr)
        print("example: python -m benchmarks.skeletons._autogen simpy src/simpy",
              file=sys.stderr)
        return 1
    repo, src_subdir = args[0], args[1]
    out = generate_skeleton(repo, src_subdir)
    target = SKELETONS_DIR / f"{repo}.al"
    target.write_text(out, encoding="utf-8")
    print(f"wrote {target}  ({out.count(chr(10))} lines, "
          f"{out.count('code ')} code nodes, {out.count('flow ')} flow nodes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
