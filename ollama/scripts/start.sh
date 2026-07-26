#!/usr/bin/env bash
# start.sh — Ensure Ollama is running and the active preset model is loaded.
#
# Usage:
#   bash ollama/scripts/start.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$COLORS_SH"
source "$SCRIPT_LIB/health.sh"
source "$SCRIPT_LIB/preflight.sh"
source "$SCRIPT_LIB/ollama_runtime.sh"

bold "================================================================"
bold " Ollama — Local macOS / Metal GPU"
bold "================================================================"
echo ""

run_preflight || exit 1
echo ""

bold "Checking runtime config..."
bash "$SCRIPT_DIR/apply-runtime-config.sh" || true
echo ""

bold "Checking Ollama..."
if ! is_ollama_healthy; then
  red "ERROR: Ollama is not running or unreachable at $OLLAMA_HOST"
  yellow "  Start it via the Ollama app or: ollama serve"
  exit 1
fi
green "  Ollama is running ✓"
echo ""

PRESET="${OLLAMA_ACTIVE_PRESET:-north-standard}"
bold "Loading preset: $PRESET"
build_model "$PRESET" || exit 1
echo ""

bold "================================================================"
green " Ollama ready — preset: $PRESET"
bold "================================================================"
echo ""
echo "  API : $OLLAMA_HOST"
echo ""
echo "  To switch preset : bash $SCRIPT_DIR/use_preset.sh"
echo "  To stop model    : bash $SCRIPT_DIR/stop.sh"
