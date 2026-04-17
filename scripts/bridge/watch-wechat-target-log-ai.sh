#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_CHAT="${1:-}"
LOG_PATH="${2:-/tmp/wechat_notify.log}"
STYLE="${3:-自然、简短、礼貌，像正常群里沟通，不要太客套}"
STATE_DIR="${STATE_DIR:-/tmp/wechat-target-log-ai}"
LAST_OFFSET_FILE="$STATE_DIR/last_offset"
FLOW_LOG_PATH="${FLOW_LOG_PATH:-/tmp/wechat_flow.log}"
LOGGER="$ROOT_DIR/logging/log-wechat-flow.sh"
mkdir -p "$STATE_DIR"

if [[ -z "$TARGET_CHAT" ]]; then
  echo "usage: watch-wechat-target-log-ai.sh <target-chat> [log-path] [style]" >&2
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

  "$LOGGER" "$FLOW_LOG_PATH" bridge detector_line_seen \
    targetChat="$TARGET_CHAT" \
    rawLine="$line" \
    chat="$chat_name" \
    preview="$preview"

  local notification_text="$chat_name: $preview"
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

  local parsed_json sender message reply_text
  parsed_json="$($ROOT_DIR/reply/parse-wechat-notification.sh "$notification_text")"
  sender="$(python3 - "$parsed_json" <<'PY'
import json, sys
print(json.loads(sys.argv[1]).get('sender', ''))
PY
)"
  message="$(python3 - "$parsed_json" <<'PY'
import json, sys
print(json.loads(sys.argv[1]).get('message', ''))
PY
)"

  "$LOGGER" "$FLOW_LOG_PATH" ai_auto_reply generation_requested \
    targetChat="$TARGET_CHAT" \
    chat="$chat_name" \
    sender="$sender" \
    message="$message"

  if ! reply_text="$($ROOT_DIR/reply/generate-reply-openclaw.sh "$chat_name" "$message" "$sender" "$STYLE")"; then
    "$LOGGER" "$FLOW_LOG_PATH" ai_auto_reply generation_failed \
      targetChat="$TARGET_CHAT" \
      chat="$chat_name" \
      sender="$sender" \
      message="$message"
    return 0
  fi

  "$LOGGER" "$FLOW_LOG_PATH" ai_auto_reply generation_succeeded \
    targetChat="$TARGET_CHAT" \
    chat="$chat_name" \
    reply="$reply_text"

  "$ROOT_DIR/sender/send-message.sh" "$chat_name" "$reply_text"
  "$LOGGER" "$FLOW_LOG_PATH" ai_auto_reply send_completed \
    targetChat="$TARGET_CHAT" \
    chat="$chat_name" \
    reply="$reply_text"
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
