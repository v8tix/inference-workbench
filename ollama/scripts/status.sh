#!/usr/bin/env bash
# status.sh — Show Ollama running state and loaded models.
#
# Usage:
#   bash ollama/scripts/status.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$COLORS_SH"
source "$SCRIPT_LIB/health.sh"

bold "=== Ollama Status ==="
echo ""

if is_ollama_healthy; then
  green "  Ollama running at $OLLAMA_HOST ✓"
  echo ""
  bold "  Loaded models:"
  ollama ps 2>/dev/null || yellow "  (none)"
else
  red "  Ollama not running or unreachable at $OLLAMA_HOST"
fi

echo ""
bold "  Active preset : ${OLLAMA_ACTIVE_PRESET:-(not set)}"
echo ""
bold "  Memory:"
memory_pressure 2>/dev/null || true
sysctl vm.swapusage 2>/dev/null || true
