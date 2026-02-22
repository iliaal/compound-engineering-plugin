# Compound Engineering Plugin

Claude Code plugin marketplace distributing the `compound-engineering` plugin for PHP/React/Python/JavaScript/TypeScript workflows.

## Repository structure

```
compound-engineering-plugin/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace catalog
└── plugins/
    └── compound-engineering/     # The plugin
        ├── .claude-plugin/
        │   └── plugin.json      # Plugin metadata
        ├── agents/              # 26 agents (review, research, design, workflow)
        ├── commands/            # 19 slash commands
        ├── skills/              # 29 skills (10 native + 19 bundled from ai-skills)
        ├── README.md            # Plugin documentation
        └── CHANGELOG.md         # Version history
```

## Working agreement

- Do not delete or overwrite user data. Avoid destructive commands.
- Hyphens for all file naming (agents, skills, commands).
- `model: inherit` removed from agents — only declare when overriding (e.g., `model: haiku`).
- Agents reference skills (one-directional); skills stay generic and portable.

## Updating the plugin

When agents, commands, or skills are added/removed:

### 1. Count components

```bash
find plugins/compound-engineering/agents -name "*.md" | wc -l
find plugins/compound-engineering/commands -name "*.md" | wc -l
ls -d plugins/compound-engineering/skills/*/ 2>/dev/null | wc -l
```

### 2. Update counts in ALL locations

- `plugins/compound-engineering/.claude-plugin/plugin.json` → `description`
- `.claude-plugin/marketplace.json` → plugin `description`
- `plugins/compound-engineering/README.md` → components table

### 3. Bump version

- `plugins/compound-engineering/.claude-plugin/plugin.json` → `version`
- `.claude-plugin/marketplace.json` → plugin `version`

### 4. Update docs

- `plugins/compound-engineering/README.md` → component tables
- `plugins/compound-engineering/CHANGELOG.md` → document changes

### 5. Validate JSON

```bash
jq . .claude-plugin/marketplace.json
jq . plugins/compound-engineering/.claude-plugin/plugin.json
```

## Common tasks

### Adding a new agent

1. Create `plugins/compound-engineering/agents/<category>/new-agent.md`
2. Update counts and README tables
3. Test with `claude agent new-agent "test"`

### Adding a new command

1. Create `plugins/compound-engineering/commands/new-command.md`
2. Update counts and README tables
3. Test with `claude /new-command`

### Adding a new skill

1. Create `plugins/compound-engineering/skills/skill-name/SKILL.md`
2. Update counts and README tables
3. Test with `claude skill skill-name`

## Bundle workflow

19 skills are bundled from the `ai-skills` repo via `scripts/bundle-skills.sh`. 10 native skills are maintained directly in this repo. `.bundle-manifest.json` tracks native vs bundled.

```
1. Edit skills in ai-skills repo
2. Run: bash scripts/bundle-skills.sh
3. Review: git diff plugins/compound-engineering/skills/
4. Update CHANGELOG.md in both repos
5. Commit and push both repos
```

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
