---
name: verification-before-completion
description: >-
  Enforces fresh verification evidence before any completion claim, commit, or
  PR. Use before claiming "tests pass", "bug fixed", "feature complete", or
  handing off work. Prevents the most common AI failure mode: asserting success
  without running the proof.
---

# Verification Before Completion

## The Rule

No completion claims without fresh verification evidence. If the verification command has not been run **immediately before the claim**, the claim cannot be made.

"Should pass", "probably works", and "looks correct" are not verification. Only command output confirming the claim counts (typically exit code 0). If pre-existing failures cause non-zero exits unrelated to your changes, see "When Verification Fails" below.

## Gate Function

Before any success claim, run through these five steps:

| Step | Action | Example |
|------|--------|---------|
| **1. Identify** | What command proves this claim? | `pytest tests/`, `npm test`, `curl -s localhost:3000/health` |
| **2. Run** | Execute the full command, fresh | Not "I ran it earlier" — run it now |
| **3. Read** | Read the complete output, check exit code | Don't scan for "passed" — read failure counts, warnings, errors |
| **4. Verify** | Does the output actually confirm the claim? | "42 passed, 0 failed" confirms "tests pass". "41 passed, 1 failed" does not. |
| **5. Claim** | Only now make the statement | "All 42 tests pass" with the evidence visible |

## When This Applies

- About to say "tests pass" or "build succeeds"
- About to commit, push, or create a PR
- About to claim a bug is fixed
- About to mark a task as complete
- Moving to the next task in a plan
- Reporting results to the user
- Agent reports success on delegated work

## Agent Delegation

When a subagent reports success:

1. Check the VCS diff — did the agent actually make changes?
2. Run the verification command yourself
3. Report the actual state, not the agent's claim

Never forward an agent's "all tests pass" without running the tests yourself.

## Requirements vs Tests

"Tests pass" and "requirements met" are different claims:

1. Re-read the plan or requirements
2. Create a line-by-line checklist
3. Verify each item against the implementation
4. Report gaps or confirm completion

Passing tests prove the code works. They don't prove the right code was written.

## Common Claims and Their Proof

| Claim | Required Proof |
|-------|---------------|
| "Tests pass" | Test runner output showing 0 failures, exit code 0 |
| "Build succeeds" | Build command output with exit code 0 |
| "Bug is fixed" | Original reproduction case now passes |
| "Feature complete" | All acceptance criteria verified individually |
| "No regressions" | Full test suite passes, not just new tests |
| "Regression test works" | Red-green cycle: test passes, revert fix, test fails, restore fix, test passes |
| "Linting clean" | Linter output showing 0 errors/warnings |

## When No Verification Command Exists

Some changes have no obvious test command — documentation, configuration, infrastructure-as-code, skill files. In these cases:

- **Documentation/prose** — verify by reading the rendered output. Confirm links work, formatting is correct, content matches intent.
- **Configuration/infra** — verify syntax (`jq .` for JSON, `yamllint` for YAML, `terraform validate`, `docker build`). If no validator exists, read the file and confirm it matches the intended change.
- **Non-runnable changes** — verify by diffing (`git diff`) and confirming the diff matches what was intended. State explicitly: "No automated verification available. Verified by reading the diff."

The principle holds: state what you checked and how, even when a test suite doesn't apply.

## When Verification Fails

If the output does not confirm the claim:

1. **Do not claim completion.** Report the actual failure output to the user.
2. **Do not retry the same verification hoping for a different result.** If it failed, something is wrong.
3. **Return to implementation.** Fix the issue, then re-run verification from Step 1 of the Gate Function.
4. **If the failure is unrelated to your changes** (pre-existing flaky test, environment issue), state this explicitly with evidence — show that the failure also occurs on the base branch or is a known issue.

## Red Flags

Stop and re-verify if you notice yourself:

- Using "should", "probably", or "seems to" about verification results
- Feeling satisfied before running the command
- Relying on a previous run ("it passed earlier")
- Verifying only part of the claim ("new tests pass" instead of "all tests pass")
- Trusting a subagent's report without independent verification
- Claiming success based on code reading ("the logic looks correct")
- Skipping verification because "it's a small change"
- Feeling confident about the result before running the command

## Integration

This skill is referenced by:
- `workflows:work` — before marking tasks complete and before shipping
- `receiving-code-review` — verify each fix before marking resolved
- `debugging` — before claiming a bug is fixed
- `finishing-branch` — before merge or PR creation
- `writing-tests` — tests as primary verification evidence
