#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${PROJECT_DIR}/.run"

stop_from_pid_file() {
    local name="$1"
    local pid_file="$2"

    if [[ ! -f "$pid_file" ]]; then
        printf '%s is not tracked as running.\n' "$name"
        return 0
    fi

    local pid
    pid="$(tr -d '[:space:]' <"$pid_file")"
    if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
        printf 'WARNING: Ignoring invalid PID file %s\n' "$pid_file" >&2
        rm -f "$pid_file"
        return 0
    fi

    if ! kill -0 "$pid" 2>/dev/null; then
        printf '%s PID %s is no longer running; removing stale PID file.\n' "$name" "$pid"
        rm -f "$pid_file"
        return 0
    fi

    printf 'Stopping %s (PID %s)...\n' "$name" "$pid"
    kill -TERM "$pid"
    for _ in {1..20}; do
        if ! kill -0 "$pid" 2>/dev/null; then
            rm -f "$pid_file"
            printf '%s stopped.\n' "$name"
            return 0
        fi
        sleep 0.25
    done

    printf 'WARNING: %s did not stop after 5 seconds; sending KILL.\n' "$name" >&2
    kill -KILL "$pid" 2>/dev/null || true
    rm -f "$pid_file"
}

stop_from_pid_file "example-frontend" "${RUNTIME_DIR}/example-frontend.pid"
stop_from_pid_file "example-backend" "${RUNTIME_DIR}/example-backend.pid"

if [[ -d "$RUNTIME_DIR" ]] && ! find "$RUNTIME_DIR" -mindepth 1 -print -quit | grep -q .; then
    rmdir "$RUNTIME_DIR"
fi
