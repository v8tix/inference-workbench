#!/usr/bin/env bash
# common.sh — Centralized path and env definitions for scripts/.
# Source this at the top of every script in this directory:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPT_DIR="$(cd "$_COMMON_DIR/.." && pwd)"
KRONK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$KRONK_DIR/.." && pwd)"
SCRIPT_LIB="$SCRIPT_DIR/lib"
COLORS_SH="$PROJECT_ROOT/lib/colors.sh"

ENV_FILE="$KRONK_DIR/.env"
MODEL_CONFIG="$KRONK_DIR/kronk.model_config.yaml"
LOGS_DIR="$KRONK_DIR/logs"
KRONK_BASE="${KRONK_BASE:-$HOME/.kronk}"

if [[ -f "$ENV_FILE" ]]; then
  set -o allexport; source "$ENV_FILE"; set +o allexport
fi
