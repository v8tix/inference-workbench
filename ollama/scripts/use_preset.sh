#!/usr/bin/env bash
# use_preset.sh — Pick an Ollama preset and apply it (build + reload + sync OpenCode).
#
# Usage:
#   bash ollama/scripts/use_preset.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$COLORS_SH"
source "$SCRIPT_LIB/ollama_runtime.sh"

NAMES=(north-turbo north-fast north-standard north-deep qwen36-turbo qwen36-fast qwen36-standard qwen36-deep)

declare -A MODEL=(
  [north-turbo]="North Mini Code 1.0"    [north-fast]="North Mini Code 1.0"
  [north-standard]="North Mini Code 1.0" [north-deep]="North Mini Code 1.0"
  [qwen36-turbo]="Qwen3.6 27B Coding"    [qwen36-fast]="Qwen3.6 27B Coding"
  [qwen36-standard]="Qwen3.6 27B Coding" [qwen36-deep]="Qwen3.6 27B Coding"
)
declare -A QUANT=(
  [north-turbo]="mlx-nvfp4"    [north-fast]="mlx-nvfp4"
  [north-standard]="mlx-nvfp4" [north-deep]="mlx-mxfp8"
  [qwen36-turbo]="mlx-nvfp4"   [qwen36-fast]="mlx-nvfp4"
  [qwen36-standard]="mlx-nvfp4" [qwen36-deep]="mlx-nvfp4"
)
declare -A CTX=(
  [north-turbo]="32K"     [north-fast]="48K"
  [north-standard]="64K"  [north-deep]="32K"
  [qwen36-turbo]="32K"    [qwen36-fast]="64K"
  [qwen36-standard]="128K" [qwen36-deep]="64K"
)
declare -A MAXOUT=(
  [north-turbo]="512"     [north-fast]="1024"
  [north-standard]="2048" [north-deep]="4096"
  [qwen36-turbo]="512"    [qwen36-fast]="1024"
  [qwen36-standard]="2048" [qwen36-deep]="4096"
)
declare -A FAMILY=(
  [north-turbo]="Speed"    [north-fast]="Speed"
  [north-standard]="Speed" [north-deep]="Depth"
  [qwen36-turbo]="Speed"   [qwen36-fast]="Speed"
  [qwen36-standard]="Speed" [qwen36-deep]="Depth"
)
declare -A WEIGHTS=(
  [north-turbo]="20 GB"    [north-fast]="20 GB"
  [north-standard]="20 GB" [north-deep]="31 GB"
  [qwen36-turbo]="20 GB"   [qwen36-fast]="20 GB"
  [qwen36-standard]="20 GB" [qwen36-deep]="20 GB"
)

ACTIVE="${OLLAMA_ACTIVE_PRESET:-}"

bold "=== Ollama Preset Selector ==="
echo ""
printf "  %-4s %-20s %-22s %-12s %-6s %-8s %-8s %s\n" \
  "#" "Preset" "Model" "Quant" "Family" "Context" "Max out" "Weights"
printf "  %-4s %-20s %-22s %-12s %-6s %-8s %-8s %s\n" \
  "---" "--------------------" "----------------------" "------------" "------" "--------" "--------" "-------"

for i in "${!NAMES[@]}"; do
  name="${NAMES[$i]}"
  marker=""; [[ "$name" == "$ACTIVE" ]] && marker=" ◀ active"
  printf "  %2d) %-20s %-22s %-12s %-6s %-8s %-8s %s%s\n" \
    $((i+1)) "$name" "${MODEL[$name]}" "${QUANT[$name]}" \
    "${FAMILY[$name]}" "${CTX[$name]}" "${MAXOUT[$name]}" "${WEIGHTS[$name]}" "$marker"
done

echo ""
read -r -p "Select preset [1-8]: " choice

if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > 8 )); then
  red "Invalid choice."
  exit 1
fi

SELECTED="${NAMES[$((choice-1))]}"
echo ""
bold "Applying: $SELECTED"
echo ""
bash "$SCRIPT_DIR/apply_preset.sh" "$SELECTED"
