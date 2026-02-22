---
name: receiving-code-review
description: >-
  Process code review feedback critically: verify before implementing, push back
  on incorrect suggestions, no performative agreement. Use when receiving PR
  comments, review feedback, or suggestions from reviewers — human or agent.
---

# Receiving Code Review

## Core Principle

Verify before implementing. Technical correctness matters more than social comfort. A reviewer can be wrong — blindly implementing bad suggestions creates bugs.

## Response Pattern

For each piece of feedback, follow this sequence:

1. **Read** — Understand what's being suggested and why
2. **Verify** — Is the suggestion technically correct for THIS codebase?
3. **Evaluate** — Does it improve the code, or is it preference/style?
4. **Respond** — Agree with evidence, disagree with evidence, or ask for clarification
5. **Implement** — Only after verification confirms the suggestion is correct

Triage all feedback first (see Implementation Order below), then implement one item at a time. Don't batch-implement everything at once.

## Handling Unclear Feedback

When feedback is ambiguous or incomplete:

- **Stop** — do not implement anything unclear
- Clarify ALL unclear items before implementing ANY of them (they may be related)
- Ask specific questions: "Are you suggesting X or Y?" not "Can you elaborate?"
- If the reviewer's intent is clear but the technical approach is wrong, say so

## Source-Specific Handling

### From the user (project owner)

- Trusted context — they know the codebase and business requirements
- Implement after understanding, but still verify technical correctness
- Ask clarifying questions when the intent is clear but the approach seems risky
- No performative agreement — just acknowledge and implement

### From automated review agents

- **Skeptical by default** — agents lack full context
- Verify every suggestion against the actual codebase
- Check for YAGNI violations (agents love adding "just in case" code)
- Discard suggestions that contradict project conventions (check CLAUDE.md)
- Agents may flag things that are intentional design decisions — check before changing

### From external reviewers (PR comments, open source)

- Verify technical correctness for THIS stack and codebase
- Check if the suggestion applies to this version of the framework/library
- Push back if the reviewer lacks context about architectural decisions
- Distinguish between "this is wrong" and "I would do it differently"

## When to Push Back

Push back (with evidence) when a suggestion:

- **Breaks existing functionality** — "This would break X because Y depends on Z"
- **Violates project conventions** — "Our CLAUDE.md specifies we do it this way because..."
- **Is technically incorrect** — "This API was deprecated in v3. We're on v4 which uses..."
- **Adds unnecessary complexity** — "This handles a case that can't occur because..."
- **Conflicts with architectural decisions** — "We chose X over Y in the brainstorm because..."

## When NOT to Push Back

Accept feedback when:

- The suggestion is correct and you missed something
- It catches a genuine bug or edge case
- It improves readability without changing behavior
- It aligns with project conventions you overlooked
- The reviewer has domain expertise you lack

## Forbidden Responses

Never respond with:

- "Great catch!" / "Excellent point!" / "You're absolutely right!" (before verifying)
- "Let me implement that now" (before understanding the full impact)
- Gratitude expressions that substitute for technical analysis
- Agreement without evidence

Instead: "Verified — this fixes [specific issue]. Implementing." or "Checked this — the current approach is correct because [reason]."

## Implementation Order

After triaging all feedback:

1. **Clarify** — resolve all unclear items first
2. **Blocking issues** — fix things that break functionality
3. **Simple fixes** — quick wins that are clearly correct
4. **Complex fixes** — changes that need careful implementation

Test after each individual fix, not after implementing everything.

## GitHub PR Reviews

- Reply in the inline comment thread, not as top-level PR comments
- Reference specific lines when explaining why you disagree
- Mark conversations as resolved only after the fix is verified
- If a suggestion spawns a larger discussion, suggest moving it to an issue

## Scope vs `pr-comment-resolver` Agent

This skill and the `pr-comment-resolver` agent handle different situations:

| | This skill | `pr-comment-resolver` agent |
|---|---|---|
| **When** | Interactive review requiring judgment | Batch-resolving mechanical PR comments |
| **Approach** | Verify, evaluate, potentially push back | Implement requested changes efficiently |
| **Skepticism** | High — check correctness first | Low — comments are pre-triaged |
| **Use for** | Unclear suggestions, architectural feedback, debatable changes | Clear-cut fixes, style nits, typos, straightforward requests |

When the `pr-comment-resolver` agent encounters feedback that requires judgment (architectural decisions, debatable trade-offs), it should escalate rather than implement.

## Integration

This skill pairs with:
- `code-review` — the outbound side (requesting reviews)
- `pr-comment-resolver` agent — for mechanical PR comment resolution (see scope table above)
- `verification-before-completion` — verify each fix before marking resolved
