#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_CHAT="${1:-}"
NOTIFICATION_TEXT="${2:-}"
STYLE="${3:-自然、简短、礼貌，像正常群里沟通，不要太客套}"
REPLY_TEXT="${4:-}"
FLOW_LOG_PATH="${FLOW_LOG_PATH:-/tmp/wechat_flow.log}"
LOGGER="$ROOT_DIR/logging/log-wechat-flow.sh"
if [[ -z "$TARGET_CHAT" || -z "$NOTIFICATION_TEXT" ]]; then
  echo "usage: wechat-flow-target.sh <target-chat> <notification-text> [style] [reply-text]" >&2
  exit 1
fi

"$LOGGER" "$FLOW_LOG_PATH" flow target_flow_started \
  targetChat="$TARGET_CHAT" \
  notificationText="$NOTIFICATION_TEXT"

PARSED_JSON="$($ROOT_DIR/reply/parse-wechat-notification.sh "$NOTIFICATION_TEXT")"
CHAT_NAME="$(python3 - "$PARSED_JSON" <<'PY'
import json, sys
print(json.loads(sys.argv[1]).get('chatName', ''))
PY
)"
MESSAGE="$(python3 - "$PARSED_JSON" <<'PY'
import json, sys
print(json.loads(sys.argv[1]).get('message', ''))
PY
)"
SENDER="$(python3 - "$PARSED_JSON" <<'PY'
import json, sys
print(json.loads(sys.argv[1]).get('sender', ''))
PY
)"
"$LOGGER" "$FLOW_LOG_PATH" flow notification_parsed \
  targetChat="$TARGET_CHAT" \
  chat="$CHAT_NAME" \
  sender="$SENDER" \
  message="$MESSAGE"

if [[ -z "$CHAT_NAME" ]]; then
  "$LOGGER" "$FLOW_LOG_PATH" flow parse_failed \
    targetChat="$TARGET_CHAT" \
    notificationText="$NOTIFICATION_TEXT" \
    error="Could not extract chat name from notification text"
  echo "Could not extract chat name from notification text" >&2
  exit 2
fi

if [[ "$CHAT_NAME" != "$TARGET_CHAT" ]]; then
  "$LOGGER" "$FLOW_LOG_PATH" flow target_ignored \
    targetChat="$TARGET_CHAT" \
    chat="$CHAT_NAME"
  echo "Ignoring notification for chat: $CHAT_NAME" >&2
  exit 3
fi

"$LOGGER" "$FLOW_LOG_PATH" flow target_matched \
  targetChat="$TARGET_CHAT" \
  chat="$CHAT_NAME"

if [[ -z "$REPLY_TEXT" ]]; then
  PROMPT="$($ROOT_DIR/reply/suggest-reply.sh "$CHAT_NAME" "$MESSAGE" "$SENDER" "$STYLE")"
  "$LOGGER" "$FLOW_LOG_PATH" drafter prompt_generated \
    targetChat="$TARGET_CHAT" \
    chat="$CHAT_NAME" \
    prompt="$PROMPT"
  printf '%s\n' "$PROMPT"
  exit 0
fi

"$LOGGER" "$FLOW_LOG_PATH" sender send_requested \
  targetChat="$TARGET_CHAT" \
  chat="$CHAT_NAME" \
  reply="$REPLY_TEXT"
if "$ROOT_DIR/sender/send-message.sh" "$TARGET_CHAT" "$REPLY_TEXT"; then
  "$LOGGER" "$FLOW_LOG_PATH" sender send_succeeded \
    targetChat="$TARGET_CHAT" \
    chat="$CHAT_NAME"
  printf 'Sent reply into target chat: %s\n' "$TARGET_CHAT"
else
  "$LOGGER" "$FLOW_LOG_PATH" sender send_failed \
    targetChat="$TARGET_CHAT" \
    chat="$CHAT_NAME" \
    reply="$REPLY_TEXT"
  exit 4
fi
