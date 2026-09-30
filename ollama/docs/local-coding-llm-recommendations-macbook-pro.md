# Ollama Setup — Local Coding LLM (48 GB MacBook Pro)

> Default model: **Qwen3-Coder-Next REAP 48B** (`qwen3-coder-next-standard`)
> Model selection rationale: see `docs/coding-llm-recommendations-macbook-pro.md`
> How the coder-next presets were built: see `docs/qwen3-coder-next-build-guide.md`
> Preset details and tuning guide: see `ollama/docs/preset-guide.md`
> Service configuration: see `ollama/docs/runtime-config-guide.md`
> Updated: September 30, 2026

---

## Why Qwen3-Coder-Next

- 48.9B MoE with ~3B active parameters per token, so generation stays fast (~32 tok/s here) despite the size.
- The best-quality local coding model on this machine.
- Requantized from Q4_K_XL (33 GB) to **Q3_K_M (24 GB in GPU memory)**, which freed ~9 GB for context: 48K became 128K.
- Runs on GGUF/llama.cpp (Metal), not MLX. The MLX weights have broken int4 metadata and crash the MLX runner.

---

## Quick start

```bash
# 1. Download the Q4_K_XL GGUF (31 GiB)
HF_TOKEN="your_token" hf download lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF \
  --include "Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf" \
  --local-dir ~/.ollama/models/sources/qwen3-coder-next/

# 2. Requantize to Q3_K_M (~10 min; llama-quantize ships with Ollama)
SRC=~/.ollama/models/sources/qwen3-coder-next
llama-quantize --allow-requantize \
  $SRC/Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf \
  $SRC/Qwen3-Coder-Next-REAP-48B-A3B-Q3_K_M.gguf \
  Q3_K_M

# 3. Build the presets
ollama create qwen3-coder-next-standard -f ollama/modelfiles/Modelfile.qwen3-coder-next-standard
ollama create qwen3-coder-next-fast     -f ollama/modelfiles/Modelfile.qwen3-coder-next-fast
ollama create qwen3-coder-next-deep     -f ollama/modelfiles/Modelfile.qwen3-coder-next-deep

# 4. Make one active (updates ollama/.env and OpenCode's default model)
bash ollama/scripts/apply_preset.sh qwen3-coder-next-standard
```

Step 2 needs `--allow-requantize` because the FP16 original is ~96 GB and isn't downloaded. The Q4 to Q3 loss is small on a 48B model. Full explanation and troubleshooting: [qwen3-coder-next-build-guide.md](../../docs/qwen3-coder-next-build-guide.md).

---

## Presets

### Qwen3-Coder-Next (GGUF Q3_K_M, 24 GB) — primary

| Preset | ctx | Max output | Est. peak | Est. headroom | Best for |
|---|---:|---:|---:|---:|---|
| `qwen3-coder-next-standard` ⭐ | **128K** | 2,048 | 36.2 GiB | **1.2 GiB** | Daily default, large repos, multi-file refactors |
| `qwen3-coder-next-fast` | 88K | 1,024 | 32.4 GiB | 5.0 GiB | More headroom, quicker turnaround |
| `qwen3-coder-next-deep` | 64K | 4,096 | 30.1 GiB | 7.3 GiB | Long answers and deep reasoning |

All three use the same weights file, so Ollama stores them once. They differ only in `num_ctx` and `num_predict`. Sampling is shared: temperature 1.0, top_k 40, top_p 0.95.

> ⚠️ **`-standard` has the thinnest margin.** These figures are estimates, and on this machine the estimate has run optimistic: a formula-approved 128K context on `qwen38-standard` locked the machine up ([incident write-up](../../docs/qwen38-memory-incident-2026-08-15.md)). The coder-next rows are not validated under sustained load. If swap grows or memory pressure turns yellow, drop to `-fast`.

### Alternates (MLX)

