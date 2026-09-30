# Exposing Ollama on the LAN

By default Ollama binds to `localhost:11434` only — unreachable from other machines. Here's how to open it up to `0.0.0.0:11434` in a way that actually survives a restart and a reboot.

This uses the same `~/.homebrew/services/ollama.env` mechanism as the rest of this repo's runtime config — see [`runtime-config-guide.md`](runtime-config-guide.md) for why plist edits don't work on this Homebrew install and what does instead. Short version: this repo's `ollama/ollama.env` already sets `OLLAMA_HOST=0.0.0.0:11434`, so if you've run `apply-runtime-config.sh`, you're already exposed. The steps below are for doing it standalone or verifying it.

## Steps

1. Add the setting (or confirm it's already in `ollama/ollama.env` and run `apply-runtime-config.sh`):
   ```bash
   mkdir -p ~/.homebrew/services
   cat > ~/.homebrew/services/ollama.env << 'EOF'
   OLLAMA_HOST=0.0.0.0:11434
   EOF
   brew services restart ollama
   ```

2. Verify it's bound to all interfaces:
   ```bash
   lsof -iTCP:11434 -sTCP:LISTEN -P
   # good:  ollama ... TCP *:11434 (LISTEN)
   # bad:   ollama ... TCP localhost:11434 (LISTEN)
   ```

3. Verify it's in the job's *own* environment, not just an inherited session var:
   ```bash
   launchctl print gui/$(id -u)/sh.brew.ollama | grep -A6 '^\tenvironment = {'
   # OLLAMA_HOST should appear here, not only under "inherited environment"
   ```

4. Verify from the remote machine:
   ```bash
   curl -s http://<laptop-lan-ip>:11434/api/tags
   ```

## Watch out for `launchctl setenv` false positives

`launchctl setenv OLLAMA_HOST 0.0.0.0:11434` makes the binding work *immediately*, but it's session-only — it shows up under `inherited environment`, not the job's own. It doesn't survive reboot/logout, and it can mask a broken persistence fix by making `lsof`/`curl` checks pass anyway. Always check step 3's own-environment block before trusting it. Once the `.env` file approach above is in place, you don't need `setenv` at all — clear a leftover one with `launchctl unsetenv OLLAMA_HOST`.

## Client-side config (remote machines)

Point `opencode.jsonc`'s provider `baseURL` at the laptop's LAN IP, not `localhost`:
```jsonc
"ollama": { "options": { "baseURL": "http://192.168.100.11:11434/v1" } }
```
Find the LAN IP with `ifconfig | grep "inet 192.168"`.
