---
name: pink-crystal-workbuddy-skin
description: "WorkBuddy 桌面端（Electron）主题定制服务。通过 asar 内联 CSS 注入，提供「毛玻璃套装」皮肤，支持动态（animated WebP 背景）与静态（单帧 JPEG 背景）两种构建产物，覆盖 macOS / Windows 双平台一键安装与回滚。必须使用 WorkBuddy 原生 --cb-* 变量体系（非 VSCode 的 --vscode-*），否则面板灰蒙蒙。本 skill 为通用个性化换装服务，不绑定任何特定图片/视频，企业或个人可基于自身素材替换默认示例背景并重新着色。"
agent_created: true
slug: pink-crystal-workbuddy-skin
version: 3.1.2
displayName: "WorkBuddy 换肤"
display_name: "WorkBuddy 换肤"
display_name_en: "WorkBuddy Skin"
description_zh: "WorkBuddy 桌面端主题定制服务。通过 asar 内联 CSS 注入提供毛玻璃套装皮肤，支持动态与静态两种构建产物，覆盖 macOS 和 Windows 双平台一键安装与回滚。"
description_en: "WorkBuddy desktop theme customization service. Injects frosted-glass skin CSS into app.asar, with dynamic and static builds, supporting macOS and Windows one-click install and rollback."
visibility: "public"
---

# Pink Crystal · 深空樱雾 — WorkBuddy 桌面端主题定制服务

本 skill 为 **WorkBuddy 桌面客户端（Electron 应用）** 提供一套可注入的视觉主题。技术实现采用
**asar 归档内联 CSS 注入**：将一段自包含的样式块追加到 `app.asar` 内 `renderer/assets/index-*.css`
末尾，覆盖 WorkBuddy 原生 CSS 变量与关键组件样式，重启客户端后持久生效。

主题本身是一套「深空樱雾」**毛玻璃（frosted-glass）视觉语言**，并提供两种构建产物：

| 产物 | 背景 | 包体 | 适用场景 |
|:---|:---|:---|:---|
| **动态版 `dynamic`** | animated WebP（动画帧序列） | 较大（base64 ~9.4 MB） | 追求灵动氛围、整机性能充裕 |
| **静态版 `static`** | 单帧 JPEG 静态图（无动画） | 轻量（base64 ~0.27 MB） | 低开销、快速加载、无需动画 |

两种产物**共享同一套最终界面规格**（毛玻璃参数、控件透明度、侧栏无边），仅背景介质不同。

> **💡 个性化换装服务声明（请先读）**
> 本 skill 是一套**通用个性化定制（换装）服务框架**，**不指定、不绑定任何特定图片或视频作为唯一素材**。
> 仓库内随附的「星空」背景仅为**示例（demo）资产**，用于演示效果与技术验证。
> - **企业用户**：可基于自身企业文化、品牌 LOGO、品牌主色及已获合法授权的图片，派生「企业需求版本」——重新设定强调色 `--wb-accent`、替换背景资产即可。
> - **个人用户**：可根据个人喜好，指定自己拥有或已获授权的任意图片 / 视频作为皮肤背景。
> - **权责说明**：任何被替换的图片 / 视频，其版权与合规责任由使用者自行承担；示例资产按「现状」提供仅供技术演示，分发前请替换为自有 / 已授权素材。

---

## ⚠️ 关键技术机制（踩坑沉淀，必读）

**WorkBuddy 的换肤变量体系是 `--cb-*`，不是 VSCode 的 `--vscode-*`！**

- 正确作用域选择器：`body[data-application-name=workbuddy]`
- 正确变量命名空间：`--cb-bg-primary`、`--cb-panel-bg-primary`、`--cb-input-background`、`--cb-vscode-editor-background` 等
- `app.asar` 中 `--cb-bg-primary` 被引用逾 120 处——这才是 WorkBuddy 真正读取的换肤变量。

若改用 VSCode 的 `--vscode-*` + `.monaco-workbench .part.*` 去覆盖背景（早期版本踩过的坑），
面板会**始终维持 WorkBuddy 原生灰色**，所有「透明 / 去灰」全部打偏 → 灰蒙蒙。

---

## 🎯 最终界面规格基线（唯一权威）

