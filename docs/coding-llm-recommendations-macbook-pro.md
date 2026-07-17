# Coding LLM Recommendations — 48 GB MacBook Pro (M5 Pro)

> Workload: agentic coding, repo exploration, multi-file edits  
> Memory budget: 32 GB + 5% tolerance (~33.6 GB) for weights + context  
> Updated: July 16, 2026

---

## Recommended models

| Priority | Model | Weights | Working ctx |
|---|---|---:|---:|
| **Primary** | North Mini Code 1.0 (`mlx-mxfp8`) | 31 GB | 128K |
| **Balanced** ⭐ | North Mini Code 1.0 (`mlx-nvfp4`) | 20 GB | 128K |
| **Memory-efficient** | Devstral Small 2 (`24b`) | 15 GB | 64K–128K |
| **Alternative** | Qwen3-Coder 30B-A3B (`30b-a3b-q4_K_M`) | 19 GB | 64K–128K |

Start with Balanced (⭐). Move to Primary for hard tasks after confirming dev environment stays responsive.

---

## Models evaluated and excluded

| Model | Reason |
|---|---|
| Kimi K2.7 Code (1.04T) | Cloud-only — no local inference |
| Devstral 2 (123B) | ~75 GB — exceeds budget |
| Qwen3-Coder 480B | 290 GB — exceeds budget |
| Qwen2.5-Coder 32B | Superseded by Qwen3-Coder 30B-A3B |

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

| ctx | Use |
|---:|---|
| 32K | Small changes, focused debugging |
| 64K | Normal repo work, a few related files |
| 128K | Large changes, long agent trajectories |

Start at 64K. Move to 128K when the agent loses relevant context. Don't increase context to compensate for poor retrieval.

---

## Memory pressure guide

Apple Silicon uses unified memory — Ollama, macOS, IDE, Docker, browser all share the same pool.

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
```

---

## Sources

- [North Mini Code 1.0 — Ollama](https://ollama.com/library/north-mini-code-1.0)
- [North Mini Code — Cohere Labs model card](https://huggingface.co/CohereLabs/North-Mini-Code-1.0)
- [Devstral Small 2 — Ollama](https://ollama.com/library/devstral-small-2)
- [Qwen3-Coder — Ollama](https://ollama.com/library/qwen3-coder)
- [Kimi K2.7 Code — Ollama](https://ollama.com/library/kimi-k2.7-code)
