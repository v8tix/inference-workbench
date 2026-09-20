# 🎛️ Ollama Preset Guide

This guide covers the available presets and how to pick the right one for your work.

The local AI setup runs on two components:

- **Ollama** — the local inference server that loads the model and handles all requests
- **OpenCode** — the AI coding tool that talks to Ollama and manages your sessions

Each preset configures both sides at once: it sets what Ollama loads, and tells OpenCode how much context and output to budget per turn. You never need to touch either config directly — picking a preset is enough.

The idea is simple:

- some presets are optimized for **speed**
- some presets are optimized for **depth**
- the ladder mixes **smaller context** (faster) with **larger context** (deeper)
- the main tradeoff is **response speed vs reasoning depth vs answer length**

North and Qwen3.6 presets use the **MLX runner** — native Apple Silicon inference. Qwen3.8 and Qwen3-Coder-Next use **GGUF/llama.cpp** via Metal (see [mlx-vs-gguf.md](../../docs/mlx-vs-gguf.md) for why).

---

## 🎯 The preset ladder at a glance

| Preset | Model | Released | Quant | Family | Context | Max output | Weights | Coding score | Best for |
|---|---|---|---|---|---|---:|---:|---:|---|---|
| `north-turbo` | North Mini Code 1.0 | Jun 2026 | mlx-nvfp4 | Speed | 32K | 512 | 20 GB | 33.4 AA¹ | Ultra-fast iteration |
| `north-fast` | North Mini Code 1.0 | Jun 2026 | mlx-nvfp4 | Speed | 48K | 1,024 | 20 GB | 33.4 AA¹ | Quick coding help |
| `north-standard` | North Mini Code 1.0 | Jun 2026 | mlx-nvfp4 | Speed | 88K | 2,048 | 20 GB | 33.4 AA¹ | Daily default ⭐ |
| `north-deep` | North Mini Code 1.0 | Jun 2026 | mlx-mxfp8 | Depth | 32K | 4,096 | 31 GB | 33.4 AA¹ | Hard debugging, architecture |
| `qwen36-fast` | Qwen3.6 27B Coding | Apr 2026 | mlx-nvfp4 | Speed | 64K | 1,024 | 20 GB | 77.2% SWE² | Alternative model, quick tasks |
| `qwen36-standard` | Qwen3.6 27B Coding | Apr 2026 | mlx-nvfp4 | Speed | 88K | 2,048 | 20 GB | 77.2% SWE² | Long sessions, second opinion ⭐ |
| `qwen36-deep` | Qwen3.6 27B Coding | Apr 2026 | mlx-nvfp4 | Depth | 64K | 4,096 | 20 GB | 77.2% SWE² | Hard problems, long answers |
| `qwen38-standard` | Qwen3.8 27B | Aug 2026 | gguf-q4 | Speed | 88K | 2,048 | 18 GB | — | Larger model, fast GGUF ⭐ |
| `qwen38-fast` | Qwen3.8 27B | Aug 2026 | gguf-q4 | Speed | 64K | 1,024 | 18 GB | — | Budget context, quick tasks |
| `qwen38-deep` | Qwen3.8 27B | Aug 2026 | gguf-q4 | Depth | 32K | 4,096 | 18 GB | — | Longer answers, small context |
| `qwen3-coder-next-standard` | Qwen3-Coder-Next REAP 48B | Feb 2026 | gguf-q3 | Quality | **128K** | 2,048 | 24 GB | — | Best quality coding model ⭐ |
| `qwen3-coder-next-fast` | Qwen3-Coder-Next REAP 48B | Feb 2026 | gguf-q3 | Quality | 88K | 1,024 | 24 GB | — | Faster coding with 48B |
| `qwen3-coder-next-deep` | Qwen3-Coder-Next REAP 48B | Feb 2026 | gguf-q3 | Depth | 64K | 4,096 | 24 GB | — | Max output, deepest reasoning |

> ¹ Artificial Analysis Coding Index (higher = better, open model scale). ² SWE-bench Verified (% of real GitHub issues resolved).

---

## ⚡ North Mini Code presets

North Mini Code 1.0 is the primary model: 30B total params, ~3B active per token (MoE architecture), released June 2026. Trained specifically for agentic software engineering — native tool use, multi-step planning, code generation. Apache 2.0 license. Two quantizations available: mlx-nvfp4 (20 GB, faster) and mlx-mxfp8 (31 GB, higher precision). Both run 100% on Metal GPU via MLX runner.

### `north-turbo`

Use when you want the quickest possible back-and-forth.

- rapid iteration, short answers
- speed matters more than completeness
- 32K context keeps prefill fast

```
num_ctx: 32768 | num_predict: 512 | quant: mlx-nvfp4 | weights: 20 GB
```

### `north-fast`

Use when you still want a quick loop but need more room than turbo.

- fast coding help with more breathing space
- multiple files in context without switching to standard
- good default when standard feels like overkill