> 经 2026-07-19 最终确认：星空示例背景 + 毛玻璃套装 + **侧栏完全无边框（border:none，彻底无竖线）**。
> 后续微调一律改 `assets/{mode}/skin.template.css` 后重建，**不要直接手改 skin.css**（会被重建覆盖）。

### 配色体系

| 角色 | 色值 | 用途 |
|:---|:---|:---|
| 深空底色 | `#10081a` | 所有毛玻璃磨砂底（透明化后透出） |
| 热粉强调 | `#ff4d9c` | 按钮 / 聚焦环 / 选中态 / 边框 |
| 浅粉辅助 | `#ffb6d0` | hover 态 / 次级文字 |
| 白色文字 | `#ffffff` | 主文字 |
| 半透文字 | `rgba(255,255,255,0.78)` | 次级文字 |

### 各控件毛玻璃规格

| 控件 | 不透明度 | 「透明度」口径 | blur | saturate | 底色 |
|:---|:---|:---|:---|:---|:---|
| **输入框** `.atm-modal-chat-input` | **0.30** | **70% 透明** | `16px` | `1.2` | `rgba(16,8,26,0.30)` |
| 侧边栏 `[data-view-id=sidebar]` | 0.30 | 70% 透明 | `20px` | `1.12` | `rgba(16,8,26,0.30)` |
| 详情面板 `[data-view-id=detail-panel]` | 0.50 | 50% 透明 | `18px` | `1.08` | `rgba(16,8,26,0.50)` |
| 下拉框 / 弹出 `[role=listbox]/[role=menu]/monaco-menu` | 0.45 | 55% 透明 | `12px` | `1.15` | `rgba(16,8,26,0.45)` |
| 对话气泡区 `[data-view-id=main-content]` | 透明 | — | — | — | `transparent` |

> 🔴 **透明度语义铁律**：用户口述「毛玻璃**透明度 70%**」= **70% 透明 = 不透明度 0.30**。
> 历史上曾误做成 `rgba(16,8,26,0.70)`（70% 不透明），导致输入框近黑、像没变。
> 本 skill 基线一律用 **0.30**（输入框 / 侧栏）、0.50（详情）、0.45（下拉）。改值前务必确认用户指的是「透明度」还是「不透明度」。

### 背景图定位（四件套，缺一不可）

```css
#root{
  color:var(--wb-text) !important;
  background:linear-gradient(rgba(0,0,0,0.35),rgba(0,0,0,0.35)),
             url("data:image/<webp|jpeg>;base64,【背景base64】") !important;
  background-size:cover !important;             /* 铺满全屏 */
  background-position:center center !important; /* 居中 */
  background-repeat:no-repeat !important;      /* 不平铺 */
  background-attachment:fixed !important;      /* 不随滚动偏移 */
}
```

### 侧栏边框（最终界面：完全无边框 border:none）

```css
[data-view-id=sidebar]{
  background:rgba(16,8,26,0.30) !important;
  border:none !important;         /* 最终确认：侧栏完全无边框，彻底无竖线 */
  backdrop-filter:blur(20px) saturate(1.12) !important;
}
```

---

## 🔧 真实选择器与双遮蔽（输入框改不动的真凶）

WorkBuddy 组件常在**自身作用域**内重定义 `--cb-*`，**遮蔽** body 级同名变量，导致 body 级覆盖失效。

### 输入框双遮蔽源（必须同时覆盖）

输入框可见元素来自 CSS Module 作用域：
- `[class*="_mainArea_"]` → 背景读 `var(--atm-surface)`
- `[class*="_content_"]` → 背景读 `var(--atm-chat-content-bg)`

只覆盖 `--atm-surface` 一个会漏掉第二个，输入框仍是旧色。必须**两个都覆盖**，并用元素选择器直打兜底：

```css
body[data-application-name=workbuddy] .atm-modal-chat-input [class*="_mainArea_"],
body[data-application-name=workbuddy] .atm-modal-chat-input [class*="_content_"],
body[data-application-name=workbuddy] .atm-modal-chat-input textarea,
body[data-application-name=workbuddy] .atm-modal-chat-input [contenteditable]{
  --atm-surface:rgba(16,8,26,0.30) !important;
  --atm-chat-content-bg:rgba(16,8,26,0.30) !important;
  background:rgba(16,8,26,0.30) !important;  /* 直打兜底，绕过变量解析 */
  backdrop-filter:blur(16px) saturate(1.2) !important;
  border:1px solid rgba(255,77,156,0.35) !important;
  border-radius:12px !important;
}
```

