# OpenCode Configuration Reference

This folder stores the repo-tracked reference copy of the OpenCode configuration used with this project.

## Files

- `opencode.jsonc` — reference copy of `~/.config/opencode/opencode.jsonc`

## Important note

- the **live** OpenCode config is still `~/.config/opencode/opencode.jsonc`
- this repo copy is a **reference file**, not the active runtime file

The preset apply workflow updates the live file through:

- `scripts/apply_llm_profile.sh`
- `scripts/sync_opencode_model.sh`
