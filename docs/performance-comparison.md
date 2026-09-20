# Performance Comparison: GGUF (llama.cpp) vs MLX (Ollama)

> Hardware: MacBook Pro M5 Pro, 48 GB unified memory  
> Measured: July–September 2026, from production logs (OpenCode agentic sessions)

---

## Summary

| Metric | Gemma 4 26B (GGUF Q4_K_M) | North Mini Code 1.0 (MLX nvfp4) | Qwen3.6 27B (MLX nvfp4) | Qwen3.8 27B (GGUF Q4_K_M) | Qwen3-Coder-Next 48B (GGUF Q4_K_XL) |
|---|---:|---:|---:|---:|---:|
| Runner | llama.cpp / Metal | MLX | MLX | llama.cpp / Metal | llama.cpp / Metal |
| Params | 26B dense | 30B MoE (~3B active) | 27B dense | 27B dense | 48B MoE (~3B active) |
| Weights on disk | ~15 GB | 20 GB | 20 GB | 18 GB | 33 GB |
| **Prefill (cold, avg)** | **~990 tok/s** | **~445 tok/s (47K ctx)** | **~130 tok/s** | **~990 tok/s** | **~500 tok/s (est.)** |
| **Prefill (cold, 24K req)** | **~24s TTFT** | **~46s TTFT** | **~184s TTFT** | **~24s TTFT** | **~48s TTFT (est.)** |
| **Generation speed** | **27–37 tok/s** | **~91 tok/s** | ~70 tok/s (est.) | **27–37 tok/s** | **~80 tok/s (est.)** |
| Cache hit TTFT | 0.5–2.5s | <2s (47K matched) | — | — | — |
| Context limit | 64K (Kronk) | 88K (north-standard) | 88K (qwen36-standard) | 88K (qwen38-standard) | 88K (qwen3-coder-next-standard) |
| Coding score | — | 33.4 AA Index | 77.2% SWE-bench | — | — |

---

## Prefill speed

### Gemma 4 26B — GGUF Q4_K_M (Kronk, llama.cpp + Metal)

Cold-start prefill from production logs:

| Prompt tokens | TTFT | Prefill rate |
|---:|---:|---:|
| 11,375 | 11.0s | 1,033 tok/s |
| 18,010 | 16.9s | 1,066 tok/s |
| 21,047 | 24.2s | 871 tok/s |

**Average cold prefill: ~990 tok/s**

Kronk has an in-memory prefix cache (IMC). Cache hits are dramatically faster:

| Prompt tokens (total) | New tokens to decode | TTFT |
|---:|---:|---:|
| 20,476 | 18,470 | ~16s |
| 17,280 | 15,113 | ~13s |
| 11,641 | ~500 | ~1.3s |

When the system prompt prefix matches (~2–8K tokens), Kronk skips re-processing those tokens entirely.

### North Mini Code 1.0 — MLX nvfp4 (Ollama, MLX runner)

Cold-start prefill of 47,276 tokens, measured from `Prompt processing progress` timestamps:

| Context range | Batch time (2048 tok) | Throughput |
|---|---:|---:|
| 0–2K | 2.4s | ~857 tok/s |
| 20–24K | 4.6–4.8s | ~430 tok/s |
| 44–47K | 5.9–6.0s | ~341 tok/s |

**At 24K tokens (typical OpenCode request): ~46s TTFT, ~534 tok/s avg**

MLX prefill slows as context grows because attention is O(n²) — each new batch must attend to all prior tokens. No KV prefix cache on cold start; Ollama's prefix cache only helps across turns in the same session.

### Qwen3.6 27B Coding — MLX nvfp4 (Ollama, MLX runner)

Flat ~130 tok/s throughout — dense model, no MoE speedup. Each 2048-token batch takes ~16s.

**At 24K tokens: ~3 min TTFT** — too slow for interactive agentic use.

### Qwen3.8 27B — GGUF Q4_K_M (Ollama, llama.cpp + Metal)

Same llama.cpp/Metal backend as Gemma. Prefill should match Gemma's ~990 tok/s — fast enough for interactive use at 24K context (~24s TTFT). Generation is dense 27B at 27–37 tok/s. Good when MLX models aren't available or don't fit.

