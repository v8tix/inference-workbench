#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$SCRIPT_LIB/colors.sh"

PRESET_DIR="$PROJECT_ROOT/kronk/presets"
ACTIVE_CONFIG="$PROJECT_ROOT/kronk/kronk.model_config.yaml"

list_presets() {
  find "$PRESET_DIR" -maxdepth 1 -type f -name "*.yaml" -print 2>/dev/null | sort
}

sync_env_tuning_profile() {
  local preset_name="$1"

  if [[ ! -f "$ENV_FILE" ]]; then
    yellow "  Warning: .env not found at $ENV_FILE — skipping tuning profile sync"
    return 0
  fi

  if grep -q "^KRONK_TUNING_PROFILE=" "$ENV_FILE"; then
    sed -i.bak "s/^KRONK_TUNING_PROFILE=.*/KRONK_TUNING_PROFILE=$preset_name/" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
  else
    printf '\nKRONK_TUNING_PROFILE=%s\n' "$preset_name" >> "$ENV_FILE"
  fi

  green "  Synced .env: KRONK_TUNING_PROFILE=$preset_name"
}

activate_preset() {
  local preset_name="$1"
  local preset_file="$PRESET_DIR/$preset_name.yaml"

  if [[ ! -f "$preset_file" ]]; then
    red "Unknown tuning preset: $preset_name"
    return 1
  fi

  cp "$preset_file" "$ACTIVE_CONFIG"
  sync_env_tuning_profile "$preset_name"

  green ""
  green "Tuning preset activated ✓"
  echo ""
  echo "  Preset : $preset_name"
  echo "  Config : $ACTIVE_CONFIG"
  echo ""
  cyan "  Restart Kronk to apply it:"
  cyan "  bash scripts/restart.sh"
}

bold "=== Kronk Tuning Preset Switcher ==="
echo ""

PRESETS=()
while IFS= read -r preset; do
  PRESETS+=("$preset")
done < <(list_presets)

if [[ ${#PRESETS[@]} -eq 0 ]]; then
  red "No tuning presets found in $PRESET_DIR"
  exit 1
fi

if [[ $# -gt 1 ]]; then
  echo "Usage: bash scripts/kronk_tuning_switch.sh [preset-name]" >&2
  exit 1
fi

if [[ $# -eq 1 ]]; then
  activate_preset "$1"
  exit 0
fi

echo "Available tuning presets:"
echo "  #  Preset"
echo "  -- --------------------------------"
for i in "${!PRESETS[@]}"; do
  preset_name="$(basename "${PRESETS[$i]}" .yaml)"
  printf "  %2d) %s\n" $((i+1)) "$preset_name"
done
echo ""

read -r -p "Select preset to activate [1-${#PRESETS[@]}]: " choice

if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#PRESETS[@]} )); then
  red "Invalid choice."
  exit 1
fi

activate_preset "$(basename "${PRESETS[$((choice-1))]}" .yaml)"
