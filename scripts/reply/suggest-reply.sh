#!/bin/bash
set -euo pipefail
CHAT_NAME="${1:-}"
INCOMING_MESSAGE="${2:-}"
SENDER="${3:-}"
STYLE="${4:-自然、简短、礼貌}"
if [[ -z "$INCOMING_MESSAGE" ]]; then
  echo "usage: suggest-reply.sh <chat-name> <incoming-message> [sender] [style]" >&2
  exit 1
fi

python3 - "$CHAT_NAME" "$INCOMING_MESSAGE" "$SENDER" "$STYLE" <<'PY'
import sys
chat_name, incoming_message, sender, style = sys.argv[1:5]
prefix = f"在“{chat_name}”里" if chat_name else "在微信聊天里"
sender_text = f"，对方是{sender}" if sender else ""
print(f"请为我生成一条微信回复建议。{prefix}{sender_text}，对方刚发来：\n{incoming_message}\n\n要求：{style}。只输出建议回复正文，不要解释。")
PY
