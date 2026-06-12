#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$SCRIPT_LIB/colors.sh"

KRONK_BASE="${KRONK_BASE:-$HOME/.kronk}"

# ── helpers ──────────────────────────────────────────────────────────────────

model_name_from_dir() {
  local dir="$1"
  local models_dir="$dir/models"
  if [[ -d "$models_dir" ]]; then
    local model_file
    model_file="$(find "$models_dir" -name "*.gguf" -not -name "mmproj*" 2>/dev/null | head -1)"
    if [[ -n "$model_file" ]]; then
      basename "$model_file" .gguf
      return 0
    fi
  fi
  if [[ -f "$dir/.env" ]]; then
    local env_model
    env_model="$(grep -E "^KRONK_MODELS=" "$dir/.env" 2>/dev/null | tail -1 | sed 's/^KRONK_MODELS=//')"
    if [[ -n "$env_model" ]]; then
      echo "$env_model"
      return 0
    fi
  fi
  if [[ -f "$dir/.model_name" ]]; then
    cat "$dir/.model_name"
    return 0
  fi
  echo ""
  return 1
}

save_active_profile() {
  local profile_name="$1"
  local target="$HOME/.kronk-$profile_name"

  if [[ -d "$target" ]]; then
    yellow "  (overwriting existing ~/.kronk-$profile_name)"
    rm -rf "$target"
  fi

  mv "$KRONK_BASE" "$target"
  printf '%s\n' "$profile_name" > "$target/.model_name"
  mkdir -p "$KRONK_BASE/models"
}

sync_env_model() {
  local model_name="$1"

  if [[ -z "$model_name" ]]; then
    yellow "  Warning: active model name is empty — skipping .env sync"
    return 0
  fi

  if [[ ! -f "$ENV_FILE" ]]; then
    yellow "  Warning: .env not found at $ENV_FILE — skipping sync"
    return 0
  fi

  if grep -q "^KRONK_MODELS=" "$ENV_FILE"; then
    sed -i.bak "s/^KRONK_MODELS=.*/KRONK_MODELS=$model_name/" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
  else
    printf '\nKRONK_MODELS=%s\n' "$model_name" >> "$ENV_FILE"
  fi

  green "  Synced .env: KRONK_MODELS=$model_name"
}

list_profiles() {
  local found=()
  for f in "$HOME"/.kronk-*; do
    if [[ -d "$f" ]]; then
      found+=("$f")
    fi
  done
  if [[ ${#found[@]} -eq 0 ]]; then
    return 1
  fi
  printf "%s\n" "${found[@]}"
}

has_active_kronk() {
  [[ -d "$KRONK_BASE" ]] && [[ -n "$(ls -A "$KRONK_BASE"/models 2>/dev/null || true)" ]]
}

create_new_profile() {
  local name="$1"
  local target="$HOME/.kronk-$name"
  if [[ -d "$target" ]]; then
    yellow "Profile '$name' already exists. Overwrite? [y/N]: "
    read -r overwrite
    if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
      echo ""
      return 1
    fi
    rm -rf "$target"
  fi
  mkdir -p "$target/models"
  echo "$name" > "$target/.model_name"
  echo "$target"
}

# ── stop kronk ───────────────────────────────────────────────────────────────

bold "=== Kronk Profile Switcher ==="
echo ""

if pgrep -f "kronk server" > /dev/null 2>&1; then
  yellow "Kronk is running — stopping first..."
  bash "$SCRIPT_DIR/stop.sh"
  echo ""
fi

# ── derive current model name ────────────────────────────────────────────────

CURRENT_MODEL="$(model_name_from_dir "$KRONK_BASE" || true)"
CURRENT_PROFILE_DIR="$HOME/.kronk-$CURRENT_MODEL"

# ── list available profiles ──────────────────────────────────────────────────

PROFILES=()
while IFS= read -r p; do
  PROFILES+=("$p")
done < <(list_profiles || true)

echo ""
bold "Active profile:"
if [[ -n "$CURRENT_MODEL" ]]; then
  green "  ~/.kronk  →  model: $CURRENT_MODEL"
  if [[ -d "$CURRENT_PROFILE_DIR" ]]; then
    yellow "  (note: ~/.kronk-$CURRENT_MODEL already exists as a saved profile)"
  fi
else
  yellow "  ~/.kronk  (no model files found)"
fi

if [[ ${#PROFILES[@]} -eq 0 ]]; then
  echo ""
  yellow "No saved profiles found (no ~/.kronk-* directories)."
  echo ""
  if [[ -n "$CURRENT_MODEL" ]]; then
    cyan "Only option: save current ~/.kronk as a profile for later switching."
    echo ""
    read -r -p "Save current profile as ~/.kronk-$CURRENT_MODEL? [Y/n]: " save_choice
    case "$save_choice" in
      n|N) yellow "No changes made."; exit 0 ;;
     *)
       save_active_profile "$CURRENT_MODEL"
       green "Profile saved as ~/.kronk-$CURRENT_MODEL ✓"
       cyan "  ~/.kronk is now empty — run the switcher again to activate a profile."
       ;;
   esac
  elif has_active_kronk; then
    yellow "~/.kronk exists but no model files found."
    echo ""
    cyan "Options:"
    echo "  n) Start new empty profile"
    echo "  q) Quit without changes"
    echo ""
    read -r -p "Choose [n/q]: " choice2
    case "$choice2" in
      n|N)
        read -r -p "Enter a name for the new profile: " new_name
        new_prof="$(create_new_profile "$new_name")" || true
        if [[ -n "$new_prof" ]]; then
          green "Empty profile created: ~/.kronk-$new_name ✓"
          mv "$KRONK_BASE" "$HOME/.kronk-${new_name}-saved" 2>/dev/null || true
        fi
        ;;
      *) yellow "No changes made."; exit 0 ;;
    esac
  else
    yellow "No active ~/.kronk and no saved profiles."
    echo ""
    cyan "Options:"
    echo "  n) Start new empty profile"
    echo "  q) Quit without changes"
    echo ""
    read -r -p "Choose [n/q]: " choice2
    case "$choice2" in
      n|N)
        read -r -p "Enter a name for the new profile: " new_name
        new_prof="$(create_new_profile "$new_name")" || true
        if [[ -n "$new_prof" ]]; then
          green "Empty profile created: ~/.kronk-$new_name ✓"
          mkdir -p "$KRONK_BASE"
          yellow "  ~/.kronk is empty — run the switcher again to activate a profile."
        fi
        ;;
      *) yellow "No changes made."; exit 0 ;;
    esac
  fi
  exit 0
