#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
PORT="${PORT:-8000}"
echo "Starting server at http://localhost:${PORT}/simple.html"
python3 -m http.server "$PORT"
