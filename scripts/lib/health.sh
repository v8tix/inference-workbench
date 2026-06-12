#!/usr/bin/env bash

KRONK_HEALTH_URL="${KRONK_HEALTH_URL:-http://localhost:11435/health}"

is_http_healthy() {
  local url="$1"
  curl -sf "$url" > /dev/null 2>&1
}

is_kronk_running() {
  pgrep -f "kronk server" > /dev/null 2>&1
}

first_kronk_pid() {
  pgrep -f "kronk server" | head -1
}

is_kronk_healthy() {
  is_kronk_running && is_http_healthy "${1:-$KRONK_HEALTH_URL}"
}
