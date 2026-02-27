---
name: simplifying-code
description: >-
  Simplifies, polishes, and declutters code without changing behavior. Use when
  asked to "simplify code", "clean up code", "polish code", "refactor",
  "declutter", "reduce complexity", "remove dead code", "remove AI slop",
  "improve readability", or "tighten up this file".
---

# Simplifying Code

## Principles

| Principle | Rule |
|-----------|------|
| **Preserve behavior** | Output must do exactly what the input did — no silent feature additions or removals. Specifically preserve: async/sync boundaries, error propagation paths, and logging side effects |
| **Explicit over clever** | Prefer explicit variables over nested expressions. Readable beats compact |
| **Simplicity over cleanliness** | Prefer straightforward code over pattern-heavy "clean" code. Three similar lines beat a premature abstraction |
| **Surgical changes** | Touch only what needs simplifying. Match existing style, naming conventions, and formatting of the surrounding code |
| **Surface assumptions** | Before changing a block, identify what imports it, what it imports, and what tests cover it. Edit dependents in the same pass |

## Process

1. **Read first** — understand the full file and its dependents before changing anything
2. **Identify invariants** — what must stay the same? Public API, return types, side effects, error behavior
3. **Identify targets** — find the highest-impact simplification opportunities (see Smell → Fix table)
4. **Apply in order** — control flow → naming → duplication → data shaping → types. Structural changes first, cosmetic last
5. **Verify** — confirm no behavior change: tests pass, types check, imports resolve

## Smell → Fix

| Smell | Fix |
|-------|-----|
| Deep nesting (>2 levels) | Guard clauses with early returns |
| Long function (>30 lines) | Extract into named functions by responsibility |
| Too many parameters (>3) | Group into an options/config object |
| Duplicated block (**3+** occurrences) | Extract shared function. Two copies = leave inline; wait for the third |
| Magic numbers/strings | Named constants |
| Complex conditional | Extract to descriptively-named boolean or function |
| Dead code / unreachable branches | Delete entirely — no commented-out code |
| Unnecessary `else` after return | Remove `else`, dedent |

## AI Slop Removal

When simplifying AI-generated code, specifically target:

- **Redundant comments** that restate the code (`// increment counter` above `counter++`) — delete them
- **Unnecessary defensive checks** for conditions that cannot occur in context — remove the guard
- **Gratuitous type casts** (`as any`, `as unknown as T`) — fix the actual type or use a proper generic
- **Over-abstraction** (factory for 2 objects, wrapper around a single call, util file with 1 function) — inline the code
- **Inconsistent style** that drifts from the file's existing conventions — match the file

## Constraints

- Only simplify what was requested — do not add features, expand scope, or introduce new dependencies
- Leave unchanged code untouched — do not add comments, docstrings, or type annotations to lines that were not simplified
- If a simplification would make the code harder to understand, skip it
- When unsure whether a block is dead code, ask instead of deleting
