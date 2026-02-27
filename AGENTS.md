# Compound Engineering Plugin

Claude Code plugin marketplace distributing the `compound-engineering` plugin for PHP/React/Python/JavaScript/TypeScript workflows.

## Repository structure

```
compound-engineering-plugin/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace catalog
├── distillery/                   # Skill distillery (generate skills from skills.sh)
│   ├── scripts/
│   │   ├── distiller.py          # Search, fetch, validate, test, A/B eval
│   │   └── test_distiller.py     # pytest tests for distiller
│   └── generated-skills/         # Generated skill output directory
├── scripts/
│   ├── update-metadata.sh        # Update component counts in plugin.json + marketplace.json
│   ├── generate-skill-hooks.sh   # Generate hook patterns from SKILL.md frontmatter
│   ├── mirror-to-ai-skills.sh    # Mirror plugin skills to ai-skills public repo
│   └── sync-to-tools.sh          # Symlink skills to .agents, .codex, .kilocode
└── plugins/
    └── compound-engineering/     # The plugin
        ├── .claude-plugin/
        │   └── plugin.json      # Plugin metadata
        ├── agents/              # 26 agents (review, research, design, workflow)
        ├── commands/            # 19 slash commands
        ├── skills/              # 31 skills (all native)
        ├── hooks/               # 1 hook (inject-skills into subagents)
        └── README.md            # Plugin documentation
```

## Working agreement

- Do not delete or overwrite user data. Avoid destructive commands.
- Hyphens for all file naming (agents, skills, commands).
- `model: inherit` removed from agents — only declare when overriding (e.g., `model: haiku`).
- Agents reference skills (one-directional); skills stay generic and portable.

## Updating the plugin

When agents, commands, skills, or hooks are added/removed:

### 1. Update counts and descriptions

```bash
bash scripts/update-metadata.sh
```

This automatically counts all components (agents, commands, skills, hooks, MCP servers) and updates descriptions in both `plugin.json` and `marketplace.json`. Run this after any component change.

### 2. Bump version

- `plugins/compound-engineering/.claude-plugin/plugin.json` → `version`
- `.claude-plugin/marketplace.json` → plugin `version`

### 3. Update docs

- `plugins/compound-engineering/README.md` → component tables
- `CHANGELOG.md` → document changes

### 4. Validate JSON

```bash
jq . .claude-plugin/marketplace.json
jq . plugins/compound-engineering/.claude-plugin/plugin.json
```

## Common tasks

### Adding a new agent

1. Create `plugins/compound-engineering/agents/<category>/new-agent.md`
2. Run `bash scripts/update-metadata.sh`
3. Update README tables
4. Test with `claude agent new-agent "test"`

### Adding a new command

1. Create `plugins/compound-engineering/commands/new-command.md`
2. Run `bash scripts/update-metadata.sh`
3. Update README tables
4. Test with `claude /new-command`

### Adding a new skill

1. Create `plugins/compound-engineering/skills/skill-name/SKILL.md`
2. Run `bash scripts/update-metadata.sh`
3. Update README tables and `hooks/skill-patterns.sh` (add trigger pattern)
4. Test with `claude skill skill-name`

### Adding a new hook

1. Add hook entry to `plugins/compound-engineering/hooks/hooks.json`
2. Create hook script in `plugins/compound-engineering/hooks/`
3. Run `bash scripts/update-metadata.sh`
4. Update README tables

## Skill distillery

The `distillery/` directory generates skills from top-rated skills on skills.sh. Use the `skill-distiller` project-level skill (`.claude/skills/skill-distiller/SKILL.md`) for the full workflow.

```
# Generate a new skill
python3 distillery/scripts/distiller.py search "react"
python3 distillery/scripts/distiller.py fetch --skills '<json>'
# ... analyze, synthesize, validate → distillery/generated-skills/<name>/

# Promote to plugin
cp -r distillery/generated-skills/<name> plugins/compound-engineering/skills/<name>
bash scripts/update-metadata.sh

# Mirror to ai-skills (read-only public distribution)
bash scripts/mirror-to-ai-skills.sh
```

## Scripts

| Script | Purpose | When to run |
|--------|---------|-------------|
| `scripts/update-metadata.sh` | Count components, update `plugin.json` + `marketplace.json` descriptions | After any component change |
| `scripts/mirror-to-ai-skills.sh` | Mirror plugin skills to `~/ai/ai-skills` (read-only distribution) | After editing or adding skills |
| `scripts/generate-skill-hooks.sh` | Generate draft `hooks/skill-patterns.sh` from SKILL.md frontmatter | After adding/removing skills (hand-tune regex after) |
| `scripts/sync-to-tools.sh` | Symlink plugin skills to `~/.agents/skills`, `~/.codex/skills`, `~/.kilocode/skills` | After editing or adding skills |

## Marketplace.json spec

Only include fields from the official Claude Code spec:

- Required: `name`, `owner`, `plugins`
- Optional: `metadata` (with description and version)
- Plugin entries: `name`, `description`, `version`, `author`, `homepage`, `tags`, `source`

Do not add custom fields (`downloads`, `stars`, `rating`, `categories`, etc.).

## Resources

- [Claude Code Plugin Documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- [Plugin Marketplace Documentation](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces)
- [Plugin Reference](https://docs.claude.com/en/docs/claude-code/plugins-reference)
