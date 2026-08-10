#!/usr/bin/env bash

set -euo pipefail

BACKEND_PORT="${BACKEND_PORT:-8080}"
FRONTEND_PORT="${FRONTEND_PORT:-4200}"
OPEN_BROWSER="${OPEN_BROWSER:-true}"

URLS=(
    "http://localhost:${FRONTEND_PORT}/"
    "http://localhost:${BACKEND_PORT}/api/v1/clock"
    "http://localhost:${BACKEND_PORT}/actuator/health"
)

if [[ "$OPEN_BROWSER" == "false" ]]; then
    printf '%s\n' "${URLS[@]}"
    exit 0
fi

case "$(uname -s)" in
    Darwin)
        command -v open >/dev/null 2>&1 || { printf 'ERROR: open is unavailable.\n' >&2; exit 1; }
        open "${URLS[@]}"
        ;;
    Linux)
        command -v xdg-open >/dev/null 2>&1 || {
            printf 'ERROR: xdg-open is unavailable. Use OPEN_BROWSER=false to print URLs.\n' >&2
            exit 1
        }
        for url in "${URLS[@]}"; do
            xdg-open "$url" >/dev/null 2>&1
        done
        ;;
    MINGW*|MSYS*|CYGWIN*)
        for url in "${URLS[@]}"; do
            cmd.exe /c start "" "$url"
        done
        ;;
    *)
        printf 'ERROR: Unsupported platform. Use OPEN_BROWSER=false to print URLs.\n' >&2
        exit 1
        ;;
esac
