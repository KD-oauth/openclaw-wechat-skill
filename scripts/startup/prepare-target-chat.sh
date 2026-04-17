#!/bin/bash
set -euo pipefail
TARGET_CHAT="${1:?usage: prepare-target-chat.sh <target-chat>}"
osascript - "$TARGET_CHAT" <<'APPLESCRIPT'
on run argv
  set targetChat to item 1 of argv
  set the clipboard to targetChat
  tell application "WeChat" to activate
  delay 0.35
  tell application "System Events"
    tell process "WeChat"
      set frontmost to true
      keystroke "f" using command down
      delay 0.35
      keystroke "a" using command down
      delay 0.1
      key code 51
      delay 0.1
      keystroke "v" using command down
      delay 0.2
      key code 36
    end tell
  end tell
  delay 0.6
  tell application "Finder" to activate
end run
APPLESCRIPT
