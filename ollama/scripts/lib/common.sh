#!/usr/bin/env bash
# common.sh — path and env definitions for ollama/scripts/.
# Source at the top of every script:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPT_DIR="$(cd "$_COMMON_DIR/.." && pwd)"
OLLAMA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$OLLAMA_DIR/.." && pwd)"
SCRIPT_LIB="$SCRIPT_DIR/lib"
COLORS_SH="$PROJECT_ROOT/lib/colors.sh"

ENV_FILE="$OLLAMA_DIR/.env"
MODELFILES_DIR="$OLLAMA_DIR/modelfiles"
LOGS_DIR="$OLLAMA_DIR/logs"

if [[ -f "$ENV_FILE" ]]; then
  set -o allexport; source "$ENV_FILE"; set +o allexport
fi

OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
OLLAMA_HEALTH_URL="$OLLAMA_HOST"
