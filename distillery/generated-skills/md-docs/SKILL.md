---
name: md-docs
description: >-
  Manages project documentation: AGENTS.md, README.md, and CONTRIBUTING.md.
  Use when asked to "update README", "update agents", "init agents",
  "create AGENTS.md", "update AGENTS.md", "update CONTRIBUTING",
  "update context files", or "init context". Not for general markdown editing.
---

# Markdown Documentation

Manage project documentation by verifying against actual codebase state. Emphasize verification over blind generation — analyze structure, files, and patterns before writing.

## Portability

AGENTS.md is the universal context file (works with Claude Code, Codex, Kilocode). If the project uses CLAUDE.md, treat it as a symlink to AGENTS.md or migrate content into AGENTS.md and create the symlink:

```bash
# If CLAUDE.md exists and AGENTS.md doesn't
mv CLAUDE.md AGENTS.md && ln -sf AGENTS.md CLAUDE.md
```

When this skill references "context files", it means AGENTS.md (and CLAUDE.md if present as symlink).

## Workflows

### Update Context Files

Verify and fix AGENTS.md against the actual codebase. See `references/update-agents.md` for the full verification workflow.

1. Read existing AGENTS.md, extract verifiable claims (paths, commands, structure, tooling)
2. Verify each claim against codebase (`ls`, `cat package.json`, `cat pyproject.toml`, etc.)
3. Fix discrepancies: outdated paths, wrong commands, missing sections, stale structure
4. Discover undocumented patterns (scripts, build tools, test frameworks not yet documented)
5. Report changes

### Update README

Generate or refresh README.md from project metadata and structure. See `references/update-readme.md` for section templates and language-specific patterns.

1. Detect language/stack from config files (package.json, pyproject.toml, composer.json)
2. Extract metadata: name, version, description, license, scripts
3. If README exists and `--preserve`: keep custom sections (About, Features), regenerate standard sections (Install, Usage)
4. Generate sections appropriate to project type (library vs application)
5. Report changes

### Update CONTRIBUTING

Update existing CONTRIBUTING.md only — never auto-create. See `references/update-contributing.md`.

### Initialize Context

Create AGENTS.md from scratch for projects without documentation. See `references/init-agents.md`.

1. Analyze project: language, framework, structure, build/test tools
2. Generate terse, expert-to-expert context sections
3. Write AGENTS.md, create CLAUDE.md symlink

## Arguments

All workflows support:

- `--dry-run`: preview changes without writing
- `--preserve`: keep existing structure, fix inaccuracies only
- `--minimal`: quick pass, high-level structure only
- `--thorough`: deep analysis of all files

## Backup Handling

Before overwriting, back up existing files:

```bash
cp AGENTS.md AGENTS.md.backup
cp README.md README.md.backup
```

Never delete backups automatically.

## Writing Style

- Terse: omit needless words, lead with the answer
- Imperative: "Build the project" not "The project is built"
- Expert-to-expert: skip basic explanations, assume competence
- Scannable: headings, lists, code blocks
- Accurate: verify every command and path against codebase
- Sentence case headings, no emoji headers

## Report Format

After every operation, display a summary:

```
✓ Updated AGENTS.md
  - Fixed build command
  - Added new directory to structure

✓ Updated README.md
  - Added installation section
  - Updated badges

⊘ CONTRIBUTING.md not found (skipped)
```
