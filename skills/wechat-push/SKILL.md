---
name: wechat-push
description: 通过 Server酱（ServerChan）把消息推送到微信。当用户要求"推送到微信""发微信通知我""微信提醒"或在自动化/定时任务中需要把内容发送到微信时使用。支持手动即时推送与配合 WorkBuddy 自动化做定时推送。
agent_created: true
---

# WeChat Push（Server酱）

## Overview

通过 Server酱（ServerChan）将任意文本/Markdown 消息推送到用户的个人微信。
Server酱是第三方中转服务：用户关注其服务号并获取 SendKey 后，调用其 HTTP 接口即可把消息经服务号下发到用户微信。
无需企业微信、无需公众号资质，是个人轻量推送的最低成本方案。

本 skill 提供一个离线可执行的推送脚本 `scripts/push.py`，AI 在需要时直接调用它完成发送，并处理 SendKey 的获取与保存。

## 何时使用

- 用户说"推送到微信：xxx""发个微信给我""微信提醒我 xxx"。
- 用户在自动化（cron）中希望定时把摘要/天气/待办/监控结果发到微信。
- 任何需要把 WorkBuddy 生成的内容主动触达用户微信的场景。

## 首次配置（SendKey）

推送前必须知道用户的 Server酱 SendKey。判定顺序（高优先级优先）：

1. 命令行 `--sendkey` 参数；
2. 环境变量 `SERVERCHAN_SENDKEY`；
3. skill 目录下的 `config.json` 中的 `sendkey` 字段。

调用脚本时若上述均无值，脚本会返回 `code: -2` 并提示未配置。此时：

1. 询问用户是否已有 Server酱 SendKey（注册地址 https://sct.ftqq.com ，登录后在「Key&API」页面获取，形如 `SCTxxxx`）。
2. 若用户已提供，运行以下命令把 Key 持久化到 `config.json`（仅本机本地存储）：
   ```
   python3 <skill_dir>/scripts/push.py --set-key "SCT你的Key"
   ```
3. 若用户还没有，简要引导其去 https://sct.ftqq.com 注册并在微信中关注「Server酱」服务号后复制 SendKey，再交给本 skill 保存。

> 安全提示：SendKey 等同推送凭证，仅存于本机 `config.json` 或环境变量，不要写入会话、日志或分享给他人。

## 手动即时推送

当用户在对话中要求推送时：

1. 从用户话语中提取**标题**（简短）与**正文**（详情，可包含 Markdown）。
   - 若用户只给了一段话，用前 20 字左右作为标题，整段作为正文。
2. 调用推送脚本（路径见 `Resources` 下的脚本定位）：
   ```
   python3 <skill_dir>/scripts/push.py --title "标题" --desp "正文，支持 **Markdown**"
   ```
3. 解析脚本输出的 JSON：
   - `code == 0`（Turbo）或旧版返回 `{"errno":0,...}` / 含 `"message":"OK"`：告知用户"已推送到微信 ✅"。
   - 其它：把 `message` 字段原样反馈给用户，必要时提示重新配置 SendKey 或检查网络。

## 定时自动推送（配合 WorkBuddy 自动化）

本 skill 同时服务于自动化场景。在创建自动化（automation）时，把下面任一阵列作为自动化 prompt 即可，AI 会自动调用本 skill 完成推送：

- 每日早报：`每天早上 9:00，抓取今日天气与待办摘要，用 wechat-push skill 推送到我的微信，标题写"今日早报"。`
- 监控告警：`每小时检查一次服务状态，若异常则用 wechat-push skill 推送微信告警，标题含"服务异常"。`
- 内容订阅：`每天 20:00 汇总今日 AI 新闻要点，通过 wechat-push skill 推送到微信。`

自动化 prompt 只需描述"做什么内容 + 用 wechat-push skill 推送"，无需重复接口细节——本 skill 的调用规则会被自动加载。

## 注意事项

- 正文 `desp` 支持 Markdown；标题尽量简短（Turbo 版标题上限 256 字节）。
- 单条消息正文上限约 64KB，超长内容请拆分或只发摘要+链接。
- 推送失败多为 SendKey 失效、网络受限或服务号未关注；先核对 SendKey，再提示用户检查微信是否关注服务号。
- 不要在 `desp` 中拼接明文密码/密钥等敏感信息。

## Resources

### scripts/push.py
核心推送脚本，功能：
- `--title <标题> --desp <正文>`：发起一次推送（同步返回 JSON 结果）。
- `--set-key <SCTxxxx>`：把 SendKey 存入 `config.json`。
- `--sendkey <key>`：临时指定 Key，覆盖其它来源。
- `--channel <n>` / `--openid <id>`：可选，指定渠道或接收人。

脚本定位：`<skill_dir>/scripts/push.py`，其中 `<skill_dir>` 为 `~/.workbuddy/skills/wechat-push`（用户级）。
调用前可用 `os.path` 解析本文件所在目录，或直接用绝对路径 `~/.workbuddy/skills/wechat-push/scripts/push.py`。

### references/serverchan.md
Server酱接口字段、返回码与 Turbo/旧版差异的速查参考，需在构造复杂请求时按需加载。
