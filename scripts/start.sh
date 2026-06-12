#!/usr/bin/env bash
# start.sh — Start Kronk on macOS.
#
# Usage:
#   bash scripts/start.sh
#   bash scripts/start.sh --force
#
# What this does:
#   1. Runs preflight checks
#   2. Verifies the active profile already contains the chosen model
#   3. Starts Kronk, waits for health, and warms the active model
#
# Update Kronk explicitly when needed:
#   bash scripts/update.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$SCRIPT_LIB/colors.sh"
source "$SCRIPT_LIB/health.sh"
source "$SCRIPT_LIB/preflight.sh"
source "$SCRIPT_LIB/kronk_runtime.sh"

FORCE=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    *)
      echo "Usage: bash scripts/start.sh [--force]" >&2
      exit 1
      ;;
  esac
done

bold "================================================================"
bold " Kronk — Local macOS / Metal GPU"
bold "================================================================"
echo ""

run_preflight || exit 1
echo ""

start_kronk_server "$FORCE"

KRONK_PID="$(first_kronk_pid 2>/dev/null || true)"
KRONK_LOG="$(ls -t "$LOGS_DIR"/kronk_*.log 2>/dev/null | head -1 || true)"
echo ""

bold "================================================================"
green " Kronk is running — Metal GPU active"
bold "================================================================"
echo ""
echo "  Kronk      : http://localhost:11435  (native, PID $KRONK_PID)"
echo ""
echo "  Logs:"
if [[ -n "${KRONK_LOG:-}" ]]; then
  echo "    tail -f $KRONK_LOG"
else
  echo "    Kronk log: already running before this start"
fi
echo ""
echo "  To stop: bash $SCRIPT_DIR/stop.sh"
