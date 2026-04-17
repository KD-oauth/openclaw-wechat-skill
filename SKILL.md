---
name: wechat-desktop-control
description: Control the local macOS WeChat desktop app with a lean production path for notification listening, message parsing, AI reply suggestion, and direct sending into the currently selected chat. Use when the user wants a minimal WeChat automation flow on their own Mac.
---

# WeChat Desktop Control

Use the bundled shell scripts for deterministic local automation on macOS.

## Quick start

Read `references/safety-notes.md` first when the task involves contacts, notifications, or sending messages.

This skill is intentionally trimmed to the current production path:

1. listen for WeChat previews from Notification Center
2. parse the preview into chat name and message text
3. choose a reply mode at startup
4. send the final reply into the currently selected WeChat chat

## Reply modes

### fixed-reply mode

Use this when the reply body is predetermined.

Recommended startup script:
- `scripts/startup/start-wechat-fixed-reply.sh <target-chat> [reply-text] [style] [notify-log] [flow-log]`

Bridge script:
- `scripts/bridge/watch-wechat-target-log.sh <target-chat> [log-path] [style] [reply-text]`

Behavior:
- startup first runs `scripts/startup/prepare-target-chat.sh <target-chat>`
- that preparation searches the target chat, then presses Enter after a 0.2 second delay, then switches to Finder
- watches detector output
- filters for the target chat
- if `reply-text` is provided, sends that fixed reply directly
- does not call OpenClaw for generation

### ai-reply mode

Use this when OpenClaw should generate the reply body.

Recommended startup script:
- `scripts/startup/start-wechat-ai-reply.sh <target-chat> [style] [notify-log] [flow-log]`

Bridge script:
- `scripts/bridge/watch-wechat-target-log-ai.sh <target-chat> [log-path] [style]`

Behavior:
- startup first runs `scripts/startup/prepare-target-chat.sh <target-chat>`
- that preparation searches the target chat, then presses Enter after a 0.2 second delay, then switches to Finder
- watches detector output
- filters for the target chat
- calls OpenClaw to generate the reply body
- sends the generated reply into the currently selected chat

## Sending assumption

Important:

- `scripts/sender/send-message.sh` no longer searches for a chat name
- `scripts/sender/send-message.sh` no longer locates the top pinned chat
- it assumes the correct WeChat chat is already selected before sending
- the intended way to satisfy that assumption is to run `scripts/startup/prepare-target-chat.sh <target-chat>` during startup

Archived experiments and older draft-first flows were moved to `archive/` so the main path stays small and obvious.

## Primary entry scripts

- `scripts/detector/wechat-detector.sh notification-center [log-path]`
- `scripts/reply/wechat-resolver.sh text <notification-text>`
- `scripts/reply/wechat-drafter.sh suggest <chat-name> <incoming-message> [sender] [style]`
- `scripts/sender/wechat-sender.sh send <chat-label> <message>`
- `scripts/bridge/wechat-flow.sh <notification-text> [style] [reply-text]`
- `scripts/bridge/wechat-flow-target.sh <target-chat> <notification-text> [style] [reply-text]`, only handle notifications for the specified target chat
- `scripts/startup/prepare-target-chat.sh <target-chat>`, search and open the target chat during startup preparation
- `scripts/startup/start-wechat-fixed-reply.sh <target-chat> [reply-text] [style] [notify-log] [flow-log]`, recommended startup for fixed-reply mode
- `scripts/startup/start-wechat-ai-reply.sh <target-chat> [style] [notify-log] [flow-log]`, recommended startup for AI-reply mode
- `scripts/bridge/watch-wechat-target-log.sh <target-chat> [log-path] [style] [reply-text]`, fixed-reply bridge for matching notifications
- `scripts/bridge/watch-wechat-target-log-ai.sh <target-chat> [log-path] [style]`, AI-reply bridge that uses OpenClaw generation
- `scripts/startup/stop-wechat-reply.sh`, stop detector and reply bridge processes

## Core scripts

- `scripts/detector/watch-wechat-notification-center.sh [log-path]`, watch Notification Center via AppleScript and append `WECHAT:<chat>|||<preview>` lines when the top WeChat notification changes
- `scripts/detector/watch-wechat-notification-center.scpt [log-path]`, the AppleScript watcher used by the shell wrapper
- `scripts/reply/parse-wechat-notification.sh <notification-text>`, parse raw notification text into JSON fields
- `scripts/reply/suggest-reply.sh <chat-name> <incoming-message> [sender] [style]`, build a compact LLM prompt for a reply suggestion
- `scripts/sender/send-message.sh <chat-label> <message>`, send the message into the currently selected chat
- `scripts/reply/generate-reply-openclaw.sh <chat-name> <incoming-message> [sender] [style]`, generate reply text through OpenClaw for AI-reply mode
- `scripts/bridge/wechat-flow.sh <notification-text> [style] [reply-text]`, minimal end-to-end flow: parse notification, output reply prompt, or send a provided reply
- `scripts/bridge/wechat-flow-target.sh <target-chat> <notification-text> [style] [reply-text]`, target-chat wrapper for a specified chat workflow
- `scripts/bridge/watch-wechat-target-log.sh <target-chat> [log-path] [style] [reply-text]`, log bridge that converts `WECHAT:<chat>|||<preview>` lines into target-chat flow input
- `scripts/logging/log-wechat-flow.sh <log-path> <stage> <event> [key=value ...]`, write structured flow logs as JSONL

## Recommended workflow

1. Confirm the node is macOS and Accessibility is enabled.
2. Start detection with `scripts/detector/wechat-detector.sh notification-center ...`.
3. For a manual step-by-step flow, parse with `scripts/reply/wechat-resolver.sh text <notification-text>`, generate with `scripts/reply/wechat-drafter.sh suggest ...`, then ensure the correct WeChat chat is already selected before sending with `scripts/sender/wechat-sender.sh send ...`.
4. For the minimal closed loop, use `scripts/bridge/wechat-flow.sh <notification-text>` to output the AI prompt, or `scripts/bridge/wechat-flow.sh <notification-text> <style> <reply-text>` to send directly.
5. For a target-chat fixed-reply workflow, prefer `scripts/startup/start-wechat-fixed-reply.sh <target-chat> ...`.
6. For a target-chat AI-reply workflow, prefer `scripts/startup/start-wechat-ai-reply.sh <target-chat> ...`.
7. Both startup scripts prepare the target chat first, using a search flow that presses Enter after a 0.2 second delay.
8. In both modes, sender actions still assume the correct WeChat chat remains selected after startup preparation.

## Notes

- These scripts rely on WeChat keyboard shortcuts and visible UI focus.
- Sending now assumes the correct WeChat chat is already selected before the sender runs.
- The notification parser is heuristic, so verify unusual group-chat notification formats.
- Sending is intentionally explicit. Older draft-first and experimental watcher flows are preserved under `archive/`.
- These scripts may need delay adjustments if the local WeChat UI changes or the machine is under load.
