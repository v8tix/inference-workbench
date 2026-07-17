#!/usr/bin/env bash
# sync-opencode-skills.sh — refresh ~/.config/opencode/skills/ from installed Claude plugins.
#
# OpenCode has no config option for extra skill directories (unlike Crush's
# skills_paths). It only auto-discovers from fixed paths, none of which point
# into ~/.claude/plugins/. So skills are copied in as real files.
#
# Sources come from ~/.claude/plugins/installed_plugins.json — the
# authoritative list of actually-installed plugins and their exact
# installPath (already version-resolved by Claude Code). This deliberately
# skips ~/.claude/plugins/marketplaces/, which holds every browsable
# marketplace catalog (including plugins never installed) and would pull in
# skills that aren't actually in use.
#
# Usage:
#   bash scripts/sync-opencode-skills.sh [--dry-run]

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/colors.sh"

DEST_DIR="$HOME/.config/opencode/skills"
MANIFEST="$HOME/.claude/plugins/installed_plugins.json"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

if [[ ! -f "$MANIFEST" ]]; then
  red "Plugin manifest not found: $MANIFEST"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  red "jq is required but not found in PATH"
  exit 1
fi

# installPath already points at the exact installed version — no version
# sorting needed, Claude Code resolved that when it installed the plugin.
SOURCES=()
while IFS= read -r install_path; do
  [[ -z "$install_path" ]] && continue
  skills_dir="$install_path/skills"
  [[ -d "$skills_dir" ]] && SOURCES+=("$skills_dir")
done < <(jq -r '.plugins[][].installPath' "$MANIFEST" 2>/dev/null)

if [[ ${#SOURCES[@]} -eq 0 ]]; then
  red "No installed plugins with a skills/ dir found in $MANIFEST"
  exit 1
fi

mkdir -p "$DEST_DIR"

updated=0

for src in "${SOURCES[@]}"; do
  for skill_path in "$src"/*/; do
    [[ -d "$skill_path" ]] || continue
    name="$(basename "$skill_path")"
    dest="$DEST_DIR/$name"

    if $DRY_RUN; then
      yellow "would replace: $name"
    else
      rm -rf "$dest"
      cp -R "$skill_path" "$dest"
      green "replaced: $name"
    fi
    updated=$((updated + 1))
  done
done

echo
bold "Done. $updated skill(s) synced from ${#SOURCES[@]} installed plugin(s)."
if $DRY_RUN; then
  yellow "(dry run — no files changed)"
fi