---

## 📦 一键安装（推荐路径）

### 执行流程

用户触发本 Skill 后，按以下步骤交互：

1. **前置检查**：确认安装路径、管理员权限、Node.js、app.asar 可读写（详见下方「安装前置检查」）。任一不满足则停止并告知用户。
2. **询问用户意图**：
   - A. 直接安装内置主题（深空樱雾，粉色系）
   - B. 自定义背景图和品牌配色后再安装
3. **如果选 A（直接安装）**：询问动态版还是静态版，然后执行安装。
4. **如果选 B（自定义）**：
   - 引导用户提供背景素材（图片或视频路径）和品牌主色（Hex 值）
   - 将素材转为 base64 写入 `assets/{mode}/bg.b64.txt`
   - 将品牌主色写入 `assets/{mode}/skin.template.css` 的 `--wb-accent` 及相关 RGBA 值
   - 执行 `python3 tools/build_skin.py <mode>` 重建 skin.css
   - 询问动态版还是静态版，然后执行安装
5. **深色模式提醒**：本主题为深色皮肤（深空底色 `#10081a` + 白色文字），需切换 WorkBuddy 到深色模式才能正确显示。安装前提醒用户：在 WorkBuddy 中按 `Cmd/Ctrl+Shift+P` → 输入 `Color Theme` → 选择深色主题（如 Default Dark Modern）。浅色模式下白字无法在深色背景上凸显，会导致看不清。
6. **执行安装**：运行 apply 脚本，备份原 app.asar，注入主题，重启 WorkBuddy。
7. **告知回滚方式**：安装完成后告知用户备份路径和 rollback 脚本位置。

### 安装前置检查（必做）

执行换肤前，先确认以下四项，任一不满足则停止并告知用户：

1. **WorkBuddy 安装路径**：不限于默认目录，需实际定位到 `WorkBuddy.exe`（Windows）或 `WorkBuddy.app`（macOS）所在位置。可检查的路径包括但不限于：
   - Windows：`%LOCALAPPDATA%\Programs\WorkBuddy`、`%ProgramFiles%\WorkBuddy`、`%ProgramFiles(x86)%\WorkBuddy`、`D:\Program Files\WorkBuddy` 及其他自定义盘符
   - macOS：`/Applications/WorkBuddy.app`
   - 若以上均未找到，询问用户 WorkBuddy 的实际安装路径
2. **管理员权限**：Windows 需管理员命令提示符；macOS 需有 `codesign` 权限。权限不足时提示用户切换终端。
3. **Node.js 已安装**：执行 `node --version` 确认可用；未安装时提示从 https://nodejs.org 下载 LTS 版本。
4. **目标 app.asar 可读写**：确认 `<安装路径>\resources\app.asar`（Windows）或 `<安装路径>/Contents/Resources/app.asar`（macOS）存在且当前用户可写入。

### 执行安装

> 脚本在**系统终端**运行（macOS 用 Terminal.app，Windows 用管理员命令提示符）：
> 脚本会退出 WorkBuddy 以替换 `app.asar`，**勿在 WorkBuddy 内置终端执行**。

#### macOS
```bash
bash ./macos/scripts/apply.sh                 # 默认装【动态】皮肤
bash ./macos/scripts/apply.sh --mode static   # 装【静态】皮肤
```
或双击 `macos/scripts/apply.command`（默认动态）。

#### Windows
```cmd
windows\scripts\apply.bat            # 动态（默认）
windows\scripts\apply.bat static     # 静态
```
> Windows 无需 `codesign` / `xattr`，部署比 macOS 更简洁。需本机已装 Node.js（asar 依赖）。

若 WorkBuddy 未安装在默认路径，将实际安装路径作为环境变量传入：
```cmd
set "WB_PATH=D:\your\path\WorkBuddy"
windows\scripts\apply.bat
```

