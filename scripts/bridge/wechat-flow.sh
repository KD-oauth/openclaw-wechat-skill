#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
NOTIFICATION_TEXT="${1:-}"
STYLE="${2:-自然、简短、礼貌}"
REPLY_TEXT="${3:-}"
FLOW_LOG_PATH="${FLOW_LOG_PATH:-/tmp/wechat_flow.log}"
LOGGER="$ROOT_DIR/logging/log-wechat-flow.sh"
if [[ -z "$NOTIFICATION_TEXT" ]]; then
  echo "usage: wechat-flow.sh <notification-text> [style] [reply-text]" >&2
  exit 1
fi

"$LOGGER" "$FLOW_LOG_PATH" flow flow_started \
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
  chat="$CHAT_NAME" \
  sender="$SENDER" \
  message="$MESSAGE"

if [[ -z "$CHAT_NAME" ]]; then
  "$LOGGER" "$FLOW_LOG_PATH" flow parse_failed \
    notificationText="$NOTIFICATION_TEXT" \
    error="Could not extract chat name from notification text"
  echo "Could not extract chat name from notification text" >&2
  exit 2
fi

if [[ -z "$REPLY_TEXT" ]]; then
  PROMPT="$($ROOT_DIR/reply/suggest-reply.sh "$CHAT_NAME" "$MESSAGE" "$SENDER" "$STYLE")"
  "$LOGGER" "$FLOW_LOG_PATH" drafter prompt_generated \
    chat="$CHAT_NAME" \
    prompt="$PROMPT"
  printf '%s\n' "$PROMPT"
  exit 0
fi

"$LOGGER" "$FLOW_LOG_PATH" sender send_requested \
  chat="$CHAT_NAME" \
  reply="$REPLY_TEXT"
if "$ROOT_DIR/sender/send-message.sh" "$CHAT_NAME" "$REPLY_TEXT"; then
  "$LOGGER" "$FLOW_LOG_PATH" sender send_succeeded \
    chat="$CHAT_NAME"
  printf 'Sent reply into chat: %s\n' "$CHAT_NAME"
else
  "$LOGGER" "$FLOW_LOG_PATH" sender send_failed \
    chat="$CHAT_NAME" \
    reply="$REPLY_TEXT"
  exit 4
fi
