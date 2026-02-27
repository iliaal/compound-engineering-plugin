---
name: debugging
description: >-
  Systematic root-cause debugging: reproduce, investigate, hypothesize, fix
  with verification. Use when asked to "debug this", "fix this bug", "why is
  this failing", "troubleshoot", or mentions errors, stack traces, broken tests,
  flaky tests, regressions, or unexpected behavior.
---

# Debugging

## The Iron Law

Never propose a fix without first identifying the root cause. "Quick fix now, investigate later" is forbidden — it creates harder bugs.

## Process

**1. Reproduce** — make the bug consistent. If intermittent, run N times under stress or simulate poor conditions (slow network, low memory) until it triggers reliably.

**2. Investigate** — trace backward through the call chain from the symptom. Add diagnostic logging at each component boundary. Compare working vs broken state using a differential table (environment, version, data, timing — what changed?).

**3. Hypothesize and test** — one change at a time. If a hypothesis is wrong, fully revert before testing the next. Use `git bisect` to find regressions efficiently.

**4. Fix and verify** — create a failing test FIRST, then fix. Run the test. Confirm the original reproduction case passes. No completion claims without fresh verification evidence.

## Three-Fix Threshold

After 3 failed fix attempts, STOP. The problem is likely architectural, not a surface bug. Step back and question assumptions about how the system works. Read the actual code path end-to-end instead of spot-checking.

## Escalation: Competing Hypotheses

When the cause is unclear across multiple components, use Analysis of Competing Hypotheses:
- Generate hypotheses across failure modes: logic error, data issue, state problem, integration failure, resource exhaustion, environment
- Investigate each with evidence: Direct (strong), Correlational (medium), Testimonial (weak)
- Cite evidence with `file:line` references
- Rank by confidence. If multiple hypotheses are equally supported, suspect compound causes.

## Intermittent Issues

- Track with correlation IDs across distributed components
- Race conditions: look for shared mutable state, check-then-act patterns, missing locks
- Resource exhaustion: monitor memory growth, connection pool depletion, file descriptor leaks
- Timing-dependent: replace arbitrary `sleep()` with condition-based polling — wait for the actual state, not a duration

## Defense-in-Depth Validation

After fixing, validate at every layer — not just where the bug appeared:
- **Entry**: does invalid input get caught?
- **Business logic**: does the fix handle edge cases?
- **Environment**: does it work across configurations?
- **Instrumentation**: add logging to detect recurrence

## Bug Triage

When multiple bugs exist, prioritize by:
- **Severity** (data loss > crash > wrong output > cosmetic) separately from **Priority** (blocking release > customer-facing > internal)
- Reproducibility: always > sometimes > once. "Sometimes" bugs need instrumentation before fixing.
- Quick wins: if a fix is < 5 minutes and unblocks others, do it first

## Common Patterns

- **Null/undefined access** — trace where the value was expected to be set, check all code paths
- **Off-by-one** — check `<` vs `<=`, array length vs last index, loop boundaries
- **Async ordering** — missing `await`, unhandled promise rejection, callback firing before setup completes
- **Type coercion** — `==` vs `===`, string-to-number conversion, truthy/falsy edge cases
- **Timezone** — always store UTC, convert at display. Check DST transitions.

## Anti-Patterns

- Shotgun debugging (random changes without hypothesis) — revert and think instead
- Multiple simultaneous changes — isolate each change or you can't learn what worked
- Fixing the symptom not the cause — the same bug will resurface differently
- Ignoring intermittent failures ("works on my machine") — instrument and reproduce under load instead
