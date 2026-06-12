# Local LLM Model Fit Research — Theory First, Then Local Catalog Reality

## Original Goal

This note is aligned with the original requirement in `prompts/context.md`:

- use a local LLM for serious software development on a **48 GB unified RAM Mac**
- keep normal model usage around **24-28 GB**
- treat **32 GB** as the practical upper budget
- prefer models that leave room for **larger context windows**
- evaluate models for:
  - coding usefulness
  - long-context practicality
  - RAM pressure
  - realistic **64K / 128K / 256K** local use

The file is written in this order:

1. **theory first**
2. **available local Kronk catalog ranking**
3. **current practical repo reality**

It does **not** describe setup steps or switching workflow.

---

## Hardware Summary

| Spec | Value |
|------|-------|
| Laptop | MacBook Pro (Mac17,8) |
| Chip | Apple M5 Pro |
| CPU | 18 cores |
| GPU | 20-core Metal GPU |
| RAM | 48 GB unified |
| Storage | 1 TB SSD |
| OS | macOS 26.5.1 |

## RAM Budget

| Budget class | Target |
|--------------|--------|
| Comfortable daily zone | **24-28 GB** |
| Upper practical target | **32 GB** |
| Main constraint | Leave headroom for IDE, browser, terminal, logs, and background tools |

---

## What Actually Matters for This Laptop

For local software engineering, the real tradeoff is not just **model quality**. It is the balance between:

1. **weight memory** — how much RAM the model itself consumes
2. **KV/cache growth** — how much extra RAM context length consumes
3. **concurrency** — higher `nseq-max` multiplies cache pressure
4. **coding quality** — reasoning, code generation, debugging usefulness

Practical implication:

- lower weight RAM buys more room for **64K / 128K / 256K**
- bigger models can be stronger coders, but they can spend the budget before context gets large
- on this machine, **64K + `nseq-max: 2`** is the current practical daily shape

---

## Theory-First: Best Fits for the Original Requirement

### Official Gemma 4 coding signals

These are the strongest coding numbers currently captured in this repo for the Gemma family.

| Model | LiveCodeBench v6 | Codeforces Elo | Tau2 | Interpretation |
|------|------------------:|----------------:|-----:|----------------|
| **Gemma 4 12B Unified** | **72.0%** | **1659** | **69.0%** | Best balance of coding quality and efficiency |
| Gemma 4 26B A4B | 77.1% | 1718 | 68.2% | Stronger raw coder, but costs more RAM |
| Gemma 4 31B | 80.0% | 2150 | 76.9% | Best Gemma coder on paper, but too heavy here |
| Gemma 3 27B (no think) | 29.1% | 110 | 16.2% | Much weaker coding generation for this use case |

### Best theoretical picks for a 48 GB Mac

| Rank | Model | Quant | Why it matters |
|------|-------|-------|----------------|
| **1** | **🥇 Gemma 4 12B** | **Q4_K_M** | Best coding/context balance if available |
| **2** | **🪶 Gemma 4 E4B** | **Q4_K_M** | Best low-RAM long-context option |
| **3** | **Gemma 3 12B IT** | **Q4_K_M** | Strong lower-RAM fallback |
| **4** | **Gemma 4 26B A4B** | **Q4_K_M** | Better raw quality, but less context headroom |
| **5** | **Gemma 3 27B IT** | **Q4_K_M** | Too dense for this exact long-context-first goal |
| **6** | **Gemma 4 31B** | **Q4_K_M** | Not a practical daily fit under this RAM budget |

### Estimated RAM envelope for the main Gemma candidates

These are planning estimates for local Kronk inference on this Mac. They are guidance, not guarantees.

