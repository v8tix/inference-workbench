# Hardware

## MacBook Pro

| Field | Value |
|---|---|
| Chip | Apple M5 Pro |
| CPU cores | 18 (6 Super + 12 Performance) |
| GPU cores | 20 |
| Memory | 48 GB unified |
| Storage | 1 TB NVMe SSD (Apple Fabric) |
| macOS | 26.5.1 (Build 25F80) |
| Metal | Metal 4 |
| Display | 16" Liquid Retina XDR, 3456×2234 |

## Inference capacity

With 48 GB unified memory shared between CPU and GPU:

| Model size | Fits? | Notes |
|---|---|---|
| ~24 GB (Q3_K_M 48B, coder-next) | ⚠️ | ~36 GiB estimated peak at 128K context, ~1.2 GiB of headroom. Not validated under sustained load |
| ~18–20 GB (nvfp4 27B) | ⚠️ | ~29 GiB estimated peak at 90K context, but a real `qwen38-standard` session peaked at 39 GiB at only 68.6K tokens. See the caveat below |
| ~31 GB (mxfp8 27B) | ⚠️ | ~34–35 GiB estimated peak at 32K context, ~2 GiB of headroom. Unvalidated under real load; run it alone |
| ~40 GB | ❌ | No room for context or OS |
| 2× models loaded | ❌ | `OLLAMA_MAX_LOADED_MODELS=1` enforced |

"Fits" means the estimate is under the limit, not that it has been shown to be safe. The estimates below have run low on this machine.

GPU memory available for Metal: ~37.4 GiB (OS + system reserves ~10.6 GiB of 48 GB).

KV cache is configured at **q4_0** (via `~/.homebrew/services/ollama.env`, applied by `ollama/scripts/apply-runtime-config.sh`). Halving cache precision vs default halves memory growth:

KV cache growth rate used for estimates: ~0.095 GiB per 1K context tokens (a rough repo-wide figure, not measured per model).

Safe context ceiling formula:
```
safe_ctx = (37.4 GiB - weights_GiB) / 0.095 GiB × 1000
```

> ⚠️ **This formula underestimates real usage.** In the 2026-08-15 incident and again afterward on a fully fixed setup, `qwen38-standard` (18 GB weights, `num_ctx` 90,112) peaked at **39.01 GiB** with only 68,608 tokens in use, about 59% above what the formula predicts. See [qwen38-memory-incident-2026-08-15.md](qwen38-memory-incident-2026-08-15.md).

Formula output for reference (now known to be optimistic):
- 20 GB weights → ~183K tokens on paper. Treat it as unreliable past ~70–90K in practice; `qwen38-standard` is held at 88K after the incident, and `qwen36-standard` uses the same ceiling
- 24 GB weights → ~141K tokens on paper. `qwen3-coder-next-standard` runs at 128K, close to that ceiling
- 31 GB weights → ~67K tokens on paper. `qwen38-deep` (32K) has nominal headroom, but it is unvalidated under real load

## Software

| Tool | Version |
|---|---|
| Kronk | 1.25.8 |
| Homebrew | 5.1.15 |
| Shell | zsh |
| Go | installed (`/usr/local/go/bin`) |
| Node | v18.20.8 (nvm) |
