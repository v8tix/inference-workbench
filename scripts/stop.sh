#!/usr/bin/env bash
# stop.sh — Stop native Kronk.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$SCRIPT_LIB/colors.sh"
source "$SCRIPT_LIB/kronk_runtime.sh"

bold "Stopping Kronk..."
echo ""

stop_kronk_server

echo ""
bold "Done"