```
num_ctx: 49152 | num_predict: 1024 | quant: mlx-nvfp4 | weights: 20 GB
```

### `north-standard` ⭐

This is the safest preset to use as the normal daily default.

- covers most everyday coding tasks
- 88K context handles most codebases and agent trajectories safely
- balanced speed vs completeness

```
num_ctx: 90112 | num_predict: 2048 | quant: mlx-nvfp4 | weights: 20 GB
```

### `north-deep`

Use when quality of output matters more than speed.

- higher-precision weights (mlx-mxfp8 vs mlx-nvfp4)
- more room for longer, more complete answers
- hard debugging, architecture decisions, long refactors

```
num_ctx: 32768 | num_predict: 4096 | quant: mlx-mxfp8 | weights: 31 GB
```

> ⚠️ Uses 31 GB, peaks at ~34 GiB GPU memory (q4_0 KV cache). Context capped at 32K to stay within safe VRAM limit.

---

## 🟠 Qwen3.6 27B Coding presets

Qwen3.6 27B is the alternative MLX model: 27B dense params, released April 2026. SWE-bench Verified 77.2% — stronger than the 35B-A3B MoE variant (73.4%) due to better training. Runs natively via MLX runner, same 20 GB footprint as north-standard. Useful when North gives unsatisfying answers or you want a different model family's take. Thinking Preservation feature retains reasoning context across messages — good for iterative sessions.

### `qwen36-fast`

Use for quick tasks when you want Qwen3.6's perspective.

- 48K context, fast responses
- good for repo exploration, focused edits, quick questions
- same memory footprint as north-standard — easy to switch

```
num_ctx: 65536 | num_predict: 1024 | quant: mlx-nvfp4 | weights: 20 GB
```

### `qwen36-standard` ⭐

Use when North gives unsatisfying answers and you want a different model family's take.

- 88K context — same ceiling as north-standard, stays within GPU VRAM
- strong on multi-language codebases and frontend/repo-level reasoning
- good second opinion for architecture decisions or hard problems

```
num_ctx: 90112 | num_predict: 2048 | quant: mlx-nvfp4 | weights: 20 GB
```

### `qwen36-deep`

Use when you need Qwen3.6's longer, more complete answers.

- 64K context with maximum output budget (4K tokens)
- thinking mode active — retains reasoning context across turns
- hard problems where north-deep isn't available (memory tight)

```
num_ctx: 65536 | num_predict: 4096 | quant: mlx-nvfp4 | weights: 20 GB
```

---

## 🔵 Qwen3.8 27B presets

Qwen3.8 27B is a larger dense model (27B params, released August 2026) with vision support. Uses GGUF Q4_K_M quantization via llama.cpp/Metal — **not MLX**. Prefill is fast (~990 tok/s), generation is slower than MoE models (~27-37 tok/s). Vision capabilities allow image input alongside code. Good fallback when MLX models aren't meeting quality needs.

These presets are built from `qwen3.8:27b` (GGUF, not the nvfp4/mxfp8 MLX variants).

### `qwen38-fast`

Use for quick tasks with larger model quality.

- 64K context, budget output
- vision support (screenshots, diagrams)
- same 18 GB footprint as north-standard

```
num_ctx: 65536 | num_predict: 1024 | quant: gguf-q4 | weights: 18 GB
```

### `qwen38-standard` ⭐

Use when you want Qwen3.8's quality without MLX dependency.

- 88K context
- vision capabilities
- reliable GGUF backend — no MLX runner issues

```
num_ctx: 90112 | num_predict: 2048 | quant: gguf-q4 | weights: 18 GB
```

### `qwen38-deep`

Use for longer answers from Qwen3.8.

- 32K context with 4K output budget
- vision support

```
num_ctx: 32768 | num_predict: 4096 | quant: gguf-q4 | weights: 18 GB
```

---

## 🟢 Qwen3-Coder-Next REAP 48B presets

Qwen3-Coder-Next REAP is a 48.9B MoE model (48 total / ~3B active per token via REAP merging), released February 2026. Uses **GGUF Q3_K_M** via llama.cpp/Metal — requantized from the original Q4_K_XL to fit 128K context on this 48 GB machine.

Originally the Q4_K_XL (33 GB) could only handle 48K context before hitting the Metal limit. Requantizing to Q3_K_M (24 GB) freed 9 GB for KV cache, enabling 128K context with comfortable headroom.

Generation is ~32-34 tok/s (model-bound). Prefill is slower than Q4_K_XL due to requantization overhead (~190-400 tok/s vs ~530-670 tok/s).

### `qwen3-coder-next-fast`

Use when you want 48B model quality with faster turnaround.

- 88K context
- MoE fast generation (~3B active params)
- 24 GB weights + comfortable headroom

```
num_ctx: 90112 | num_predict: 1024 | quant: gguf-q3 | weights: 24 GB
```

### `qwen3-coder-next-standard` ⭐

Use for best-quality coding assistance on this machine.

