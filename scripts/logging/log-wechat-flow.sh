#!/bin/bash
set -euo pipefail
LOG_PATH="${1:-/tmp/wechat_flow.log}"
STAGE="${2:-}"
EVENT="${3:-}"
shift 3 || true
if [[ -z "$STAGE" || -z "$EVENT" ]]; then
  echo "usage: log-wechat-flow.sh <log-path> <stage> <event> [key=value ...]" >&2
  exit 1
fi
mkdir -p "$(dirname "$LOG_PATH")"
python3 - "$LOG_PATH" "$STAGE" "$EVENT" "$@" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

log_path, stage, event, *pairs = sys.argv[1:]
payload = {
    "time": datetime.now().astimezone().isoformat(timespec="seconds"),
    "stage": stage,
    "event": event,
}
for pair in pairs:
    if "=" not in pair:
        continue
    key, value = pair.split("=", 1)
    payload[key] = value
with Path(log_path).open("a", encoding="utf-8") as f:
    f.write(json.dumps(payload, ensure_ascii=False) + "\n")
PY
