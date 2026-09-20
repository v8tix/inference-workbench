# inference-workbench

Local inference infrastructure for running **Kronk** and **Ollama** on a **macOS Apple Silicon** machine with a preset-based model setup.

---

## Engines

| Engine | Port | Backend | Models | Config |
|---|---|---|---|---|---|
| **Kronk** | 11435 | GGUF / Metal | Gemma 4 26B, Qwen3.6 35B | `kronk/` |
| **Ollama** | 11434 | MLX + GGUF / Metal | North Mini Code 1.0, Qwen3.6 27B, Qwen3.8 27B, Qwen3-Coder-Next 48B | `ollama/` |

Both engines expose an OpenAI-compatible API and integrate with OpenCode via `~/.config/opencode/opencode.jsonc`.

---

## Repo structure

```
inference-workbench/
├── lib/                      # Shared shell libraries
│   └── colors.sh
├── kronk/                    # Kronk engine
│   ├── scripts/              # start, stop, restart, update, presets
│   ├── docs/                 # Kronk guides
│   ├── presets/              # Gemma tuning presets (YAML)
│   ├── opencode/             # Kronk OpenCode config reference
│   ├── kronk.model_config.yaml
│   └── .env
├── ollama/                   # Ollama engine
│   ├── scripts/              # start, stop, restart, presets
│   ├── docs/                 # Ollama guides + preset-guide
│   ├── modelfiles/           # Modelfiles for all presets
│   ├── models/               # Downloaded model weights (GGUF, safetensors)
│   ├── opencode/             # Ollama OpenCode config reference
│   └── .env
└── docs/                     # Engine-agnostic docs (model selection, troubleshooting)
```

---

## Kronk

### Scripts

| Script | What it does |
|---|---|
| `bash kronk/scripts/start.sh` | Start Kronk, wait for health, warm up model |
| `bash kronk/scripts/stop.sh` | Stop Kronk cleanly |
| `bash kronk/scripts/restart.sh` | Full stop/start cycle |
| `bash kronk/scripts/update.sh` | Check and install Kronk updates |
| `bash kronk/scripts/use_preset.sh` | Interactive preset picker |
| `bash kronk/scripts/apply_llm_profile.sh <preset>` | Apply preset and restart |

### Presets

| Preset | Context | Output | Notes |
|---|---:|---:|---|
| `gemma-turbo` | 32K | 512 | Fastest |
| `gemma-fast` | 32K | 1,024 | |
| `gemma-standard` | 64K | 2,048 | Daily default ⭐ |
| `gemma-deep` | 64K | 2,048 | Thinking on |
| `gemma-max` | 64K | 4,096 | Thinking on, longest output |

### Setup

```bash
cp kronk/.env.example kronk/.env
# Set KRONK_MODELS to match your active profile model
bash kronk/scripts/start.sh
```

Logs: `kronk/logs/`  
API: `http://localhost:11435`  
Guide: `kronk/docs/gemma_tunning_guide.md`

---

## Ollama

### Scripts

| Script | What it does |
|---|---|
| `bash ollama/scripts/start.sh` | Start Ollama service |
| `bash ollama/scripts/stop.sh` | Stop Ollama service |
| `bash ollama/scripts/restart.sh` | Restart Ollama service |
| `bash ollama/scripts/use_preset.sh` | Interactive preset picker |
| `bash ollama/scripts/apply_preset.sh <preset>` | Apply preset directly |

### Presets

