#!/usr/bin/env bash

run_preflight() {
  local ok=true

  bold "Running preflight checks..."
  command -v ollama >/dev/null 2>&1 && green "  Found dependency: ollama ✓" || { red "ERROR: ollama not installed. See https://ollama.com"; ok=false; }
  command -v curl   >/dev/null 2>&1 && green "  Found dependency: curl ✓"   || { red "ERROR: Missing: curl — brew install curl"; ok=false; }
  command -v jq     >/dev/null 2>&1 && green "  Found dependency: jq ✓"     || { red "ERROR: Missing: jq — brew install jq"; ok=false; }

  [[ -f "$ENV_FILE" ]] && green "  Env file found: $ENV_FILE ✓" || yellow "  Warning: .env not found at $ENV_FILE (defaults apply)"
  [[ -d "$MODELFILES_DIR" ]] && green "  Modelfiles dir ready ✓" || { red "ERROR: Missing modelfiles dir: $MODELFILES_DIR"; ok=false; }

  if [[ -n "${OLLAMA_ACTIVE_PRESET:-}" ]]; then
    green "  Active preset: $OLLAMA_ACTIVE_PRESET ✓"
  else
    yellow "  Warning: OLLAMA_ACTIVE_PRESET not set in .env"
  fi

  mkdir -p "$LOGS_DIR"

  [[ "$ok" == true ]]
}
