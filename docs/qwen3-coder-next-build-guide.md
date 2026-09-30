# Building qwen3-coder-next (`-fast`, `-standard`, `-deep`)

How the three `qwen3-coder-next-*` Ollama models were built: download the Q4_K_XL GGUF, requantize it to Q3_K_M, and create three presets that differ only in context window and output length.

- **Model:** Qwen3-Coder-Next REAP 48B-A3B (48.9B MoE, ~3B active params)
- **Hardware:** MacBook Pro M5 Pro, 48 GB unified memory (Metal limit ≈ 37.4 GiB)
- **Runtime:** Ollama (llama.cpp / Metal, GGUF), plus `llama-quantize` shipped with Ollama

Short setup reference: [ollama/docs/qwen3-coder-next-guide.md](../ollama/docs/qwen3-coder-next-guide.md).

## 1. The problem

The Q4_K_XL GGUF is ~33 GB on disk. With an 88K context window the process needs ~42 GiB, past the 37.4 GiB Metal limit. The result was ~25 GB of swap, generation around 32 tok/s and frequent context compactions.

## 2. The approach: requantize instead of buying hardware

Requantizing Q4_K_XL to Q3_K_M trades a small quality loss for a large memory saving:

| | Q4_K_XL | Q3_K_M |
|---|---:|---:|
| On disk | ~33 GB (31 GiB) | ~22 GB (22 GiB as shown by `ls -lh`) |
| In GPU memory | ~33 GB | ~24 GB |
| Saved | | ~9 GB, spent on context |

Context went from 48K to 128K. Generation stayed at ~32 tok/s, since it is bound by the model rather than the context. Prefill is slower on a cold start, but cache-hit sessions stay sub-second. Swap dropped from 25 GB to 18 GB.

### Why `--allow-requantize`

`llama-quantize` refuses to quantize an already-quantized model, because the loss compounds (like re-saving a JPEG at lower quality). The original FP16 weights are ~96 GB, so they were never downloaded. `--allow-requantize` accepts that loss. On a 48B model the Q4 to Q3 gap is small enough to be barely noticeable in daily coding.

If you have the FP16 weights, quantize from those instead. It is always better than Q4 to Q3.

## 3. Why GGUF and not MLX

The MLX weights (`toby1991/Qwen3-Coder-Next-REAP-48B-A3B-4bit-mlx`) have broken int4 quantization metadata. Ollama's MLX runner crashes on load with:

```
mlx: [quantized_matmul] The shapes of the weight and scales are incompatible
based on bits and group_size. w.shape() == (308,512) and scales.shape() == (308,32)
with group_size=64 and bits=4
```

The GGUF from `lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF` works through llama.cpp/Metal. See [mlx-runner-troubleshooting.md](mlx-runner-troubleshooting.md).

## 4. Step by step

Sources live outside the repo in `~/.ollama/models/sources/qwen3-coder-next/` so the large GGUF files are never committed.

### 4.1 Download Q4_K_XL

```bash
HF_TOKEN="your_token" hf download lovedheart/Qwen3-Coder-Next-REAP-48B-A3B-GGUF \
  --include "Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf" \
  --local-dir ~/.ollama/models/sources/qwen3-coder-next/
```

### 4.2 Requantize to Q3_K_M

This takes about 10 minutes. `llama-quantize` ships with Ollama (check with `command -v llama-quantize`).

```bash
SRC=~/.ollama/models/sources/qwen3-coder-next
llama-quantize --allow-requantize \
  $SRC/Qwen3-Coder-Next-REAP-48B-A3B-Q4_K_XL.gguf \
  $SRC/Qwen3-Coder-Next-REAP-48B-A3B-Q3_K_M.gguf \
  Q3_K_M
```

Other target types: `Q4_K_M`, `Q3_K_L`, `Q3_K_S`, `Q2_K`, `IQ4_NL`, `IQ3_M`, `IQ2_M`.

### 4.3 Create the three presets

All three Modelfiles point at the same Q3_K_M GGUF, so Ollama stores the weights once. They share sampling parameters and differ only in `num_ctx` and `num_predict`.

```bash
ollama create qwen3-coder-next-standard -f ollama/modelfiles/Modelfile.qwen3-coder-next-standard
ollama create qwen3-coder-next-fast     -f ollama/modelfiles/Modelfile.qwen3-coder-next-fast
ollama create qwen3-coder-next-deep     -f ollama/modelfiles/Modelfile.qwen3-coder-next-deep
```

Each Modelfile has this shape (example: `standard`):

```
FROM /Users/vrock/.ollama/models/sources/qwen3-coder-next/Qwen3-Coder-Next-REAP-48B-A3B-Q3_K_M.gguf
PARAMETER temperature 1.0
PARAMETER top_k 40
PARAMETER top_p 0.95
PARAMETER num_ctx 131072
PARAMETER num_predict 2048
```

`FROM` needs an absolute path, so edit it if your home directory differs.

## 5. Preset configuration

| Preset | `num_ctx` | `num_predict` | `temperature` | `top_k` | `top_p` | Use it for |
|---|---:|---:|---:|---:|---:|---|
| `qwen3-coder-next-fast` | 90,112 (88K) | 1,024 | 1.0 | 40 | 0.95 | Quick edits, short answers |
| `qwen3-coder-next-standard` ⭐ | 131,072 (128K) | 2,048 | 1.0 | 40 | 0.95 | Default: largest context, balanced output |
| `qwen3-coder-next-deep` | 65,536 (64K) | 4,096 | 1.0 | 40 | 0.95 | Long generations and reasoning, at the cost of context |

### Memory budget

| Preset | Weights | KV cache | Peak | Headroom vs 37.4 GiB |
|---|---:|---:|---:|---:|
| `-fast` | 24 GB | 8.4 GiB | 32.4 GiB | 5.0 GiB |
| `-standard` | 24 GB | 12.2 GiB | 36.2 GiB | **1.2 GiB** |
| `-deep` | 24 GB | 6.1 GiB | 30.1 GiB | 7.3 GiB |

`-standard` is the tightest. Close other memory-heavy apps before using it, or fall back to `-fast`.

## 6. Verify

```bash
ollama list | grep qwen3-coder-next
ollama show qwen3-coder-next-standard --modelfile   # check num_ctx / num_predict

curl -s http://localhost:11434/api/generate \
  -d '{"model":"qwen3-coder-next-standard","prompt":"say hi","stream":false}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','ERROR'))"
```

`ollama show` also lists `TEMPLATE {{ .Prompt }}`. Ollama adds that default when it imports a GGUF, and the repo Modelfiles don't need to set it.

While a model is loaded, `ollama ps` shows the real memory use and whether any of it spilled to CPU. Check `sysctl vm.swapusage` for swap.

## 7. Troubleshooting

- **`mlx runner failed` / `[quantized_matmul]`:** the model was created from the old safetensors source. Remove and recreate it:
  ```bash
  ollama rm qwen3-coder-next-standard qwen3-coder-next-fast qwen3-coder-next-deep
  # then re-run the three `ollama create` commands from 4.3
  ```
- **Swap still growing on `-standard`:** drop to `-fast` (88K). There is only 1.2 GiB of headroom at 128K.
- **Quality dip on hard problems:** this is the cost of Q4 to Q3. Try `Q3_K_L` or `Q4_K_M` with a smaller context if memory allows.

## Stack

Ollama, `llama-quantize` (`--allow-requantize`), Qwen3-Coder-Next REAP-48B-A3B, M5 Pro 48 GB.
