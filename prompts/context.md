### Title

Choose a local Gemma-focused LLM setup for heavy software development with large context windows

### Description

I want to run a local LLM on my laptop for daily software engineering work.

My laptop has **48 GB unified RAM**, and I want to allocate around **32 GB maximum** to Kronk/model usage. My preferred operating range is:

- **24-28 GB normally**
- **32 GB maximum**

The model will be used for:

- local coding (mainly Go, plus PostgreSQL/MySQL)
- refactoring
- debugging
- architecture review
- handling larger code context without exhausting laptop RAM

I especially want you to evaluate **Gemma-family models with lower RAM usage**, so they can preserve enough headroom for **larger context windows**.

Prioritize models from **2025 or later**, especially:

- **Gemma 3**: 4B, 12B, 27B
- **Gemma 4**: E4B, 12B, 26B A4B, 31B

Important decision criteria:

1. **Long-context practicality on a 48 GB Mac**
2. **Coding usefulness**
3. **RAM headroom for daily use**
4. **Whether 64K / 128K / 256K context is realistic locally**

Do not optimize only for benchmark quality. I care more about the best balance of:

- strong coding output
- low RAM pressure
- ability to keep much larger context windows than a maxed-out 27B/31B dense model

---

## Tasks

Work through tasks one at a time, in order. Do not batch them all together.

### Task 1 — Research Gemma model fits for this laptop

**Goal:** Check my laptop hardware and identify which Gemma-family models are the best fit for software development when long context matters.

- My hardware description is located here:
```
/Users/vrock/Public/V8TIX/prompts/local-llm-mac-check.txt
```

**Deliverables:**
- Save the model analysis in:
```
prompts
```
- Create tables that show:
  - estimated RAM usage
  - context-window practicality (16K / 32K / 64K / 128K / 256K where relevant)
  - coding usefulness
  - PROs and CONs
  - which Gemma model is best for:
    - lowest RAM
    - best long-context value
    - best coding quality within budget
    - best “huge context without killing the laptop”

### Task 2 — Recommend Kronk-friendly configs

**Goal:** For the best Gemma candidates, propose Kronk config guidance that keeps RAM controlled while allowing larger context windows.

Focus on:

- `context-window`
- `cache-type-k`
- `cache-type-v`
- `nseq-max`
- quantization tradeoffs where relevant

Make the recommendation practical for this laptop, not theoretical.
