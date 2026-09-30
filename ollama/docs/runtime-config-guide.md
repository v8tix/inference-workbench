# 🔧 Ollama Runtime Configuration Guide

How Ollama's configured as a background service on this machine.

---

## How it runs

Ollama runs as a launchd user agent via Homebrew Services — starts at login, restarts on crash, no terminal needed.

- Managed via `brew services {start,stop,restart} ollama`
- Env override file: `~/.homebrew/services/ollama.env` — the source of truth; the plist is generated from it
- Log: `/opt/homebrew/var/log/ollama.log`
- API: `http://localhost:11434`

---

## How the plist is generated (verified 2026-09-30, Homebrew 7.0.7)

The launchd plist, `~/Library/LaunchAgents/sh.brew.ollama.plist`, is **generated output, not a file to edit**. The label is `sh.brew.ollama`. Older Homebrew used `homebrew.mxcl.ollama`, and that file no longer exists.

Every `brew services start` or `restart` runs this flow (Homebrew `services/cli.rb` and `service.rb`):

1. Delete the installed plist.
2. Build a new one from the formula's `service do … end` block. For ollama that is `ollama serve`, `keep_alive`, `working_dir`, the log path, and two env vars: `OLLAMA_FLASH_ATTENTION=1` and **`OLLAMA_KV_CACHE_TYPE=q8_0`**.
3. Merge `~/.homebrew/services/ollama.env` on top (`KEY=value` per line, user values win).
4. Write the result to `~/Library/LaunchAgents/sh.brew.ollama.plist` and load it.

That is why the plist "survives" restarts: it is rebuilt each time with your env file merged in. It also explains the 2026-08-15 incident. The formula's own default is `q8_0`, so a plist that didn't carry your `q4_0` silently ran `q8_0`.

**Test:** I hand-edited the plist (added a marker variable and set `OLLAMA_KV_CACHE_TYPE=q8_0`), ran `brew services restart ollama`, and the plist came back byte-identical to the original. The marker was gone and the running job had `q4_0`. Hand edits are lost. Only the env file persists.

Consequences:
- Put settings in `ollama/ollama.env` (applied by `apply-runtime-config.sh`), never in the plist.
- Don't write `homebrew.mxcl.ollama.plist` and `launchctl load` it yourself. The label no longer matches, so you'd get a second job next to `sh.brew.ollama`.

---

## Active environment variables

Set via `ollama/ollama.env`, applied by `ollama/scripts/apply-runtime-config.sh`, which writes them to `~/.homebrew/services/ollama.env` — Homebrew's own documented mechanism for adding/overriding a service's env vars (`brew services --help`). This **persists across both `brew services restart` and `brew upgrade`**.

| Variable | Value | Purpose |
|---|---|---|
| `OLLAMA_FLASH_ATTENTION` | `1` | Reduces memory pressure on long context |
| `OLLAMA_KV_CACHE_TYPE` | `q4_0` | Halves KV cache vs default precision |
| `OLLAMA_NUM_PARALLEL` | `1` | One request at a time — no ctx memory multiplication |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | One model in memory at a time |
| `OLLAMA_GPU_OVERHEAD` | `2147483648` (2 GiB) | Hard safety margin, added after the 2026-08-15 OOM incident ([details](../../docs/qwen38-memory-incident-2026-08-15.md)) |
| `OLLAMA_HOST` | `0.0.0.0:11434` | Listen on all interfaces (LAN access) |
| `OLLAMA_KEEP_ALIVE` | `4h` | Keep model loaded between requests |

---

## Changing runtime config

Edit `ollama/ollama.env`, then:
```bash
bash ollama/scripts/apply-runtime-config.sh
```
Reads the env vars, writes them to `~/.homebrew/services/ollama.env`, skips the restart if nothing changed, otherwise runs `brew services restart ollama`. Safe to re-run any time — idempotent.

---

## Managing the service

```bash
brew services start ollama
brew services stop ollama
brew services restart ollama
brew services list | grep ollama
tail -f /opt/homebrew/var/log/ollama.log
curl http://localhost:11434
ollama ps
```

All of these are safe to run directly now — unlike the old plist approach, `brew services restart`/`start` no longer drops the custom env vars, since Homebrew merges `~/.homebrew/services/ollama.env` on top of the formula's own service definition every time.

---

## 💾 Does the config persist?

| Scenario | Preserved? | Why |
|---|---|---|
| 🔄 Reboot / login | ✅ | Homebrew reads the env file on every job start |
| 💥 Ollama crash / `pkill` | ✅ | Restart re-reads the same env file |
| 🍺 `brew services restart` | ✅ | Exactly the mechanism designed to survive it |
| 🍺 `brew upgrade ollama` | ✅ | Persists across upgrades per Homebrew's own docs |

No more "re-run after every brew services command" — that caveat only applied to the old, broken plist approach.

## 📦 Backup

Source of truth: `ollama/ollama.env` (tracked) + `ollama/scripts/apply-runtime-config.sh`. `~/.homebrew/services/ollama.env` itself isn't tracked — same as `~/.config/opencode/opencode.jsonc`. If it drifts or gets lost, just re-run `apply-runtime-config.sh`.

To check what's *actually* running (not just declared):
```bash
launchctl print gui/$(id -u)/homebrew.mxcl.ollama | grep -A12 "environment = {"
```
Check the job's own `environment` block, not `inherited environment` — the latter can be a stale `launchctl setenv` masking a real problem.

---

## Notes

- `OLLAMA_NUM_PARALLEL=1` is deliberate — parallel requests multiply KV cache memory, and this is a single-user coding workload.
- `OLLAMA_MAX_LOADED_MODELS=1` stops two large models sitting in memory when switching presets.
- `OLLAMA_GPU_OVERHEAD` is a hard reserve Ollama actually enforces — the closest thing to a real backstop against overcommitting memory. The KV-cache formula in `docs/hardware.md` is informational only; this is the one setting that isn't.
- `start.sh` calls `apply-runtime-config.sh` automatically, but it's no longer the only safe path — any `brew services` command works now.
