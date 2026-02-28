#!/usr/bin/env bash
set -Eeuo pipefail

# Update the locally installed Claude Code plugin to match the latest pushed version.
#
# Root cause this solves: Claude Code clones the marketplace repo once and never
# git-pulls it. So the local marketplace.json stays stale, Claude Code thinks
# the installed version is already the latest, and new versions sit orphaned in cache.
#
# What this script does:
#   1. Pulls the marketplace clone to get the latest marketplace.json + plugin source
#   2. Reads the new version from the updated marketplace.json
#   3. Copies plugin files from the marketplace clone into the versioned cache dir
#   4. Removes any .orphaned_at marker on the new version
#   5. Updates installed_plugins.json to point to the new version
#   6. Marks old cached versions as orphaned
#
# Usage: bash scripts/update-plugin.sh
#
# Safe to run repeatedly — idempotent.

MARKETPLACE_NAME="iliaal-marketplace"
PLUGIN_NAME="compound-engineering"
PLUGIN_KEY="${PLUGIN_NAME}@${MARKETPLACE_NAME}"

PLUGINS_DIR="$HOME/.claude/plugins"
MARKETPLACE_DIR="$PLUGINS_DIR/marketplaces/$MARKETPLACE_NAME"
CACHE_DIR="$PLUGINS_DIR/cache/$MARKETPLACE_NAME/$PLUGIN_NAME"
INSTALLED_JSON="$PLUGINS_DIR/installed_plugins.json"

# --- Preflight checks ---
if [[ ! -d "$MARKETPLACE_DIR/.git" ]]; then
    echo "ERROR: Marketplace clone not found at $MARKETPLACE_DIR"
    echo "Install the plugin first via /plugin in Claude Code."
    exit 1
fi

if [[ ! -f "$INSTALLED_JSON" ]]; then
    echo "ERROR: $INSTALLED_JSON not found. Plugin not installed."
    exit 1
fi

# --- Step 1: Pull the marketplace clone ---
echo "Pulling marketplace clone..."
cd "$MARKETPLACE_DIR"
git fetch origin main --quiet 2>/dev/null
git reset --hard origin/main --quiet 2>/dev/null
echo "  Marketplace clone updated to $(git rev-parse --short HEAD)"

# Read versions
NEW_VERSION=$(python3 -c "
import json, sys
with open('.claude-plugin/marketplace.json') as f:
    data = json.load(f)
for p in data['plugins']:
    if p['name'] == '$PLUGIN_NAME':
        print(p['version'])
        sys.exit(0)
print('NOT_FOUND', file=sys.stderr)
sys.exit(1)
")
GIT_SHA=$(git rev-parse --short HEAD)
FULL_SHA=$(git rev-parse HEAD)

CURRENT_VERSION=$(python3 -c "
import json
with open('$INSTALLED_JSON') as f:
    data = json.load(f)
entries = data.get('plugins', {}).get('$PLUGIN_KEY', [])
for e in entries:
    if e.get('scope') == 'user':
        print(e.get('version', 'unknown'))
        break
else:
    print('unknown')
")

echo "  Installed: v$CURRENT_VERSION"
echo "  Available: v$NEW_VERSION"

if [[ "$NEW_VERSION" == "$CURRENT_VERSION" ]]; then
    echo ""
    echo "Already up to date (v$CURRENT_VERSION)."
    exit 0
fi

# --- Step 2: Copy plugin files to versioned cache ---
PLUGIN_SOURCE="$MARKETPLACE_DIR/plugins/$PLUGIN_NAME"
NEW_CACHE="$CACHE_DIR/$NEW_VERSION"

if [[ ! -d "$PLUGIN_SOURCE" ]]; then
    echo "ERROR: Plugin source not found at $PLUGIN_SOURCE"
    exit 1
fi

echo ""
echo "Installing v$NEW_VERSION..."

# Remove stale cache if exists (could be orphaned from a previous attempt)
if [[ -d "$NEW_CACHE" ]]; then
    rm -rf "$NEW_CACHE"
fi

# Copy plugin files
cp -r "$PLUGIN_SOURCE" "$NEW_CACHE"

# Remove orphaned marker if somehow still present
rm -f "$NEW_CACHE/.orphaned_at"

echo "  Cached at $NEW_CACHE"

# --- Step 3: Update installed_plugins.json ---
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

python3 -c "
import json

with open('$INSTALLED_JSON') as f:
    data = json.load(f)

entries = data.get('plugins', {}).get('$PLUGIN_KEY', [])
updated = False
for e in entries:
    if e.get('scope') == 'user':
        e['installPath'] = '$NEW_CACHE'
        e['version'] = '$NEW_VERSION'
        e['lastUpdated'] = '$NOW_ISO'
        e['gitCommitSha'] = '$GIT_SHA'
        updated = True
        break

if not updated:
    print('WARNING: No user-scope entry found in installed_plugins.json')

with open('$INSTALLED_JSON', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"

echo "  Updated installed_plugins.json"

# --- Step 4: Orphan old cached versions ---
ORPHAN_TS=$(date +%s%3N)
for dir in "$CACHE_DIR"/*/; do
    ver=$(basename "$dir")
    if [[ "$ver" != "$NEW_VERSION" && ! -f "$dir/.orphaned_at" ]]; then
        echo "$ORPHAN_TS" > "$dir/.orphaned_at"
        echo "  Orphaned old version: v$ver"
    fi
done

# --- Step 5: Update known_marketplaces.json lastUpdated ---
KNOWN_JSON="$PLUGINS_DIR/known_marketplaces.json"
if [[ -f "$KNOWN_JSON" ]]; then
    python3 -c "
import json

with open('$KNOWN_JSON') as f:
    data = json.load(f)

if '$MARKETPLACE_NAME' in data:
    data['$MARKETPLACE_NAME']['lastUpdated'] = '$NOW_ISO'

with open('$KNOWN_JSON', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
    echo "  Updated known_marketplaces.json timestamp"
fi

echo ""
echo "Done. v$CURRENT_VERSION → v$NEW_VERSION"
echo "Restart Claude Code to pick up the new version."