| Model | Quant | 16K | 32K | 64K | 128K | 256K | Practical reading |
|------|-------|----:|----:|----:|-----:|-----:|-------------------|
| **Gemma 4 E4B** | Q4_K_M | ~7 GB | ~8 GB | ~10 GB | ~13 GB | n/a / not target | Safest path to large context |
| **Gemma 3 4B IT** | Q4_K_M | ~8 GB | ~9 GB | ~11 GB | ~15 GB | n/a | Light, but too shallow for primary coding use |
| **Gemma 4 12B** | Q4_K_M | ~13 GB | ~15 GB | ~18 GB | ~23 GB | ~31 GB | **Best huge-context value** |
| **Gemma 3 12B IT** | Q4_K_M | ~14 GB | ~16 GB | ~19 GB | ~24 GB | n/a | Good 128K-class fallback |
| **Gemma 4 26B A4B** | Q4_K_M | ~20 GB | ~22 GB | ~26 GB | ~32 GB | ~44 GB | Strong at 32K-64K, tight past that |
| **Gemma 3 27B IT** | Q4_K_M | ~24 GB | ~27 GB | ~32 GB | ~40 GB | n/a | Uses too much RAM for the long-context goal |
| **Gemma 4 31B** | Q4_K_M | ~28 GB | ~31 GB | ~37 GB | ~49 GB | ~73 GB | Too close to the ceiling |

### Theory-first conclusions

| Goal | Best theoretical choice | Why |
|------|--------------------------|-----|
| Lowest RAM | **Gemma 4 E4B Q4_K_M** | Maximizes context headroom |
| Best long-context value | **🥇 Gemma 4 12B Q4_K_M** | Best balance of coding usefulness and context |
| Best coding quality within budget | **Gemma 4 26B A4B Q4_K_M** | Strongest Gemma choice that still makes sense locally |
| Best “huge context without killing the laptop” | **🥇 Gemma 4 12B Q4_K_M** | Sweet spot for this exact requirement |

### Theory-first bottom line

If the catalog were ideal, the best match for the original requirement would still be:

1. **🥇 Gemma 4 12B Q4_K_M**
2. **🪶 Gemma 4 E4B Q4_K_M**
3. **Gemma 3 12B IT Q4_K_M**

That remains true because the original requirement values:

- coding usefulness
- lower RAM pressure
- much larger realistic context windows

more than pure benchmark-maximizing model size.

---

## Local Kronk Catalog Reality

### Relevant coding-capable entries currently visible in the local catalog

This section ranks what is **actually available right now** in the local Kronk catalog and is relevant for coding on this machine.

| Model ID | Family | Type | Catalog size | Notes |
|---------|--------|------|-------------:|------|
| `unsloth/Qwen3.6-35B-A3B-UD-Q4_K_M` | Qwen3.6-35B-A3B | Hybrid | **21.45 GB** | Strong coding candidate; fits the laptop better than the Q8 version |
| `ggml-org/gemma-4-26B-A4B-it-Q8_0` | gemma-4-26B-A4B-it | MoE | **26.13 GB** | Heavier than ideal, but already proven in this repo |
| `unsloth/gemma-4-26B-A4B-it-UD-Q4_K_M` | gemma-4-26B-A4B-it | MoE | **16.82 GB** | Very attractive catalog option because it should leave more context headroom than Q8_0 |
| `bartowski/cerebras_Qwen3-Coder-REAP-25B-A3B-Q8_0` | cerebras Qwen3 Coder | MoE | **24.64 GB** | Interesting coding entry, but less established in this repo |
| `Qwen/Qwen3-8B-Q8_0` | Qwen3-8B | Dense | **8.11 GB** | Light option, but lower ceiling for difficult tasks |

Non-primary entries like embeddings, rerankers, and omni models are excluded from the main ranking because they are not the core coding choices for this requirement.

### Ranking of what is best **right now** in the local catalog

| Rank | Available model | Why it ranks here |
|------|------------------|-------------------|
| **1** | **🥇 `unsloth/Qwen3.6-35B-A3B-UD-Q4_K_M`** | Best available coding-focused option in the current catalog: lighter than Q8 variants, strong benchmark reputation, and now aligned to the same 64K / `nseq-max: 2` daily shape used in this repo |
| **2** | **`unsloth/gemma-4-26B-A4B-it-UD-Q4_K_M`** | Best available **Gemma** option in the local catalog for this laptop because the Q4 variant should preserve more context headroom than the Q8 profile |
| **3** | **`ggml-org/gemma-4-26B-A4B-it-Q8_0`** | Worse than the Q4 Gemma variant in theory, but very important because it is already proven and currently kept as the default practical profile |
| **4** | **`bartowski/cerebras_Qwen3-Coder-REAP-25B-A3B-Q8_0`** | Attractive size and likely useful for coding, but less validated in this repo than Qwen3.6 and Gemma 4 26B |
| **5** | **`Qwen/Qwen3-8B-Q8_0`** | Easiest lightweight Qwen coding option, but clearly lower ceiling for hard debugging and architecture work |

