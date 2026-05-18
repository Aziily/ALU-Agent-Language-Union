# Forward Compatibility — limitations & non-locks

This document accumulates per-phase "forward compatibility checks" — the
design constraints we deliberately AVOID adding to keep AL future-compatible
with: (a) a unified code+agent paradigm where the same .al file mixes
deterministic code with LLM-call agents, and (b) a future "intent-only
post-language mode" where on-device agents do most synthesis directly
from `intent:` declarations.

## Per-phase audit

### Phase A (v0.7 build)

- `intent:` field is available on EVERY node kind, not just code → ✅
  forward-compatible with intent-only mode
- `code` and `agent` are sibling top-level kinds → ✅ unified paradigm
- Host language is "Python" via codegen but the spec doesn't preclude
  other targets (just no current codegen for them) → soft lock,
  intentional

### Phase B (Codex co-iter v0.7.1-3)

- `target: <relpath>::<qualname>` ASSUMES the target file is Python.
  An intent-only post-language mode would need either a new field
  (`target_agent:`?) OR redefine `target:` to be language-agnostic.
  → minor forward-compat concern; flagged for v1.0+ revisit
- `---PATCH: <relpath>---` is filesystem-pathed. Future agent-side
  patching might not have a filesystem. → soft lock; can be redefined
  later
- `uses:` is a generic ReferenceList — doesn't assume a target language
  → ✅
- `body:` field on code is a Python BlockScalar but conceptually could
  hold ANY block scalar interpreted by the host-language renderer →
  forward-compat by analogy

### Phase C-F (validation)

(Per-phase report appends here as each lands)

- Phase C: no new language features; only inject infrastructure
  hardening. No forward-compat changes.
- Phase D: TBD
- Phase E: equivalence proof framework is Python-specific (uses
  `ast` module) — but it's a proof, not a runtime constraint, so it
  doesn't lock production.
- Phase F: HumanEval / MBPP adapters extend the harness to multi-source.
  No language-level locks added.

## Long-term vision constraints

| Long-term goal | What this plan does | What this plan leaves open |
|---|---|---|
| Unified code+agent paradigm | `code` / `agent` are siblings; mixed-files work | Runtime to actually execute the agent calls — currently codegen-only |
| Intent-only post-language mode | `intent:` available everywhere | No empty-body inference engine; `intent:` is decoration unless paired with executable scaffold |
| Multi-language host | Spec mentions Python but architecture allows others | No non-Python codegen written |
| Edit-driven workflow | AL is text editable + parser+serializer round-trip | No interactive editor; that's v0.5 scope on hold |

## Non-locks (deliberately omitted to preserve flexibility)

1. We did NOT add a runtime / interpreter. `body:` is just Python; flows
   are static descriptions. This avoids locking in execution semantics
   before the language design stabilizes.
2. We did NOT make `intent:` mandatory. Optional everywhere → backward
   compatible with non-intent-using AL files.
3. We did NOT add `try`/`except`/`retry` keywords. Decision deferred since
   Phase B; would constrain future agent error handling.
4. We did NOT promote `uses:` to mandatory. Soft-only → preserves
   compatibility with files written before the field existed.

## Phase G action items

- Update this file with Phase D/F/G per-phase audit lines
- Cross-reference each item in `claims.md` to ensure no forward-compat
  conflict
