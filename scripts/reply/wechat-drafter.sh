#!/bin/bash
set -euo pipefail
MODE="${1:-suggest}"
shift || true
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
case "$MODE" in
  suggest)
    exec "$SCRIPT_DIR/suggest-reply.sh" "$@"
    ;;
  *)
    echo "usage: wechat-drafter.sh [suggest] ..." >&2
    exit 1
    ;;
esac
