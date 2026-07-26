# 🔧 Ollama Runtime Configuration Guide

Covers how Ollama is configured to run on this machine as a background service.

---

## How it runs

Ollama runs as a **launchd user agent** — starts automatically at login, restarts if it crashes, no terminal needed.

- Managed via: `~/Library/LaunchAgents/homebrew.mxcl.ollama.plist`
- Log: `/opt/homebrew/var/log/ollama.log`
- API: `http://localhost:11434`

---

## Active environment variables

Set via `ollama/ollama.env` — applied by `ollama/scripts/apply-runtime-config.sh`:

| Variable | Default | Purpose |
|---|---|---|
| `OLLAMA_FLASH_ATTENTION` | `1` | Reduces memory pressure on long context |
| `OLLAMA_KV_CACHE_TYPE` | `q4_0` | Halves KV cache vs default precision |
| `OLLAMA_NUM_PARALLEL` | `1` | One request at a time — prevents ctx memory multiplication |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | One model in memory at a time |
| `OLLAMA_HOST` | `0.0.0.0:11434` | Listen on all interfaces (LAN access) |

---

## Changing runtime config

Edit `ollama/ollama.env`, then run:

```bash
bash ollama/scripts/apply-runtime-config.sh
```

That's it. The script:
1. Reads env vars from `ollama/ollama.env`
2. Generates a complete plist via heredoc
3. Compares with the existing plist (skips if identical)
4. Unloads old plist, loads new one via `launchctl`
5. Ollama restarts automatically with the new env vars

### Idempotent

Re-running with the same config is a no-op. Safe to call multiple times.

### After brew services

`brew services start ollama` overwrites the plist with defaults, dropping `NUM_PARALLEL` and `MAX_LOADED_MODELS`. Re-run `apply-runtime-config.sh` to restore them.

---

## Managing the service

```bash
# Start (and register at login)
brew services start ollama

# Stop (and unregister from login)
brew services stop ollama

# Restart
brew services restart ollama

# Check status
brew services list | grep ollama

# View live logs
tail -f /opt/homebrew/var/log/ollama.log

# Verify API is up
curl http://localhost:11434

# Check loaded model + memory
ollama ps
```

---

## 💾 Does the config persist?

| Scenario | Config preserved? | Why |
|---|---|---|
| 🔄 **Reboot / login** | ✅ **Yes** | launchd loads the plist at every login |
| 💥 **Ollama crash / `pkill ollama`** | ✅ **Yes** | `KeepAlive=true` — launchd restarts with same env vars |
| 🍺 **`brew services restart ollama`** | ❌ **No** | brew overwrites the plist with defaults |
| 🚀 **`bash ollama/scripts/start.sh`** | ✅ **Yes** | auto-calls `apply-runtime-config.sh` to restore |

> ⚠️ **After `brew services start/restart ollama`, always re-run:**
> ```bash
> bash ollama/scripts/apply-runtime-config.sh
> ```
> Or just use `bash ollama/scripts/start.sh` which does it automatically.

## 📦 Backup plist

The generated plist is **not** tracked in this repo — it lives in your home directory.
The source of truth is `ollama/ollama.env` + `ollama/scripts/apply-runtime-config.sh`.
If you lose your plist, re-run the script to regenerate it.

---

## Notes

- `brew services start ollama` overwrites the plist with the default brew version (missing `NUM_PARALLEL` and `MAX_LOADED_MODELS`). Re-run `apply-runtime-config.sh` after any `brew services` command.
- `OLLAMA_NUM_PARALLEL=1` is intentional — running multiple parallel requests multiplies KV cache memory. Single-user coding workload has no need for parallelism.
- `OLLAMA_MAX_LOADED_MODELS=1` prevents two large models sitting in memory when switching presets.
- `apply-runtime-config.sh` is automatically called by `start.sh` — so normal startup also ensures correct runtime config.