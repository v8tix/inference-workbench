#!/usr/bin/env bash
# apply-runtime-config.sh — Generate and apply Ollama launchd plist from ollama.env
#
# This script reads ollama/ollama.env, generates a complete launchd plist
# via heredoc, and applies it. Safe to re-run — idempotent.
#
# Usage:
#   bash ollama/scripts/apply-runtime-config.sh
#
# After changing a value in ollama.env, re-run this script to apply it.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$COLORS_SH"

PLIST_DEST="$HOME/Library/LaunchAgents/homebrew.mxcl.ollama.plist"
RUNTIME_ENV="$OLLAMA_DIR/ollama.env"

# --- Load runtime env with defaults -------------------------------------------

OLLAMA_FLASH_ATTENTION="${OLLAMA_FLASH_ATTENTION:-1}"
OLLAMA_KV_CACHE_TYPE="${OLLAMA_KV_CACHE_TYPE:-q4_0}"
OLLAMA_NUM_PARALLEL="${OLLAMA_NUM_PARALLEL:-1}"
OLLAMA_MAX_LOADED_MODELS="${OLLAMA_MAX_LOADED_MODELS:-1}"
OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-4h}"

if [[ -f "$RUNTIME_ENV" ]]; then
  set -o allexport; source "$RUNTIME_ENV"; set +o allexport
fi

# --- Generate plist via heredoc -----------------------------------------------

generate_plist() {
  cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>EnvironmentVariables</key>
	<dict>
		<key>OLLAMA_FLASH_ATTENTION</key>
		<string>${OLLAMA_FLASH_ATTENTION}</string>
		<key>OLLAMA_KV_CACHE_TYPE</key>
		<string>${OLLAMA_KV_CACHE_TYPE}</string>
		<key>OLLAMA_HOST</key>
		<string>${OLLAMA_HOST}</string>
		<key>OLLAMA_NUM_PARALLEL</key>
		<string>${OLLAMA_NUM_PARALLEL}</string>
		<key>OLLAMA_MAX_LOADED_MODELS</key>
		<string>${OLLAMA_MAX_LOADED_MODELS}</string>
		<key>OLLAMA_KEEP_ALIVE</key>
		<string>${OLLAMA_KEEP_ALIVE}</string>
	</dict>
	<key>KeepAlive</key>
	<true/>
	<key>Label</key>
	<string>homebrew.mxcl.ollama</string>
	<key>LimitLoadToSessionType</key>
	<array>
		<string>Aqua</string>
		<string>Background</string>
		<string>LoginWindow</string>
		<string>StandardIO</string>
		<string>System</string>
	</array>
	<key>ProgramArguments</key>
	<array>
		<string>/opt/homebrew/opt/ollama/bin/ollama</string>
		<string>serve</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StandardErrorPath</key>
	<string>/opt/homebrew/var/log/ollama.log</string>
	<key>StandardOutPath</key>
	<string>/opt/homebrew/var/log/ollama.log</string>
</dict>
</plist>
PLIST
}

# --- Apply plist --------------------------------------------------------------

NEW_PLIST="$(generate_plist)"

if [[ -f "$PLIST_DEST" ]] && [[ "$(cat "$PLIST_DEST")" == "$NEW_PLIST" ]]; then
  green "  Runtime config unchanged — nothing to do"
  exit 0
fi

bold "  Generating launchd plist..."
echo "$NEW_PLIST" > "$PLIST_DEST"
green "  Written to $PLIST_DEST"

bold "  Unloading old plist..."
launchctl unload "$PLIST_DEST" 2>/dev/null || true

bold "  Loading new plist..."
launchctl load "$PLIST_DEST"
green "  Runtime config applied — Ollama will restart with new env vars ✓"

echo ""
yellow "  Active config:"
echo "    OLLAMA_FLASH_ATTENTION  = $OLLAMA_FLASH_ATTENTION"
echo "    OLLAMA_KV_CACHE_TYPE    = $OLLAMA_KV_CACHE_TYPE"
echo "    OLLAMA_HOST             = $OLLAMA_HOST"
echo "    OLLAMA_NUM_PARALLEL     = $OLLAMA_NUM_PARALLEL"
echo "    OLLAMA_MAX_LOADED_MODELS = $OLLAMA_MAX_LOADED_MODELS"
echo "    OLLAMA_KEEP_ALIVE        = $OLLAMA_KEEP_ALIVE"
echo ""
yellow "  Edit ollama/ollama.env and re-run this script to change values."
yellow "  brew services start ollama overwrites the plist — re-run after it."