#!/usr/bin/env bash

# update.sh — Check for and optionally install Kronk updates.
#
# Usage:
#   bash scripts/update.sh
#   bash scripts/update.sh --yes
#   bash scripts/update.sh --check-only

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$SCRIPT_LIB/colors.sh"
source "$SCRIPT_LIB/kronk_mgr.sh"

AUTO_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --yes)
      export KRONK_AUTO_UPDATE=true
      ;;
    --check-only)
      current="$(get_installed_kronk_version || true)"
      latest="$(get_latest_kronk_version)"
      [[ -n "$current" && "$current" == "$latest" ]]
      exit $?
      ;;
    *)
      AUTO_ARGS+=("$arg")
      ;;
  esac
done

check_kronk_updates "${AUTO_ARGS[@]+"${AUTO_ARGS[@]}"}"
