# Compound Engineering Plugin

Claude Code plugin marketplace distributing the `compound-engineering` plugin for PHP/React/Python/JavaScript/TypeScript workflows.

## Repository Structure

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

## Updating the Plugin

When agents, commands, or skills are added/removed:

### 1. Count components

```bash
find plugins/compound-engineering/agents -name "*.md" | wc -l
find plugins/compound-engineering/commands -name "*.md" | wc -l
ls -d plugins/compound-engineering/skills/*/ 2>/dev/null | wc -l
```

### 2. Update counts in ALL locations

- [ ] `plugins/compound-engineering/.claude-plugin/plugin.json` → `description`
- [ ] `.claude-plugin/marketplace.json` → plugin `description`
- [ ] `plugins/compound-engineering/README.md` → components table

### 3. Bump version

- [ ] `plugins/compound-engineering/.claude-plugin/plugin.json` → `version`
- [ ] `.claude-plugin/marketplace.json` → plugin `version`

### 4. Update docs

- [ ] `plugins/compound-engineering/README.md` → component tables
- [ ] `plugins/compound-engineering/CHANGELOG.md` → document changes

### 5. Validate JSON

```bash
cat .claude-plugin/marketplace.json | jq .
cat plugins/compound-engineering/.claude-plugin/plugin.json | jq .
```

## Common Tasks

### Adding a New Agent

1. Create `plugins/compound-engineering/agents/<category>/new-agent.md`
2. Update counts and README tables
3. Test with `claude agent new-agent "test"`

### Adding a New Command

1. Create `plugins/compound-engineering/commands/new-command.md`
2. Update counts and README tables
3. Test with `claude /new-command`

### Adding a New Skill

1. Create `plugins/compound-engineering/skills/skill-name/SKILL.md`
2. Update counts and README tables
3. Test with `claude skill skill-name`

## Marketplace.json Spec

Only include fields from the official Claude Code spec:

- Required: `name`, `owner`, `plugins`
- Optional: `metadata` (with description and version)
- Plugin entries: `name`, `description`, `version`, `author`, `homepage`, `tags`, `source`

Do not add custom fields (`downloads`, `stars`, `rating`, `categories`, etc.).

## Resources

- [Claude Code Plugin Documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- [Plugin Marketplace Documentation](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces)
- [Plugin Reference](https://docs.claude.com/en/docs/claude-code/plugins-reference)
