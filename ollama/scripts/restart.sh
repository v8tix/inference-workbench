#!/usr/bin/env bash
# restart.sh — Reload the active preset (stop model + rebuild + reload).
#
# Usage:
#   bash ollama/scripts/restart.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$COLORS_SH"
source "$SCRIPT_LIB/health.sh"
source "$SCRIPT_LIB/ollama_runtime.sh"

bold "================================================================"
bold " Restarting Ollama preset"
bold "================================================================"
echo ""

stop_active_model
echo ""

PRESET="${OLLAMA_ACTIVE_PRESET:-north-standard}"
bold "Reloading preset: $PRESET"
build_model "$PRESET" || exit 1

echo ""
bold "================================================================"
green " Done ✓  — preset: $PRESET"
bold "================================================================"
