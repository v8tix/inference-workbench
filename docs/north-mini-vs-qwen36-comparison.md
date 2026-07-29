# 🦣 Running Local LLMs with Ollama: Why Qwen3.6 Crushes North-Mini-Code on Instruction Following 🧠

## TL;DR 📌

When running local LLMs via Ollama, Qwen3.6-27B outperforms North-Mini-Code-1.0 on instruction following because it's a dense model with superior benchmark scores, richer training data, and built-in thinking preservation. North-Mini-Code trades raw capability for compute efficiency via its MoE architecture — only 10% of its 30B params fire per token ⚡.

## The Local LLM Game on macOS 🖥️

Ollama makes it trivial to run powerful models locally on your machine. Two popular choices for coding tasks:

- **Qwen3.6-27B** — Dense, multimodal powerhouse (`ollama/qwen3.6:27b`) 🚀
- **North-Mini-Code-1.0** — MoE-based, compute-efficient code model optimized for agentic tasks (`ollama/north-mini-code`) ⚡

Both pull and run with a single `ollama run` command, but they take very different approaches to the same problem.

## Model Specs 📊

| | North-Mini-Code-1.0 | Qwen3.6-27B |
|---|---|---|
| **Developer** | Cohere Labs | Qwen (Alibaba) |
| **Architecture** | Sparse MoE | Dense + multimodal |
| **Total params** | 30B | 27B |
| **Active params** | **3B (10%)** | **27B (100%)** |
| **Context length** | 256K | 262K (extensible to 1M) |
| **Input** | Text only | Text + image + video |
| **Ollama available** | ✅ Yes | ✅ Yes |
| **Hugging Face downloads** | ~13.7K/month | ~6.2M/month |

## Benchmark Comparison 🏆

| Benchmark | North-Mini-Code | Qwen3.6-27B | Winner 🥇 |
|---|---|---|---|
| SWE-bench Verified | 67.6 | **77.2** | Qwen3.6 |
| SWE-bench Pro | 40.2 | **53.5** | Qwen3.6 |
| Terminal-Bench 2.0 | **36** | **59.3** | Qwen3.6 |

Qwen3.6 pulls ahead across every coding benchmark by a wide margin — no contest 📈.

## Why Qwen3.6 Understands Instructions Better 🔍

### 1️⃣ Active parameter count matters

North-Mini-Code's MoE architecture means only ~3B params fire per token vs Qwen3.6's full 27B. That's a **9x gap** in active compute 🤯. When an instruction requires multi-step reasoning, the full 27B consistently activates relevant knowledge; the 3B MoE expert selection can miss nuances.

### 2️⃣ Quantization compounds the problem

Running North-Mini-Code in Q4_K_M quantization (Ollama's default for large models) loses precision in the already-limited expert routing layer ⚠️. Qwen3.6 in similar Q4 quantization still has 9x the active parameters, so it retains its edge even quantized.

### 3️⃣ Multimodal training 🎨

Qwen3.6 was trained on text, image, and video data, which sharpens its general instruction-following capabilities. North-Mini-Code is text-only and optimized specifically for agentic terminal tasks, not general instruction following.

### 4️⃣ Thinking preservation 🔄

Qwen3.6 supports `preserve_thinking` — it retains reasoning context across turns, enabling it to track multi-step instructions conversationally. This directly translates to better instruction adherence over extended interactions 💬.

## When to Use Each 🤔

### North-Mini-Code ⚡
- Automated SWE tasks 🛠️
- Terminal operations
- Constrained hardware (lower RAM, slower storage)
- Server-side inference where FLOP/token matters

### Qwen3.6 🚀
- Interactive coding assistants 💻
- Complex multi-step tasks
- Multimodal workflows (images + code)
- Local development where quality > latency
- 32GB+ RAM recommended for smooth experience

## Running with Ollama — Quick Start 🏃‍♂️

### Qwen3.6-27B
```bash
ollama pull qwen3.6:27b
ollama run qwen3.6:27b "Explain how Ollama works under the hood"
```

### North-Mini-Code-1.0
```bash
ollama pull cohere/north-mini-code
ollama run cohere/north-mini-code "Write a Python script"
```

### Modfile — Tweak Settings 🛠️
```dockerfile
FROM qwen3.6:27b

PARAMETER temperature 0.6
PARAMETER top_p 0.95
PARAMETER num_ctx 32768

SYSTEM "You are a precise coding assistant."
```

Then build and run:
```bash
ollama create qwen3.6-coder -f Modfile
ollama run qwen3.6-coder "Build a REST API in Go"
```

## Recommended Settings ⚙️

### Qwen3.6
- 🧠 **Thinking mode (general):** `temperature=1.0, top_p=0.95, top_k=20`
- 💻 **Thinking mode (precise coding):** `temperature=0.6, top_p=0.95, top_k=20`
- 📝 **Instruct mode:** `temperature=0.7, top_p=0.80, top_k=20, presence_penalty=1.5`

### North-Mini-Code
- `temperature=1.0, top_p=0.95`
- Prefer Q5 quantization — Q4 degrades instruction following ⚠️

## Verdict 🎯

For local development, **Qwen3.6-27B is the clear winner** for instruction following through Ollama. The 9x active parameter advantage dominates even with quantization. North-Mini-Code shines only when you're tightly constrained on hardware and need MoE efficiency. If your machine can handle 27B, go Qwen3.6 🍏✨
