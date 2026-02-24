---
name: git-worktree
description: >-
  Manage Git worktrees for isolated parallel development. Create, list, switch,
  and clean up worktrees.
---

# Git Worktree Manager

Unified interface for managing Git worktrees across your development workflow -- isolated PR reviews, parallel feature work, and cleanup.

## What This Skill Does

- **Create worktrees** from main branch with clear branch names
- **List worktrees** with current status
- **Switch between worktrees** for parallel work
- **Clean up completed worktrees** automatically
- **Automatic .env file copying** from main repo to new worktrees
- **Automatic .gitignore management** for worktree directory

## CRITICAL: Always Use the Manager Script

**NEVER call `git worktree add` directly.** Always use the `worktree-manager.sh` script.

The script handles critical setup that raw git commands don't:
1. Copies `.env`, `.env.local`, `.env.test`, etc. from main repo
2. Ensures `.worktrees` is in `.gitignore`
3. Creates consistent directory structure

```bash
# CORRECT - Always use the script
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create feature-name

# WRONG - Never do this directly
git worktree add .worktrees/feature-name -b feature-name main
```

## Commands

| Command | Description | Example |
|---------|-------------|---------|
| `create <branch> [from]` | Create worktree + branch (default: from main) | `...worktree-manager.sh create feature-login` |
| `list` / `ls` | List all worktrees with status | `...worktree-manager.sh list` |
| `switch <name>` / `go` | Switch to existing worktree | `...worktree-manager.sh switch feature-login` |
| `copy-env <name>` | Copy .env files to existing worktree | `...worktree-manager.sh copy-env feature-login` |
| `cleanup` / `clean` | Interactively remove inactive worktrees | `...worktree-manager.sh cleanup` |

All commands use: `bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh <command>`

## Integration with Workflows

### `/workflows:review`

1. Check current branch
2. If ALREADY on target branch -> stay there, no worktree needed
3. If DIFFERENT branch -> offer worktree: "Use worktree for isolated review? (y/n)"

### `/workflows:work`

Always offer choice:
1. New branch on current worktree (live work)
2. Worktree (parallel work)

## References

- [workflow-examples.md](./references/workflow-examples.md) - Code review and parallel development workflows
- [troubleshooting.md](./references/troubleshooting.md) - Common issues, directory structure, how it works
- [worktree-manager.sh](./scripts/worktree-manager.sh) - The manager script
