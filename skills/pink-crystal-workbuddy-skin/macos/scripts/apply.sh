#!/bin/bash
###############################################################################
# Pink Crystal · 樱花少女 —— WorkBuddy 一键换肤（asar 内联法 · 双模式）
#
# 用法（务必在 *系统终端 Terminal.app* 里跑，不要在 WorkBuddy 内置终端跑，
#      因为脚本会退出 WorkBuddy）：
#   bash ./macos/scripts/apply.sh                # 默认装【动态】皮肤
#   bash ./macos/scripts/apply.sh --mode static  # 装【静态】皮肤
#   bash ./macos/scripts/apply.sh --mode dynamic # 显式装动态
#
# 幂等：重复运行先剥离旧皮肤块（无论 dynamic/static 标记）再重注入，不会累积。
# 关键修复：剥离用「前缀匹配 WORKBUDDY_SKIN」+ lastIndexOf(END SKIN)，
#          兼容 pink-crystal / pink-crystal-dynamic 两种标记（否则会累积）。
###############################################################################
set -euo pipefail
unset NODE_OPTIONS

# ---------- 解析 --mode ----------
MODE="dynamic"
while [ $# -gt 0 ]; do
  case "$1" in
    --mode|-m) MODE="${2:-dynamic}"; shift 2;;
    *) shift;;
  esac
done
case "$MODE" in
  dynamic|static) ;;
  *) echo "❌ --mode 只能是 dynamic 或 static"; exit 1;;
esac

APP="/Applications/WorkBuddy.app"
ASAR="$APP/Contents/Resources/app.asar"
SKILLDIR="$(cd "$(dirname "$0")/../.." && pwd)"
SKIN_CSS="$SKILLDIR/assets/$MODE/skin.css"
WORK="/tmp/wb_pink_$(date +%s)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BAK="$HOME/WorkBuddy/App_app.asar.bak.$STAMP"

log(){ printf "\033[1;35m[Pink Crystal]\033[0m %s\n" "$*"; }
die(){ printf "\033[1;31m[FAIL]\033[0m %s\n" "$*" >&2; exit 1; }

[ -d "$APP" ]      || die "未找到 $APP"
[ -f "$ASAR" ]     || die "未找到 app.asar：$ASAR"
[ -f "$SKIN_CSS" ] || die "缺皮肤素材：$SKIN_CSS（mode=$MODE 不存在）"

# 定位 node（优先 WorkBuddy 自带）
NODE=""
for c in "$HOME"/.workbuddy/binaries/node/versions/*/bin/node; do [ -x "$c" ] && NODE="$c" && break; done
[ -z "$NODE" ] && NODE="$(command -v node || true)"
[ -n "$NODE" ] || die "找不到 node"

# 本地 asar 优先（根治受限网络下 npx 卡死）
ASAR_BIN=""
for c in "$HOME/.workbuddy/binaries/node/workspace/node_modules/.bin/asar" \
         "$SKILLDIR/node_modules/.bin/asar"; do
  [ -x "$c" ] && ASAR_BIN="$c" && break
done
asar_extract(){ [ -n "$ASAR_BIN" ] && "$ASAR_BIN" extract "$@" || npx --yes @electron/asar extract "$@"; }
asar_pack(){    [ -n "$ASAR_BIN" ] && "$ASAR_BIN" pack "$@"    || npx --yes @electron/asar pack "$@"; }

# entitlements 可空（WorkBuddy 实际无 entitlements，传空 plist 会报 empty）
codesign -d --entitlements :- "$APP" > /tmp/wb_ent.plist 2>/dev/null || true
ENT_FLAG=""
if [ -s /tmp/wb_ent.plist ]; then ENT_FLAG="--entitlements /tmp/wb_ent.plist"; fi

log "模式=$MODE  node=$NODE  asar=${ASAR_BIN:-npx}"

# 解包
rm -rf "$WORK"; mkdir -p "$WORK"
asar_extract "$ASAR" "$WORK" || die "解包失败"

MAIN="$(ls "$WORK"/renderer/assets/index-*.css 2>/dev/null | head -1)"
[ -n "$MAIN" ] && [ -f "$MAIN" ] || die "未找到 renderer/assets/index-*.css"
log "主样式=${MAIN#$WORK/}"

# 幂等：稳健剥离（前缀匹配 + lastIndexOf，兼容两种标记）
if grep -q "WORKBUDDY_SKIN" "$MAIN"; then
  log "检测到旧皮肤块，先剥离（幂等）..."
  "$NODE" -e '
    const fs=require("fs"); const f=process.argv[1];
    let s=fs.readFileSync(f,"utf8");
    const a=s.indexOf("/* WORKBUDDY_SKIN");
    const e=s.lastIndexOf("/* END SKIN */");
    if(a>=0 && e>a){ s=s.slice(0,a)+s.slice(e+"/* END SKIN */".length); fs.writeFileSync(f,s); }
  ' "$MAIN"
fi

# 注入皮肤 CSS（含 base64 背景图）
printf "\n" >> "$MAIN"
cat "$SKIN_CSS" >> "$MAIN"

# 清理 index.html 残留 skin.css <link>（asar 协议下会静默失败）
IDX="$WORK/renderer/index.html"
if [ -f "$IDX" ] && grep -q "skin.css" "$IDX"; then
  log "移除 index.html 中残留的 skin.css <link>..."
  "$NODE" -e 'const fs=require("fs");const f=process.argv[1];let s=fs.readFileSync(f,"utf8");s=s.replace(/<link[^>]*skin\.css[^>]*>\s*/gi,"");fs.writeFileSync(f,s);' "$IDX"
fi

grep -q "WORKBUDDY_SKIN" "$MAIN" || die "注入后未检出标识，中止"

# 重打包
NEW="/tmp/new_app_$STAMP.asar"
asar_pack "$WORK" "$NEW" || die "重打包失败"
[ -f "$NEW" ] || die "未生成新 asar"
log "新 asar 大小：$(du -h "$NEW" | cut -f1)"

# 退出 → 备份 → 替换 → 重签 → 去隔离
log "退出 WorkBuddy..."
osascript -e 'tell application "WorkBuddy" to quit' 2>/dev/null || true
for i in $(seq 1 12); do pgrep -f "WorkBuddy.app/Contents/MacOS" >/dev/null 2>&1 || break; sleep 1; done
pkill -f "WorkBuddy.app/Contents/MacOS" 2>/dev/null || true
sleep 2

cp "$ASAR" "$BAK" || die "备份失败（中止，绝不无备份替换）"
cp "$NEW" "$ASAR" || die "替换失败"

log "重签（ENT_FLAG=${ENT_FLAG:-<ad-hoc>}）..."
codesign --force --deep --sign - $ENT_FLAG "$APP" \
  || { log "重签失败，回滚..."; cp "$BAK" "$ASAR"; codesign --force --deep --sign - $ENT_FLAG "$APP" || true; die "已回滚，请检查"; }

xattr -cr "$APP" || true

# 自检
CNT="$(grep -a -c "WORKBUDDY_SKIN" "$ASAR" 2>/dev/null || echo 0)"
[ "$CNT" -gt 0 ] || die "自检失败：asar 内未检出皮肤标识"
codesign --verify --verbose=2 "$APP" >/dev/null 2>&1 || die "自检失败：签名无效"
log "✅ 模式=$MODE 命中=$CNT 签名有效"

open "$APP"
log "🎀 完成！回滚点：$BAK"
log "   若界面异常：bash $SKILLDIR/macos/scripts/rollback.sh \"$BAK\""
