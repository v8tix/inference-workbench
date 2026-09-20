# 🧩 Structured Output (JSON Schema) Support

The preset ladder in `preset-guide.md` is tuned for the OpenCode coding-assistant
use case — chat/completion only. It does **not** cover structured output
(JSON-schema-constrained generation, e.g. OpenAI's `response_format:
json_schema`, or an agent framework's `OutputSchema`), which agentic
frameworks calling Ollama directly (outside OpenCode) may need.

## Finding: MLX presets can't do it, a GGUF quant of the same model can

Confirmed live against Ollama 0.33.2 on this machine, both on the OpenAI-compatible
`/v1/chat/completions` endpoint and the `/v1/responses` endpoint (the surface
Google's ADK Go SDK's `openaimodel` package targets):

| Model | Quant / runner | `response_format: json_schema` (strict) |
|---|---|---|
| `qwen38-standard` (and every other `mlx-nvfp4`/`mlx-mxfp8` preset in this repo) | MLX | ❌ `501 Not Implemented` — `{"message":"structured output is unavailable"}` |
| `qwen3.8:27b` (Q4_K_M) | GGUF / llama.cpp | ✅ `200 OK` — valid JSON matching the schema, on both endpoints |

Same model family (Qwen 3.5/3.8, ~27B), same Ollama server — the deciding
factor is quantization/runtime, not the model weights themselves. **All
presets in this repo's ladder use the MLX runner** (see `preset-guide.md`:
"No GGUF/llama.cpp"), so none of them can serve grammar-constrained /
JSON-schema-constrained output today. `qwen3.8:27b` is already pulled on this
machine (`ollama list`) but isn't one of this repo's managed presets or
Modelfiles — it was pulled directly, outside `use_preset.sh`/`apply_preset.sh`.

## Reproduction

```bash
curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen38-standard",
    "messages": [{"role": "user", "content": "hello"}],
    "response_format": {"type": "json_schema", "json_schema": {
      "name": "x", "strict": true,
      "schema": {"type": "object", "properties": {"a": {"type": "string"}}, "required": ["a"]}
    }}
  }'
# → 501 Not Implemented: "structured output is unavailable"

curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.8:27b",
    "messages": [{"role": "user", "content": "hello"}],
    "response_format": {"type": "json_schema", "json_schema": {
      "name": "x", "strict": true,
      "schema": {"type": "object", "properties": {"a": {"type": "string"}}, "required": ["a"]}
    }}
  }'
# → 200 OK, valid JSON
```

## Recommendation

For anything that needs guaranteed JSON-schema-shaped output from this
machine's Ollama server (agent frameworks, function-calling with strict
schemas, etc.), point it at a GGUF-quantized model — `qwen3.8:27b` is
already available — rather than any `north-*`/`qwen36-*`/`qwen38-*` MLX
preset. This doesn't change the OpenCode presets or scripts in this repo;
it's a separate, unmanaged model to reach for when structured output is a
requirement, not a coding-assistant chat session.

No new preset or Modelfile was added for this — `qwen3.8:27b` works as-is
with Ollama's default parameters. If a dedicated preset (custom context/output
budget) turns out to be worth managing here later, it belongs alongside the
`qwen36-*`/`north-*` Modelfiles following the same pattern.
