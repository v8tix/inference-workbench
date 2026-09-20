# Model Fit with llmfit — 48 GB MacBook Pro (M5 Pro)

> Tool: [llmfit](https://github.com/AlexsJones/llmfit) (`/opt/homebrew/bin/llmfit`)
> Run date: 2026-09-20
> Estimates assume an **8K-token context** unless stated otherwise.

llmfit detects RAM/CPU/GPU, then scores every model in its database for fit, speed and quality.
Scores are a rough guide — they weigh speed and memory fit as well as quality, and llmfit does **not** measure coding quality.

---

## Detected hardware

Command: `llmfit system`

| Field | Value |
|---|---|
| CPU | Apple M5 Pro (18 cores) |
| RAM | 48 GB unified (about 24 GB free at run time) |
| RAM bandwidth | ~506 GB/s (measured) |
| Backend | Metal |
| GPU-available memory | 37.44 GB of 48 GB shared |

This matches the ~37.4 GiB Metal budget already used in [hardware.md](hardware.md).

---

## Capabilities llmfit tracks

llmfit only tracks **Tool Use** and **Vision**. There is no audio or video field.
Across the 300 models queried, the only values in `capabilities` were `Tool Use` (173) and `Vision` (90).
For audio/video support, check the model card on Hugging Face.

`release_date` is available but can be `None`, and for re-quantized uploads it is the upload date, not the base model's release
(e.g. the `DeepSeek-R1-0528-Qwen3-8B` MLX-4bit upload shows 2025-11-30; the base model is 2025-05-29).

---

## Table 1 — Best overall (highest score)

| Model | Params | Quant | Mem GB | tok/s | Fit | Score |
|---|---:|---|---:|---:|---|---:|
| Qwen3.5-9B Claude-4.6-Opus Reasoning Distilled | 7.5B | mlx-8bit | 8.3 | 67 | Perfect | 93.4 |
| DeepSeek-R1-0528-Qwen3-8B | 8.2B | mlx-8bit | 9.8 | 62 | Perfect | 92.6 |
| DeepSeek-R1-Distill-Qwen-7B | 7.6B | mlx-8bit | 8.6 | 66 | Perfect | 91.9 |
| Gemma-4-E4B reasoning variants | ~8B | mlx-8bit | ~9.2 | 63 | Perfect | 91.9 |

Small models dominate the score ranking because they are fast and leave lots of headroom.

## Table 2 — Largest models that fit

| Model | Params | Quant | Mem GB | tok/s | Fit |
|---|---:|---|---:|---:|---|
| DeepSeek-R1-Distill-Llama-70B | 60.1B | mlx-4bit | 36.1 | 17 | Good |
| Qwen3-Coder-Next-REAP-48B-A3B (MoE) | 48.9B | mlx-4bit | 25.0 | 146 | Perfect |
| DeepSeek-V4-Flash-Vision (MoE) | 46.4B | mlx-4bit | 23.8 | 242 | Perfect |
| ISOM-R1-Enterprise-40B-Beta | 41.8B | mlx-4bit | 38.5 | 24 | Good |
| Qwen3.6-35B-A3B (MoE) | 36.0B | mlx-8bit | 18.4 | 110 | Perfect |
| Qwen3.5-35B-A3B (MoE) | 36.0B | mlx-8bit | 18.4 | 110 | Perfect |
| GKA-primed-HQwen3-32B-Reasoner | 34.1B | mlx-8bit | 36.6 | 15 | Good |
| DeepSeek-R1-Distill-Qwen-32B | 33.7B | mlx-8bit | 36.2 | 15 | Good |

MoE models (`A3B` = ~3B active parameters per token) are far faster than dense models of similar size.
Dense 32B/70B fit but consume nearly all GPU memory and run at ~15 tok/s.

## Table 3 — Features and release date

| Model | Params | Mem GB | tok/s | Tool | Vision | Context | Released |
|---|---:|---:|---:|:-:|:-:|---:|---|
| Qwen3.5-9B-Claude-4.6-Opus-Reasoning-Distilled | 7.5B | 8.3 | 67 | ✓ | – | 256K | 2026-03-04 |
| DeepSeek-R1-0528-Qwen3-8B | 8.2B | 9.8 | 62 | ✓ | – | 128K | 2025-05-29 |
| DeepSeek-R1-Distill-Llama-70B | 60.1B | 36.1 | 17 | – | – | 128K | 2025-01-20 |
| Qwen3-Coder-Next-REAP-48B-A3B (4-bit) | 48.9B | 25.0 | 146 | ✓ | – | 256K | 2026-02-08 |
| DeepSeek-V4-Flash-Vision (MLX 4-bit) | 46.4B | 23.8 | 242 | – | ✓ | 4K | 2026-09-02 |
| ISOM-R1-Enterprise-40B-Beta | 41.8B | 38.5 | 24 | – | – | 8K | 2026-08-30 |
| **Qwen3.6-35B-A3B** | 36.0B | 18.4 | 110 | ✓ | ✓ | 256K | 2026-09-14 |
| Huihui-Qwen3.6-35B-A3B-abliterated | 36.0B | 18.4 | 110 | ✓ | ✓ | 256K | 2026-04-18 |
| Qwen3.5-35B-A3B | 36.0B | 18.4 | 110 | ✓ | ✓ | 256K | 2026-02-24 |
| GKA-primed-HQwen3-32B-Reasoner | 34.1B | 36.6 | 15 | ✓ | – | 128K | unknown |
| DeepSeek-R1-Distill-Qwen-32B (unsloth 4-bit) | 33.4B | 35.9 | 15 | – | – | 128K | 2025-01-22 |

## Table 4 — Best for coding

Command: `llmfit recommend --use-case coding`

| Rank | Model | Params | Mem GB | tok/s | Tool | Context | Released |
|---:|---|---:|---:|---:|:-:|---:|---|
| 1 | **Qwen3-Coder-Next-REAP-48B-A3B** (4-bit MLX) | 48.9B | 25.0 | 146 | ✓ | 256K | 2026-02-08 |
| 2 | **Qwen3-Coder-30B-A3B-Instruct** (8-bit) | 30.5B | 15.6 | 132 | ✓ | 256K | 2025-07-31 |
| 3 | Qwen3-Coder-REAP-25B-A3B (8-bit MLX) | 24.9B | 12.7 | 137 | ✓ | 256K | 2025-11-05 |
| 4 | Qwen3.6-35B-A3B (general, with vision) | 36.0B | 18.4 | 110 | ✓ | 256K | 2026-09-14 |

Skipped: 3–4B coders (fast, but weak — they rank high only on speed) and dense 32B/70B models (~15 tok/s, too slow for interactive use).

---

## How the results were produced

All numbers come from llmfit's JSON output. Every subcommand accepts `--json`, and `recommend` emits JSON by default.

### 1. Detect hardware

```bash
llmfit system
```

### 2. Get top recommendations

```bash
llmfit recommend --limit 20
```

Each model object includes: `name`, `params_b`, `best_quant`, `memory_required_gb`, `estimated_tps`,
`fit_level` (`Perfect` / `Good` / …), `score`, `capabilities`, `context_length`, `release_date`, `runtime`.

Summary table (Table 1):

```bash
llmfit recommend --limit 20 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)['models']
for m in d:
    print(m['name'], m['params_b'], m['best_quant'], m['memory_required_gb'],
          m['estimated_tps'], m['fit_level'], m['score'])
"
```

### 3. Find the largest models that fit (Table 2)

Pull a wide list, keep `Perfect`/`Good` fits, sort by parameter count, de-duplicate re-quantized copies of the same model:

```bash
llmfit recommend --limit 300 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)['models']
d=[m for m in d if m['fit_level'] in ('Perfect','Good')]
d.sort(key=lambda m:-m['params_b'])
seen=set()
for m in d:
    k=m['name'].split('/')[-1][:30]
    if k in seen: continue
    seen.add(k)
    print(m['name'], m['params_b'], m['best_quant'], m['memory_required_gb'], m['estimated_tps'], m['fit_level'])
    if len(seen)>=12: break
"
```

### 4. Check which capabilities exist (Table 3)

```bash
llmfit recommend --limit 300 2>/dev/null | python3 -c "
import json,sys,collections
d=json.load(sys.stdin)['models']
print(collections.Counter(x for m in d for x in m['capabilities']))
"
# Counter({'Tool Use': 173, 'Vision': 90})
```

Then print `capabilities`, `context_length` and `release_date` per model.

### 5. Coding-specific ranking (Table 4)

```bash
llmfit recommend --use-case coding --limit 15
```

### Useful flags

| Flag | Purpose |
|---|---|
| `--max-context N` | Estimate memory at a longer context (default assumption here: 8192) |
| `--memory 32G` / `--ram 64G` | Simulate different hardware |
| `--profile <name>` | Score against a hardware profile (`llmfit hardware list`) |
| `--json` | Force JSON on any subcommand |

### Fields to interpret with care

| Field | Caveat |
|---|---|
| `estimated_tps` | Estimated from GPU bandwidth roofline, calibrated (`estimate_confidence: calibrated`); not measured on this machine (`measured_tps: null`) |
| `memory_required_gb` | Computed at 8K context; KV cache grows with `--max-context` |
| `score` | Blends fit, speed, quality and context; not a coding benchmark |
| `release_date` | May be an upload date, or `None` |

---

## What this project already runs on this laptop

Configuration read from this repo (see [README](../README.md), [hardware.md](hardware.md),
[coding-llm-recommendations-macbook-pro.md](coding-llm-recommendations-macbook-pro.md)):

| Setting | Value |
|---|---|
| Metal budget | ~37.4 GiB (same as llmfit's 37.44 GB) |
| Ollama runtime | `OLLAMA_FLASH_ATTENTION=1`, `OLLAMA_KV_CACHE_TYPE=q4_0`, `OLLAMA_NUM_PARALLEL=1`, `OLLAMA_MAX_LOADED_MODELS=1`, `OLLAMA_KEEP_ALIVE=4h` |
| Kronk (active) | `gemma-4-26B-A4B-it-Q8_0`, preset `gemma-standard`: 64K ctx, `nseq-max: 2`, q4_0 K/V cache, flash attention |
| Kronk (alternate) | `Qwen3.6-35B-A3B-UD-Q4_K_M`, 64K ctx, `nseq-max: 2`, thinking on |
| Ollama presets | `north-*` (North Mini Code 1.0, nvfp4 20 GB / mxfp8 31 GB, 32K–88K ctx) and `qwen36-*` (Qwen3.6 27B Coding nvfp4, 64K–88K ctx) |
| Installed in Ollama (`ollama list`) | `qwen3.6:27b-coding-nvfp4` (19 GB), `qwen3.8:27b` variants (17–31 GB) and the `qwen36-*` / `qwen38-*` presets built from them |
| KV cache growth (measured, q4_0) | ~0.095 GiB per 1K tokens |

### How llmfit's picks compare to the working setup

| Observation | Detail |
|---|---|
| Consistent | Both llmfit and the repo favor MoE models with ~3B active parameters (Qwen3.6-35B-A3B, Qwen3-Coder, Gemma 4 26B-A4B, North Mini Code 30B) |
| Consistent | Dense 32B+ models are avoided; ~20 GB weights leave room for 64K–90K context |
| Gap | llmfit sizes memory at 8K context; the repo runs 64K–90K, so budget ~6–9 GiB more for KV cache (`safe_ctx = (37.4 − weights_GiB) / 0.095 × 1000`) |
| Candidate to try | `Qwen3-Coder-30B-A3B-Instruct` (15.6 GB) — llmfit's #2 coding pick, not yet among the repo presets |
| Not in llmfit list | North Mini Code 1.0 was not among the models returned by the queries above, so llmfit can't confirm its fit; the repo's own measurements are the source of truth for it |

---

## Working config: `qwen38-standard`

Source: `ollama show qwen38-standard --modelfile` and `ollama show qwen38-standard`.
There is no `Modelfile.qwen38-standard` in `ollama/modelfiles/` — the preset exists only in the local Ollama store.

| Field | Value |
|---|---|
| Base | `qwen3.8:27b-nvfp4` (18 GB on disk) |
| Architecture | `qwen3_5`, 27.8B dense |
| Native context | 262,144 |
| `num_ctx` | 90112 (88K) |
| `num_predict` | 2048 |
| `temperature` / `top_k` / `top_p` / `min_p` | 0.2 / 40 / 0.95 / 0 |
| `repeat_penalty` / `presence_penalty` | 1 / 0 |
| Renderer / parser | `qwen3.8` / `qwen3.5` |
| Capabilities | completion, vision, tools, thinking |
| Runtime | Ollama, `KV_CACHE_TYPE=q4_0`, flash attention, 1 parallel request |

Memory estimate with the repo formula: 18 GB weights + 88K × 0.095 GiB/K ≈ 8.4 GiB KV → **~26–27 GiB**, about 10 GiB under the 37.4 GiB Metal limit.

A suggested Modelfile to add to the repo (reconstructed from the values above):

```
FROM qwen3.8:27b-nvfp4
PARAMETER num_ctx 90112
PARAMETER num_predict 2048
PARAMETER temperature 0.2
PARAMETER top_k 40
PARAMETER top_p 0.95
```

### llmfit vs the working config

llmfit does not score `qwen3.8:27b-nvfp4` itself (Qwen3.8 27B uploads show up only in search, unscored). The closest scored entries, at `--max-context 90112`:

| Model | Mem GB | tok/s | Fit |
|---|---:|---:|---|
| qwen3.8-27b-yarn4-mixed-kl-128k (mlx-8bit) | 33.8 | 18 | Good |
| Qwen3.6-27B Claude-Opus Reasoning Distill (8-bit) | 32.9 | 19 | Good |

These are 8-bit, so they are heavier than your nvfp4 build (18 GB weights). llmfit's "Good" fit at ~33 GB for 8-bit is consistent with your nvfp4 build fitting comfortably.

### Coding models that fit next to it (at 88K context)

Command: `llmfit --max-context 90112 recommend --use-case coding --limit 40`

| Model | Mem GB @88K | tok/s | Fit | Note |
|---|---:|---:|---|---|
| Qwen3-Coder-Next-REAP-40B-A3B (mxfp4) | 21.0 | 146 | Perfect | MoE, ~3B active; same memory class as qwen38-standard but far faster |
| Qwen3-Coder-30B-A3B-Instruct (8-bit) | 15.6 | 132 | Perfect | Smaller and faster than qwen38-standard |
| Qwen3-Coder-REAP-25B-A3B (8-bit) | 12.7 | 137 | Perfect | Lightest serious coder |

Compared with `qwen38-standard` (dense 27.8B, ~18 tok/s class by llmfit's estimate for similar dense models), the MoE Qwen3-Coder models are roughly 7× faster at similar or lower memory.
Trade-off: qwen38-standard is newer, has vision and thinking, and is the model already proven in your workflow; llmfit cannot measure coding quality.
Best candidate to try alongside it: `Qwen3-Coder-30B-A3B-Instruct`.
