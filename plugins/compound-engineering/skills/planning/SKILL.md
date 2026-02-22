---
name: planning
description: >-
  Software implementation planning with file-based persistence (task_plan.md,
  findings.md, progress.md). Use when asked to "plan", "break down this
  feature", "implementation plan", or starting complex tasks needing >5 tool
  calls. Apply proactively before non-trivial coding.
---

# Planning

## Core Principle

```
Context window = RAM (volatile, limited)
Filesystem     = Disk (persistent, unlimited)
→ Anything important gets written to disk.
```

Planning tokens are cheaper than implementation tokens. Front-load thinking; scale effort to complexity.

## When to Plan

- **Always plan**: multi-file changes, new features, refactors, >5 tool calls
- **Skip planning**: single-file edits, quick lookups, simple questions

## Planning Files

Create in project root before starting work:

| File | Purpose | Update When |
|------|---------|-------------|
| `task_plan.md` | Phases, tasks, decisions, errors | After each phase |
| `findings.md` | Research, discoveries, code analysis | After any discovery |
| `progress.md` | Session log, test results, files changed | Throughout session |

## Plan Template

```markdown
# Plan: [Feature/Task Name]

## Approach
[1-3 sentences: what and why]

## Scope
- **In**: [what's included]
- **Out**: [what's explicitly excluded]

## Phase 1: [Name]
**Files**: [specific files, max 5-8 per phase]
**Tasks**:
- [ ] [Verb-first atomic task] — `path/to/file.ts`
- [ ] [Next task]
**Verify**: [specific test: "POST /api/users → 201", not "test feature"]
**Exit**: [clear done definition]

## Phase 2: [Name]
...

## Open Questions
- [Max 3, only truly blocking unknowns]
```

## Phase Sizing Rules

Every phase must be **context-safe**:
- Max 5-8 files touched
- Max 2 dependencies on other phases
- Fits in one 2-4 hour session (implementation + verification + fixes)
- If a phase violates these → split it

## Clarifying Questions

Scale to complexity:
- Small task: 0-1 questions, assume reasonable defaults
- Medium feature: 1-2 questions on critical unknowns
- Large project: 3-5 questions (auth, data model, integrations, scope)

Only ask if truly blocking. Make reasonable assumptions for everything else.

## Task Rules

- **Atomic**: one logical unit of work per task
- **Verb-first**: "Add...", "Create...", "Refactor...", "Verify..."
- **Concrete**: name specific files, endpoints, components
- **Ordered**: respect dependencies, sequential when needed
- **Verifiable**: include at least one validation task per phase

## Context Management Rules

| Situation | Action |
|-----------|--------|
| Starting new phase | Read task_plan.md (refresh goals in attention window) |
| After any discovery | Write to findings.md immediately |
| After completing phase | Update task_plan.md status, log to progress.md |
| After viewing image/PDF | Write findings NOW (multimodal content doesn't persist) |
| Resuming after gap | Read all planning files |
| Just wrote a file | Don't re-read it (still in context) |
| Error occurred | Log to task_plan.md, read relevant files for state |

## Error Protocol

```
ATTEMPT 1: Diagnose root cause → targeted fix
ATTEMPT 2: Different approach (different tool, library, method)
ATTEMPT 3: Question assumptions → search for solutions → update plan
AFTER 3 FAILURES: Escalate to user with what you tried
```

**Never repeat the exact same failing action.** Track attempts, mutate approach.

## Iterative Refinement

For complex projects, iterate on the plan before implementing:
1. Draft initial plan
2. Review for gaps, missing edge cases, architectural issues
3. Revise until suggestions become incremental
4. Only then start implementation

## 5-Question Context Check

If you can answer these, your planning is solid:

| Question | Source |
|----------|--------|
| Where am I? | Current phase in task_plan.md |
| Where am I going? | Remaining phases |
| What's the goal? | Approach section |
| What have I learned? | findings.md |
| What have I done? | progress.md |

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Start coding without a plan | Create task_plan.md first |
| State goals once and forget | Re-read plan before decisions |
| Hide errors and retry silently | Log errors, mutate approach |
| Keep everything in context | Write large content to files |
| Repeat failed actions | Track attempts in plan file |
| Create vague tasks ("improve X") | Concrete verb-first tasks with file paths |
| Plan phases with 12+ files | Split into 5-8 file chunks |
| Plan at 100% capacity | Budget for verification, fixes, and unknowns |
