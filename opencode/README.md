# OpenCode Configuration Reference

This folder stores the repo-tracked reference copy of the OpenCode configuration used with this project.

## Files

- `opencode.json` — general MCP and tooling config (not engine-specific)

## Engine-specific OpenCode configs

- `kronk/opencode/opencode.jsonc` — reference copy of `~/.config/opencode/opencode.jsonc` for Kronk models

## Important note

- the **live** OpenCode config is still `~/.config/opencode/opencode.jsonc`
- repo copies are **reference files**, not the active runtime files

The preset apply workflow updates the live file through:

- `kronk/scripts/apply_llm_profile.sh`
- `kronk/scripts/sync_opencode_model.sh`
