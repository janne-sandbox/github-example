#!/bin/sh
set -eu

: "${BACKEND_REST_BASE_URL:=http://localhost:8080}"
: "${BACKEND_WEBSOCKET_BASE_URL:=ws://localhost:8080}"
: "${RECONNECT_DELAY_MS:=1000}"

cat > /usr/share/nginx/html/config.js <<EOF
window.__CLOCK_CONFIG__ = {
  restBaseUrl: '${BACKEND_REST_BASE_URL}',
  webSocketBaseUrl: '${BACKEND_WEBSOCKET_BASE_URL}',
  reconnectDelayMs: ${RECONNECT_DELAY_MS}
};
EOF
