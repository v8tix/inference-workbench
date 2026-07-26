# Coding LLM Recommendations — 48 GB MacBook Pro (M5 Pro)

> Workload: agentic coding, repo exploration, multi-file edits  
> KV cache: q4_0 (configurable via `ollama/ollama.env`)  
> Updated: July 26, 2026

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

All presets stay well within the 37.4 GiB Metal limit with comfortable headroom.

### Context sizing guide

| ctx | Use | Prefill speed |
|---:|---|---|
| 32K | Small changes, focused debugging | Fastest |
| 49K–65K | Normal repo work, a few related files | Fast |
| 90K | Large changes, long agent trajectories | Moderate |
| 128K | Very large repos, multi-hour sessions | Slower prefill |

Start at 90K. Only drop to 49K/65K if prefill feels too slow. Only increase to 128K if the agent consistently loses relevant context.

### Can I increase north-standard beyond 90K?

Yes. With q4_0 KV cache, the safe ceiling for 20 GB weights is ~183K. To go to 128K:

1. Edit `ollama/modelfiles/Modelfile.north-standard`:
   ```
   PARAMETER num_ctx 131072
   ```
2. Rebuild and reload:
   ```bash
   bash ollama/scripts/apply_preset.sh north-standard
   ```
3. Also update the matching OpenCode context in `~/.config/opencode/opencode.jsonc`:
   ```json
   "model": "ollama/north-standard",
   "maxContextTokens": 131072
   ```

128K peaks at ~32.2 GiB — 5.2 GiB headroom. The model validates up to 488K, so 128K is well within its tested range.

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
- [Kimi K2.7 Code — Ollama](https://ollama.com/library/kimi-k2.7-code)
