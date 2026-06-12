#!/usr/bin/env bash
# common.sh — Centralized path and env definitions for scripts/.
# Source this at the top of every script in this directory:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPT_DIR="$(cd "$_COMMON_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT_LIB="$SCRIPT_DIR/lib"

ENV_FILE="$PROJECT_ROOT/.env"
MODEL_CONFIG="$PROJECT_ROOT/kronk/kronk.model_config.yaml"
LOGS_DIR="$PROJECT_ROOT/logs"
KRONK_BASE="${KRONK_BASE:-$HOME/.kronk}"

if [[ -f "$ENV_FILE" ]]; then
  set -o allexport; source "$ENV_FILE"; set +o allexport
fi