**幂等保障**：apply 脚本每次先剥离旧皮肤块（前缀匹配 `/* WORKBUDDY_SKIN` + `lastIndexOf(END SKIN)`，
兼容 `pink-crystal` / `pink-crystal-frost` / `pink-crystal-frost-static` 三种标记），再重注入，
**绝不累积叠加**。执行前自动时间戳备份原 `app.asar`。

---

## 🔄 还原 / 回滚

```bash
# macOS
bash ./macos/scripts/rollback.sh                 # 自动选最新备份
bash ./macos/scripts/rollback.sh /path/to/App_app.asar.bak.YYYYmmdd_HHMMSS

# Windows
windows\scripts\rollback.bat                      # 自动选最新备份
```

- 备份点：`~/WorkBuddy/App_app.asar.bak.*`（macOS）/ `%USERPROFILE%\WorkBuddy\App_app.asar.bak.*`（Windows）
- 重装 / 升级 WorkBuddy 会还原 `app.asar`，主题丢失，重跑 apply 即可（约 1 分钟）。

---

## 🛠 手动降级 SOP（脚本不可用时的保底）

apply 脚本已封装全流程；若脚本环境异常，按此 7 步手动重装（系统终端）：

```bash
ASAR="/Applications/WorkBuddy.app/Contents/Resources/app.asar"   # macOS 路径；Windows 见 apply.bat
WORK="/tmp/wb_pink_$(date +%s)"
SKILL=~/.workbuddy/skills/pink-crystal-workbuddy-skin
NODE=$(ls ~/.workbuddy/binaries/node/versions/*/bin/node | head -1)
ASARBIN=$(ls ~/.workbuddy/binaries/node/workspace/node_modules/.bin/asar 2>/dev/null || echo "")

# 0. 确保 skin.css 就位（若丢失：python3 $SKILL/tools/build_skin.py <mode>）
# 1. 备份
cp "$ASAR" ~/WorkBuddy/App_app.asar.bak.$(date +%Y%m%d_%H%M%S)
# 2. 解包
unset NODE_OPTIONS
if [ -n "$ASARBIN" ]; then "$ASARBIN" extract "$ASAR" "$WORK";
else npx --yes @electron/asar extract "$ASAR" "$WORK"; fi
# 3. 剥离旧块（幂等）
MAIN=$(ls "$WORK"/renderer/assets/index-*.css | head -1)
"$NODE" -e 'const fs=require("fs");const f=process.argv[1];let s=fs.readFileSync(f,"utf8");const a=s.indexOf("/* WORKBUDDY_SKIN");const e=s.lastIndexOf("/* END SKIN */");if(a>=0&&e>a){s=s.slice(0,a)+s.slice(e+"/* END SKIN */".length);fs.writeFileSync(f,s);}' "$MAIN"
# 4. 注入
cat "$SKILL/assets/dynamic/skin.css" >> "$MAIN"
# 5. 重打包
if [ -n "$ASARBIN" ]; then "$ASARBIN" pack "$WORK" /tmp/new_app.asar;
else npx --yes @electron/asar pack "$WORK" /tmp/new_app.asar; fi
# 6. 退出 + 原子替换
osascript -e 'tell application "WorkBuddy" to quit' 2>/dev/null || true   # Windows 用 taskkill /IM WorkBuddy.exe /F
sleep 3; pkill -f "WorkBuddy.app/Contents/MacOS" 2>/dev/null || true; sleep 2
mv /tmp/new_app.asar "$ASAR"
# 7. 重签 + 去隔离（仅 macOS；WorkBuddy 无 entitlements，纯 ad-hoc）
codesign --force --deep --sign - "/Applications/WorkBuddy.app"   # Windows 跳过此步
xattr -c "$ASAR"; xattr -c "/Applications/WorkBuddy.app/Contents/MacOS/Electron"
```

---

## 🖼 背景资产（可替换示例，非锁定）

> 🔴 **背景资产 = 一段 base64 内嵌于 `#root` 背景的媒体**，与「个性化服务」声明一致：
> **不绑定任何特定图/视频**。当前随附示例为「星空」动画（动态版）与「星空静态帧」（静态版），
> 均由用户自有素材经 VideoGen / ffmpeg 生成，**仅为演示**。
> 任何合法 WebP（动态）/ JPEG（静态）背景均可替换，不存在「前缀固定不可换」。

