#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_PORT="${BACKEND_PORT:-8080}"
FRONTEND_PORT="${FRONTEND_PORT:-4200}"
BACKEND_URL="http://localhost:${BACKEND_PORT}"
FRONTEND_URL="http://localhost:${FRONTEND_PORT}"
STARTED_SERVICES=false

cleanup() {
    if [[ "$STARTED_SERVICES" == "true" ]]; then
        "${PROJECT_DIR}/stop-dev-local.sh"
    fi
}
trap cleanup EXIT INT TERM

command -v curl >/dev/null 2>&1 || { printf 'ERROR: curl is required.\n' >&2; exit 1; }
command -v node >/dev/null 2>&1 || { printf 'ERROR: Node.js is required.\n' >&2; exit 1; }

if ! curl --fail --silent --output /dev/null "${BACKEND_URL}/actuator/health" || \
   ! curl --fail --silent --output /dev/null "${FRONTEND_URL}/"; then
    printf 'Local applications are not both ready; starting them for the smoke test...\n'
    "${PROJECT_DIR}/start-dev-local.sh"
    STARTED_SERVICES=true
fi

HEALTH_JSON="$(curl --fail --silent "${BACKEND_URL}/actuator/health")"
CLOCK_JSON="$(curl --fail --silent "${BACKEND_URL}/api/v1/clock")"
FRONTEND_HTML="$(curl --fail --silent "${FRONTEND_URL}/")"

HEALTH_JSON="$HEALTH_JSON" CLOCK_JSON="$CLOCK_JSON" FRONTEND_HTML="$FRONTEND_HTML" node <<'NODE'
const health = JSON.parse(process.env.HEALTH_JSON);
const clock = JSON.parse(process.env.CLOCK_JSON);
if (health.status !== 'UP') throw new Error(`Backend health was ${health.status}`);
if (!clock.text?.startsWith('Hello World, clock is ')) throw new Error('Invalid REST clock text');
if (Number.isNaN(Date.parse(clock.timestamp))) throw new Error('Invalid REST timestamp');
if (!process.env.FRONTEND_HTML.includes('<app-root')) throw new Error('Frontend app root was not rendered in HTML');
console.log('PASS: health, REST payload, and frontend HTML');
NODE

WS_URL="ws://localhost:${BACKEND_PORT}/ws/clock" node <<'NODE'
const messages = [];
const socket = new WebSocket(process.env.WS_URL);
const timeout = setTimeout(() => {
  console.error('FAIL: timed out waiting for WebSocket messages');
  process.exit(1);
}, 5000);

socket.onmessage = event => {
  const payload = JSON.parse(event.data);
  if (!payload.text?.startsWith('Hello World, clock is ') || Number.isNaN(Date.parse(payload.timestamp))) {
    console.error('FAIL: invalid WebSocket clock payload');
    process.exit(1);
  }
  messages.push({ receivedAt: Date.now(), payload });
  if (messages.length === 2) {
    clearTimeout(timeout);
    const interval = messages[1].receivedAt - messages[0].receivedAt;
    if (interval < 750 || interval > 1500) {
      console.error(`FAIL: WebSocket interval ${interval} ms is outside 750-1500 ms`);
      process.exit(1);
    }
    console.log(`PASS: two WebSocket messages received ${interval} ms apart`);
    socket.close();
    process.exit(0);
  }
};

socket.onerror = () => {
  clearTimeout(timeout);
  console.error('FAIL: WebSocket connection error');
  process.exit(1);
};
NODE

printf 'Smoke tests passed.\n'
