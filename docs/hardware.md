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
|---|---|---|---|
| ~20 GB (nvfp4 27–30B) | ✅ | ~29 GB peak with 90K context — comfortable |
| ~31 GB (mxfp8 30B) | ✅ | ~34 GB peak with 32K context — fits with headroom |
| ~40 GB | ⚠️ | No room for context or OS |
| 2× models loaded | ❌ | `OLLAMA_MAX_LOADED_MODELS=1` enforced |

GPU memory available for Metal: ~37.4 GiB (OS + system reserves ~10.6 GiB of 48 GB).

KV cache is configured at **q4_0** (launchd plist). Halving cache precision vs default halves memory growth:

KV cache growth rate (empirical, q4_0): ~0.095 GiB per 1K context tokens.

Safe context ceiling formula:
```
safe_ctx = (37.4 GiB - weights_GiB) / 0.095 GiB × 1000
```

Examples:
- 20 GB weights → safe_ctx ≈ 183K tokens — north-standard/qwen36-standard at 90K is well within budget
- 31 GB weights → safe_ctx ≈ 67K tokens — north-deep (32K) has nearly 2× headroom

## Software

| Tool | Version |
|---|---|
| Kronk | 1.25.8 |
| Homebrew | 5.1.15 |
| Shell | zsh |
| Go | installed (`/usr/local/go/bin`) |
| Node | v18.20.8 (nvm) |