| Preset | Model | Released | Quant | Context | Weights | Best for |
|---|---|---|---|---|---:|---:|---|
| `north-turbo` | North Mini Code 1.0 | Jun 2026 | mlx-nvfp4 | 32K | 20 GB | Ultra-fast iteration |
| `north-fast` | North Mini Code 1.0 | Jun 2026 | mlx-nvfp4 | 48K | 20 GB | Quick coding help |
| `north-standard` | North Mini Code 1.0 | Jun 2026 | mlx-nvfp4 | 88K | 20 GB | Daily default ⭐ |
| `north-deep` | North Mini Code 1.0 | Jun 2026 | mlx-mxfp8 | 32K | 31 GB | Hard debugging, architecture |
| `qwen36-fast` | Qwen3.6 27B Coding | Apr 2026 | mlx-nvfp4 | 64K | 20 GB | Alternative model, quick tasks |
| `qwen36-standard` | Qwen3.6 27B Coding | Apr 2026 | mlx-nvfp4 | 88K | 20 GB | Long sessions, second opinion ⭐ |
| `qwen36-deep` | Qwen3.6 27B Coding | Apr 2026 | mlx-nvfp4 | 64K | 20 GB | Hard problems, long answers |
| `qwen38-fast` | Qwen3.8 27B | Aug 2026 | gguf-q4 | 64K | 18 GB | Quick GGUF, vision-capable |
| `qwen38-standard` | Qwen3.8 27B | Aug 2026 | gguf-q4 | 88K | 18 GB | GGUF daily default ⭐ |
| `qwen38-deep` | Qwen3.8 27B | Aug 2026 | gguf-q4 | 32K | 18 GB | GGUF deep reasoning |
| `qwen3-coder-next-fast` | Qwen3-Coder-Next REAP 48B | Feb 2026 | gguf-q3 | 88K | 24 GB | Fast 48B coding |
| `qwen3-coder-next-standard` | Qwen3-Coder-Next REAP 48B | Feb 2026 | gguf-q3 | **128K** | 24 GB | Best quality ⭐ |
| `qwen3-coder-next-deep` | Qwen3-Coder-Next REAP 48B | Feb 2026 | gguf-q3 | 64K | 24 GB | Max output reasoning |

### Setup

```bash
# Pull MLX base models
ollama pull north-mini-code-1.0:mlx-nvfp4   # 20 GB
ollama pull north-mini-code-1.0:mlx-mxfp8   # 31 GB
ollama pull qwen3.6:27b-coding-nvfp4         # 20 GB

# Build MLX presets
ollama create north-turbo     -f ollama/modelfiles/Modelfile.north-turbo
ollama create north-fast      -f ollama/modelfiles/Modelfile.north-fast
ollama create north-standard  -f ollama/modelfiles/Modelfile.north-standard
ollama create north-deep      -f ollama/modelfiles/Modelfile.north-deep
ollama create qwen36-fast     -f ollama/modelfiles/Modelfile.qwen36-fast
ollama create qwen36-standard -f ollama/modelfiles/Modelfile.qwen36-standard
ollama create qwen36-deep     -f ollama/modelfiles/Modelfile.qwen36-deep

# Download GGUF base model for Qwen3-Coder-Next (31 GB)
hf download lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF \
  --include "Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf" \
  --local-dir ~/.ollama/models/sources/qwen3-coder-next/

# Requantize to Q3_K_M (22 GB) for better memory fit
llama-quantize --allow-requantize \
  ~/.ollama/models/sources/qwen3-coder-next/Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf \
  ~/.ollama/models/sources/qwen3-coder-next/Qwen3-Coder-Next-REAP-48B-A3B-Q3_K_M.gguf \
  Q3_K_M

# Build GGUF presets (from Q3_K_M)
ollama create qwen3-coder-next-standard -f ollama/modelfiles/Modelfile.qwen3-coder-next-standard
ollama create qwen3-coder-next-fast    -f ollama/modelfiles/Modelfile.qwen3-coder-next-fast
ollama create qwen3-coder-next-deep    -f ollama/modelfiles/Modelfile.qwen3-coder-next-deep
```

> Qwen3.8 GGUF presets use `ollama pull qwen3.8:27b` (see `ollama/modelfiles/Modelfile.qwen38-*`).

Ollama runs as a launchd service — see `ollama/docs/runtime-config-guide.md`.  
API: `http://localhost:11434`  
Guide: `ollama/docs/preset-guide.md`

---

## OpenCode integration

Both engines are registered in `~/.config/opencode/opencode.jsonc`.

- Kronk provider: `api: "openai"`, base URL `http://localhost:11435/v1`
- Ollama provider: `npm: "@ai-sdk/openai-compatible"`, base URL `http://localhost:11434/v1`

Reference copies live in `kronk/opencode/` and `ollama/opencode/`. The live config is at `~/.config/opencode/opencode.jsonc`.

---

## Notes

- macOS-only, Apple Silicon / Metal
- No CI, no build system, no test suite — bash orchestration only
- **MLX models** (North, Qwen3.6): native Apple Silicon MLX runner, fastest generation
- **GGUF models** (Qwen3.8, Qwen3-Coder-Next): llama.cpp/Metal, faster prefill, broader model availability
- Some HuggingFace MLX weights have broken quantization metadata — switch to GGUF when hit (see [mlx-runner-troubleshooting.md](docs/mlx-runner-troubleshooting.md))
