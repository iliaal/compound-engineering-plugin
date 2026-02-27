---
name: code-review
description: >-
  Performs two-stage code reviews (spec compliance, then code quality) with
  severity-ranked findings. Use when asked to "review code", "review this PR",
  "check this diff", "review before merge", or mentions reviewing, auditing,
  or critiquing code changes, pull requests, or diffs.
---

# Code Review

## Two-Stage Review

**Stage 1 — Spec compliance** (do this FIRST): verify the changes implement what was intended. Check against the PR description, issue, or task spec. Identify missing requirements, unnecessary additions, and interpretation gaps. If the implementation is wrong, stop here — reviewing code quality on the wrong feature wastes effort.

**Stage 2 — Code quality**: only after Stage 1 passes, review for correctness, maintainability, security, and performance.

## Review Process

1. **Context** — read the PR description, linked issue, or task spec. Run the project's test/lint suite if available (`npm run test`, `make check`, etc.) to catch automated failures before manual review.
2. **Structural scan** — architecture, file organization, API surface changes. Flag breaking changes.
3. **Line-by-line** — correctness, edge cases, error handling, naming, readability. Use question-based feedback ("What happens if `input` is empty here?") instead of declarative statements to encourage author thinking.
4. **Security** — input validation, auth checks, secrets exposure, injection vectors (SQL, XSS, command). Flag race conditions (TOCTOU, check-then-act).
5. **Removal candidates** — identify dead code, unused imports, feature-flagged code that can be cleaned up. Distinguish safe-to-delete (no references) from defer-with-plan (needs migration).
6. **Summary** — present findings grouped by severity, then ask user how to proceed. Do NOT auto-implement fixes.

## Severity Levels

- **Critical** — must fix before merge. Security vulnerabilities, data loss, broken functionality, race conditions.
- **Important** — should fix before merge. Performance issues, missing error handling, poor maintainability, silent failures.
- **Minor** — optional. Naming, style preferences, minor simplifications. Skip if linters already cover it.

## What to Check

Correctness:
- Edge cases (null, empty, boundary values, concurrent access)
- Error paths (are failures handled or swallowed?)
- Type safety (implicit conversions, `any` types, unchecked casts)

Maintainability:
- Functions doing too much (split by responsibility, not size)
- Deeply nested logic (extract early returns instead)
- Naming that obscures intent

Performance:
- N+1 queries (loop with query per item — use batch/join instead)
- Unbounded collections (arrays/maps without size limits)
- Missing indexes on queried columns

## Anti-Patterns in Reviews

- Nitpicking style when linters exist — defer to automated tools instead
- "While you're at it..." scope creep — open a separate issue instead
- Blocking on personal preference — approve with a Minor comment instead
- Rubber-stamping without reading — always verify at least Stage 1
- Reviewing code quality before verifying spec compliance — do Stage 1 first

## Output Format

```
## Review: [brief title]

### Critical
- **[file:line]** — [issue]. [What happens if not fixed]. Fix: [concrete suggestion].

### Important
- **[file:line]** — [issue]. [Why it matters]. Consider: [alternative approach].

### Minor
- **[file:line]** — [observation].

### What's Working Well
- [specific positive observation with why it's good]
```

Ground every finding in actual code — no invented line references. Limit to 10 findings per severity. If more exist, note the count and show the highest-impact ones.
