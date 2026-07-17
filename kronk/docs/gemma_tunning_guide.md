# 🎛️ Gemma Tuning Guide

This guide covers the available Gemma profiles and how to pick the right one for your work.

The local AI setup here runs on two components:

- **Kronk** — the local inference server that loads the model and handles all requests
- **OpenCode** — the AI coding tool that talks to Kronk and manages your sessions

Each profile configures both sides at once: it sets what the inference server loads, and it tells OpenCode how much context and output to budget per turn. You never need to touch either config directly — picking a profile is enough.

The idea is simple:

- some profiles are optimized for **speed**
- some profiles are optimized for **depth**
- the ladder mixes **32K token context window profiles** (faster) with **65K token context window profiles** (deeper)
- the main tradeoff is usually **response speed vs reasoning depth vs answer length**

## 🎯 The profile ladder at a glance

| Profile | Family | Context window | Thinking | Max output tokens | Best for | Why it exists |
|---|---|---:|---|---:|---|---|
| `gemma-turbo` | Speed | 32K tokens | off | 512 | ultra-fast iteration | keeps the loop as short and fast as possible |
| `gemma-fast` | Speed | 32K tokens | off | 1,024 | quick coding help | gives fast responses with a bit more room than turbo |
| `gemma-standard` | Speed | 65K tokens | off | 2,048 | daily default | adds more headroom for normal coding sessions without turning thinking on |
| `gemma-deep` | Depth | 65K tokens | on | 2,048 | tricky debugging and planning | adds reasoning depth and more room for larger working sets |
| `gemma-max` | Depth | 65K tokens | on | 4,096 | long deep answers | gives the most room for complex sessions and more complete responses |

## ⚡ Speed profiles

### `gemma-turbo`

Use this when you want the quickest possible back-and-forth.

It exists for moments where:

- you are iterating rapidly
- you want shorter answers
- speed matters more than completeness

```yaml
context-window: 32768
nseq-max: 2
sampling-parameters:
  temperature: 0.2
  max_tokens: 512
  enable_thinking: false
```

### `gemma-fast`

Use this when you still want a quick loop, but you need a little more room than turbo.

It exists for moments where:

- you want fast coding help
- the shortest profile feels too constrained
- you still prefer responsiveness over depth

```yaml
context-window: 32768
nseq-max: 2
sampling-parameters:
  temperature: 0.2
  max_tokens: 1024
  enable_thinking: false
```

### `gemma-standard`

This is the safest profile to recommend as the normal default.

It exists because most work does not need the fastest or deepest extreme:

- it stays practical for everyday tasks
- it keeps answers useful without getting too long
- it is the easiest starting point for most teammates

```yaml
context-window: 65536
nseq-max: 2
sampling-parameters:
  temperature: 0.2
  max_tokens: 2048
  enable_thinking: false
```

## 🧠 Depth profiles

### `gemma-deep`

Use this when the quality of reasoning matters more than raw speed.

It exists for moments where:

- the task is harder to reason about
- debugging or planning needs more depth
- you want better thinking without always jumping to the longest output

```yaml
context-window: 65536
nseq-max: 2
sampling-parameters:
  temperature: 0.2
  max_tokens: 2048
  enable_thinking: true
```

### `gemma-max`

Use this when you want the most complete and roomiest answer in the ladder.

It exists for moments where:

- the task needs deeper reasoning
- the answer will likely be longer
- completeness matters more than latency

```yaml
context-window: 65536
nseq-max: 2
sampling-parameters:
  temperature: 0.2
  max_tokens: 4096
  enable_thinking: true
```

## 🧭 Simple recommendation

If someone does not know where to start:

1. start with **`gemma-standard`**
2. move down to **`gemma-fast`** or **`gemma-turbo`** if the loop feels too slow
3. move up to **`gemma-deep`** or **`gemma-max`** only when better reasoning or longer answers are genuinely needed

## 💡 One important idea

The profiles are not about “better vs worse.”

They exist because different moments need different behavior:

- **speed profiles** help when you want momentum
- **depth profiles** help when you want more reasoning

That is why the ladder is useful: it gives a simple way to trade off speed, depth, and answer size without changing the whole workflow.

---

## ⚙️ What each profile actually configures

Each profile sets these values on the local inference server, and they are mirrored in the OpenCode configuration so both sides stay in sync. Included here so you have the full picture without needing access to the config files.

| Profile | Context window (tokens) | Max output tokens | Thinking | Concurrent slots |
|---|---:|---:|---|---:|
| `gemma-turbo` | 32,768 | 512 | off | 2 |
| `gemma-fast` | 32,768 | 1,024 | off | 2 |
| `gemma-standard` | 65,536 | 2,048 | off | 2 |
| `gemma-deep` | 65,536 | 2,048 | on | 2 |
| `gemma-max` | 65,536 | 4,096 | on | 2 |

### OpenCode ↔ inference server alignment

OpenCode declares what it expects from each profile. These values must match the inference server config — a mismatch causes context overflow (OpenCode fills more than the server can hold).

| Profile | OpenCode context limit | Server context window | OpenCode output limit | Server max output |
|---|---:|---:|---:|---:|
| `gemma-turbo` | 32,768 | 32,768 | 512 | 512 |
| `gemma-fast` | 32,768 | 32,768 | 1,024 | 1,024 |
| `gemma-standard` | 65,536 | 65,536 | 2,048 | 2,048 |
| `gemma-deep` | 65,536 | 65,536 | 2,048 | 2,048 |
| `gemma-max` | 65,536 | 65,536 | 4,096 | 4,096 |

- **Context window** — how many tokens the model holds in memory at once (conversation history + your prompt + its answer)
- **Max output tokens** — hard cap on how long the model's answer can be
- **Thinking** — whether the model reasons step-by-step before answering (slower but deeper)
- **Concurrent slots** — how many requests the server handles in parallel without canceling one

---

## 📊 What healthy `gemma-standard` looks like

A well-configured `gemma-standard` session with a typical agentic context (~43K tokens, IMC cache warm) should look like this:

| Metric | Expected |
|---|---|
| IMC cache restored | ~90 ms |
| TTFT (time to first token) | 1.7 – 2.5 s |
| TPS (tokens per second) | ~27 |
| Total elapsed (agentic turn) | 7 – 30 s |
| Context usage | 60 – 70% of the context window |
| Errors | none |

If you are seeing `context canceled` errors or TTFT in the minutes range, that is a signal something is wrong with the profile or the session context has grown past a healthy size.

> **Note:** `nseq-max: 1` was briefly used but caused `context canceled` errors when OpenCode fired a second concurrent request while a long prefill was in progress. All profiles now use `nseq-max: 2`.

---

## 🔄 How to switch profiles

Use the interactive picker — it shows all profiles, marks the active one, and applies your selection:

```bash
bash scripts/use_preset.sh
```

Or apply a specific profile directly:

```bash
bash scripts/apply_llm_profile.sh gemma-standard
```

Both commands switch the inference server config, restart Kronk, and update OpenCode's default model.
