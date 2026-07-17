#!/usr/bin/env bash

is_ollama_running() {
  pgrep -x "ollama" > /dev/null 2>&1
}

is_ollama_healthy() {
  curl -sf "${OLLAMA_HEALTH_URL:-http://localhost:11434}" > /dev/null 2>&1
}

first_ollama_pid() {
  pgrep -x "ollama" | head -1
}
