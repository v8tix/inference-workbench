# MLX vs GGUF on Apple Silicon

## What they are

**llama.cpp + GGUF** is a cross-platform inference engine that runs on CPUs, NVIDIA GPUs, AMD GPUs, Apple Silicon, phones, and Raspberry Pis. That portability is its strength. It uses Metal as its Apple Silicon GPU backend — the same low-level GPU API used by games and graphics apps. It works well, but it makes no assumptions about any specific architecture.

**MLX** is Apple's own machine learning framework, built exclusively for Apple Silicon. It sits on top of Metal and exploits the one thing llama.cpp deliberately avoids depending on: unified memory. On Apple Silicon, the CPU and GPU share the same physical RAM — no data copies between them, ever. MLX was designed around this from day one.

They both end up on the Metal GPU. The difference is in everything above that layer.

---

## Performance tradeoffs

Measured on a 48 GB MacBook Pro M5 Pro — see [performance-comparison.md](performance-comparison.md) for full data.

| Phase | Gemma 4 26B (GGUF) | North Mini Code 1.0 (MLX) |
|---|---|---|
| Prefill — 24K tokens | ~24s (~990 tok/s) | ~46s (~534 tok/s) |
| Generation speed | 27–37 tok/s | ~91 tok/s |
| 400-token answer | ~15s after prefill | ~4s after prefill |

GGUF prefills faster. llama.cpp's Metal backend is heavily optimized for large matrix multiplications — the dominant operation during prompt processing.

MLX generates faster. Generation is memory-bandwidth-bound: each token requires loading model weights from RAM. MLX benefits here because North Mini Code uses a MoE (Mixture of Experts) architecture — only ~3B of its 30B parameters activate per token. Combined with zero-copy unified memory access, the per-token cost is much lower.

For interactive agentic coding sessions, generation speed matters more than prefill speed. Most of the wall-clock time a developer experiences is waiting for the answer to stream, not waiting for the first token.

---

## Model availability

Most models on Ollama are GGUF-only. MLX quantizations (nvfp4, mxfp8) require the original model authors to publish them — they can't be auto-converted from GGUF. As of mid-2026, only a small number of labs publish MLX weights: North Training and Alibaba's Qwen team are the main ones relevant to coding use cases.

This is the primary constraint on MLX adoption — not hardware, not software, but publishing pipeline.

---

## When to use each

| Scenario | Use |
|---|---|
| Daily agentic coding (fast response loop) | MLX — generation speed dominates |
| Model not available in MLX | GGUF — it still works, Metal backend is solid |
| Hard problems, deep reasoning | Qwen3.6 27B MLX — slow prefill, best quality |
| Memory-constrained (< 24 GB) | GGUF Q4_K_M typically more size-efficient |

---

> Related: [performance-comparison.md](performance-comparison.md) — full benchmark data with raw numbers from production logs.
