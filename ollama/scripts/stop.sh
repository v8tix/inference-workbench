#!/usr/bin/env bash
# stop.sh — Unload the active model from Ollama memory.
#
# Usage:
#   bash ollama/scripts/stop.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$COLORS_SH"
source "$SCRIPT_LIB/ollama_runtime.sh"

bold "Stopping active Ollama model..."
echo ""
stop_active_model
echo ""
bold "Done"
