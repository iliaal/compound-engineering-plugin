# Compound Engineering Plugin

AI-powered development tools for PHP/React/Python/JavaScript/TypeScript workflows. 22 agents, 19 commands, 10 skills, 1 MCP server.

## Claude Code Install

```bash
/plugin marketplace add https://github.com/iliaal/compound-engineering-plugin
/plugin install compound-engineering
```

## OpenCode & Codex Install

This repo includes a Bun/TypeScript CLI that converts Claude Code plugins to OpenCode and Codex formats.

```bash
# Convert to OpenCode format
bunx @every-env/compound-plugin install compound-engineering --to opencode

# Convert to Codex format
bunx @every-env/compound-plugin install compound-engineering --to codex
```

Local dev:

```bash
bun run src/index.ts install ./plugins/compound-engineering --to opencode
```

## Sync Personal Config

Sync your personal Claude Code config (`~/.claude/`) to other AI coding tools:

```bash
# Sync skills and MCP servers to OpenCode
bunx @every-env/compound-plugin sync --target opencode

# Sync to Codex
bunx @every-env/compound-plugin sync --target codex
```

Skills are symlinked (not copied) so changes in Claude Code are reflected immediately.

## Workflow

```
Plan -> Work -> Review -> Compound -> Repeat
```

| Command | Purpose |
|---------|---------|
| `/workflows:plan` | Turn feature ideas into detailed implementation plans |
| `/workflows:work` | Execute plans with worktrees and task tracking |
| `/workflows:review` | Multi-agent code review before merging |
| `/workflows:compound` | Document learnings to make future work easier |

## Learn More

- [Full component reference](plugins/compound-engineering/README.md) - all agents, commands, skills