fi

# ── show profiles ────────────────────────────────────────────────────────────

echo ""
bold "Available profiles:"
echo "  #  Profile Directory                      Model"
echo "  -- -------------------------------------- -------------------------"
for i in "${!PROFILES[@]}"; do
  dir="${PROFILES[$i]}"
  name="$(basename "$dir")"
  mname="$(model_name_from_dir "$dir" || echo "unknown")"
  printf "  %2d) %-38s %s\n" $((i+1)) "$name" "$mname"
done
echo ""
echo "  n) Start new (empty) profile"
echo "  s) Save current profile"
echo "  q) Quit without changes"
echo ""

read -r -p "Select profile to activate [1-${#PROFILES[@]}/n/s/q]: " choice

case "$choice" in
  q|Q) green "No changes made."; exit 0 ;;

  n|N)
    read -r -p "Enter a name for the new profile: " new_name
    new_prof="$(create_new_profile "$new_name")" || true
    if [[ -z "$new_prof" ]]; then
      exit 0
    fi
    green "Empty profile created: ~/.kronk-$new_name ✓"
    if [[ -d "$KRONK_BASE" ]] && [[ -n "$(ls -A "$KRONK_BASE" 2>/dev/null)" ]]; then
      if [[ -n "$CURRENT_MODEL" ]]; then
        yellow "  Saving current ~/.kronk as ~/.kronk-$CURRENT_MODEL"
        save_active_profile "$CURRENT_MODEL"
      else
        yellow "  Saving current ~/.kronk as ~/.kronk-unknown"
        save_active_profile "unknown"
      fi
      rm -rf "$KRONK_BASE"
    fi
    mv "$new_prof" "$KRONK_BASE"
    sync_env_model "$new_name"
    green ""
    green "New profile '$new_name' is now active ✓"
    echo ""
    cyan "  Next steps: pull a model into the active ~/.kronk profile with"
    cyan "  kronk model pull <MODEL_ID> --local"
    cyan "  Then sync .env if needed and start Kronk:  bash scripts/start.sh"
    exit 0
    ;;

  s|S)
    if [[ -z "$CURRENT_MODEL" ]]; then
      read -r -p "Enter a name for the profile: " profile_name
    else
      profile_name="$CURRENT_MODEL"
    fi
    save_active_profile "$profile_name"
    green "Profile saved as ~/.kronk-$profile_name ✓"
    cyan "  ~/.kronk is now empty — run the switcher again to activate a profile."
    exit 0
    ;;

  *)
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#PROFILES[@]} )); then
      red "Invalid choice."
      exit 1
    fi
    ;;
esac

TARGET="${PROFILES[$((choice-1))]}"
TARGET_NAME="$(basename "$TARGET")"

# ── switch: rename current → profile, then target → active ──────────────────

echo ""
bold "Switching profiles..."

# Save current as profile (if it has models) — MOVE, not copy
if [[ -d "$KRONK_BASE" ]] && [[ -n "$(ls -A "$KRONK_BASE" 2>/dev/null)" ]]; then
  if [[ -n "$CURRENT_MODEL" ]]; then
    yellow "  Moving ~/.kronk → ~/.kronk-$CURRENT_MODEL"
    save_active_profile "$CURRENT_MODEL"
  else
    yellow "  Current ~/.kronk has no identifiable model, saving as ~/.kronk-unknown"
    save_active_profile "unknown"
  fi
else
  yellow "  Current ~/.kronk is empty or missing — no profile to save"
  rm -rf "$KRONK_BASE"
fi

# Activate target
yellow "  Activating $TARGET_NAME → ~/.kronk"
rm -rf "$KRONK_BASE"
mv "$TARGET" "$KRONK_BASE"

green ""
green "Switch complete ✓"
echo ""
bold "Now active:"
ACTIVE_MODEL="$(model_name_from_dir "$KRONK_BASE" || true)"
sync_env_model "$ACTIVE_MODEL"
green "  ~/.kronk  →  model: $ACTIVE_MODEL"
echo ""
cyan "  Start Kronk:  bash scripts/start.sh"
cyan "  Or restart:   bash scripts/restart.sh kronk"
echo ""
cyan "  Make sure .env has KRONK_MODELS set correctly and"
cyan "  kronk/kronk.model_config.yaml has the matching config."
