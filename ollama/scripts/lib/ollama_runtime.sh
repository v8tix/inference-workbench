#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$COLORS_SH"
source "$SCRIPT_LIB/health.sh"

# Preset → modelfile + created model name
get_modelfile() {
  case "$1" in
    north-turbo)     echo "Modelfile.north-turbo" ;;
    north-fast)      echo "Modelfile.north-fast" ;;
    north-standard)  echo "Modelfile.north-standard" ;;
    north-deep)      echo "Modelfile.north-deep" ;;
    qwen36-turbo)    echo "Modelfile.qwen36-turbo" ;;
    qwen36-fast)     echo "Modelfile.qwen36-fast" ;;
    qwen36-standard) echo "Modelfile.qwen36-standard" ;;
    qwen36-deep)     echo "Modelfile.qwen36-deep" ;;
    *)               echo "" ;;
  esac
}

is_valid_preset() {
  local result
  result="$(get_modelfile "$1")"
  [[ -n "$result" ]]
}

get_model_name() {
  echo "$1"
}

build_model() {
  local preset="$1"
  local modelfile_name
  modelfile_name="$(get_modelfile "$preset")"

  if [[ -z "$modelfile_name" ]]; then
    red "ERROR: Unknown preset: $preset"
    return 1
  fi

  local modelfile="$MODELFILES_DIR/$modelfile_name"

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
