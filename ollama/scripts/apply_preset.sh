#!/usr/bin/env bash
# apply_preset.sh — Build, reload, and sync a named Ollama preset.
#
# Usage:
#   bash ollama/scripts/apply_preset.sh <preset-name> [--rebuild]
#   bash ollama/scripts/apply_preset.sh qwen36-standard
#   bash ollama/scripts/apply_preset.sh qwen36-standard --rebuild   # force rebuild even if it already exists

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$COLORS_SH"
source "$SCRIPT_LIB/ollama_runtime.sh"

PRESET=""
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --rebuild|--force) FORCE=1 ;;
    *) PRESET="$arg" ;;
  esac
done

if [[ -z "$PRESET" ]]; then
  echo "Usage: bash ollama/scripts/apply_preset.sh <preset-name> [--rebuild]" >&2
  exit 1
fi

stop_active_model
build_model "$PRESET" "$FORCE" || exit 1
sync_env_preset "$PRESET"
sync_opencode_model "$PRESET"
