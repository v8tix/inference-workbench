#!/usr/bin/env bash
# apply-runtime-config.sh — Apply ollama/ollama.env via Homebrew's services env override.
#
# This Homebrew install uses the JSON API tap (no local homebrew/core clone), which means
# `brew services restart` regenerates the launchd job fresh from Homebrew's API cache on
# every run — it does NOT read the Cellar plist, the LaunchAgents plist, or the formula's
# per-keg .rb copy. Editing any of those is a dead end (confirmed by testing).
#
# The one mechanism that actually persists across `brew services restart` AND `brew upgrade`
# is $HOMEBREW_USER_CONFIG_HOME/services/ollama.env (defaults to ~/.homebrew/services/ollama.env),
# documented in `brew services --help`. This script writes ollama/ollama.env into that file
# and restarts the service.
#
# Usage:
#   bash ollama/scripts/apply-runtime-config.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$COLORS_SH"

RUNTIME_ENV="$OLLAMA_DIR/ollama.env"
SERVICES_ENV_DIR="${HOMEBREW_USER_CONFIG_HOME:-$HOME/.homebrew}/services"
SERVICES_ENV_FILE="$SERVICES_ENV_DIR/ollama.env"

if [[ ! -f "$RUNTIME_ENV" ]]; then
  red "ERROR: $RUNTIME_ENV not found"
  exit 1
fi

mkdir -p "$SERVICES_ENV_DIR"

# Strip comments/blank lines, keep only KEY=value
NEW_CONTENT="$(grep -v '^\s*#' "$RUNTIME_ENV" | grep -v '^\s*$')"

if [[ -f "$SERVICES_ENV_FILE" ]] && [[ "$(cat "$SERVICES_ENV_FILE")" == "$NEW_CONTENT" ]]; then
  green "  Runtime config unchanged — nothing to do"
  exit 0
fi

bold "  Writing $SERVICES_ENV_FILE..."
printf '%s\n' "$NEW_CONTENT" > "$SERVICES_ENV_FILE"
green "  Written ✓"

bold "  Restarting Ollama to apply..."
brew services restart ollama
green "  Runtime config applied ✓"

echo ""
yellow "  Active config:"
sed 's/^/    /' "$SERVICES_ENV_FILE"
echo ""
yellow "  Verify with:"
echo '    launchctl print gui/$(id -u)/homebrew.mxcl.ollama | grep -A12 "environment = {"'
