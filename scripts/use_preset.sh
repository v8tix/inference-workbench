#!/usr/bin/env bash
# use_profile.sh — Pick a Gemma profile and apply it (switch + restart + sync OpenCode).
#
# Usage:
#   bash scripts/use_profile.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$SCRIPT_LIB/colors.sh"

NAMES=(gemma-turbo gemma-fast gemma-standard gemma-deep gemma-max)

declare -A FAMILY=( [gemma-turbo]=Speed  [gemma-fast]=Speed  [gemma-standard]=Speed [gemma-deep]=Depth [gemma-max]=Depth  )
declare -A CTX=(    [gemma-turbo]=32K    [gemma-fast]=32K    [gemma-standard]=65K   [gemma-deep]=65K   [gemma-max]=65K    )
declare -A THINK=(  [gemma-turbo]=off    [gemma-fast]=off    [gemma-standard]=off   [gemma-deep]=on    [gemma-max]=on     )
declare -A TOKENS=( [gemma-turbo]=512    [gemma-fast]=1024   [gemma-standard]=2048  [gemma-deep]=2048  [gemma-max]=4096   )
declare -A DESC=(
  [gemma-turbo]="Quickest loop, smallest output"
  [gemma-fast]="Fast coding help"
  [gemma-standard]="Daily default"
  [gemma-deep]="Tricky debugging and planning"
  [gemma-max]="Long deep answers"
)

ACTIVE=""
if [[ -f "$ENV_FILE" ]] && grep -q "^KRONK_TUNING_PROFILE=" "$ENV_FILE"; then
  ACTIVE="$(grep "^KRONK_TUNING_PROFILE=" "$ENV_FILE" | tail -1 | sed 's/^KRONK_TUNING_PROFILE=//')"
fi

bold "=== Gemma Profile Selector ==="
echo ""
printf "  %-4s %-16s %-7s %-8s %-10s %-10s %s\n" \
  "#" "Profile" "Family" "Context" "Thinking" "Max out" "Best for"
printf "  %-4s %-16s %-7s %-8s %-10s %-10s %s\n" \
  "---" "----------------" "-------" "--------" "----------" "----------" "--------"

for i in "${!NAMES[@]}"; do
  name="${NAMES[$i]}"
  marker=""
  [[ "$name" == "$ACTIVE" ]] && marker=" ◀ active"
  printf "  %2d) %-16s %-7s %-8s %-10s %-10s %s%s\n" \
    $((i+1)) "$name" "${FAMILY[$name]}" "${CTX[$name]}" \
    "${THINK[$name]}" "${TOKENS[$name]}" "${DESC[$name]}" "$marker"
done

echo ""
read -r -p "Select profile [1-${#NAMES[@]}]: " choice

if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#NAMES[@]} )); then
  red "Invalid choice."
  exit 1
fi

SELECTED="${NAMES[$((choice-1))]}"
echo ""
bold "Applying: $SELECTED"
echo ""
bash "$SCRIPT_DIR/apply_llm_profile.sh" "$SELECTED"
