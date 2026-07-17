# Ollama Setup — Local Coding LLM (48 GB MacBook Pro)

> Model selection rationale: see `docs/coding-llm-recommendations-macbook-pro.md`  
> Preset details and tuning guide: see `ollama/docs/preset-guide.md`  
> Service configuration: see `ollama/docs/runtime-config-guide.md`  
> Updated: July 16, 2026

---

## Quick start

```bash
# Pull all base models
ollama pull north-mini-code-1.0:mlx-nvfp4   # 20 GB — north-turbo/fast/standard
ollama pull north-mini-code-1.0:mlx-mxfp8   # 31 GB — north-deep
ollama pull qwen3.6:27b-coding-nvfp4         # 20 GB — qwen36-fast/standard/deep

# Build all presets
ollama create north-turbo      -f ollama/modelfiles/Modelfile.north-turbo
ollama create north-fast       -f ollama/modelfiles/Modelfile.north-fast
ollama create north-standard   -f ollama/modelfiles/Modelfile.north-standard
ollama create north-deep       -f ollama/modelfiles/Modelfile.north-deep
ollama create qwen36-fast      -f ollama/modelfiles/Modelfile.qwen36-fast
ollama create qwen36-standard  -f ollama/modelfiles/Modelfile.qwen36-standard
ollama create qwen36-deep      -f ollama/modelfiles/Modelfile.qwen36-deep
```

All presets use MLX runner (native Apple Silicon). No GGUF/llama.cpp.

---

## Presets

| Preset | Base model | Quant | ctx | Weights | Best for |
|---|---|---|---:|---:|---|
| `north-turbo` | North Mini Code 1.0 | mlx-nvfp4 | 32K | 20 GB | Ultra-fast iteration |
| `north-fast` | North Mini Code 1.0 | mlx-nvfp4 | 48K | 20 GB | Quick coding help |
| `north-standard` | North Mini Code 1.0 | mlx-nvfp4 | 88K | 20 GB | Daily default ⭐ |
| `north-deep` | North Mini Code 1.0 | mlx-mxfp8 | 32K | 31 GB | Hard debugging, architecture |
| `qwen36-fast` | Qwen3.6 27B Coding | mlx-nvfp4 | 64K | 20 GB | Alternative model, quick tasks |
| `qwen36-standard` | Qwen3.6 27B Coding | mlx-nvfp4 | 88K | 20 GB | Long sessions, second opinion ⭐ |
| `qwen36-deep` | Qwen3.6 27B Coding | mlx-nvfp4 | 64K | 20 GB | Hard problems, long answers |

Context limits are calibrated against observed GPU memory usage on this hardware — see `preset-guide.md` for rationale.

---

## Runtime config

Env vars set via launchd plist at `~/Library/LaunchAgents/homebrew.mxcl.ollama.plist`:

| Variable | Value | Purpose |
|---|---|---|
| `OLLAMA_FLASH_ATTENTION` | `1` | Reduces memory pressure on long context |
| `OLLAMA_KV_CACHE_TYPE` | `q8_0` | Shrinks KV cache vs default precision |
| `OLLAMA_NUM_PARALLEL` | `1` | Prevents context memory multiplication |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | One model in memory at a time |

See `runtime-config-guide.md` for how to edit and reload the plist.

---

## OpenCode integration

Provider type: `@ai-sdk/openai-compatible` (different from Kronk which uses `api: "openai"`).

Config at `ollama/opencode/opencode.jsonc`. Model IDs must match the **created model name** from `ollama create`, not the raw tag. Tool calls require `num_ctx ≥ 16K` — covered by all presets.

```bash
ollama ps   # check loaded model and memory usage
```
