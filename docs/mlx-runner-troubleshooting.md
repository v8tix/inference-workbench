# MLX Runner Troubleshooting Guide

This guide covers diagnosing and fixing "mlx runner exited unexpectedly" and "mlx runner failed" errors in Ollama on Apple Silicon.

---

## Common error patterns

### 1. `mlx runner exited unexpectedly: exit status 2`

**Log entry:**
```
flag provided but not defined: -mlx-engine
Usage of mlxrunner:
  -model string   Model name
  -port int       Port to listen on
  -verbose        Enable debug logging
```

**Root cause:** Ollama server version is outdated. The server passes a `-mlx-engine` flag that the bundled `mlxrunner` binary doesn't recognize.

**Fix:**
```bash
brew upgrade ollama
brew services restart ollama
ollama --version   # should show 0.34.2+
```

### 2. `mlx runner failed: panic: [quantized_matmul] incompatible shapes`

**Error:**
```
mlx: [quantized_matmul] The shapes of the weight and scales are incompatible
based on bits and group_size. w.shape() == (308,512) and scales.shape() == (308,32)
with group_size=64 and bits=4
```

**Root cause:** The model's MLX (safetensors) weights were quantized with a different MLX library version and have broken metadata. This is a model-level issue, not an Ollama issue.

**Fix:** Switch to a GGUF version of the same model, or find a different source for the MLX weights.

### 3. `mlx runner process died` / `signal: killed`

**Root cause:** Out of memory — the model weights + KV cache exceed available GPU memory (48 GB ceiling on this machine).

**Fix:** Reduce context window or switch to a smaller model variant.

### 4. `mlx runner failed` with no model-specific error

**Root cause:** The `mlx` or `mlx-lm` Python packages are not installed, or installed for the wrong Python version.

**Fix:**
```bash
pip3 install mlx mlx-lm
# If using uv:
uv tool install mlx-lm
```

---

## Checking the Ollama log

```bash
cat /opt/homebrew/var/log/ollama.log | grep -i -A3 -B3 "mlx\|error\|exit\|runner" | tail -80
```

## Checking which backend a model uses

```bash
curl -s http://localhost:11434/api/show -d '{"model":"<model-name>"}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('Format:', d['details']['format'])"
```

- `safetensors` = MLX backend
- `gguf` = llama.cpp backend

## Preventing MLX model issues

Only a subset of models publish MLX-compatible safetensors weights. Before importing:

1. Check if the HF repo explicitly supports MLX (look for `mlx` tags or `mlx_lm` usage)
2. Prefer GGUF versions when available — they work with llama.cpp/Metal and are more broadly tested
3. If you must use MLX weights, verify the quantization was created with a recent `mlx-lm` version

## Manual MLX runner test

```bash
# Test if mlx_lm can load the model directly
mlx_lm generate --model /path/to/model --prompt "hello" --max-tokens 10

# Start an MLX server to check HTTP inference
mlx_lm server --model /path/to/model --port 8080
```

## Related

- [mlx-vs-gguf.md](mlx-vs-gguf.md) — architectural comparison of the two backends
- [qwen3-coder-next-guide.md](../ollama/docs/qwen3-coder-next-guide.md) — specific guide for the Qwen3-Coder-Next model that hit this issue