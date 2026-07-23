#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ServerChan (Server酱) 微信推送脚本。

支持两种 SendKey 格式：
  - Turbo 版（推荐）：以 "SCT" 开头，接口 https://sctapi.ftqq.com/<key>.send
  - 旧版：以 "SCU" 开头，接口 https://sc.ftqq.com/<key>.send

SendKey 优先级：--sendkey 参数 > 环境变量 SERVERCHAN_SENDKEY > config.json

用法：
  python3 push.py --title "标题" --desp "正文(Markdown)"
  python3 push.py --set-key "SCTxxxxxx"      # 首次保存 SendKey 到 config.json
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_PATH = os.path.join(SKILL_DIR, "config.json")

TURBO_PREFIXES = ("SCT",)


def load_sendkey():
    # 1. 环境变量
    key = os.environ.get("SERVERCHAN_SENDKEY")
    if key and key.strip():
        return key.strip()
    # 2. config.json
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, "r", encoding="utf-8") as f:
                data = json.load(f)
            key = data.get("sendkey")
            if key and key.strip():
                return key.strip()
        except Exception:
            pass
    return None


def save_sendkey(key):
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        json.dump({"sendkey": key.strip()}, f, ensure_ascii=False, indent=2)


def endpoint_for(key):
    if key.upper().startswith(TURBO_PREFIXES):
        return f"https://sctapi.ftqq.com/{key}.send", True
    return f"https://sc.ftqq.com/{key}.send", False


def push(sendkey, title, desp="", channel=None, openid=None):
    sendkey = sendkey.strip()
    url, is_turbo = endpoint_for(sendkey)

    # Turbo 版用 title/desp；旧版用 text/desp
    if is_turbo:
        params = {"title": title, "desp": desp}
    else:
        params = {"text": title, "desp": desp}

    if channel:
        params["channel"] = channel
    if openid:
        params["openid"] = openid

    data = urllib.parse.urlencode(params).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("User-Agent", "WorkBuddy-wechat-push/1.0")

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            body = resp.read().decode("utf-8", errors="replace")
        return body
    except urllib.error.HTTPError as e:
        return json.dumps({"code": -1, "message": f"HTTP {e.code}: {e.reason}", "raw": e.read().decode('utf-8', errors='replace')}, ensure_ascii=False)
    except Exception as e:  # noqa: BLE001
        return json.dumps({"code": -1, "message": str(e)}, ensure_ascii=False)


def main():
    p = argparse.ArgumentParser(description="Push message to WeChat via ServerChan")
    p.add_argument("--title", help="消息标题（必填）")
    p.add_argument("--desp", default="", help="消息正文，支持 Markdown")
    p.add_argument("--sendkey", default=None, help="ServerChan SendKey（覆盖 config/env）")
    p.add_argument("--channel", default=None, help="推送渠道，如 9")
    p.add_argument("--openid", default=None, help="指定接收人 openid")
    p.add_argument("--set-key", default=None, help="把 SendKey 保存到 config.json 并退出")
    args = p.parse_args()

    if args.set_key:
        save_sendkey(args.set_key)
        print(json.dumps({"code": 0, "message": "SendKey 已保存到 config.json"}, ensure_ascii=False))
        return

    if not args.title:
        print(json.dumps({"code": -2, "message": "缺少 --title 参数"}, ensure_ascii=False))
        sys.exit(2)

    key = args.sendkey or load_sendkey()
    if not key:
        print(json.dumps({
            "code": -2,
            "message": ("未配置 SendKey。请先运行 "
                        "`python3 <skill>/scripts/push.py --set-key SCTxxxx`，"
                        "或设置环境变量 SERVERCHAN_SENDKEY，或在 config.json 写入 {\"sendkey\": \"...\"}")
        }, ensure_ascii=False))
        sys.exit(2)

    result = push(key, args.title, args.desp, args.channel, args.openid)
    print(result)


if __name__ == "__main__":
    main()
