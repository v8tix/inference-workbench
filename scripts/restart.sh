#!/usr/bin/env bash
# restart.sh — Force a full stop/start cycle for Kronk.
#
# Usage:
#   bash scripts/restart.sh
#   bash scripts/restart.sh kronk

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$SCRIPT_LIB/colors.sh"
source "$SCRIPT_LIB/kronk_runtime.sh"

SERVICE="${1:-}"

if [[ -n "$SERVICE" && "$SERVICE" != "kronk" ]]; then
  echo "Usage: bash scripts/restart.sh [kronk]" >&2
  exit 1
fi

if [[ -n "$SERVICE" ]]; then
  bold "================================================================"
  bold " Restarting Kronk only"
  bold "================================================================"
  echo ""

  stop_kronk_server
  echo ""
  start_kronk_server true

  echo ""
  bold "================================================================"
  green " Done ✓"
  bold "================================================================"
  exit 0
fi

bold "================================================================"
bold " Force restart — Kronk"
bold "================================================================"
echo ""

bash "$SCRIPT_DIR/stop.sh"
echo ""
bash "$SCRIPT_DIR/start.sh"

echo ""
bold "================================================================"
green " All done ✓"
bold "================================================================"
