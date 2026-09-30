#!/usr/bin/env bash
# use_preset.sh — Pick an Ollama preset and apply it (build + reload + sync OpenCode).
#
# Usage:
#   bash ollama/scripts/use_preset.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$COLORS_SH"
source "$SCRIPT_LIB/ollama_runtime.sh"

# name|model|quant|family|context|max output|weights
# (plain table instead of `declare -A`: macOS ships bash 3.2, which has no associative arrays)
PRESETS=(
  "qwen36-turbo|Qwen3.6 27B Coding|mlx-nvfp4|Speed|32K|512|20 GB"
  "qwen36-fast|Qwen3.6 27B Coding|mlx-nvfp4|Speed|64K|1024|20 GB"
  "qwen36-standard|Qwen3.6 27B Coding|mlx-nvfp4|Speed|88K|2048|20 GB"
  "qwen36-deep|Qwen3.6 27B Coding|mlx-nvfp4|Depth|64K|4096|20 GB"
  "qwen38-fast|Qwen3.8 27B|mlx-nvfp4|Speed|64K|1024|18 GB"
  "qwen38-standard|Qwen3.8 27B|mlx-nvfp4|Speed|88K|2048|18 GB"
  "qwen38-deep|Qwen3.8 27B|mlx-mxfp8|Depth|32K|4096|32 GB"
)

ACTIVE="${OLLAMA_ACTIVE_PRESET:-}"

bold "=== Ollama Preset Selector ==="
echo ""
printf "  %-4s %-20s %-22s %-12s %-6s %-8s %-8s %s\n" \
  "#" "Preset" "Model" "Quant" "Family" "Context" "Max out" "Weights"
printf "  %-4s %-20s %-22s %-12s %-6s %-8s %-8s %s\n" \
  "---" "--------------------" "----------------------" "------------" "------" "--------" "--------" "-------"

i=0
for row in "${PRESETS[@]}"; do
  IFS='|' read -r name model quant family ctx maxout weights <<< "$row"
  i=$((i+1))
  marker=""; [[ "$name" == "$ACTIVE" ]] && marker=" ◀ active"
  printf "  %2d) %-20s %-22s %-12s %-6s %-8s %-8s %s%s\n" \
    "$i" "$name" "$model" "$quant" "$family" "$ctx" "$maxout" "$weights" "$marker"
done

echo ""
read -r -p "Select preset [1-${#PRESETS[@]}]: " choice

if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#PRESETS[@]} )); then
  red "Invalid choice."
  exit 1
fi

SELECTED="${PRESETS[$((choice-1))]%%|*}"
echo ""
bold "Applying: $SELECTED"
echo ""
bash "$SCRIPT_DIR/apply_preset.sh" "$SELECTED"
