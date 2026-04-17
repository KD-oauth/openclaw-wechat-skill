#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CHAT_LABEL="${1:-当前聊天}"
MESSAGE="${2:?usage: send-message.sh <chat-label> <message>}"
FLOW_LOG_PATH="${FLOW_LOG_PATH:-/tmp/wechat_flow.log}"
LOGGER="$ROOT_DIR/logging/log-wechat-flow.sh"
"$LOGGER" "$FLOW_LOG_PATH" sender ui_send_begin \
  chat="$CHAT_LABEL" \
  reply="$MESSAGE"
if osascript - "$MESSAGE" <<'APPLESCRIPT'
on run argv
  set messageText to item 1 of argv
  tell application "WeChat" to activate
  delay 0.35
  tell application "System Events"
    tell process "WeChat"
      set frontmost to true
      key code 48
      delay 0.2
      key code 48
      delay 0.3
    end tell
  end tell
  set the clipboard to messageText
  delay 0.1
  tell application "System Events"
    tell process "WeChat"
      keystroke "v" using command down
      delay 0.4
      key code 36
    end tell
  end tell
  delay 0.5
  tell application "Finder" to activate
end run
APPLESCRIPT
then
  "$LOGGER" "$FLOW_LOG_PATH" sender ui_send_finished \
    chat="$CHAT_LABEL"
else
  "$LOGGER" "$FLOW_LOG_PATH" sender ui_send_failed \
    chat="$CHAT_LABEL" \
    reply="$MESSAGE"
  exit 1
fi