为防 `skin.css` 单文件丢失导致背景无法复原，采用**模板 + 独立 base64 分离存储**：

```
assets/
├── dynamic/
│   ├── skin.css            # 完整动态皮肤（注入目标）
│   ├── skin.template.css   # 模板（base64 处为占位符 __PINK_CRYSTAL_BG_B64__）
│   └── bg.b64.txt          # 动态背景 base64 存档（animated WebP）
└── static/
    ├── skin.css            # 完整静态皮肤（注入目标）
    ├── skin.template.css   # 模板（同占位符）
    └── bg.b64.txt          # 静态背景 base64 存档（JPEG 单帧）
tools/
├── build_skin.py           # 读 template + b64 → 重建 skin.css（双模式，带规则校验）
└── extract_bg.py           # 应急：从 asar 抽 base64 写回 bg.b64.txt（校验媒体头）
docs/
├── design-spec-v6.md          # 原始设计规格（v6，毛玻璃套装初版）
└── design-spec-v6.1.md        # 设计规格修正版（v6.1：澄清「70%透明=0.30不透明」+ 输入框双源遮蔽）
```

- **正常安装**：apply 直接用 `assets/{mode}/skin.css`，无需 build。
- **skin.css 丢了**：`python3 tools/extract_bg.py`（从 asar 抽）→ `python3 tools/build_skin.py <mode>` 重建。
- **改样式**：编辑 `assets/{mode}/skin.template.css` → `python3 tools/build_skin.py <mode>` → 重跑 apply。
- **换背景资产（个性化核心流程）**：
  1. 准备自有 / 已授权素材（图片或视频）；
  2. 视频 → animated WebP：`ffmpeg -i in.mp4 -vf "fps=15,scale=1280:-2" -c:v libwebp_anim -lossless 0 -q:v 60 -loop 0 out.webp`（静态版则用 `ffmpeg -i in.mp4 -ss 2 -frames:v 1 -vf scale=1280:-2 out.jpg`）；
  3. 把媒体 base64 写入 `assets/{mode}/bg.b64.txt`（覆盖示例资产）；
  4. 如需调整文字可读性，改 `skin.template.css` 中 `linear-gradient(rgba(0,0,0,0.35),...)` 的遮罩强度；
  5. `python3 tools/build_skin.py <mode>` → 重跑 apply 部署。
  - ⚠️ 视频生成模型不支持 `aspect_ratio` 手动比例（HTTP400），image-to-video 时必须省略该字段让其自动沿用原图比例。
  - ⚠️ 企业版重新着色：将 `--wb-accent`（默认 `#ff4d9c`）改为企业品牌主色即可批量替换所有粉色调。

---

## 📋 已知坑（全量，已在脚本/模板中固化）

