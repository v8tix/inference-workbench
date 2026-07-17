# inference-workbench

Local inference infrastructure for running **Kronk** and **Ollama** on a **macOS Apple Silicon** machine with a preset-based model setup.

---

## Engines

| Engine | Port | Backend | Models | Config |
|---|---|---|---|---|
| **Kronk** | 11435 | GGUF / Metal | Gemma 4 26B, Qwen3.6 35B | `kronk/` |
| **Ollama** | 11434 | MLX / Metal | North Mini Code 1.0, Qwen3.6 27B Coding | `ollama/` |

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
│   ├── docs/                 # Ollama guides
│   ├── modelfiles/           # Modelfiles for all 8 presets
│   ├── opencode/             # Ollama OpenCode config reference
│   └── .env
└── docs/                     # Engine-agnostic docs (model selection, etc.)
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
|---|---|---|---|---:|---:|---|
| `north-turbo` | North Mini Code 1.0 | Jun 2026 | mlx-nvfp4 | 32K | 20 GB | Ultra-fast iteration |
| `north-fast` | North Mini Code 1.0 | Jun 2026 | mlx-nvfp4 | 48K | 20 GB | Quick coding help |
| `north-standard` | North Mini Code 1.0 | Jun 2026 | mlx-nvfp4 | 88K | 20 GB | Daily default ⭐ |
| `north-deep` | North Mini Code 1.0 | Jun 2026 | mlx-mxfp8 | 32K | 31 GB | Hard debugging, architecture |
| `qwen36-fast` | Qwen3.6 27B Coding | Apr 2026 | mlx-nvfp4 | 64K | 20 GB | Alternative model, quick tasks |
| `qwen36-standard` | Qwen3.6 27B Coding | Apr 2026 | mlx-nvfp4 | 88K | 20 GB | Long sessions, second opinion ⭐ |
| `qwen36-deep` | Qwen3.6 27B Coding | Apr 2026 | mlx-nvfp4 | 64K | 20 GB | Hard problems, long answers |

### Setup

```bash
# Pull base models (all MLX — native Apple Silicon)
ollama pull north-mini-code-1.0:mlx-nvfp4   # 20 GB
ollama pull north-mini-code-1.0:mlx-mxfp8   # 31 GB
ollama pull qwen3.6:27b-coding-nvfp4         # 20 GB

# Build presets
ollama create north-turbo     -f ollama/modelfiles/Modelfile.north-turbo
ollama create north-fast      -f ollama/modelfiles/Modelfile.north-fast
ollama create north-standard  -f ollama/modelfiles/Modelfile.north-standard
ollama create north-deep      -f ollama/modelfiles/Modelfile.north-deep
ollama create qwen36-fast     -f ollama/modelfiles/Modelfile.qwen36-fast
ollama create qwen36-standard -f ollama/modelfiles/Modelfile.qwen36-standard
ollama create qwen36-deep     -f ollama/modelfiles/Modelfile.qwen36-deep
```

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
