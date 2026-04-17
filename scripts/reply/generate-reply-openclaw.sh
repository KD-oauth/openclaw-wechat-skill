#!/bin/bash
set -euo pipefail
CHAT_NAME="${1:-}"
INCOMING_MESSAGE="${2:-}"
SENDER="${3:-}"
STYLE="${4:-自然、简短、礼貌，像正常群里沟通，不要太客套}"
SESSION_ID="${OPENCLAW_REPLY_SESSION_ID:-agent:main:main}"
if [[ -z "$INCOMING_MESSAGE" ]]; then
  echo "usage: generate-reply-openclaw.sh <chat-name> <incoming-message> [sender] [style]" >&2
  exit 1
fi

PROMPT="$(python3 - "$CHAT_NAME" "$INCOMING_MESSAGE" "$SENDER" "$STYLE" <<'PY'
import sys
chat_name, incoming_message, sender, style = sys.argv[1:5]
prefix = f"在“{chat_name}”里" if chat_name else "在微信聊天里"
sender_text = f"，对方是{sender}" if sender else ""
print(f"请为我生成一条微信回复建议。{prefix}{sender_text}，对方刚发来：\n{incoming_message}\n\n要求：{style}。只输出建议回复正文，不要解释。")
PY
)"

RAW_OUTPUT="$(openclaw agent --session-id "$SESSION_ID" --message "$PROMPT" --json 2>&1)"
python3 - "$RAW_OUTPUT" <<'PY'
import json, re, sys
raw = sys.argv[1]
m = re.search(r'"finalAssistantVisibleText"\s*:\s*"((?:\\.|[^"\\])*)"', raw, re.S)
if not m:
    raise SystemExit('finalAssistantVisibleText not found in openclaw output')
print(json.loads('"' + m.group(1) + '"'))
PY
