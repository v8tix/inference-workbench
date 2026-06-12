#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$SCRIPT_LIB/colors.sh"
source "$SCRIPT_LIB/health.sh"

warmup_kronk_server() {
  local warmup_payload

  warmup_payload=$(cat <<EOF
{"model":"$KRONK_MODELS","messages":[{"role":"user","content":"Warm up."}],"max_tokens":1,"temperature":0}
EOF
)

  if curl -sf \
    --max-time 30 \
    -H "Content-Type: application/json" \
    -d "$warmup_payload" \
    "http://localhost:11435/v1/chat/completions" > /dev/null 2>&1; then
    green "  Kronk warm-up complete ✓"
    return 0
  fi

  yellow "  Warm-up request failed — first real request may be slower"
  return 0
}

stop_kronk_server() {
  local kronk_pid
  kronk_pid="$(pgrep -f "kronk server" | head -1 || true)"

  if [[ -n "$kronk_pid" ]]; then
    yellow "Stopping Kronk (native, PID $kronk_pid)..."
    if kill "$kronk_pid" 2>/dev/null; then
      for _ in {1..5}; do
        if ! kill -0 "$kronk_pid" 2>/dev/null; then
          green "Kronk stopped ✓"
          return 0
        fi
        sleep 1
      done
    fi

    kill -9 "$kronk_pid" 2>/dev/null || true
    green "Kronk force-stopped ✓"
    return 0
  fi

  yellow "Kronk is not running"
  return 0
}

start_kronk_server() {
  local force="${1:-false}"
  local kronk_pid kronk_log

  bold "Starting Kronk (native macOS / Metal GPU)..."

  if [[ "$force" != "true" ]] && is_kronk_healthy; then
    kronk_pid="$(first_kronk_pid)"
    green "  Kronk already running and healthy — skipping restart ✓"
    cyan "  Use 'bash $SCRIPT_DIR/restart.sh' to force a full restart"
    return 0
  fi

  if is_kronk_running; then
    yellow "  Kronk process found but unhealthy — restarting..."
    stop_kronk_server
  fi

  mkdir -p "$LOGS_DIR"
  kronk_log="$LOGS_DIR/kronk_$(date +%Y%m%d_%H%M%S).log"

  perl -MPOSIX=setsid -e 'setsid() or die "setsid failed: $!"; exec @ARGV or die "exec failed: $!"' \
    kronk server start \
    --base-path "$KRONK_BASE" \
    --api-host "${KRONK_WEB_API_HOST:-0.0.0.0:11435}" \
    --debug-host "${KRONK_WEB_DEBUG_HOST:-0.0.0.0:8091}" \
    --model-config-file "$MODEL_CONFIG" \
    --models-in-pool 1 \
    < /dev/null > "$kronk_log" 2>&1 &
  kronk_pid=$!
  disown "$kronk_pid" 2>/dev/null || true

  echo "  PID : $kronk_pid"
  echo "  Log : $kronk_log"
  echo ""
  echo "  Waiting for Kronk to be ready (up to 60s)..."

  for _ in {1..30}; do
    sleep 2
    if is_http_healthy "$KRONK_HEALTH_URL"; then
      green "  Kronk is ready ✓"
      warmup_kronk_server
      return 0
    fi
    if ! kill -0 "$kronk_pid" 2>/dev/null; then
      red "  ERROR: Kronk process died — check $kronk_log"
      tail -30 "$kronk_log"
      yellow "  Possible fixes:"
      yellow "    - rerun start.sh after Kronk update"
      yellow "    - remove ~/.kronk/libraries and let the script repair them"
      yellow "    - verify model config and model files"
      return 1
    fi
    printf "."
  done

  echo ""
  red "  ERROR: Timed out waiting for Kronk health"
  return 1
}
