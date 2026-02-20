# Decision Log: OpenCode Commands as .md Files

## Decision: ADR-001 - Store Commands as Individual .md Files

**Date:** 2026-02-20  
**Status:** Adopted

## Context

The original design stored commands configurations inline in `opencode.json` under `config.command`. This tightly couples command metadata with config, making it harder to version-control commands separately and share command files.

## Decision

Store commands definitions as individual `.md` files in `.opencode/commands/` directory, with YAML frontmatter for metadata and markdown body for the command prompt.

**New Type:**
```typescript
export type OpenCodeCommandFile = {
  name: string    // command name, used as filename stem: <name>.md
  content: string // full file content: YAML frontmatter + body
}
```

**Bundle Structure:**
```typescript
export type OpenCodeBundle = {
  config: OpenCodeConfig
  agents: OpenCodeAgentFile[]
  commandFiles: OpenCodeCommandFile[]  // NEW
  plugins: OpenCodePluginFile[]
  skillDirs: { sourceDir: string; name: string }[]
}
```

## Consequences

- **Positive:** Commands can be versioned, shared, and edited independently
- **Negative:** Requires updating converter, writer, and all consumers
- **Migration:** Phase 1-4 will implement the full migration

## Alternatives Considered

1. Keep inline in config - Rejected: limits flexibility
2. Use separate JSON files - Rejected: YAML frontmatter is more idiomatic for command

---

## Decision: Phase 2 - Converter Emits .md Files

**Date:** 2026-02-20  
**Status:** Implemented

## Context

The converter needs to populate `commandFiles` in the bundle rather than `config.command`.

## Decision

`convertCommands()` returns `OpenCodeCommandFile[]` where each file contains:
- **filename**: `<command-name>.md`
- **content**: YAML frontmatter (`description`, optionally `model`) + body (template text with Claude path rewriting)

### Frontmatter Structure
```yaml
---
description: "Review code changes"
model: openai/gpt-4o
---

Template text here...
```

### Filtering
- Commands with `disableModelInvocation: true` are excluded from output

### Path Rewriting
- `.claude/` paths rewritten to `.opencode/` in body content (via `rewriteClaudePaths()`)

## Consequences

- Converter now produces command files ready for file-system output
- Writer phase will handle writing to `.opencode/commands/` directory
- Phase 1 type changes are now fully utilizeds