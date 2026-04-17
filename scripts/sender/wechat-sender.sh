#!/bin/bash
set -euo pipefail
MODE="${1:-send}"
shift || true
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
case "$MODE" in
  send)
    exec "$SCRIPT_DIR/send-message.sh" "$@"
    ;;
  *)
    echo "usage: wechat-sender.sh [send] ..." >&2
    exit 1
    ;;
esac
