#!/usr/bin/env bash
# apply_preset.sh — Build, reload, and sync a named Ollama preset.
#
# Usage:
#   bash ollama/scripts/apply_preset.sh <preset-name>
#   bash ollama/scripts/apply_preset.sh north-standard

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$COLORS_SH"
source "$SCRIPT_LIB/ollama_runtime.sh"

PRESET="${1:-}"

if [[ -z "$PRESET" ]]; then
  echo "Usage: bash ollama/scripts/apply_preset.sh <preset-name>" >&2
  exit 1
fi

stop_active_model
build_model "$PRESET" || exit 1
sync_env_preset "$PRESET"
sync_opencode_model "$PRESET"
