#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${PROJECT_DIR}/.run"
LOG_DIR="${PROJECT_DIR}/logs"
BACKEND_PORT="${BACKEND_PORT:-8080}"
FRONTEND_PORT="${FRONTEND_PORT:-4200}"
BACKEND_PID_FILE="${RUNTIME_DIR}/example-backend.pid"
FRONTEND_PID_FILE="${RUNTIME_DIR}/example-frontend.pid"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' is not installed or not on PATH."
}

port_is_listening() {
    lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

wait_for_url() {
    local name="$1"
    local url="$2"
    local pid="$3"
    local attempts="${4:-60}"

    for ((attempt = 1; attempt <= attempts; attempt++)); do
        if curl --fail --silent --output /dev/null "$url"; then
            printf '%s is ready: %s\n' "$name" "$url"
            return 0
        fi
        if ! kill -0 "$pid" 2>/dev/null; then
            printf 'ERROR: %s stopped before becoming ready. Check %s/%s.log\n' \
                "$name" "$LOG_DIR" "$name" >&2
            return 1
        fi
        sleep 1
    done

    printf 'ERROR: Timed out waiting for %s at %s\n' "$name" "$url" >&2
    return 1
}

require_command java
require_command mvn
require_command node
require_command npm
require_command curl
require_command lsof

[[ -f "${PROJECT_DIR}/example-frontend/package.json" ]] || fail \
    "example-frontend/package.json is missing. Complete tracker task 3.1 before starting both applications."

[[ ! -f "$BACKEND_PID_FILE" && ! -f "$FRONTEND_PID_FILE" ]] || fail \
    "Project PID files already exist. Run ./stop-dev-local.sh and retry."

port_is_listening "$BACKEND_PORT" && fail \
    "Backend port ${BACKEND_PORT} is already in use. Set BACKEND_PORT or stop the owning process."
port_is_listening "$FRONTEND_PORT" && fail \
    "Frontend port ${FRONTEND_PORT} is already in use. Set FRONTEND_PORT or stop the owning process."

mkdir -p "$RUNTIME_DIR" "$LOG_DIR"

printf 'Building backend...\n'
(cd "$PROJECT_DIR" && env DEBUG=false mvn --quiet -pl example-backend package)

BACKEND_JAR="${PROJECT_DIR}/example-backend/target/example-backend-1.0.0-SNAPSHOT.jar"
[[ -f "$BACKEND_JAR" ]] || fail "Backend build did not create ${BACKEND_JAR}."

printf 'Starting backend on port %s...\n' "$BACKEND_PORT"
java -jar "$BACKEND_JAR" --server.port="$BACKEND_PORT" \
    >"${LOG_DIR}/example-backend.log" 2>&1 &
BACKEND_PID=$!
printf '%s\n' "$BACKEND_PID" >"$BACKEND_PID_FILE"

printf 'Starting frontend on port %s...\n' "$FRONTEND_PORT"
(
    cd "${PROJECT_DIR}/example-frontend"
    exec ./node_modules/.bin/ng serve --host 127.0.0.1 --port "$FRONTEND_PORT"
) >"${LOG_DIR}/example-frontend.log" 2>&1 &
FRONTEND_PID=$!
printf '%s\n' "$FRONTEND_PID" >"$FRONTEND_PID_FILE"

if ! wait_for_url "example-backend" "http://localhost:${BACKEND_PORT}/actuator/health" "$BACKEND_PID" || \
   ! wait_for_url "example-frontend" "http://localhost:${FRONTEND_PORT}/" "$FRONTEND_PID"; then
    "${PROJECT_DIR}/stop-dev-local.sh"
    exit 1
fi

printf '\nLocal applications are running.\n'
printf 'Frontend: http://localhost:%s\n' "$FRONTEND_PORT"
printf 'Backend:  http://localhost:%s/api/v1/clock\n' "$BACKEND_PORT"
printf 'Logs:     %s\n' "$LOG_DIR"
printf 'Stop:     ./stop-dev-local.sh\n'
