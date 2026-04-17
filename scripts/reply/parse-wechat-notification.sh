#!/bin/bash
set -euo pipefail
RAW_INPUT="${1:-}"
if [[ -z "$RAW_INPUT" ]]; then
  RAW_INPUT="$(cat)"
fi
RAW_INPUT="$(printf '%s' "$RAW_INPUT" | tr '\r' '\n' | sed '/^[[:space:]]*$/d')"
if [[ -z "$RAW_INPUT" ]]; then
  echo '{"chatName":"","sender":"","message":"","raw":""}'
  exit 0
fi

python3 - "$RAW_INPUT" <<'PY'
import json
import re
import sys

raw = sys.argv[1].strip()
lines = [line.strip() for line in raw.splitlines() if line.strip()]
text = "\n".join(lines)
chat = ""
sender = ""
message = ""

patterns = [
    r'^(?P<chat>[^:：\n]+)[:：]\s*(?P<message>.+)$',
    r'^(?P<chat>[^\n]+?)\s*[\-—–]\s*(?P<message>.+)$',
    r'^来自\s*(?P<chat>[^\n]+?)\s*[:：]\s*(?P<message>.+)$',
]
for line in lines:
    for pattern in patterns:
        m = re.match(pattern, line)
        if m:
            chat = m.group('chat').strip()
            message = m.group('message').strip()
            break
    if chat:
        break

if not chat and lines:
    chat = lines[0]
if not message and len(lines) >= 2:
    message = lines[-1]
if not message:
    message = raw

sender_patterns = [
    r'(?P<sender>[^:：]+)[:：]\s*(?P<body>.+)',
    r'\[(?P<sender>[^\]]+)\]\s*(?P<body>.+)',
]
for pattern in sender_patterns:
    m = re.match(pattern, message)
    if m:
        sender = m.group('sender').strip()
        body = m.group('body').strip()
        if body:
            message = body
        break

print(json.dumps({
    "chatName": chat,
    "sender": sender,
    "message": message,
    "raw": raw,
}, ensure_ascii=False))
PY
