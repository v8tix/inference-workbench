# 🙂 Kronk Profiles Guide

This repo uses **Kronk profiles** for saved model directories and a separate **Gemma tuning ladder** for day-to-day speed vs depth tuning.

## 🧠 Two layers to remember

- `~/.kronk` = the active saved profile
- `~/.kronk-<name>` = saved model profiles
- `scripts/kronk_switch.sh` = switches saved profiles
- `scripts/kronk_tuning_switch.sh` = switches the active tuning preset
- `scripts/apply_llm_profile.sh` = switches a preset and restarts Kronk

---

## ⚡ Speed up your workflow first

Before changing presets, try these:

1. keep the prompt focused on one task
2. attach fewer files
3. ask for a shorter answer first
4. let OpenCode compact when the task drifts

If that is not enough, then switch presets.

---

## 🎛️ Preferred Gemma presets

### 🏷️ Preset naming convention

The preset ladder is split into **two groups**:

- **speed presets** for faster loops and shorter answers
- **depth presets** for heavier reasoning and longer answers

Naming rule:

- **speed**: `gemma-<speed-label>`
- **depth**: `gemma-<depth-label>`

### ⚡ Speed presets

| Preset | Thinking | `max_tokens` | Best for |
|---|---|---:|---|
| `gemma-turbo` | off | 512 | fastest loop |
| `gemma-fast` | off | 1024 | quick coding help |
| `gemma-standard` | off | 2048 | default daily work |

### 🧠 Depth presets

| Preset | Thinking | `max_tokens` | Best for |
|---|---|---:|---|
| `gemma-deep` | on | 2048 | deeper debugging / planning |
| `gemma-max` | on | 4096 | longest deep answers |

All of these use the same Gemma baseline:

- **32K context**
- **`nseq-max: 1`**

---

## 🚀 Start Kronk

From the repo root:

`bash scripts/start.sh`

What it does:

- runs preflight checks
- verifies the active profile already has the chosen model
- starts Kronk
- warms the active model

To update Kronk explicitly:

`bash scripts/update.sh`

---

## 🛑 Stop Kronk

`bash scripts/stop.sh`

## 🔁 Restart Kronk

`bash scripts/restart.sh`

Restart only Kronk:

`bash scripts/restart.sh kronk`

---

## 🔀 Switch saved model profiles

Run:

`bash scripts/kronk_switch.sh`

The switcher shows:

- the active profile in `~/.kronk`
- the saved profiles found under `~/.kronk-*`
- options to switch, save, or create a new empty profile

---

## 🎚️ Switch tuning presets

Interactive:

`bash scripts/kronk_tuning_switch.sh`

Direct:

`bash scripts/kronk_tuning_switch.sh gemma-standard`

One-step apply + restart:

`bash scripts/apply_llm_profile.sh gemma-standard`

That flow also syncs OpenCode's global default model to the same preset alias.

## 🔗 OpenCode Integration

OpenCode uses the preset aliases defined in the global config file:

- **live config**: `~/.config/opencode/opencode.jsonc`
- **repo copy**: `opencode/opencode.jsonc`

When you apply a preset with:

`bash scripts/apply_llm_profile.sh gemma-standard`

the workflow does three things:

1. switches the active Kronk preset
2. restarts Kronk
3. updates OpenCode's default model through `scripts/sync_opencode_model.sh`

Use `opencode/opencode.jsonc` as the tracked reference copy for the repo. The live OpenCode file in your home directory remains the active runtime file.

---

## 🧭 Which preset should I use?

```mermaid
flowchart TD
    A[Pick a preset] --> B{Need the fastest loop?}
    B -->|Yes| C[gemma-turbo]
    B -->|No| D{Need deeper reasoning?}
    D -->|No| E[gemma-standard]
    D -->|Yes| F{Need very long answers too?}
    F -->|No| G[gemma-deep]
    F -->|Yes| H[gemma-max]
```

Quick rule:

- use **`gemma-standard`** by default
- drop to **`gemma-fast`** or **`gemma-turbo`** when the loop feels slow
- move up to **`gemma-deep`** or **`gemma-max`** only when quality or answer length is the missing piece

---

## 💾 Save the current profile

If your active `~/.kronk` already has a model loaded, the switcher can save it as:

`~/.kronk-<model-name>`

That makes it easy to come back to the same setup later.

---

## 🆕 Create a new empty profile

Choose `n` in the switcher.

After that:

1. pull a model into the active `~/.kronk` with `kronk model pull <MODEL_ID> --local`
2. make sure `.env` has the matching `KRONK_MODELS=...`
3. start Kronk with `bash scripts/start.sh`

---

## ✅ Typical daily flow

1. choose the saved model profile you want: `bash scripts/kronk_switch.sh`
2. apply the daily preset you want: `bash scripts/apply_llm_profile.sh gemma-standard`
3. work normally
4. stop Kronk when done: `bash scripts/stop.sh`

---

## 🪵 Logs

After starting Kronk, logs are written under `logs/`.

To follow the newest log:

`tail -f logs/kronk_*.log`
