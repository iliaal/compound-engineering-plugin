---
name: file-todos
description: >-
  File-based todo tracking in the todos/ directory. Use when creating, triaging,
  listing, or managing todo files, converting PR comments to tracked work items,
  or checking todo status and dependencies.
disable-model-invocation: true
---

# File-Based Todo Tracking Skill

## Overview

The `todos/` directory contains a file-based tracking system for managing code review feedback, technical debt, feature requests, and work items. Each todo is a markdown file with YAML frontmatter and structured sections.

Use this skill when creating new todos, managing lifecycle (pending -> ready -> complete), triaging pending items, checking dependencies, or converting PR comments into tracked work.

## File Naming Convention

```
{issue_id}-{status}-{priority}-{description}.md
```

- **issue_id**: Sequential number (001, 002, 003...) -- never reused
- **status**: `pending` (needs triage), `ready` (approved), `complete` (done)
- **priority**: `p1` (critical), `p2` (important), `p3` (nice-to-have)
- **description**: kebab-case, brief description

Examples: `001-pending-p1-mailer-test.md`, `002-ready-p1-fix-n-plus-1.md`, `005-complete-p2-refactor-csv.md`

## File Structure

Use [todo-template.md](./assets/todo-template.md) as a starting point. YAML frontmatter:

```yaml
---
status: ready              # pending | ready | complete
priority: p1               # p1 | p2 | p3
issue_id: "002"
tags: [rails, performance, database]
dependencies: ["001"]      # Issue IDs this is blocked by
---
```

**Required sections:** Problem Statement, Findings, Proposed Solutions, Recommended Action, Acceptance Criteria, Work Log

**Optional sections:** Technical Details, Resources, Notes

## Key Distinctions

**File-todos system (this skill):** Markdown files in `todos/` directory for development/project tracking. Used by humans and agents.

**Application Todo model:** Database model for user-facing task management. Different from this file-based system.

**TodoWrite tool:** In-memory task tracking during agent sessions. Temporary, not persisted to disk.

## References

- [workflows.md](./references/workflows.md) - Creating, triaging, dependencies, work logs, completing todos, integration table
- [quick-reference.md](./references/quick-reference.md) - Bash commands for finding work, dependencies, searching
- [todo-template.md](./assets/todo-template.md) - Template for new todo files
