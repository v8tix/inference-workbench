# Coding LLM Recommendations — 48 GB MacBook Pro (M5 Pro)

> Workload: agentic coding, repo exploration, multi-file edits  
> KV cache: q4_0 (configurable via `ollama/ollama.env`)  
> Updated: September 20, 2026

---

## Recommended models

| Priority | Model | Weights | Working ctx |
|---|---|---|---:|---:|
| **Primary** | North Mini Code 1.0 (`mlx-mxfp8`) | 31 GB | 128K |
| **Balanced** ⭐ | North Mini Code 1.0 (`mlx-nvfp4`) | 20 GB | 128K |
| **Best quality** | Qwen3-Coder-Next REAP 48B (`Q3_K_M GGUF`) | 24 GB | **128K** |
| **GGUF daily** | Qwen3.8 27B (`Q4_K_M GGUF`) | 18 GB | 88K |
| **Memory-efficient** | Devstral Small 2 (`24b`) | 15 GB | 64K–128K |

Start with Balanced (⭐). Move to Best quality for hard tasks — the Q3_K_M quant now fits 128K context comfortably at 24 GB.

---

## Models evaluated and excluded

| Model | Reason |
|---|---|---|
| Kimi K2.7 Code (1.04T) | Cloud-only — no local inference |
| Devstral 2 (123B) | ~75 GB — exceeds budget |
| Qwen3-Coder 480B | 290 GB — exceeds budget |
| Qwen3-Coder 30B-A3B | Superseded by Qwen3-Coder-Next REAP 48B |
| Qwen2.5-Coder 32B | Superseded by Qwen3-Coder-Next REAP 48B |

---

## Why North Mini Code 1.0

| Factor | Detail |
|---|---|
| Architecture | 30B total / ~3B active per token (MoE) |
| Agentic training | Tool use, multi-file edits, long trajectories |
| Context | 488K validated; use 128K working |
| Apple Silicon | MLX quantizations (`mlx-mxfp8`, `mlx-nvfp4`) |
| License | Apache 2.0 |
| Released | June 2026 |

---

## Context strategy

KV cache at q4_0 grows at ~0.095 GiB per 1K tokens (empirical). With 37.4 GiB available for Metal:

```
safe_ctx = (37.4 GiB - weights_GiB) / 0.095 GiB × 1000
```

### Memory budget by preset

| Preset | Weights | ctx | KV cache | Peak memory | Headroom |
|---|---|---|---:|---:|---:|
| `north-turbo` | 20 GB | 32K | 3.0 GiB | 23.0 GiB | 14.4 GiB |
| `north-fast` | 20 GB | 49K | 4.7 GiB | 24.7 GiB | 12.7 GiB |
| `north-standard` | 20 GB | 90K | 8.6 GiB | 28.6 GiB | 8.8 GiB |
| `north-deep` | 31 GB | 32K | 3.0 GiB | 34.0 GiB | 3.4 GiB |
| `qwen36-fast` | 20 GB | 65K | 6.2 GiB | 26.2 GiB | 11.2 GiB |
| `qwen36-standard` | 20 GB | 90K | 8.6 GiB | 28.6 GiB | 8.8 GiB |
| `qwen36-deep` | 20 GB | 65K | 6.2 GiB | 26.2 GiB | 11.2 GiB |
| `qwen38-fast` | 18 GB | 65K | 6.2 GiB | 24.2 GiB | 13.2 GiB |
| `qwen38-standard` | 18 GB | 90K | 8.6 GiB | 26.6 GiB | 10.8 GiB |
| `qwen38-deep` | 18 GB | 32K | 3.0 GiB | 21.0 GiB | 16.4 GiB |
| `qwen3-coder-next-fast` | 24 GB | 88K | 8.4 GiB | 32.4 GiB | 5.0 GiB ✅ |
| `qwen3-coder-next-standard` ⭐ | 24 GB | 128K | 12.2 GiB | 36.2 GiB | 1.2 GiB ✅ |
| `qwen3-coder-next-deep` | 24 GB | 64K | 6.1 GiB | 30.1 GiB | 7.3 GiB ✅ |

All presets fit within the 37.4 GiB Metal limit. The 48B model at Q3_K_M (24 GB) now comfortably supports 128K context.

### Context sizing guide

| ctx | Use | Prefill speed |
|---:|---|---|
| 32K | Small changes, focused debugging | Fastest |
| 49K–65K | Normal repo work, a few related files | Fast |
| 90K | Large changes, long agent trajectories | Moderate |
| 128K | Very large repos, multi-hour sessions | Slower prefill |

Start at 90K. Only drop to 49K/65K if prefill feels too slow. Only increase to 128K if the agent consistently loses relevant context.

### Can I increase qwen3-coder-next-standard beyond 128K?

That's the safe ceiling for 24 GB weights at Q3_K_M. To go higher, quantize further to Q2_K (~17 GB, 215K ctx) — the original GGUF from `lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF` can be requantized with `llama-quantize`.

See [qwen3-coder-next-guide.md](../ollama/docs/qwen3-coder-next-guide.md#quantization) for details.

> ⚠️ Higher context = slower prefills. Each request pays the cost of processing the full accumulated context. Only increase when you actually need the room.

### When NOT to increase context

- Prefill takes >30s → you're past the comfort zone, not under it
- Agent is slow but doesn't forget context → your problem is retrieval, not context size
- System-wide memory pressure is yellow/red → reduce context instead

---

## Memory pressure guide

Apple Silicon uses unified memory — Ollama, macOS, IDE, Docker, browser all share the same pool.
Metal limit: ~37.4 GiB. KV cache at q4_0 (~0.095 GiB/K).

| State | Action |
|---|---|
| Pressure green | Continue |
| Pressure yellow | Reduce ctx or stop containers |
| Swap growing | Reduce ctx before switching models |
| Prompt ingestion slow | Load fewer files |
| macOS unresponsive | Stop model, switch to memory-efficient preset |

```bash
memory_pressure      # macOS pressure level
sysctl vm.swapusage  # swap usage
ollama ps             # model memory in GPU
```

---

## Sources

- [North Mini Code 1.0 — Ollama](https://ollama.com/library/north-mini-code-1.0)
- [North Mini Code — Cohere Labs model card](https://huggingface.co/CohereLabs/North-Mini-Code-1.0)
- [Devstral Small 2 — Ollama](https://ollama.com/library/devstral-small-2)
- [Qwen3-Coder — Ollama](https://ollama.com/library/qwen3-coder)
- [Qwen3-Coder-Next — HuggingFace (GGUF)](https://huggingface.co/lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF)
- [Qwen3.8 — Ollama](https://ollama.com/library/qwen3.8)
- [Kimi K2.7 Code — Ollama](https://ollama.com/library/kimi-k2.7-code)
- [MLX Runner Troubleshooting](mlx-runner-troubleshooting.md)
