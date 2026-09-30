# inference-workbench

Local LLM inference for coding on a **macOS Apple Silicon** laptop (MacBook Pro M5 Pro, 48 GB unified memory), run with **Ollama** and a preset-based model setup. Pick a preset, and the scripts build the model, set the context and output limits, and point OpenCode at it.

**Default preset: `qwen3-coder-next-standard`** — Qwen3-Coder-Next REAP 48B, 128K context.

| | |
|---|---|
| Engine | Ollama (launchd service via Homebrew), port `11434` |
| Runners | MLX (Qwen3.6, Qwen3.8) and llama.cpp / Metal (Qwen3-Coder-Next) |
| API | OpenAI-compatible at `/v1` |
| Client | OpenCode, configured in `~/.config/opencode/opencode.jsonc` |

---

## Quick start

```bash
bash ollama/scripts/start.sh        # apply runtime config, start Ollama, load the active preset
bash ollama/scripts/use_preset.sh   # pick a different preset interactively
bash ollama/scripts/status.sh       # what is running and loaded
```

The active preset is `OLLAMA_ACTIVE_PRESET` in `ollama/.env`. Setting up the models for the first time: see [Setup](#setup).

---

## Presets

| Preset | Model | Runner / quant | Context | Max output | Weights | Best for |
|---|---|---|---:|---:|---:|---|
| `qwen3-coder-next-standard` ⭐ | Qwen3-Coder-Next REAP 48B | GGUF Q3_K_M | **128K** | 2,048 | 24 GB | Daily default, large repos |
| `qwen3-coder-next-fast` | Qwen3-Coder-Next REAP 48B | GGUF Q3_K_M | 88K | 1,024 | 24 GB | More headroom, quicker turnaround |
| `qwen3-coder-next-deep` | Qwen3-Coder-Next REAP 48B | GGUF Q3_K_M | 64K | 4,096 | 24 GB | Long answers, deep reasoning |
| `qwen38-standard` | Qwen3.8 27B | MLX nvfp4 | 88K | 2,048 | 18 GB | Vision-capable, smaller footprint |
| `qwen38-fast` | Qwen3.8 27B | MLX nvfp4 | 64K | 1,024 | 18 GB | Quick tasks |
| `qwen38-deep` | Qwen3.8 27B | MLX mxfp8 | 32K | 4,096 | 31 GB | Highest precision; run it alone |
| `qwen36-standard` | Qwen3.6 27B Coding | MLX nvfp4 | 88K | 2,048 | 19 GB | Second opinion from another model family |
| `qwen36-fast` | Qwen3.6 27B Coding | MLX nvfp4 | 64K | 1,024 | 19 GB | Quick tasks |
| `qwen36-deep` | Qwen3.6 27B Coding | MLX nvfp4 | 64K | 4,096 | 19 GB | Long answers |
| `qwen36-turbo` | Qwen3.6 27B Coding | MLX nvfp4 | 32K | 512 | 19 GB | Fastest, small context (build on demand) |

All presets use temperature 0.2, except Qwen3-Coder-Next, which uses 1.0 (both with `top_k 40`, `top_p 0.95`). Only one model is kept in memory at a time.

> ⚠️ **Memory margins are thin.** The GPU can use about 37.4 GiB of the 48 GB. `qwen3-coder-next-standard` has an estimated ~1.2 GiB of headroom at 128K, and `qwen38-deep` about 2 GiB. These are estimates, and real use has run well above them: see [the 2026-08-15 incident](docs/qwen38-memory-incident-2026-08-15.md). If swap grows or memory pressure turns yellow, switch to a `-fast` preset.

Details per preset: [ollama/docs/preset-guide.md](ollama/docs/preset-guide.md).

---

## Setup

### Qwen3.8 and Qwen3.6 (MLX)

```bash
ollama pull qwen3.6:27b-coding-nvfp4   # 19 GB
ollama pull qwen3.8:27b-nvfp4          # 18 GB (needs Ollama >= 0.32.12)
ollama pull qwen3.8:27b-mxfp8          # 31 GB

for p in qwen36-fast qwen36-standard qwen36-deep qwen38-fast qwen38-standard qwen38-deep; do
  ollama create $p -f ollama/modelfiles/Modelfile.$p
done
```

### Qwen3-Coder-Next (GGUF)

The weights are downloaded as Q4_K_XL (31 GiB) and requantized to Q3_K_M (24 GB in GPU memory). That frees ~9 GB for context: 48K became 128K.

```bash
# 1. Download
hf download lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF \
  --include "Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf" \
  --local-dir ~/.ollama/models/sources/qwen3-coder-next/

# 2. Requantize (llama-quantize ships with Ollama; ~10 min)
SRC=~/.ollama/models/sources/qwen3-coder-next
llama-quantize --allow-requantize \
  $SRC/Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf \
  $SRC/Qwen3-Coder-Next-REAP-48B-A3B-Q3_K_M.gguf \
  Q3_K_M

# 3. Build the presets
for p in qwen3-coder-next-standard qwen3-coder-next-fast qwen3-coder-next-deep; do
  ollama create $p -f ollama/modelfiles/Modelfile.$p
done
```

`--allow-requantize` is needed because the FP16 original (~96 GB) isn't downloaded. The weights live outside the repo, in `~/.ollama/models/sources/`. Full story and troubleshooting: [docs/qwen3-coder-next-build-guide.md](docs/qwen3-coder-next-build-guide.md).

### Make a preset active

```bash
bash ollama/scripts/apply_preset.sh qwen3-coder-next-standard
```

This builds the model if missing, sets `OLLAMA_ACTIVE_PRESET` in `ollama/.env`, and sets OpenCode's default model.

---

## Scripts

| Script | What it does |
|---|---|
| `bash ollama/scripts/start.sh` | Apply runtime config, make sure Ollama is running, load the active preset |
| `bash ollama/scripts/stop.sh` | Unload the active model from memory |
| `bash ollama/scripts/restart.sh` | Stop, then reload the active preset |
| `bash ollama/scripts/status.sh` | Show whether Ollama is running and which models are loaded |
| `bash ollama/scripts/use_preset.sh` | Interactive preset picker |
| `bash ollama/scripts/apply_preset.sh <preset> [--rebuild]` | Apply a preset directly; `--rebuild` recreates the model |
| `bash ollama/scripts/apply-runtime-config.sh` | Write `ollama/ollama.env` to Homebrew's services env file and restart the service |

The scripts run on macOS's default bash 3.2.

---

## Runtime config

Ollama runs as a launchd service managed by Homebrew (`brew services`). Its environment comes from `ollama/ollama.env`:

| Variable | Value | Purpose |
|---|---|---|
| `OLLAMA_KV_CACHE_TYPE` | `q4_0` | Smaller KV cache; Homebrew's own default is `q8_0` |
| `OLLAMA_FLASH_ATTENTION` | `1` | Lower memory pressure on long context |
| `OLLAMA_NUM_PARALLEL` | `1` | One request at a time |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | One model in memory |
| `OLLAMA_GPU_OVERHEAD` | `2147483648` | 2 GiB hard memory reserve |
| `OLLAMA_KEEP_ALIVE` | `4h` | Keep the model loaded between requests |
| `OLLAMA_HOST` | `0.0.0.0:11434` | Listen on all interfaces (LAN access) |

To change a value, edit `ollama/ollama.env` and run `bash ollama/scripts/apply-runtime-config.sh`. **Don't edit the launchd plist:** Homebrew regenerates it from the formula plus `~/.homebrew/services/ollama.env` on every `brew services start/restart`, so hand edits are lost. See [ollama/docs/runtime-config-guide.md](ollama/docs/runtime-config-guide.md).

---

## OpenCode integration

- Provider: `@ai-sdk/openai-compatible`, base URL `http://192.168.100.41:11434/v1` (this laptop's ethernet address; `localhost` works for sessions on the laptop itself).
- Live config: `~/.config/opencode/opencode.jsonc`. Reference copy: [ollama/opencode/opencode.jsonc](ollama/opencode/opencode.jsonc).
- Model IDs are the **created model names** (for example `qwen3-coder-next-standard`), not the raw Ollama tags.
- Each model's `limit.context` and `limit.output` in OpenCode must equal the Modelfile's `num_ctx` and `num_predict`. A mismatch causes context overflow or truncated answers.
- `use_preset.sh` and `apply_preset.sh` set OpenCode's default model; they skip that step, with a warning, if the config isn't valid JSON for `jq` (a trailing comma, for example).

LAN access and the ethernet address: [ollama/docs/lan-exposure-persistent-setup.md](ollama/docs/lan-exposure-persistent-setup.md).

---

## Repo structure

```
inference-workbench/
├── ollama/
│   ├── scripts/        # start, stop, restart, status, presets, runtime config
│   ├── modelfiles/     # one Modelfile per preset
│   ├── docs/           # Ollama guides
│   ├── opencode/       # reference OpenCode config
│   ├── crush/          # reference Crush config
│   ├── ollama.env      # runtime environment (applied to the Homebrew service)
│   └── .env            # active preset
├── docs/               # model selection, hardware, benchmarks, troubleshooting
├── opencode/           # general OpenCode MCP/tooling config
├── prompts/            # research prompts used to choose models
├── scripts/            # sync-opencode-skills.sh
└── lib/                # shared shell helpers
```

---

## Docs

**Start here**

- [ollama/docs/preset-guide.md](ollama/docs/preset-guide.md) — what each preset is for and how it is configured
- [ollama/docs/local-coding-llm-recommendations-macbook-pro.md](ollama/docs/local-coding-llm-recommendations-macbook-pro.md) — setup with the coder-next presets
- [docs/coding-llm-recommendations-macbook-pro.md](docs/coding-llm-recommendations-macbook-pro.md) — model selection and context strategy

**Memory and performance**

- [docs/hardware.md](docs/hardware.md) — what fits in 48 GB, and why the estimates are optimistic
- [docs/qwen38-memory-incident-2026-08-15.md](docs/qwen38-memory-incident-2026-08-15.md) — the out-of-memory incident behind the context limits
- [docs/performance-comparison.md](docs/performance-comparison.md) — prefill and generation measurements
- [docs/mlx-vs-gguf.md](docs/mlx-vs-gguf.md) — MLX vs GGUF trade-offs

**Models**

- [docs/qwen3-coder-next-build-guide.md](docs/qwen3-coder-next-build-guide.md) — how the coder-next presets were built
- [ollama/docs/qwen3-coder-next-guide.md](ollama/docs/qwen3-coder-next-guide.md) — coder-next setup reference
- [docs/qwen36-params-guide.md](docs/qwen36-params-guide.md) — Qwen3.6 parameters explained
- [docs/llmfit-model-fit.md](docs/llmfit-model-fit.md) — `llmfit` results for this machine

**Operations**

- [ollama/docs/runtime-config-guide.md](ollama/docs/runtime-config-guide.md) — how the service is configured and why the plist isn't edited
- [ollama/docs/lan-exposure-persistent-setup.md](ollama/docs/lan-exposure-persistent-setup.md) — exposing Ollama on the LAN
- [docs/mlx-runner-troubleshooting.md](docs/mlx-runner-troubleshooting.md) — MLX runner crashes
- [ollama/docs/structured-output-support.md](ollama/docs/structured-output-support.md) — JSON-schema output
- [ollama/docs/crush-skills-guide.md](ollama/docs/crush-skills-guide.md) — Crush skills configuration

---

## Notes

- macOS only, Apple Silicon / Metal.
- No CI, build system or test suite: bash orchestration only.
- **MLX models** (Qwen3.6, Qwen3.8) use Ollama's native Apple Silicon runner. **GGUF models** (Qwen3-Coder-Next) use llama.cpp/Metal, which has faster prefill and broader model availability.
- Some Hugging Face MLX weights have broken quantization metadata. The Qwen3-Coder-Next MLX build crashes on load, so the GGUF build is used.