- **128K context** — max ceiling without swap on 48 GB
- best reasoning quality of any local model
- good for complex architecture, multi-file refactors

```
num_ctx: 131072 | num_predict: 2048 | quant: gguf-q3 | weights: 24 GB
```

### `qwen3-coder-next-deep`

Use for the deepest reasoning available locally.

- 64K context with 4K output budget
- longest possible answers from the best local model

```
num_ctx: 65536 | num_predict: 4096 | quant: gguf-q3 | weights: 24 GB
```

---

## 🧭 Simple recommendation

If you don't know where to start:

1. Start with **`north-standard`** ⭐
2. Move down to **`north-fast`** or **`north-turbo`** if the loop feels too slow
3. Move up to **`north-deep`** when harder reasoning or longer answers are genuinely needed
4. Switch to **`qwen36-standard`** when you want a different model family's perspective
5. Use **`qwen36-deep`** for long answers from Qwen when memory is already at 31 GB (north-deep running)
6. Try **`qwen38-standard`** for vision-capable GGUF-based model
7. Move to **`qwen3-coder-next-standard`** for the best quality local model (33 GB, needs headroom)

---

## 💡 Speed vs Depth

| Want | Use |
|---|---|---|
| Fast loop, short answers | `north-turbo` or `north-fast` |
| Normal daily coding | `north-standard` ⭐ |
| Hard problems, long answers | `north-deep` |
| Alternative model, quick | `qwen36-fast` |
| Alternative model, long session | `qwen36-standard` |
| Long answers from Qwen | `qwen36-deep` |
| GGUF-based, vision-capable | `qwen38-standard` |
| Best quality coding | `qwen3-coder-next-standard` ⭐ |

---

## ⚙️ What each preset actually configures

| Preset | Context (tokens) | Max output | Quant | Weights |
|---|---|---:|---:|---|---:|
| `north-turbo` | 32,768 | 512 | mlx-nvfp4 | 20 GB |
| `north-fast` | 49,152 | 1,024 | mlx-nvfp4 | 20 GB |
| `north-standard` | 90,112 | 2,048 | mlx-nvfp4 | 20 GB |
| `north-deep` | 32,768 | 4,096 | mlx-mxfp8 | 31 GB |
| `qwen36-fast` | 65,536 | 1,024 | mlx-nvfp4 | 20 GB |
| `qwen36-standard` | 90,112 | 2,048 | mlx-nvfp4 | 20 GB |
| `qwen36-deep` | 65,536 | 4,096 | mlx-nvfp4 | 20 GB |
| `qwen38-fast` | 65,536 | 1,024 | gguf-q4 | 18 GB |
| `qwen38-standard` | 90,112 | 2,048 | gguf-q4 | 18 GB |
| `qwen38-deep` | 32,768 | 4,096 | gguf-q4 | 18 GB |
| `qwen3-coder-next-fast` | 88,192 | 1,024 | gguf-q3 | 24 GB |
| `qwen3-coder-next-standard` | 131,072 | 2,048 | gguf-q3 | 24 GB |
| `qwen3-coder-next-deep` | 65,536 | 4,096 | gguf-q3 | 24 GB |

### OpenCode ↔ Ollama alignment

OpenCode declares context and output limits per model. These must match what the Modelfile sets — a mismatch causes context overflow or truncated answers.

| Preset | OpenCode context | Modelfile num_ctx | OpenCode output | Modelfile num_predict |
|---|---|---:|---:|---:|---:|
| `north-turbo` | 32,768 | 32,768 | 512 | 512 |
| `north-fast` | 49,152 | 49,152 | 1,024 | 1,024 |
| `north-standard` | 90,112 | 90,112 | 2,048 | 2,048 |
| `north-deep` | 32,768 | 32,768 | 4,096 | 4,096 |
| `qwen36-fast` | 65,536 | 65,536 | 1,024 | 1,024 |
| `qwen36-standard` | 90,112 | 90,112 | 2,048 | 2,048 |
| `qwen36-deep` | 65,536 | 65,536 | 4,096 | 4,096 |
| `qwen38-fast` | 65,536 | 65,536 | 1,024 | 1,024 |
| `qwen38-standard` | 90,112 | 90,112 | 2,048 | 2,048 |
| `qwen38-deep` | 32,768 | 32,768 | 4,096 | 4,096 |
| `qwen3-coder-next-fast` | 90,112 | 90,112 | 1,024 | 1,024 |
| `qwen3-coder-next-standard` | 131,072 | 131,072 | 2,048 | 2,048 |
| `qwen3-coder-next-deep` | 65,536 | 65,536 | 4,096 | 4,096 |

---

## 🔄 How to switch presets

Interactive picker — shows all presets, marks the active one, applies your selection:

```bash
bash ollama/scripts/use_preset.sh
```

Apply a specific preset directly:

```bash
bash ollama/scripts/apply_preset.sh north-standard
```

Both commands stop the current model, rebuild with the new Modelfile, and sync OpenCode's default model.
