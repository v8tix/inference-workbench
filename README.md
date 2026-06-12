# local-llm-infra

Friendly local infrastructure for running **Kronk** on a **macOS Apple Silicon** machine with a **profile-based** model setup.

This repo is intentionally small and operational:

- it manages **Kronk only**
- it assumes models live inside Kronk profiles under `~/.kronk` / `~/.kronk-*`
- it gives you a few bash scripts to **start, stop, restart, update, and switch profiles**

## What this repo does

In practice, this repo helps you run a local coding model with a repeatable setup:

- **`scripts/start.sh`** starts Kronk, waits for health, and sends a warm-up request
- **`scripts/stop.sh`** stops Kronk cleanly
- **`scripts/restart.sh`** does a stop/start cycle
- **`scripts/update.sh`** checks for and installs Kronk updates
- **`scripts/kronk_switch.sh`** switches the active Kronk profile and syncs `.env`
- **`scripts/kronk_tuning_switch.sh`** switches between Gemma tuning presets

The current runtime tuning lives in:

- **`kronk/kronk.model_config.yaml`** — context window, batching, concurrency, and sampling

## How the profile setup works

This repo uses a **profile-only** workflow:

- `~/.kronk` = the **active** Kronk profile
- `~/.kronk-<name>` = a **saved** Kronk profile

That means you can keep separate model setups without mixing their files. The switcher moves directories instead of rebuilding the environment from raw backups.

## Prerequisites

These commands need to exist on your machine:

- `curl`
- `jq`
- `pgrep`
- `go`

`scripts/start.sh` checks those automatically before starting.

## Basic setup

1. Copy `.env.example` to `.env`
2. Set `KRONK_MODELS` to the model you want active
3. Make sure the active profile in `~/.kronk` actually contains that model
4. Tune model behavior in `kronk/kronk.model_config.yaml` if needed

Example:

```bash
cp .env.example .env
```

## Available scripts

| Script | What it does | Options |
|---|---|---|
| `bash scripts/start.sh` | Starts Kronk, waits for health, warms the active model | `--force` forces a restart even if Kronk is already healthy |
| `bash scripts/stop.sh` | Stops the running Kronk process | none |
| `bash scripts/restart.sh` | Full stop/start cycle | optional `kronk` argument |
| `bash scripts/update.sh` | Checks for a newer Kronk version and updates explicitly | `--yes`, `--check-only` |
| `bash scripts/kronk_switch.sh` | Interactive profile switcher | interactive menu: switch, save, create, quit |
| `bash scripts/kronk_tuning_switch.sh` | Activates a Gemma tuning preset by copying it into the active config file | optional preset name |
| `bash scripts/apply_llm_profile.sh` | Activates a tuning preset and immediately restarts Kronk | required preset name |

## Script details and examples

### Start

```bash
bash scripts/start.sh
```

Force a fresh restart:

```bash
bash scripts/start.sh --force
```

What start does:

1. runs preflight checks
2. verifies `KRONK_MODELS` is set
3. verifies the matching `.gguf` exists in the active profile
4. starts Kronk in the background
5. waits for the health endpoint
6. sends a tiny warm-up request so the first real request is smoother

### Stop

```bash
bash scripts/stop.sh
```

Use this when you want a clean shutdown.

### Restart

```bash
bash scripts/restart.sh
```

Or:

```bash
bash scripts/restart.sh kronk
```

Both are Kronk restarts in practice. The second form makes the intent explicit and uses the runtime functions directly.

### Update

Check whether Kronk is current:

```bash
bash scripts/update.sh --check-only
```

Update with prompt:

```bash
bash scripts/update.sh
```

Update without prompt:

```bash
bash scripts/update.sh --yes
```

Updates are now **separate from startup**, so `start.sh` stays clean and predictable.

### Switch profiles

```bash
bash scripts/kronk_switch.sh
```

The switcher shows:

- the active profile
- the saved profiles
- options to activate one
- an option to save the current profile
- an option to create a new empty profile

Common switcher choices:

- `1`, `2`, `3`... = activate a saved profile
- `s` = save the current active profile
- `n` = create a new empty profile
- `q` = quit

### Switch tuning presets

```bash
bash scripts/kronk_tuning_switch.sh
```

Or activate one directly:

```bash
bash scripts/kronk_tuning_switch.sh gemma-standard
```

Or apply and restart in one step:

```bash
bash scripts/apply_llm_profile.sh gemma-standard
```

That command also syncs the OpenCode global default model to the same preset alias.

### OpenCode Integration

This repo also keeps OpenCode aligned with the active preset workflow.

- **live OpenCode config**: `~/.config/opencode/opencode.jsonc`
- **repo reference copy**: `opencode/opencode.jsonc`
- **sync script**: `bash scripts/sync_opencode_model.sh <preset-name>`

When you run:

```bash
bash scripts/apply_llm_profile.sh gemma-standard
```

the flow is:

1. activate the Kronk preset
2. restart Kronk
3. update OpenCode's global default model to the same preset alias

Use the repo copy under `opencode/` as a tracked reference, not as the live runtime file.

Available Gemma presets follow two naming groups:

- **speed presets**: `gemma-turbo`, `gemma-fast`, `gemma-standard`
- **depth presets**: `gemma-deep`, `gemma-max`

Speed presets:

- `gemma-turbo` = 32K, `nseq-max: 1`, thinking off, `max_tokens: 512`
- `gemma-fast` = 32K, `nseq-max: 1`, thinking off, `max_tokens: 1024`
- `gemma-standard` = 32K, `nseq-max: 1`, thinking off, `max_tokens: 2048`

Depth presets:

- `gemma-deep` = 32K, `nseq-max: 1`, thinking on, `max_tokens: 2048`
- `gemma-max` = 32K, `nseq-max: 1`, thinking on, `max_tokens: 4096`

The tuning switcher updates the active `kronk/kronk.model_config.yaml` and syncs `KRONK_TUNING_PROFILE` in `.env`.
Restart Kronk after switching to apply the new preset.
If you use `apply_llm_profile.sh`, OpenCode's global default model is updated too.

## Typical daily workflow

If Kronk is already installed and your active profile is ready:

```bash
bash scripts/start.sh
```

If you want to switch to another saved model first:

```bash
bash scripts/kronk_switch.sh
bash scripts/start.sh
```

If you want to upgrade Kronk first:

```bash
bash scripts/update.sh --yes
bash scripts/start.sh
```

When done:

```bash
bash scripts/stop.sh
```

## Logs and troubleshooting

Kronk logs are written under `logs/`.

Tail the latest log:

```bash
tail -f logs/kronk_*.log
```

Useful runtime endpoints:

- API: `http://localhost:11435`
- Health: `http://localhost:11435/health`
- Debug: `http://localhost:8091`

If startup fails:

1. check that `.env` exists and `KRONK_MODELS` matches the active model
2. check that the model file exists somewhere under `~/.kronk/models`
3. inspect the latest file in `logs/`
4. if needed, switch to a valid saved profile with `bash scripts/kronk_switch.sh`

## Helpful files

| File | Purpose |
|---|---|
| `.env.example` | Example environment variables |
| `kronk/kronk.model_config.yaml` | Model tuning and context settings |
| `docs/profiles-guide.md` | More detail on the profile workflow |
| `docs/model-tuning.md` | Notes about context, RAM, and practical tuning on this machine |

## Notes

- This repo is **macOS-only**
- It is designed around **Apple Silicon / Metal**
- It is intentionally **Kronk-only**
- There is **no CI, no build system, and no automated test suite** here — it is mostly bash orchestration
