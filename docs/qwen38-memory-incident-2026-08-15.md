# Memory incident: qwen38-standard at 128K (2026-08-15)

Why `qwen38-standard` runs at 90,112 tokens (88K) and not 131,072, what was broken, and what to take from it when sizing context for any model on this 48 GB Mac.

## What happened

`qwen38-standard` originally shipped with `num_ctx 131072`. The KV-cache formula in [hardware.md](hardware.md) scored it safe with ~7 GiB to spare. In real use, after a handful of short test prompts, Ollama's peak memory climbed to 38 GiB and swap hit 98%. The machine locked up until the client (OpenCode) was stopped. Ollama itself never crashed.

## Root causes (both fixed)

1. **`OLLAMA_KV_CACHE_TYPE` was silently running `q8_0`**, twice the memory the `q4_0` math assumes. The plist-based runtime config never applied: this Homebrew install uses the JSON API tap, so `brew services restart` regenerates the launchd job from Homebrew's cache and ignores plist edits. Fix: `apply-runtime-config.sh` now writes `~/.homebrew/services/ollama.env`. See [runtime-config-guide.md](../ollama/docs/runtime-config-guide.md).
2. **Docker Desktop's VM was set to 40 GB of the 48 GB machine** and competed with Ollama for the same unified memory. It was reduced to 12 GB.

Guard-rails that were documented but never enforced now are: `OLLAMA_MAX_LOADED_MODELS=1`, `OLLAMA_NUM_PARALLEL=1` and `OLLAMA_GPU_OVERHEAD=2147483648` (a 2 GiB hard reserve).

## Re-test after the fixes

A genuine 68,608-token coding session (76% of the 90,112 ceiling) completed, but peaked at **39.01 GiB**. That is about **59% above** what the formula predicts at that token count.

**Decision:** keep `qwen38-standard` at 90,112. Even with every known bug fixed there is little real headroom, so don't raise it without new evidence.

## Lessons

- Treat `safe_ctx = (37.4 GiB - weights_GiB) / 0.095 GiB × 1000` as optimistic. It assumes the full 37.4 GiB is free at request time and undercounts real use.
- The 0.095 GiB/1K figure was measured on the dense Qwen 27B models. It does **not** describe other architectures.
- Verify the setting that's actually running, not the one you declared:
  ```bash
  launchctl print gui/$(id -u)/homebrew.mxcl.ollama | grep -A12 "environment = {"
  ```
  Read the job's own `environment` block. `inherited environment` can hide a stale `launchctl setenv`.
- Watch `ollama ps`, `sysctl vm.swapusage` and `memory_pressure` under real sustained load, not a quick test.

## Does this affect qwen3-coder-next?

Yes, as a warning. [qwen3-coder-next-build-guide.md](qwen3-coder-next-build-guide.md) runs `-standard` at 128K with 1.2 GiB of headroom by the same style of estimate. That is the same ceiling and a thinner margin than the one that failed here. Its KV figures come from a different model, so the 59% gap isn't proven for it, but nobody has measured it under sustained load. Validate before relying on it.
