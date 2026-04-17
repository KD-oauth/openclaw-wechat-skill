#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_CHAT="${1:?usage: start-wechat-fixed-reply.sh <target-chat> [reply-text] [style] [notify-log] [flow-log]}"
REPLY_TEXT="${2:-收到，我来处理。}"
STYLE="${3:-自然、简短、礼貌，像正常群里沟通，不要太客套}"
NOTIFY_LOG="${4:-/tmp/wechat_notify.log}"
FLOW_LOG_PATH="${5:-/tmp/wechat_flow.log}"
mkdir -p /tmp/wechat-test
: > "$NOTIFY_LOG"
: > "$FLOW_LOG_PATH"
export FLOW_LOG_PATH
"$SCRIPT_DIR/prepare-target-chat.sh" "$TARGET_CHAT"
nohup bash "$ROOT_DIR/detector/wechat-detector.sh" notification-center "$NOTIFY_LOG" >/tmp/wechat-test/detector.out 2>/tmp/wechat-test/detector.err &
DETECTOR_PID=$!
nohup bash "$ROOT_DIR/bridge/watch-wechat-target-log.sh" "$TARGET_CHAT" "$NOTIFY_LOG" "$STYLE" "$REPLY_TEXT" >/tmp/wechat-test/bridge.out 2>/tmp/wechat-test/bridge.err &
BRIDGE_PID=$!
printf 'detector=%s\nbridge=%s\n' "$DETECTOR_PID" "$BRIDGE_PID"