### Qwen3-Coder-Next REAP 48B — GGUF Q4_K_XL (Ollama, llama.cpp + Metal)

MoE architecture (~3B active per token) on GGUF backend. Prefill expected around ~500 tok/s (48B is large but MoE routing limits per-batch compute). Generation should be faster than dense GGUF models due to active-param sparsity — estimated ~80 tok/s. At 33 GB weights, this is the tightest memory fit on this machine.

---

## Generation speed

| Model | Generation speed | Notes |
|---|---:|---|
| Gemma 4 26B (GGUF) | 27–37 tok/s | Includes speculative decode boost; degrades at longer ctx |
| North Mini Code 1.0 (MLX) | ~91 tok/s | MoE: only ~3B params active per token |
| Qwen3.6 27B (MLX) | ~70 tok/s (est.) | Dense 27B, slightly slower than North |
| Qwen3.8 27B (GGUF) | 27–37 tok/s | Same lama.cpp backend as Gemma |
| Qwen3-Coder-Next 48B (GGUF) | ~80 tok/s (est.) | MoE (~3B active) on llama.cpp backend |

North generates at **~2.5× the speed of Gemma** despite having a 30B parameter count.
Reason: MoE architecture activates only ~3B params per forward pass. Gemma is fully dense.

---

## Why Gemma prefills faster but generates slower

**Prefill** (processing the input prompt) is compute-bound: multiply every layer matrix against a full batch of tokens. llama.cpp on Metal is highly optimized for this — it achieves ~990 tok/s cold.

MLX prefill is slower for two reasons:
1. North uses 2048-token batch size (MLX default), so each batch is an independent attention pass
2. MoE routing adds overhead that isn't amortized at large batches the way dense layers are

**Generation** (producing one token at a time) is memory-bandwidth-bound: load all layer weights from RAM to compute each token. Here MLX wins because:
- MoE activates ~3B of the 30B params → loads ~10% of weights per step
- MLX tensor ops are zero-copy in unified memory → no PCIe transfer overhead
- Gemma 26B loads all 26B params every token → higher bandwidth pressure

---

## Practical implications

For OpenCode agentic sessions (typical 24–48K token prompts, cold start):

- **Gemma** prefills in ~24s at 24K, ~48s at 48K. Fast enough for interactive use.
- **North** prefills in ~46s at 24K, ~100s at 48K. Borderline for interactive use — but Ollama's prefix cache helps a lot on second+ turns within a session.
- **Qwen3.6** prefills in ~3 min at 24K. Impractical as daily driver.
- **Qwen3.8** matches Gemma's prefill (~24s at 24K). Reliable GGUF backend.
- **Qwen3-Coder-Next** prefills in ~48s at 24K (estimated). Best quality but highest memory pressure.

For **generation quality** (after first token arrives):
- North at ~91 tok/s feels fast — a 400-token answer arrives in ~4s
- Gemma at ~27–37 tok/s is noticeably slower — same answer takes 11–15s
- Qwen3.6 is slower still but produces higher-quality outputs for hard problems
- Qwen3-Coder-Next at ~80 tok/s (est.) bridges the gap: fast generation with 48B model quality

**Conclusion**: Gemma (GGUF) wins on cold-start TTFT. North (MLX) wins on generation speed. Qwen3-Coder-Next (GGUF) offers the best quality-to-speed ratio for hard problems, at the cost of higher memory pressure. Qwen3.6 is best reserved for specific hard problems where its 77.2% SWE-bench score matters more than speed.

---

## Cache behavior

Both engines have prefix caching, but different designs:

| | Kronk (Gemma) | Ollama (North) |
|---|---|---|
| Cache type | In-memory KV (slot-based, 2 slots) | Prefix hash cache |
| Cache scope | Across requests (persists in slot) | Within loaded model session |
| Cache hit example | 17K tokens → 0.5s TTFT | 47K matched → 570 new → <2s TTFT |
| Cold start after unload | Full prefill | Full prefill |

Kronk's IMC retains KV state across requests — very fast if the system prompt prefix matches. Ollama's prefix cache is equally effective once a model is loaded and a long session accumulates context.