| Preset | Base model | Quant | ctx | Weights | Best for |
|---|---|---|---:|---:|---|
| `qwen38-standard` | Qwen3.8 27B | mlx-nvfp4 | 88K | 18 GB | Vision-capable, smaller footprint |
| `qwen38-fast` | Qwen3.8 27B | mlx-nvfp4 | 64K | 18 GB | Quick tasks |
| `qwen38-deep` | Qwen3.8 27B | mlx-mxfp8 | 32K | 31 GB | Highest precision; leaves ~2 GiB headroom, run it alone |
| `qwen36-standard` | Qwen3.6 27B Coding | mlx-nvfp4 | 88K | 19 GB | Second opinion from another model family |
| `qwen36-fast` | Qwen3.6 27B Coding | mlx-nvfp4 | 64K | 19 GB | Quick tasks |
| `qwen36-deep` | Qwen3.6 27B Coding | mlx-nvfp4 | 64K | 19 GB | Long answers |

The Qwen3.8 presets need Ollama ≥ 0.32.12. Their base tags are `qwen3.8:27b-nvfp4` and `qwen3.8:27b-mxfp8`.

Switch presets with:

```bash
bash ollama/scripts/use_preset.sh
```

Only one model is kept in memory at a time (`OLLAMA_MAX_LOADED_MODELS=1`). Switching unloads the current one.

---

## Runtime config

Env vars live in `ollama/ollama.env`. `ollama/scripts/apply-runtime-config.sh` writes them to `~/.homebrew/services/ollama.env`, and Homebrew merges them into the generated launchd plist at `~/Library/LaunchAgents/sh.brew.ollama.plist`. **Don't edit the plist.** Homebrew regenerates it on every `brew services start/restart`, and its own formula default for the KV cache is `q8_0`.

| Variable | Value | Purpose |
|---|---|---|
| `OLLAMA_FLASH_ATTENTION` | `1` | Reduces memory pressure on long context |
| `OLLAMA_KV_CACHE_TYPE` | `q4_0` | Halves KV cache vs default precision. Required for the 128K budget |
| `OLLAMA_NUM_PARALLEL` | `1` | Prevents context memory multiplication |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | One model in memory at a time |
| `OLLAMA_GPU_OVERHEAD` | `2147483648` | 2 GiB hard memory reserve |
| `OLLAMA_KEEP_ALIVE` | `4h` | Keep the model loaded between requests |
| `OLLAMA_HOST` | `0.0.0.0:11434` | Listen on all interfaces (LAN access) |

See `runtime-config-guide.md` for how it works and how to apply changes.

---

## OpenCode integration

Provider type: `@ai-sdk/openai-compatible` (different from Kronk, which uses `api: "openai"`).

Config at `ollama/opencode/opencode.jsonc` (reference copy of `~/.config/opencode/opencode.jsonc`). Model IDs must match the **created model name** from `ollama create`, not the raw tag. `baseURL` points at this laptop's ethernet address, `http://192.168.100.41:11434/v1`. See `lan-exposure-persistent-setup.md`.

`apply_preset.sh` and `use_preset.sh` set OpenCode's default model to the chosen preset. The limits in OpenCode must match each Modelfile's `num_ctx` and `num_predict`:

| Preset | OpenCode context / output | Modelfile `num_ctx` / `num_predict` |
|---|---|---|
| `qwen3-coder-next-standard` | 131,072 / 2,048 | 131,072 / 2,048 |
| `qwen3-coder-next-fast` | 90,112 / 1,024 | 90,112 / 1,024 |
| `qwen3-coder-next-deep` | 65,536 / 4,096 | 65,536 / 4,096 |

Tool calls require `num_ctx ≥ 16K`, which all presets meet.

---

## Checking memory

```bash
ollama ps              # loaded model, size, context, CPU/GPU split
sysctl vm.swapusage    # swap in use — growing swap means reduce context
memory_pressure        # macOS pressure level
```

Apple Silicon shares one memory pool across Ollama, macOS, your IDE, Docker and the browser. The Metal limit is ~37.4 GiB. With `-standard` at 128K, close other memory-heavy apps first.
