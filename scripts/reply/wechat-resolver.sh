#!/bin/bash
set -euo pipefail
MODE="${1:-text}"
shift || true
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
case "$MODE" in
  text)
    # Normalize a raw notification text into structured JSON using the existing parser.
    exec "$SCRIPT_DIR/parse-wechat-notification.sh" "$@"
    ;;
  *)
    echo "usage: wechat-resolver.sh [text] ..." >&2
    exit 1
    ;;
esac