### What the local catalog does **not** currently give you

The biggest gap between the original requirement and the local catalog is that the catalog does **not** currently solve the best low-RAM Gemma targets directly:

- no **Gemma 4 12B Q4_K_M**
- no **Gemma 4 E4B Q4_K_M**
- no **Gemma 3 12B IT Q4_K_M**

That means the best *theoretical* Gemma choices and the best *currently available* local choices are not the same thing.

---

## Current Practical Repo Reality

### Current kept profiles

The repo now operates around two practical saved profiles:

| Profile | Quant / size class | Current tuning shape | Why it matters |
|--------|---------------------|----------------------|----------------|
| **`gemma-4-26B-A4B-it-Q8_0`** | heavy but proven | **64K**, `nseq-max: 2`, `q4_0` KV cache, thinking on | Current default practical profile |
| **`Qwen3.6-35B-A3B-UD-Q4_K_M`** | lighter than Gemma Q8_0 | **64K**, `nseq-max: 2`, `q4_0` KV cache, thinking on | Current alternate practical profile |

### Measured current Gemma profile reality

From the current runtime notes already captured in the repo:

| Setting | Value |
|------|-------|
| Model | `gemma-4-26B-A4B-it-Q8_0` |
| Context window | **65536** |
| `nseq-max` | **2** |
| Predicted RAM | **22.4 GB** |
| Slot memory | **5.1 GB** |
| RAM budget seen by Kronk | **38.7 GB** |

This is important because it changes how the Q8 Gemma profile should be interpreted:

- it is **not** the best theoretical long-context pick
- but it **is** a proven practical 64K local profile on this exact machine

### Practical reading of the two kept profiles

| Question | Better answer right now |
|---------|--------------------------|
| Best current default if you value a proven local profile | **Gemma 4 26B A4B Q8_0** |
| Best current alternate if you want a lighter benchmark-strong coder | **Qwen3.6-35B-A3B-UD-Q4_K_M** |
| Best theoretical future Gemma target if added later | **Gemma 4 12B Q4_K_M** |

---

## Friendly Conclusions

### If you are thinking purely in theory

The best answer for the original requirement is still:

- **🥇 Gemma 4 12B Q4_K_M**

because it best balances:

- coding quality
- RAM headroom
- realistic long-context use on a 48 GB Mac

### If you are thinking about the local Kronk catalog available right now

The strongest current choices are:

1. **🥇 `unsloth/Qwen3.6-35B-A3B-UD-Q4_K_M`**
2. **`unsloth/gemma-4-26B-A4B-it-UD-Q4_K_M`**
3. **`ggml-org/gemma-4-26B-A4B-it-Q8_0`**

### If you are thinking about the practical repo state right now

The two profiles that matter are:

1. **`gemma-4-26B-A4B-it-Q8_0`** — current proven default
2. **`Qwen3.6-35B-A3B-UD-Q4_K_M`** — current alternate, aligned to the same 64K daily shape

---

## Final Bottom Line

There are really **three different “best” answers**, depending on what question you mean:

| Question | Best answer |
|---------|-------------|
| Best **theoretical Gemma** fit for the original requirement | **🥇 Gemma 4 12B Q4_K_M** |
| Best **currently available catalog** option for coding on this machine | **🥇 `unsloth/Qwen3.6-35B-A3B-UD-Q4_K_M`** |
| Best **currently proven local profile** already kept in this repo | **`gemma-4-26B-A4B-it-Q8_0`** |

That split is the most honest way to align:

- the original requirement in `prompts/context.md`
- the current Kronk catalog
- real RAM/context tradeoffs
- and the actual profile reality already working in this repo
