---
title: Convert .local.md Settings for OpenCode and Codex
type: feat
date: 2026-02-08
---

# Convert .local.md Settings for OpenCode and Codex

## Overview

PR #124 introduces `.claude/compound-engineering.local.md` — a YAML frontmatter settings file that workflow commands (`review.md`, `work.md`) read at runtime to decide which agents to run. The conversion script already handles agents, commands, skills, hooks, and MCP servers. It does **not** handle `.local.md` settings files.

The question: can OpenCode and Codex support this same pattern? And what does the converter need to do?

## Analysis: What `.local.md` Actually Does

The settings file does two things:

1. **YAML frontmatter** with structured config: `review_agents: [list]`, `plan_review_agents: [list]`
2. **Markdown body** with free-text instructions passed to review agents as context

The commands (`review.md`, `work.md`) read this file at runtime using the Read tool and use the values to decide which Task agents to spawn. This is **prompt-level logic** — it's instructions in the command body telling the AI "read this file, parse it, act on it."

## Key Insight: This Already Works

The converter already converts `review.md` and `work.md` command bodies verbatim (for OpenCode) or as generated skills (for Codex). The instructions that say "Read `.claude/compound-engineering.local.md`" are just markdown text inside the command body. When the converter outputs them:

- **OpenCode**: The command template includes the full body. The AI reads it, follows the instructions, reads the settings file.
- **Codex**: The command becomes a prompt + generated skill. The skill body includes the instructions. The AI reads it, follows the instructions, reads the settings file.

**The `.local.md` file itself is not a plugin component** — it's a runtime artifact created per-project by the user (via `/compound-engineering-setup`). The converter doesn't need to bundle it.

## What Needs Attention

### 1. Setup Command Has `disable-model-invocation: true`

`setup.md` has `disable-model-invocation: true`. The converter already handles this correctly:

- **OpenCode** (`claude-to-opencode.ts:117`): Skips commands with `disableModelInvocation`
- **Codex** (`claude-to-codex.ts:22`): Filters them out of prompts and generated skills

This means `/compound-engineering-setup` won't be auto-invocable in either target. That's correct — it's a deliberate user action. But it also means users of the converted plugin have **no way to run setup**. They'd need to manually create the `.local.md` file.

### 2. The `.local.md` File Path Is Claude-Specific

The commands reference `.claude/compound-engineering.local.md`. In OpenCode, the equivalent directory is `.opencode/`. In Codex, it's `.codex/`. The converter currently does **no text rewriting** of file paths inside command bodies.

### 3. Slash Command References in Config-Aware Sections

The commands say things like "Run `/compound-engineering-setup` to create a settings file." The Codex converter already transforms `/command-name` → `/prompts:command-name`, but since setup has `disable-model-invocation`, there's no matching prompt. This reference becomes a dead link.

### 4. `Task {agent-name}(...)` Syntax in Review Commands

`review.md` uses `Task {agent-name}(PR content)` — the Codex converter already transforms these to `$skill-name` references. OpenCode passes them through as template text.

## Proposed Solution

### Phase 1: Add Settings File Path Rewriting to Converters

Both converters should rewrite `.claude/` paths inside command bodies to the target-appropriate directory.

**File:** `src/converters/claude-to-opencode.ts`

Add a `transformContentForOpenCode(body)` function that replaces:
- `.claude/compound-engineering.local.md` → `.opencode/compound-engineering.local.md`
- `~/.claude/compound-engineering.local.md` → `~/.config/opencode/compound-engineering.local.md`

Apply it in `convertCommands()` to the command body before storing as template.

**File:** `src/converters/claude-to-codex.ts`

Extend `transformContentForCodex(body)` to also replace:
- `.claude/compound-engineering.local.md` → `.codex/compound-engineering.local.md`
- `~/.claude/compound-engineering.local.md` → `~/.codex/compound-engineering.local.md`

### Phase 2: Generate Setup Equivalent for Each Target

Since `setup.md` is excluded by `disable-model-invocation`, the converter should generate a **target-native setup instruction** that tells users how to create the settings file.

**Option A: Include setup as a non-auto-invocable command anyway** (recommended)

Change the converters to include `disable-model-invocation` commands but mark them appropriately:
- **OpenCode**: Include in command map but add a `manual: true` flag or comment
- **Codex**: Include as a prompt (user can still invoke it manually via `/prompts:compound-engineering-setup`)

This is the simplest approach — the setup instructions are useful even if not auto-triggered.

**Option B: Generate a README/instructions file**

Create a `compound-engineering-settings.md` file in the output that documents how to create the settings file for the target platform. More complex, less useful.

**Recommendation: Option A** — just stop filtering out `disable-model-invocation` commands entirely. Both OpenCode and Codex support user-invoked commands/prompts. The flag exists to prevent Claude from auto-invoking during conversation, not to hide the command entirely.

### Phase 3: Update Tests

**File:** `tests/converter.test.ts`

- Add test that `.claude/` paths in command bodies are rewritten to `.opencode/` paths
- Update existing `disable-model-invocation` test to verify the command IS included (if Option A)

**File:** `tests/codex-converter.test.ts`

- Add test that `.claude/` paths are rewritten to `.codex/` paths
- Add test that setup command is included as a prompt (if Option A)
- Add test that slash command references to setup are preserved correctly

### Phase 4: Add Fixture for Settings-Aware Command

**File:** `tests/fixtures/sample-plugin/commands/settings-aware-command.md`

```markdown
---
name: workflows:review
description: Run comprehensive code reviews
---

Read `.claude/compound-engineering.local.md` for agent config.
If not found, use defaults.
Run `/compound-engineering-setup` to create settings.
```

Test that the converter rewrites the paths and command references correctly.

## Acceptance Criteria

- [ ] OpenCode converter rewrites `.claude/` → `.opencode/` in command bodies
- [ ] Codex converter rewrites `.claude/` → `.codex/` in command/skill bodies
- [ ] Global path `~/.claude/` rewritten to target-appropriate global path
- [ ] `disable-model-invocation` commands are included (not filtered) in both targets
- [ ] Tests cover path rewriting for both targets
- [ ] Tests cover setup command inclusion
- [ ] Existing tests still pass

## What We're NOT Doing

- Not bundling the `.local.md` file itself (it's user-created per-project)
- Not converting YAML frontmatter format (both targets can read `.md` files with YAML)
- Not adding target-specific setup wizards (the instructions in the command body work across all targets)
- Not rewriting `AskUserQuestion` tool references (all three platforms support equivalent interactive tools)

## Complexity Assessment

This is a **small change** — mostly string replacement in the converters plus updating the `disable-model-invocation` filter. The `.local.md` pattern is prompt-level instructions, not a proprietary API. It works anywhere an AI can read a file and follow instructions.
