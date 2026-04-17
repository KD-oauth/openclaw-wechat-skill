# OPENCLAW-WECHAT-SKILL

## 写在前面
### 本项目是一次粗糙的实验版本，基于macOS通知中心+AppleScript实现。功能有限，无法读取图片/长文本，适合刚接触OpenClaw尝试跑通流程

## 工作流程

1. 从 macOS Notification Center 监听微信预览
2. 解析出群名、发送者、消息内容
3. 按启动模式(支持固定内容回复 和 AI回复)决定回复来源
4. 把最终回复发送到当前已选好的微信聊天

## 启动模式

### 1. fixed-reply mode

固定文案自动回复。

适合：
- 先回一句“收到，我来处理。”
- 希望流程最短、最稳
- 不需要模型参与生成

推荐启动脚本：

```bash
skills/wechat-desktop-control/scripts/startup/start-wechat-fixed-reply.sh <target-chat> [reply-text] [style] [notify-log] [flow-log]
```

底层桥接脚本：

```bash
skills/wechat-desktop-control/scripts/bridge/watch-wechat-target-log.sh <target-chat> [log-path] [style] [reply-text]
```

说明：
- 启动时会先执行 `scripts/startup/prepare-target-chat.sh <target-chat>`
- 也就是先搜索并打开目标群，再切回 Finder
- 当提供 `reply-text` 时，收到目标群通知后会直接发送这段固定回复
- 不会调用 OpenClaw 生成正文

### 2. ai-reply mode

由 OpenClaw 生成回复正文，再自动发送。

适合：
- 希望根据消息内容动态回复
- 接受链路更长一些
- 希望用 OpenClaw 参与思考和生成

推荐启动脚本：

```bash
skills/wechat-desktop-control/scripts/startup/start-wechat-ai-reply.sh <target-chat> [style] [notify-log] [flow-log]
```

底层桥接脚本：

```bash
skills/wechat-desktop-control/scripts/bridge/watch-wechat-target-log-ai.sh <target-chat> [log-path] [style]
```

说明：
- 启动时会先执行 `scripts/startup/prepare-target-chat.sh <target-chat>`
- 也就是先搜索并打开目标群，再切回 Finder
- 收到目标群通知后，会调用 OpenClaw 生成回复正文
- 再调用 sender 把回复发到当前已准备好的聊天

## 发送前提

非常重要：

- `scripts/sender/send-message.sh` **不再负责搜索群名**
- `scripts/sender/send-message.sh` **不再负责定位置顶聊天**
- 它现在默认：**当前聊天已经是你要发送的那个聊天**

也就是说，不管是 fixed-reply mode 还是 ai-reply mode，推荐都先通过启动脚本完成一次聊天准备：

```bash
skills/wechat-desktop-control/scripts/startup/prepare-target-chat.sh <target-chat>
```

这个准备步骤会：
- 搜索目标群
- 在输入搜索内容后 **0.2 秒内立刻回车** 打开目标群
- 然后切回 Finder

## 最短使用示例

### 1. 监听微信通知

```bash
skills/wechat-desktop-control/scripts/detector/wechat-detector.sh notification-center /tmp/wechat_notify.log
```

通知日志里会追加类似内容：

```text
WECHAT:目标群|||请今天把材料发我
```

### 2. 解析通知文本

```bash
skills/wechat-desktop-control/scripts/reply/wechat-resolver.sh text '目标群: 请今天把材料发我'
```

### 3. 生成 AI 回复提示词

```bash
skills/wechat-desktop-control/scripts/reply/wechat-drafter.sh suggest '目标群' '请今天把材料发我'
```

### 4. 直接发送消息

前提：当前微信聊天已经切到你要发送的目标聊天。

```bash
skills/wechat-desktop-control/scripts/sender/wechat-sender.sh send '当前聊天' '好的，我整理完马上发你。'
```

### 5. 一键闭环

只生成 AI 提示词：

```bash
skills/wechat-desktop-control/scripts/bridge/wechat-flow.sh '目标群: 请今天把材料发我'
```

直接发送最终回复：

```bash
skills/wechat-desktop-control/scripts/bridge/wechat-flow.sh '目标群: 请今天把材料发我' '自然、简短、礼貌' '好的，我整理完马上发你。'
```

### 6. 按目标群过滤处理

只生成指定群的 AI 提示词：

```bash
skills/wechat-desktop-control/scripts/bridge/wechat-flow-target.sh '目标群' '目标群: 请今天把材料发我'
```

如果通知不是目标群，会自动忽略。

直接发送指定群对应的最终回复（发送动作本身仍然要求当前聊天已选好）：

```bash
skills/wechat-desktop-control/scripts/bridge/wechat-flow-target.sh '项目A群' '项目A群: 明天确认一下方案' '自然、简短、礼貌' '好的，我下午确认后回你。'
```

### 7. fixed-reply mode: 推荐启动方式

```bash
skills/wechat-desktop-control/scripts/startup/start-wechat-fixed-reply.sh '目标群' '收到，我来处理。'
```

这条命令会自动：

1. 搜索并打开目标群
2. 切回 Finder
3. 启动 detector
4. 启动 fixed-reply bridge

### 8. fixed-reply mode: 底层手动启动方式

先启动通知监听：

```bash
skills/wechat-desktop-control/scripts/detector/wechat-detector.sh notification-center /tmp/wechat_notify.log
```

再启动固定回复桥接器：

```bash
skills/wechat-desktop-control/scripts/bridge/watch-wechat-target-log.sh '目标群' /tmp/wechat_notify.log
```

这样当日志里出现：

```text
WECHAT:目标群|||请今天把材料发我
```

桥接器会自动转成：

```text
目标群: 请今天把材料发我
```

并调用 `wechat-flow-target.sh`。如果未提供 reply-text，就输出 AI 提示词；如果提供了 reply-text，就向当前已选好的聊天发送。

### 9. ai-reply mode: 推荐启动方式

```bash
skills/wechat-desktop-control/scripts/startup/start-wechat-ai-reply.sh '目标群'
```

这条命令会自动：

1. 搜索并打开目标群
2. 切回 Finder
3. 启动 detector
4. 启动 AI bridge

### 10. ai-reply mode: 底层手动启动方式

先启动通知监听：

```bash
skills/wechat-desktop-control/scripts/detector/wechat-detector.sh notification-center /tmp/wechat_notify.log
```

再启动 AI 自动回复桥接器：

```bash
skills/wechat-desktop-control/scripts/bridge/watch-wechat-target-log-ai.sh '目标群' /tmp/wechat_notify.log '自然、简短、礼貌，像正常群里沟通，不要太客套'
```

这样当日志里出现目标群通知时：

1. 脚本会解析通知文本
2. 调用 OpenClaw 生成回复正文
3. 再把回复发到当前已选好的聊天

## 目录说明

- `scripts/startup/` 启动、停止、聊天准备
- `scripts/detector/` 通知监听
- `scripts/bridge/` 通知到动作的桥接层
- `scripts/reply/` 解析、提示词、OpenClaw 回复生成
- `scripts/sender/` 发送消息
- `scripts/logging/` 流程日志
- `archive/` 历史实验脚本和旧方案
- `references/safety-notes.md` 安全说明
