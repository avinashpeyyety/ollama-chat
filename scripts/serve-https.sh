#!/usr/bin/env bash
# Durable local HTTPS for Ollama Chat (control :3443 + main :3445).
# Usage:
#   ./scripts/serve-https.sh
#   ./scripts/serve-https.sh stop|status|restart
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
USER_PORT="${USER_PORT:-3443}"
MAIN_PORT="${MAIN_PORT:-3445}"
LOG="${OLLAMA_CHAT_LOG:-/tmp/ollama-chat-https.log}"
PIDFILE="/tmp/ollama-chat-https.pid"

cmd="${1:-start}"

listening() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

status() {
  local ok=0
  if listening "$USER_PORT"; then
    echo "running  https://127.0.0.1:${USER_PORT}  (supervisor)"
  else
    echo "stopped  https://127.0.0.1:${USER_PORT}  (supervisor)"
    ok=1
  fi
  if listening "$MAIN_PORT"; then
    echo "running  https://127.0.0.1:${MAIN_PORT}  (chat)"
  else
    echo "stopped  https://127.0.0.1:${MAIN_PORT}  (chat)"
    ok=1
  fi
  return $ok
}

stop() {
  # Prefer package stop, then port kill
  (cd "$ROOT" && npm run stop --silent 2>/dev/null) || true
  for p in "$USER_PORT" "$MAIN_PORT"; do
    local pids
    pids="$(lsof -nP -iTCP:"$p" -sTCP:LISTEN -t 2>/dev/null || true)"
    if [[ -n "${pids}" ]]; then
      # shellcheck disable=SC2086
      kill $pids 2>/dev/null || true
      sleep 0.2
      # shellcheck disable=SC2086
      kill -9 $pids 2>/dev/null || true
    fi
  done
  rm -f "$PIDFILE"
  echo "stopped  ollama-chat HTTPS"
}

start() {
  if listening "$USER_PORT" && listening "$MAIN_PORT"; then
    status
    return 0
  fi
  cd "$ROOT"
  if [[ ! -f certs/cert.pem || ! -f certs/key.pem ]]; then
    npm run setup
  fi
  # If only main is up (orphan), leave it; start supervisor which reuses main
  nohup env USER_PORT="$USER_PORT" MAIN_PORT="$MAIN_PORT" node control-server.js \
    >>"$LOG" 2>&1 &
  echo $! >"$PIDFILE"
  disown 2>/dev/null || true
  for _ in $(seq 1 50); do
    if listening "$MAIN_PORT"; then
      status || true
      echo "  UI: https://127.0.0.1:${USER_PORT}  (or :${MAIN_PORT})"
      echo "  log: ${LOG}"
      return 0
    fi
    sleep 0.2
  done
  echo "failed to start ollama-chat — see ${LOG}" >&2
  tail -40 "$LOG" >&2 || true
  return 1
}

case "$cmd" in
  start) start ;;
  stop) stop ;;
  status) status ;;
  restart) stop; sleep 0.4; start ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}" >&2
    exit 2
    ;;
esac
