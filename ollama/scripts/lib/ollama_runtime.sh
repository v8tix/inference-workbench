#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$COLORS_SH"
source "$SCRIPT_LIB/health.sh"

# Preset → modelfile + created model name
declare -A PRESET_MODELFILE=(
  [north-turbo]="Modelfile.north-turbo"
  [north-fast]="Modelfile.north-fast"
  [north-standard]="Modelfile.north-standard"
  [north-deep]="Modelfile.north-deep"
  [devstral-fast]="Modelfile.devstral-fast"
  [devstral-standard]="Modelfile.devstral-standard"
  [qwen-fast]="Modelfile.qwen-fast"
  [qwen-standard]="Modelfile.qwen-standard"
)

get_model_name() {
  echo "$1"
}

build_model() {
  local preset="$1"
  local modelfile="$MODELFILES_DIR/${PRESET_MODELFILE[$preset]}"

  if [[ -z "${PRESET_MODELFILE[$preset]:-}" ]]; then
    red "ERROR: Unknown preset: $preset"
    return 1
  fi

  if [[ ! -f "$modelfile" ]]; then
    red "ERROR: Modelfile not found: $modelfile"
    return 1
  fi

  yellow "  Building model '$preset' from $modelfile..."
  ollama create "$preset" -f "$modelfile"
  green "  Model '$preset' ready ✓"
}

sync_env_preset() {
  local preset="$1"

  if [[ ! -f "$ENV_FILE" ]]; then
    yellow "  Warning: .env not found — skipping preset sync"
    return 0
  fi

  if grep -q "^OLLAMA_ACTIVE_PRESET=" "$ENV_FILE"; then
    sed -i.bak "s/^OLLAMA_ACTIVE_PRESET=.*/OLLAMA_ACTIVE_PRESET=$preset/" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
  else
    printf '\nOLLAMA_ACTIVE_PRESET=%s\n' "$preset" >> "$ENV_FILE"
  fi

  green "  Synced .env: OLLAMA_ACTIVE_PRESET=$preset"
}

sync_opencode_model() {
  local preset="$1"
  local opencode_config="$HOME/.config/opencode/opencode.jsonc"

  if [[ ! -f "$opencode_config" ]]; then
    yellow "  Warning: OpenCode config not found at $opencode_config — skipping sync"
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    yellow "  Warning: jq not found — skipping OpenCode sync"
    return 0
  fi

  if ! jq -e --arg key "$preset" '.provider.ollama.models[$key]' "$opencode_config" >/dev/null 2>&1; then
    yellow "  Warning: OpenCode config missing ollama preset alias: $preset — skipping sync"
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  jq --arg model "ollama/$preset" '.model = $model' "$opencode_config" > "$tmp"
  mv "$tmp" "$opencode_config"
  green "  Synced OpenCode default model: ollama/$preset"
}

stop_active_model() {
  local running
  running="$(ollama ps 2>/dev/null | tail -n +2 | awk '{print $1}' | head -1 || true)"
  if [[ -n "$running" ]]; then
    yellow "  Stopping loaded model: $running..."
    ollama stop "$running" 2>/dev/null || true
    green "  Model stopped ✓"
  fi
}
