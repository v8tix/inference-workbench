#!/usr/bin/env bash

check_command() {
  local cmd="$1"
  local install_hint="${2:-}"

  if command -v "$cmd" >/dev/null 2>&1; then
    green "  Found dependency: $cmd ✓"
    return 0
  fi

  red "ERROR: Missing required command: $cmd"
  if [[ -n "$install_hint" ]]; then
    yellow "  Fix: $install_hint"
  fi
  return 1
}

ensure_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    green "  Directory ready: $dir ✓"
    return 0
  fi

  mkdir -p "$dir"
  green "  Created directory: $dir ✓"
}

check_file_exists() {
  local file="$1"
  local label="$2"

  if [[ -f "$file" ]]; then
    green "  ${label} found: $file ✓"
    return 0
  fi

  red "ERROR: Missing ${label}: $file"
  return 1
}

check_env_file() {
  local env_file="$1"
  if [[ -f "$env_file" ]]; then
    green "  Env file found: $env_file ✓"
    return 0
  fi

  yellow "  Warning: .env not found at $env_file (defaults may apply)"
  return 0
}

check_required_env() {
  local name="$1"
  local value="${!name:-}"
  if [[ -n "$value" ]]; then
    green "  Env set: $name ✓"
    return 0
  fi

  red "ERROR: Required environment variable is missing: $name"
  return 1
}

check_active_model_file() {
  local model_id="$1"
  local model_file
  model_file="$(find "$KRONK_BASE/models" -name "${model_id}.gguf" -not -path "*/sha/*" 2>/dev/null | head -1 || true)"
  if [[ -n "$model_file" ]]; then
    green "  Active model ready: $model_file ✓"
    return 0
  fi

  red "ERROR: Active Kronk profile does not contain ${model_id}.gguf"
  yellow "  Fix: switch to a saved profile with bash scripts/kronk_switch.sh"
  yellow "  Or pull the model into ~/.kronk with: kronk model pull $model_id --local"
  return 1
}

run_preflight() {
  local ok=true

  bold "Running preflight checks..."
  check_command curl "brew install curl" || ok=false
  check_command jq "brew install jq" || ok=false
  check_command pgrep || ok=false
  check_command go "brew install go" || ok=false
  check_env_file "$ENV_FILE" || ok=false
  check_file_exists "$MODEL_CONFIG" "model config" || ok=false
  ensure_dir "$KRONK_BASE"
  ensure_dir "$KRONK_BASE/models"
  ensure_dir "$LOGS_DIR"
  check_required_env KRONK_MODELS || ok=false
  check_active_model_file "$KRONK_MODELS" || ok=false

  [[ "$ok" == true ]]
}
