# Safety notes

- This skill controls the local macOS WeChat desktop client via AppleScript and System Events.
- It assumes macOS Accessibility permission is enabled for the OpenClaw host app.
- The current production path depends on Notification Center preview text, not full conversation history.
- Notification parsing is heuristic. Verify the extracted chat name and message meaning before relying on it for important conversations.
- Group-chat automation is higher risk because notification previews can be truncated and may not carry enough context.
- `scripts/sender/send-message.sh` assumes the correct WeChat chat is already selected before sending.
- If WeChat UI layout, Notification Center structure, or shortcuts change, scripts may need adjustment.
- Prefer fixed-reply mode or explicit review when the consequences of a wrong reply are high.
