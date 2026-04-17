#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_CHAT="${1:?usage: start-wechat-ai-reply.sh <target-chat> [style] [notify-log] [flow-log]}"
STYLE="${2:-自然、简短、礼貌，像正常群里沟通，不要太客套}"
NOTIFY_LOG="${3:-/tmp/wechat_notify.log}"
FLOW_LOG_PATH="${4:-/tmp/wechat_flow.log}"
mkdir -p /tmp/wechat-test
: > "$NOTIFY_LOG"
: > "$FLOW_LOG_PATH"
export FLOW_LOG_PATH
"$SCRIPT_DIR/prepare-target-chat.sh" "$TARGET_CHAT"
nohup bash "$ROOT_DIR/detector/wechat-detector.sh" notification-center "$NOTIFY_LOG" >/tmp/wechat-test/detector.out 2>/tmp/wechat-test/detector.err &
DETECTOR_PID=$!
nohup bash "$ROOT_DIR/bridge/watch-wechat-target-log-ai.sh" "$TARGET_CHAT" "$NOTIFY_LOG" "$STYLE" >/tmp/wechat-test/bridge-ai.out 2>/tmp/wechat-test/bridge-ai.err &
BRIDGE_PID=$!
printf 'detector=%s\nbridge=%s\n' "$DETECTOR_PID" "$BRIDGE_PID"
