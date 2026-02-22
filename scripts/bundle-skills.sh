#!/usr/bin/env bash
set -Eeuo pipefail

# Bundle skills from ai-skills repo into compound-engineering plugin
# Usage: bash scripts/bundle-skills.sh [--dry-run]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/compound-engineering"
SKILLS_DIR="$PLUGIN_DIR/skills"
MANIFEST="$SKILLS_DIR/.bundle-manifest.json"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

# Resolve source path from manifest
SOURCE_DIR="$(jq -r '.source' "$MANIFEST")"
SOURCE_DIR="${SOURCE_DIR/#\~/$HOME}"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Read native skills list
mapfile -t NATIVE_SKILLS < <(jq -r '.native[]' "$MANIFEST")

is_native() {
    local name="$1"
    for native in "${NATIVE_SKILLS[@]}"; do
        [[ "$native" == "$name" ]] && return 0
    done
    return 1
}

# --- Bundle skills ---

added=0
updated=0
removed=0
skipped=0
bundled_skills=()

printf "Source: %s\n" "$SOURCE_DIR"
printf "Target: %s\n\n" "$SKILLS_DIR"

if [[ ! -d "$SOURCE_DIR" ]]; then
    printf "ERROR: Source directory does not exist: %s\n" "$SOURCE_DIR" >&2
    exit 1
fi

# Copy skills from source
for skill_dir in "$SOURCE_DIR"/*/; do
    skill_name="$(basename "$skill_dir")"

    # Skip native skills
    if is_native "$skill_name"; then
        skipped=$((skipped + 1))
        continue
    fi

    # Check SKILL.md exists
    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
        continue
    fi

    target_dir="$SKILLS_DIR/$skill_name"
    bundled_skills+=("$skill_name")

    if [[ -d "$target_dir" ]]; then
        # Check if content changed
        if diff -rq "$skill_dir" "$target_dir" >/dev/null 2>&1; then
            continue
        fi
        action="updated"
        updated=$((updated + 1))
    else
        action="added"
        added=$((added + 1))
    fi

    printf "  %-10s %s\n" "$action" "$skill_name"

    if [[ "$DRY_RUN" == false ]]; then
        rm -rf "$target_dir"
        cp -r "$skill_dir" "$target_dir"
    fi
done

# Remove stale bundled skills (exist in target but not in source and not native)
for skill_dir in "$SKILLS_DIR"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"

    is_native "$skill_name" && continue

    # Check if it exists in source
    if [[ ! -d "$SOURCE_DIR/$skill_name" ]]; then
        printf "  %-10s %s\n" "removed" "$skill_name"
        removed=$((removed + 1))
        if [[ "$DRY_RUN" == false ]]; then
            rm -rf "$skill_dir"
        fi
    fi
done

# --- Update manifest timestamp ---

if [[ "$DRY_RUN" == false ]]; then
    tmp=$(mktemp)
    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.bundled_at = $ts' "$MANIFEST" > "$tmp"
    mv "$tmp" "$MANIFEST"
fi

# --- Count components ---

agent_count=$(find "$PLUGIN_DIR/agents" -name "*.md" -type f | wc -l)
command_count=$(find "$PLUGIN_DIR/commands" -name "*.md" -type f | wc -l)
skill_count=$(find "$SKILLS_DIR" -name "SKILL.md" -type f | wc -l)
hook_count=0
if [[ -f "$PLUGIN_DIR/hooks/hooks.json" ]]; then
    hook_count=$(jq '[.[] | .[].hooks | length] | add // 0' "$PLUGIN_DIR/hooks/hooks.json")
fi
mcp_count=$(jq '.mcpServers | length' "$PLUGIN_JSON")

# Build hook fragment for descriptions
hook_fragment=""
[[ "$hook_count" -gt 0 ]] && hook_fragment="${hook_count} hook, "

# --- Update metadata ---

if [[ "$DRY_RUN" == false ]]; then
    # Update plugin.json description
    desc="AI-powered development tools. ${agent_count} agents, ${command_count} commands, ${skill_count} skills, ${hook_fragment}${mcp_count} MCP server for code review, research, design, and workflow automation."
    tmp=$(mktemp)
    jq --arg d "$desc" '.description = $d' "$PLUGIN_JSON" > "$tmp"
    mv "$tmp" "$PLUGIN_JSON"

    # Update marketplace.json plugin description
    mkt_desc="AI-powered development tools that get smarter with every use. Make each unit of engineering work easier than the last. Includes ${agent_count} specialized agents, ${command_count} commands, ${skill_count} skills, and ${hook_fragment}${mcp_count} MCP server."
    tmp=$(mktemp)
    jq --arg d "$mkt_desc" '.plugins[0].description = $d' "$MARKETPLACE_JSON" > "$tmp"
    mv "$tmp" "$MARKETPLACE_JSON"

    # Validate JSON
    jq . "$PLUGIN_JSON" > /dev/null
    jq . "$MARKETPLACE_JSON" > /dev/null
fi

# --- Summary ---

printf "\n--- Summary ---\n"
printf "  Added:   %d\n" "$added"
printf "  Updated: %d\n" "$updated"
printf "  Removed: %d\n" "$removed"
printf "  Skipped: %d (native)\n" "$skipped"
printf "\n  Agents:   %d\n" "$agent_count"
printf "  Commands: %d\n" "$command_count"
printf "  Skills:   %d\n" "$skill_count"
printf "  MCP:      %d\n" "$mcp_count"

if [[ "$DRY_RUN" == true ]]; then
    printf "\n  (dry run — no changes made)\n"
fi