1. **灰蒙蒙真根因**：用 `--vscode-*` 变量改背景无效（WorkBuddy 不读它）。必须用 `--cb-*` + `body[data-application-name=work]`.
2. **局部变量遮蔽**：组件在自身作用域重定义 `--cb-*`（如 `--cb-input-background: var(--atm-surface)`），遮蔽 body 级变量。必须挖出真实 class（`atm-*` 命名空间），用同名选择器 `!important` 同时覆盖变量与 `background`，并对后代下放。
3. **双遮蔽源**：输入框背景同时读 `--atm-surface` 与 `--atm-chat-content-bg`，漏一个仍是旧色。两者都必须覆盖。
4. **透明度方向做反**：「透明度 70%」= 不透明度 0.30，不是 0.70。做反会变近黑实心块。
5. **背景定位缺失**：`#root` 仅 `url(...)` 会按原像素左上角平铺、未铺满未居中 = 看着乱。必须补 `cover / center / no-repeat / fixed`。
6. **背景可替换（软校验）**：任何合法媒体背景均可换。抽取/校验只认媒体头（WebP: `RIFF/WEBP`；JPEG: `FFD8`），不限定具体图。换图流程见上方「背景资产」章节。
7. **独立 CSS `<link>` 不可用**：asar 协议下 `<link crossorigin>` 因 CORS 静默失败。必须内联注入主样式文件末尾。
8. **重签名（仅 macOS）**：改 asar 后必须 `codesign --force --deep --sign -`。WorkBuddy **无 entitlements**，传空 plist 会报 `empty` → 仅当 plist 非空才传 `--entitlements`，否则纯 ad-hoc 签名。Windows 无此步骤。
9. **剥离旧块用前缀匹配** `/* WORKBUDDY_SKIN` + `lastIndexOf(END SKIN)`，否则遇不同标记会剥离失败、块累积。
10. **沙箱 NODE_OPTIONS**：`NODE_OPTIONS=--use-system-ca` 会让 `node -e` 崩 → 脚本开头 `unset NODE_OPTIONS`。
11. **asar 定位（跨平台）**：macOS 优先用 `~/.workbuddy/binaries/node/workspace/node_modules/.bin/asar`，失败回退 npx；Windows 优先本地 `node_modules/.bin/asar` 或全局 `asar`，再回退 `npx --yes @electron/asar`。受限网络下 npx 可能卡死，离线环境请先 `npm install -g @electron/asar`。
12. **动画不播放排查**：多为 WorkBuddy 未真正重启（仍用旧 inode）。完全退出（macOS `Cmd+Q` / Windows 任务管理器结束进程）后重开。
13. **`extract_bg.py` 缺 `import base64` 误报**：`_is_webp()` 调 `base64.b64decode` 但文件头只 `import os, re, sys`，`NameError` 被 `except` 吞掉 → 校验恒返 False → 误报「不是合法媒体」。修复：补 `import base64`（已固化）。凡是脚本靠 `except` 兜底校验的，务必先确认被调函数所属模块已 import。

---

## 📁 文件清单（v3.1.0 封装后）

```
pink-crystal-workbuddy-skin/
├── SKILL.md                       # 本文件
├── README.md                      # 仓库说明（含个性化服务声明）
├── DISCLAIMER.md                  # 资产版权与个性化权责声明
├── assets/
│   ├── dynamic/
│   │   ├── skin.css               # 完整动态皮肤（animated WebP 背景，注入目标）
│   │   ├── skin.template.css      # 模板（base64 占位符，便于改样式/换色）
│   │   └── bg.b64.txt             # 动态背景 base64 存档（示例：星空 animated WebP）
│   ├── static/
│   │   ├── skin.css               # 完整静态皮肤（JPEG 单帧背景，轻量）
│   │   ├── skin.template.css      # 模板（同占位符）
│   │   └── bg.b64.txt             # 静态背景 base64 存档（示例：星空静态帧 JPEG）
├── tools/
│   ├── build_skin.py              # 模板+base64 → 重建 skin.css（支持 dynamic/static）
│   └── extract_bg.py              # 应急从 asar 抽 base64
├── docs/
│   ├── design-spec-v6.md          # 原始设计规格（v6）
│   └── design-spec-v6.1.md        # 设计规格修正版（v6.1：澄清「70%透明=0.30不透明」+ 输入框双源遮蔽）
├── macos/scripts/
│   ├── apply.sh                   # 一键安装（双模式 --mode，幂等，含备份+重签）
│   ├── apply.command              # macOS 双击启动（默认动态）
│   └── rollback.sh                # 一键回滚
└── windows/scripts/
    ├── apply.bat                  # 一键安装（双模式，参数 static/dynamic，离线友好）
    ├── inject.js                  # 注入辅助（幂等剥离旧块+注入新块+清理 index.html，规避 cmd 引号问题）
    └── rollback.bat               # 一键回滚
```

## 注意事项

- **应用更新后需重新应用**：WorkBuddy 升级会还原 `app.asar`，主题丢失。重跑 apply 即可。
- **仅修改 app.asar**：不触碰应用本体其他文件。备份保留在用户目录 `WorkBuddy/App_app.asar.bak.*`。
- **动态版包体大**：动画 WebP base64 使 dynamic/skin.css 约 9.4 MB，注入后 asar 增大属正常。
- **静态版轻量**：static/skin.css 仅约 0.27 MB，推荐性能敏感或企业批量分发场景。
- **个性化合规**：分发给第三方前，请替换示例背景资产为企业/个人自有或已授权素材，并确认不侵犯第三方权益。

## 相关

- 通用 asar 换肤方法：`workbuddy-asar-skin`
