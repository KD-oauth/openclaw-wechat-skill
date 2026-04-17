#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_CHAT="${1:-}"
LOG_PATH="${2:-/tmp/wechat_notify.log}"
STYLE="${3:-自然、简短、礼貌，像正常群里沟通，不要太客套}"
REPLY_TEXT="${4:-}"
STATE_DIR="${STATE_DIR:-/tmp/wechat-target-log}"
LAST_OFFSET_FILE="$STATE_DIR/last_offset"
FLOW_LOG_PATH="${FLOW_LOG_PATH:-/tmp/wechat_flow.log}"
LOGGER="$ROOT_DIR/logging/log-wechat-flow.sh"
mkdir -p "$STATE_DIR"

if [[ -z "$TARGET_CHAT" ]]; then
  echo "usage: watch-wechat-target-log.sh <target-chat> [log-path] [style] [reply-text]" >&2
  exit 1
fi

if [[ ! -f "$LOG_PATH" ]]; then
  touch "$LOG_PATH"
fi

LAST_OFFSET=0
if [[ -f "$LAST_OFFSET_FILE" ]]; then
  LAST_OFFSET="$(cat "$LAST_OFFSET_FILE" 2>/dev/null || echo 0)"
fi

process_line() {
  local line="$1"
  [[ "$line" == WECHAT:* ]] || return 0
  local payload="${line#WECHAT:}"
  local chat_name="${payload%%|||*}"
  local preview="${payload#*|||}"
  [[ -n "$chat_name" && -n "$preview" ]] || return 0

  local notification_text
  "$LOGGER" "$FLOW_LOG_PATH" bridge detector_line_seen \
    targetChat="$TARGET_CHAT" \
    rawLine="$line" \
    chat="$chat_name" \
    preview="$preview"

  notification_text="$chat_name: $preview"
  "$LOGGER" "$FLOW_LOG_PATH" bridge notification_normalized \
    targetChat="$TARGET_CHAT" \
    chat="$chat_name" \
    preview="$preview" \
    notificationText="$notification_text"

  if [[ "$chat_name" != "$TARGET_CHAT" ]]; then
    "$LOGGER" "$FLOW_LOG_PATH" bridge target_ignored \
      targetChat="$TARGET_CHAT" \
      chat="$chat_name" \
      preview="$preview"
    return 0
  fi

  "$LOGGER" "$FLOW_LOG_PATH" bridge target_matched \
    targetChat="$TARGET_CHAT" \
    chat="$chat_name" \
    preview="$preview"

  if [[ -n "$REPLY_TEXT" ]]; then
    "$SCRIPT_DIR/wechat-flow-target.sh" "$TARGET_CHAT" "$notification_text" "$STYLE" "$REPLY_TEXT"
  else
    "$SCRIPT_DIR/wechat-flow-target.sh" "$TARGET_CHAT" "$notification_text" "$STYLE"
  fi
}

while true; do
  size=$(wc -c < "$LOG_PATH")
  if [[ "$size" -lt "$LAST_OFFSET" ]]; then
    LAST_OFFSET=0
  fi
  if [[ "$size" -gt "$LAST_OFFSET" ]]; then
    chunk=$(tail -c +$((LAST_OFFSET + 1)) "$LOG_PATH")
    while IFS= read -r line; do
      process_line "$line"
    done <<< "$chunk"
    LAST_OFFSET="$size"
    printf '%s' "$LAST_OFFSET" > "$LAST_OFFSET_FILE"
  fi
  sleep 1
done
