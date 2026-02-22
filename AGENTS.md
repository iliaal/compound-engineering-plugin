# Compound Engineering Plugin

Claude Code plugin marketplace distributing the `compound-engineering` plugin for PHP/React/Python/JavaScript/TypeScript workflows.

## Repository structure

```
compound-engineering-plugin/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace catalog
├── scripts/
│   ├── bundle-skills.sh          # Bundle skills from ai-skills repo
│   ├── update-metadata.sh        # Update component counts in plugin.json + marketplace.json
│   └── generate-skill-hooks.sh   # Generate hook patterns from SKILL.md frontmatter
└── plugins/
    └── compound-engineering/     # The plugin
        ├── .claude-plugin/
        │   └── plugin.json      # Plugin metadata
        ├── agents/              # 26 agents (review, research, design, workflow)
        ├── commands/            # 19 slash commands
        ├── skills/              # 29 skills (10 native + 19 bundled from ai-skills)
        ├── hooks/               # 1 hook (inject-skills into subagents)
        ├── README.md            # Plugin documentation
        └── CHANGELOG.md         # Version history
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
- `plugins/compound-engineering/CHANGELOG.md` → document changes

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

## Bundle workflow

19 skills are bundled from the `ai-skills` repo via `scripts/bundle-skills.sh`. 10 native skills are maintained directly in this repo. `.bundle-manifest.json` tracks native vs bundled.

```
1. Edit skills in ~/ai/ai-skills/skills/<skill-name>/SKILL.md (canonical source)
2. Run: bash scripts/bundle-skills.sh (bundles + calls update-metadata.sh)
3. Review: git diff plugins/compound-engineering/skills/
4. Update hooks/skill-patterns.sh if trigger keywords changed
5. Update CHANGELOG.md in both repos
6. Commit and push both repos
```

## Scripts

| Script | Purpose | When to run |
|--------|---------|-------------|
| `scripts/update-metadata.sh` | Count components, update `plugin.json` + `marketplace.json` descriptions | After any component change |
| `scripts/bundle-skills.sh` | Bundle skills from ai-skills repo (calls `update-metadata.sh` automatically) | After editing bundled skills |
| `scripts/generate-skill-hooks.sh` | Generate draft `hooks/skill-patterns.sh` from SKILL.md frontmatter | After adding/removing skills (hand-tune regex after) |

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
