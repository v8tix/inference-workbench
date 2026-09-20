# Qwen3-Coder-Next REAP 48B Setup Guide

Qwen3-Coder-Next (via REAP expert merging) is a 48.9B MoE coding model — the largest model in the workbench. Uses GGUF/llama.cpp, not MLX.

## Why GGUF, not MLX

The official MLX weights on HuggingFace (`toby1991/Qwen3-Coder-Next-REAP-48B-A3B-4bit-mlx`) have **broken int4 quantization metadata**. When Ollama's MLX runner loads them, it crashes with:

```
mlx: [quantized_matmul] The shapes of the weight and scales are incompatible
based on bits and group_size. w.shape() == (308,512) and scales.shape() == (308,32)
with group_size=64 and bits=4
```

The GGUF version from `lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF` works reliably via llama.cpp/Metal.

## Quantization

The base model is Q4_K_XL (~33 GB). For this 48 GB Mac, it was requantized to **Q3_K_M (~22 GB on disk, 24 GB in GPU memory)** — the sweet spot that enables 128K context while staying within the Metal limit.

The quantized file is at `ollama/models/qwen3-coder-next/Qwen3-Coder-Next-REAP-48B-A3B-Q3_K_M.gguf`.

To requantize to a different level:

```bash
llama-quantize --allow-requantize \
  ollama/models/qwen3-coder-next/Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf \
  ollama/models/qwen3-coder-next/Qwen3-Coder-Next-REAP-48B-A3B-Q3_K_M.gguf \
  Q3_K_M
```

Available types: Q4_K_M, Q3_K_L, Q3_K_M, Q3_K_S, Q2_K, IQ4_NL, IQ3_M, IQ2_M

## Setup

```bash
# Download GGUF (31 GB for Q4_K_XL)
hf download lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF \
  --include "Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf" \
  --local-dir ollama/models/qwen3-coder-next/

# Requantize to Q3_K_M (22 GB)
llama-quantize --allow-requantize \
  ollama/models/qwen3-coder-next/Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf \
  ollama/models/qwen3-coder-next/Qwen3-Coder-Next-REAP-48B-A3B-Q3_K_M.gguf \
  Q3_K_M

# Build presets
ollama create qwen3-coder-next-standard  -f ollama/modelfiles/Modelfile.qwen3-coder-next-standard
ollama create qwen3-coder-next-fast     -f ollama/modelfiles/Modelfile.qwen3-coder-next-fast
ollama create qwen3-coder-next-deep     -f ollama/modelfiles/Modelfile.qwen3-coder-next-deep
```

## Presets

| Preset | Context | Output | Weights |
|---|---|---|---:|---:|
| `qwen3-coder-next-fast` | 88K | 1,024 | 24 GB |
| `qwen3-coder-next-standard` ⭐ | **128K** | 2,048 | 24 GB |
| `qwen3-coder-next-deep` | 64K | 4,096 | 24 GB |

## Memory notes

| Preset | Weights | ctx | KV cache | Peak | Headroom |
|---|---|---|---:|---:|---:|
| `qwen3-coder-next-fast` | 24 GB | 88K | 8.4 GiB | 32.4 GiB | 5.0 GiB ✅ |
| `qwen3-coder-next-standard` ⭐ | 24 GB | 128K | 12.2 GiB | 36.2 GiB | 1.2 GiB ✅ |
| `qwen3-coder-next-deep` | 24 GB | 64K | 6.1 GiB | 30.1 GiB | 7.3 GiB ✅ |

All fit within the 37.4 GiB Metal limit. The Q3_K_M quantization freed 9 GB compared to Q4_K_XL.

## Verifying

```bash
curl -s http://localhost:11434/api/generate \
  -d '{"model":"qwen3-coder-next-standard","prompt":"say hi","stream":false}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','ERROR'))"
```

## Troubleshooting

If you see `mlx runner failed` or `[quantized_matmul]` errors, the model was accidentally created from the old safetensors source. Delete and recreate:

```bash
ollama rm qwen3-coder-next-standard qwen3-coder-next-fast qwen3-coder-next-deep
ollama create qwen3-coder-next-standard -f ollama/modelfiles/Modelfile.qwen3-coder-next-standard
ollama create qwen3-coder-next-fast    -f ollama/modelfiles/Modelfile.qwen3-coder-next-fast
ollama create qwen3-coder-next-deep    -f ollama/modelfiles/Modelfile.qwen3-coder-next-deep
```

See also [mlx-runner-troubleshooting.md](../../docs/mlx-runner-troubleshooting.md) for MLX runner crash debugging.