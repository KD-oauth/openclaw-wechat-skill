#!/bin/bash
set -euo pipefail
pkill -f 'watch-wechat-notification-center.scpt /tmp/wechat_notify.log' 2>/dev/null || true
pkill -f 'watch-wechat-target-log.sh .* /tmp/wechat_notify.log' 2>/dev/null || true
pkill -f 'watch-wechat-target-log-ai.sh .* /tmp/wechat_notify.log' 2>/dev/null || true
printf 'Stopped WeChat detector and reply bridge processes.\n'
