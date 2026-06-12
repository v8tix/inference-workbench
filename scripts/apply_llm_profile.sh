#!/usr/bin/env bash
# apply_llm_profile.sh — Apply a Kronk tuning preset and restart Kronk.
#
# Usage:
#   bash scripts/apply_llm_profile.sh <preset-name>
#   bash scripts/apply_llm_profile.sh gemma-fast

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESET_NAME="${1:-}"

if [[ -z "$PRESET_NAME" ]]; then
  echo "Usage: bash scripts/apply_llm_profile.sh <preset-name>" >&2
  exit 1
fi

bash "$SCRIPT_DIR/kronk_tuning_switch.sh" "$PRESET_NAME"
bash "$SCRIPT_DIR/restart.sh"
bash "$SCRIPT_DIR/sync_opencode_model.sh" "$PRESET_NAME"
