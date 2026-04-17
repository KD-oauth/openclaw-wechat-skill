#!/bin/bash
set -euo pipefail
LOG_PATH="${1:-/tmp/wechat_notify.log}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec osascript "$SCRIPT_DIR/watch-wechat-notification-center.scpt" "$LOG_PATH"
