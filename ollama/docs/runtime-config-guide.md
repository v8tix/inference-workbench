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

Set in the plist — applied every time Ollama starts:

| Variable | Value | Purpose |
|---|---|---|
| `OLLAMA_FLASH_ATTENTION` | `1` | Reduces memory pressure on long context |
| `OLLAMA_KV_CACHE_TYPE` | `q8_0` | Shrinks KV cache vs default precision |
| `OLLAMA_NUM_PARALLEL` | `1` | One request at a time — prevents ctx memory multiplication |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | One model in memory at a time |

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

## Changing env vars

Edit the plist directly:

```bash
$EDITOR ~/Library/LaunchAgents/homebrew.mxcl.ollama.plist
```

Then reload:

```bash
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.ollama.plist
launchctl load   ~/Library/LaunchAgents/homebrew.mxcl.ollama.plist
```

Plist location: `~/Library/LaunchAgents/homebrew.mxcl.ollama.plist`  
This file is **not** tracked in this repo — it lives in your home directory. The reference copy of the config lives here in `ollama/docs/`.

---

## Notes

- `brew services start ollama` overwrites the plist with the default brew version (missing `NUM_PARALLEL` and `MAX_LOADED_MODELS`). If you run it, re-apply the custom plist manually.
- `OLLAMA_NUM_PARALLEL=1` is intentional — running multiple parallel requests multiplies KV cache memory. Single-user coding workload has no need for parallelism.
- `OLLAMA_MAX_LOADED_MODELS=1` prevents two large models sitting in memory when switching presets.
