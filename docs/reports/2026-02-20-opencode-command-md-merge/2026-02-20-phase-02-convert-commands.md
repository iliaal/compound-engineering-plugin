# Phase 2 Handoff Report: Convert Commands to .md Files

**Date:** 2026-02-20  
**Phase:** 2 of 4  
**Status:** Complete

## Summary

Implemented `convertCommands()` to emit `.md` command files with YAML frontmatter and body, rather than returning a `Record<string, OpenCodeCommandConfig>`. Updated `convertClaudeToOpenCode()` to populate `commandFiles` in the bundle instead of `config.command`.

## Changes Made

### 1. Converter Function (`src/converters/claude-to-opencode.ts`)

- **Renamed variable** (line 69): `commandFile` (was `commandMap`)
- **Removed config.command**: Config no longer includes `command` field
- **Added commandFiles to return** (line 83): `commandFiles: cmdFiles`

New `convertCommands()` function (lines 116-132):
```typescript
// Commands are written as individual .md files rather than entries in opencode.json.
// Chosen over JSON map because opencode resolves commands by filename at runtime (ADR-001).
function convertCommands(commands: ClaudeCommand[]): OpenCodeCommandFile[] {
  const files: OpenCodeCommandFile[] = []
  for (const command of commands) {
    if (command.disableModelInvocation) continue
    const frontmatter: Record<string, unknown> = {
      description: command.description,
    }
    if (command.model && command.model !== "inherit") {
      frontmatter.model = normalizeModel(command.model)
    }
    const content = formatFrontmatter(frontmatter, rewriteClaudePaths(command.body))
    files.push({ name: command.name, content })
  }
  return files
}
```

### 2. Test Updates (`tests/converter.test.ts`)

- **Renamed test** (line 11): `"from-command mode: map allowedTools to global permission block"` (was `"maps commands, permissions, and agents"`)
- **Added assertion** (line 19): `expect(bundle.config.command).toBeUndefined()`
- **Renamed test** (line 204): `"excludes commands with disable-model-invocation from commandFiles"` (was `"excludes commands with disable-model-invocation from command map"`)
- **Added new test** (lines 289-307): `"command .md files include description in frontmatter"` - validates YAML frontmatter `description` field and body content

## Test Status

All 11 converter tests pass:
```
11 pass, 0 fail in converter.test.ts
```

All 181 tests in the full suite pass:
```
181 pass, 0 fail
```

## Next Steps (Phase 3)

- Update writer to output `.md` files for commands to `.opencode/commands/` directory
- Update config merge to handle command files from multiple plugins sources
- Ensure writer tests pass with new output structure