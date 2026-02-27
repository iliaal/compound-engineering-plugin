# Compound Engineering Plugin

Claude Code plugin with 26 agents, 19 commands, 31 skills, 1 hook, and 1 MCP server for PHP/React/Python/JavaScript/TypeScript workflows. Includes a skill distillery for generating new skills from top-rated sources.

## Install

### Claude Code

```bash
/plugin marketplace add https://github.com/iliaal/compound-engineering-plugin
/plugin install compound-engineering
```

### OpenCode & Codex

The repo includes a Bun/TypeScript CLI that converts Claude Code plugins to OpenCode and Codex formats:

```bash
# Install to OpenCode
bun run src/index.ts install ./plugins/compound-engineering --to opencode

# Install to Codex
bun run src/index.ts install ./plugins/compound-engineering --to codex

# Sync personal Claude Code config (~/.claude/) to other tools
bun run src/index.ts sync --target opencode
```

## Repository Structure

```
compound-engineering-plugin/
├── plugins/compound-engineering/   # The plugin
│   ├── agents/                     # 26 specialized subagents
│   ├── commands/                   # 19 slash commands
│   ├── skills/                     # 31 skills
│   ├── hooks/                      # Skill injection into subagents
│   └── README.md                   # Full component reference
├── distillery/                     # Skill generation from skills.sh
│   ├── scripts/                    # distiller.py + tests (102 passing)
│   └── generated-skills/           # Generated skill output
├── scripts/                        # Repo maintenance scripts
│   ├── update-metadata.sh          # Update component counts
│   ├── generate-skill-hooks.sh     # Generate trigger patterns from frontmatter
│   └── sync-to-tools.sh            # Symlink skills to .agents, .codex, .kilocode
└── src/                            # Bun/TS CLI for OpenCode/Codex conversion
```

## Core Workflow

```
Plan → Work → Review → Compound → Repeat
```

| Command | Purpose |
|---------|---------|
| `/workflows:plan` | Turn feature ideas into detailed implementation plans |
| `/workflows:work` | Execute plans with worktrees and task tracking |
| `/workflows:review` | Multi-agent code review before merging |
| `/workflows:compound` | Document learnings to make future work easier |

## Skill Distillery

The `distillery/` directory generates skills by fetching top-rated skills from [skills.sh](https://skills.sh), analyzing them, and synthesizing one token-efficient skill combining the best elements.

```bash
python3 distillery/scripts/distiller.py search "react"
python3 distillery/scripts/distiller.py fetch --skills '<json>'
python3 distillery/scripts/distiller.py validate <name>
python3 distillery/scripts/distiller.py ab-eval <name> --prompts '<json>'
python3 distillery/scripts/distiller.py eval-triggers <name> --queries '<json>'
```

Generated skills land in `distillery/generated-skills/`, then get promoted to `plugins/compound-engineering/skills/`.

Skills are also available standalone via the [ai-skills](https://github.com/iliaal/ai-skills) repo:

```bash
npx skills add iliaal/ai-skills -s code-review
```

## Full Component Reference

See [plugins/compound-engineering/README.md](plugins/compound-engineering/README.md) for the complete catalog of agents, commands, skills, hooks, and MCP servers.

## License

MIT
