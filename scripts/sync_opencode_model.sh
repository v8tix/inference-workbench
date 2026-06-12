#!/usr/bin/env bash
#
# sync_opencode_model.sh — Sync OpenCode's default model to a preset alias.
#
# Usage:
#   bash scripts/sync_opencode_model.sh <preset-name>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRESET_NAME="${1:-}"
PRESET_FILE="$PROJECT_ROOT/kronk/presets/${PRESET_NAME}.yaml"
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.jsonc"

if [[ -z "$PRESET_NAME" ]]; then
  echo "Usage: bash scripts/sync_opencode_model.sh <preset-name>" >&2
  exit 1
fi

if [[ ! -f "$PRESET_FILE" ]]; then
  echo "Unknown tuning preset: $PRESET_NAME" >&2
  exit 1
fi

if [[ ! -f "$OPENCODE_CONFIG" ]]; then
  echo "OpenCode config not found: $OPENCODE_CONFIG" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to update $OPENCODE_CONFIG" >&2
  exit 1
fi

if ! jq -e --arg key "$PRESET_NAME" '.provider.kronk.models[$key]' "$OPENCODE_CONFIG" >/dev/null; then
  echo "OpenCode config is missing kronk preset alias: $PRESET_NAME" >&2
  exit 1
fi

TMP_FILE="$(mktemp)"
jq --arg model "kronk/$PRESET_NAME" '.model = $model' "$OPENCODE_CONFIG" > "$TMP_FILE"
mv "$TMP_FILE" "$OPENCODE_CONFIG"

echo "Synced OpenCode default model: kronk/$PRESET_NAME"
