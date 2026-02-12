---
title: Simplify Plugin Settings with .local.md Pattern
type: feat
date: 2026-02-08
---

# Simplify Plugin Settings

## Overview

Replace the 486-line `/compound-engineering-setup` wizard and JSON config with the `.local.md` plugin-settings pattern. Make agent configuration dead simple: a YAML frontmatter file users edit directly, with a lightweight setup command that generates the template.

## Problem Statement

The current branch (`feat/compound-engineering-setup`) has:
- A 486-line setup command with Quick/Advanced/Minimal modes, add/remove loops, custom agent discovery
- JSON config file (`.claude/compound-engineering.json`) — not the plugin-settings convention
- Config-loading boilerplate that would be duplicated across 4 workflow commands
- Over-engineered for "which agents should review my code?"

Meanwhile, the workflow commands on main have hardcoded agent lists that can't be customized per-project.

## Proposed Solution

Use `.claude/compound-engineering.local.md` with YAML frontmatter. Three simple changes:

1. **Rewrite `setup.md`** (486 → ~60 lines) — detect project type, create template file
2. **Add config reading to workflow commands** (~5 lines each) — read file, fall back to defaults
3. **Config is optional** — everything works without it via auto-detection

### Settings File Format

```markdown
---
review_agents: [kieran-rails-reviewer, code-simplicity-reviewer, security-sentinel]
plan_review_agents: [kieran-rails-reviewer, code-simplicity-reviewer]
---

# Review Context

Any extra instructions for review agents go here.
Focus on N+1 queries — we've had issues in the brief system.
Skip agent-native checks for internal admin pages.
```

That's it. No `conditionalAgents`, no `options`, no `customAgents` mapping. Conditional agents (migration, frontend, architecture, data) stay hardcoded in the review command — they trigger based on file patterns, not config.

## Implementation Plan

### Phase 1: Rewrite setup.md

**File:** `plugins/compound-engineering/commands/setup.md`
**From:** 486 lines → **To:** ~60 lines

The setup command should:

- [x] Detect project type (Gemfile+Rails, tsconfig, pyproject.toml, etc.)
- [x] Check if `.claude/compound-engineering.local.md` already exists
- [x] If exists: show current config, ask if user wants to regenerate
- [x] If not: create `.claude/compound-engineering.local.md` with smart defaults for detected type
- [x] Display the file path and tell user they can edit it directly
- [x] No wizard, no multi-step AskUserQuestion flows, no modify loops

**Default agents by project type:**

| Type | review_agents | plan_review_agents |
|------|--------------|-------------------|
| Rails | kieran-rails-reviewer, dhh-rails-reviewer, code-simplicity-reviewer, security-sentinel, performance-oracle | kieran-rails-reviewer, code-simplicity-reviewer |
| Python | kieran-python-reviewer, code-simplicity-reviewer, security-sentinel, performance-oracle | kieran-python-reviewer, code-simplicity-reviewer |
| TypeScript | kieran-typescript-reviewer, code-simplicity-reviewer, security-sentinel, performance-oracle | kieran-typescript-reviewer, code-simplicity-reviewer |
| General | code-simplicity-reviewer, security-sentinel, performance-oracle | code-simplicity-reviewer, architecture-strategist |

### Phase 2: Update review.md

**File:** `plugins/compound-engineering/commands/workflows/review.md`
**Change:** Replace hardcoded agent list (lines 64-81) with config-aware section

Add before the parallel agents section (~5 lines):

```markdown
#### Load Review Agents

Read `.claude/compound-engineering.local.md` (project) or `~/.claude/compound-engineering.local.md` (global).
If found, use `review_agents` from YAML frontmatter. If not found, auto-detect project type and use defaults:
- Rails: kieran-rails-reviewer, dhh-rails-reviewer, code-simplicity-reviewer, security-sentinel, performance-oracle
- Python: kieran-python-reviewer, code-simplicity-reviewer, security-sentinel, performance-oracle
- TypeScript: kieran-typescript-reviewer, code-simplicity-reviewer, security-sentinel, performance-oracle
- General: code-simplicity-reviewer, security-sentinel, performance-oracle

Run all review agents in parallel using Task tool.
```

**Keep conditional agents hardcoded** — they trigger on file patterns (db/migrate, *.ts, etc.), not user preference. This is correct behavior.

**Add `schema-drift-detector` as a conditional agent** — currently exists as an agent but isn't wired into any command. Add it to the migrations conditional block:

```markdown
**MIGRATIONS: If PR contains database migrations or schema.rb changes:**

- Task schema-drift-detector(PR content) - Detects unrelated schema.rb changes (run FIRST)
- Task data-migration-expert(PR content) - Validates ID mappings, rollback safety
- Task deployment-verification-agent(PR content) - Go/No-Go deployment checklist

**When to run:** PR includes `db/migrate/*.rb` OR `db/schema.rb`
```

`schema-drift-detector` should run first per its own docs — catches drift before other DB reviewers waste time on unrelated changes.

### Phase 3: Update work.md

**File:** `plugins/compound-engineering/commands/workflows/work.md`
**Change:** Replace hardcoded agent list in "Consider Reviewer Agents" section (lines 180-193)

Replace with:

```markdown
If review agents are needed, read from `.claude/compound-engineering.local.md` frontmatter (`review_agents`).
If no config, use project-appropriate defaults. Run in parallel with Task tool.
```

### Phase 4: Update compound.md

**File:** `plugins/compound-engineering/commands/workflows/compound.md`
**Change:** Update Phase 3 "Optional Enhancement" (lines 92-98) and "Applicable Specialized Agents" section (lines 214-234)

The specialized agents in compound.md are problem-type-based (performance → performance-oracle, security → security-sentinel). These should stay hardcoded — they're not "review agents", they're domain experts triggered by problem category. No config needed.

**Only change:** Add a note that users can customize review agents via `/compound-engineering-setup`, but don't add config-reading logic here.

## Acceptance Criteria

- [ ] `setup.md` is under 80 lines
- [ ] Running `/compound-engineering-setup` creates `.claude/compound-engineering.local.md` with correct defaults
- [ ] Running `/compound-engineering-setup` when config exists shows current config and asks before overwriting
- [ ] `/workflows:review` reads agents from `.local.md` when present
- [ ] `/workflows:review` falls back to auto-detected defaults when no config
- [ ] `/workflows:work` reads agents from `.local.md` when present
- [ ] `compound.md` unchanged except for a reference to the setup command
- [ ] No JSON config files — only `.local.md`
- [ ] Config file is optional — everything works without it
- [ ] Conditional agents (migrations, frontend, architecture, data) remain hardcoded in review.md

### Phase 5: Structural Cleanup

**5a. Delete `technical_review.md`**

`commands/technical_review.md` is a one-line command (`Have @agent-dhh-rails-reviewer @agent-kieran-rails-reviewer @agent-code-simplicity-reviewer review...`) with `disable-model-invocation: true`. It duplicates the `/plan_review` skill. Delete it.

- [x] Delete `plugins/compound-engineering/commands/technical_review.md`

**5b. Add `disable-model-invocation: true` to `setup.md`**

The setup command is deliberate — users run it explicitly. It should not be auto-invoked.

- [x] Add `disable-model-invocation: true` to `setup.md` frontmatter

**5c. Update component counts**

After changes: 29 agents, 24 commands (25 - 1 deleted technical_review), 18 skills, 1 MCP.

Wait — with setup.md added and technical_review.md deleted: 25 - 1 = 24. Same as main. Verify actual count after changes.

- [x] Update `plugin.json` description with correct counts
- [x] Update `marketplace.json` description with correct counts
- [x] Update `README.md` component counts table

**5d. Update CHANGELOG.md**

- [x] Add entry for v2.32.0 documenting: settings support, schema-drift-detector wired in, technical_review removed

## Acceptance Criteria

- [ ] `setup.md` is under 80 lines
- [ ] `setup.md` has `disable-model-invocation: true`
- [ ] Running `/compound-engineering-setup` creates `.claude/compound-engineering.local.md` with correct defaults
- [ ] Running `/compound-engineering-setup` when config exists shows current config and asks before overwriting
- [ ] `/workflows:review` reads agents from `.local.md` when present
- [ ] `/workflows:review` falls back to auto-detected defaults when no config
- [ ] `/workflows:review` runs `schema-drift-detector` for PRs with migrations or schema.rb
- [ ] `/workflows:work` reads agents from `.local.md` when present
- [ ] `compound.md` unchanged except for a reference to the setup command
- [ ] `technical_review.md` deleted
- [ ] No JSON config files — only `.local.md`
- [ ] Config file is optional — everything works without it
- [ ] Conditional agents (migrations, frontend, architecture, data) remain hardcoded in review.md
- [ ] Component counts match across plugin.json, marketplace.json, and README.md

## What We're NOT Doing

- No multi-step wizard (users edit the file directly)
- No custom agent discovery (users add agent names to the YAML list)
- No `conditionalAgents` config (stays hardcoded by file pattern)
- No `options` object (agentNative, parallelReviews — not needed)
- No global vs project distinction in the command (just check both paths)
- No config-loading boilerplate duplicated across commands
