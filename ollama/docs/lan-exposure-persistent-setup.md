# Exposing Ollama on the LAN (persistent across reboot/restart)

By default homebrew's ollama binds to `localhost:11434` only — unreachable from other
machines on the network. This doc covers making it listen on all interfaces
(`0.0.0.0:11434`) in a way that survives both `brew services restart ollama` and a full
laptop reboot.

## Why two fixes are needed

- `launchctl setenv OLLAMA_HOST=...` — takes effect immediately, but is **session-only**.
  Lost on reboot/logout, and even a `brew services restart` can leave it in place only
  by luck (any regeneration of the launchd plist ignores it).
- The actual persistent source of truth is the **launchd plist**, and brew regenerates
  `~/Library/LaunchAgents/homebrew.mxcl.ollama.plist` from a template that lives inside
  the versioned Cellar path:
  `/opt/homebrew/Cellar/ollama/<version>/homebrew.mxcl.ollama.plist`

Editing only the LaunchAgents copy works until the next `brew services restart`, which
overwrites it from the Cellar template. **Both files must be edited** (or at minimum the
Cellar template, since that's what regenerates the other).

## Steps

1. Find the current Cellar template:

   ```bash
   find /opt/homebrew/Cellar/ollama -name "*.plist"
   # e.g. /opt/homebrew/Cellar/ollama/0.32.1/homebrew.mxcl.ollama.plist
   ```

2. Add `OLLAMA_HOST` to the `EnvironmentVariables` dict in that file:

   ```xml
   <key>EnvironmentVariables</key>
   <dict>
       <key>OLLAMA_FLASH_ATTENTION</key>
       <string>1</string>
       <key>OLLAMA_KV_CACHE_TYPE</key>
       <string>q4_0</string>
       <key>OLLAMA_HOST</key>
       <string>0.0.0.0:11434</string>
   </dict>
   ```

3. Also patch the live copy so it's correct immediately without a full restart cycle:

   ```bash
   # same edit applied to:
   ~/Library/LaunchAgents/homebrew.mxcl.ollama.plist
   ```

4. Restart the service so launchd reloads it:

   ```bash
   brew services stop ollama
   brew services start ollama
   ```

5. Verify it's bound to all interfaces, not just localhost:

   ```bash
   lsof -iTCP:11434 -sTCP:LISTEN -P
   # good:  ollama ... TCP *:11434 (LISTEN)
   # bad:   ollama ... TCP localhost:11434 (LISTEN)
   ```

6. Verify from the remote machine:

   ```bash
   curl -s http://<laptop-lan-ip>:11434/api/tags
   ```

## Gotcha: `brew upgrade ollama`

An upgrade creates a **new versioned Cellar directory** (e.g. `0.33.0/`) with a fresh,
unpatched plist template. The next service restart after an upgrade will silently drop
`OLLAMA_HOST` again. Re-apply step 1–4 after any ollama upgrade.

Quick way to check if the fix is still in place after an upgrade/restart:

```bash
lsof -iTCP:11434 -sTCP:LISTEN -P | grep -q '\*:11434' && echo OK || echo "LOCALHOST ONLY - re-patch"
```

## Client-side config (opencode.jsonc on remote machines)

Point provider `baseURL` at the laptop's LAN IP, not `localhost`:

```jsonc
"ollama": {
  "options": {
    "baseURL": "http://192.168.100.11:11434/v1"
  }
}
```

Find the laptop's LAN IP with:

```bash
ifconfig | grep "inet 192.168"
```
