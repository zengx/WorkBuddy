# Server酱（ServerChan）接口速查

## 两个版本

| 版本 | SendKey 前缀 | 接口地址 | 标题字段 | 正文字段 |
|------|-------------|----------|----------|----------|
| Turbo（推荐） | `SCT` | `https://sctapi.ftqq.com/<key>.send` | `title` | `desp` |
| 旧版 | `SCU` | `https://sc.ftqq.com/<key>.send` | `text` | `desp` |

`push.py` 已根据前缀自动选择版本，无需手动指定。

## 请求

- 方法：GET 或 POST（脚本用 POST + `application/x-www-form-urlencoded`）
- 必填：`title` / `text`（标题）
- 可选：`desp`（正文，支持 Markdown）、`channel`（渠道，如 `9`）、`openid`（指定接收人）

## 返回（Turbo 版 JSON）

```json
{
  "code": 0,
  "message": "OK",
  "data": { "pushid": "...", "readkey": "...", "error": "SUCCESS", "errno": 0 }
}
```

- `code == 0`：推送成功。
- `code != 0`：失败，`message` 含原因（常见：SendKey 无效、用户未关注服务号、频率/额度超限）。
- 旧版返回含 `errno` 字段，`errno == 0` 为成功。

## 常用错误与排查

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| code -2 / 未配置 Key | 未保存 SendKey | 运行 `--set-key` 或设置环境变量 |
| code !=0 报 key 无效 | SendKey 复制错/失效 | 让用户去后台重新复制 |
| 接口调用成功但微信收不到 | 未关注「Server酱」服务号 | 提示用户在微信关注服务号并绑定 |
| 收不到且后台显示已发送 | 微信通知被折叠/免打扰 | 指导用户检查微信通知设置 |

## 限制

- 免费版有每日推送条数上限（Turbo 约 5 条/日，旧版按触发额度），高频场景建议升级或错峰。
- 标题 ≤ 256 字节；正文 ≤ 约 64KB。
