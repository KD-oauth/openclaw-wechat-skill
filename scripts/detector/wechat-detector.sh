#!/bin/bash
set -euo pipefail
MODE="${1:-notification-center}"
shift || true
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
case "$MODE" in
  notification-center)
    exec "$SCRIPT_DIR/watch-wechat-notification-center.sh" "$@"
    ;;
  *)
    echo "usage: wechat-detector.sh [notification-center] ..." >&2
    exit 1
    ;;
esac
