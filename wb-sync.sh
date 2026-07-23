#!/bin/zsh
# WorkBuddy 跨设备同步脚本
# 用法: wb-sync [init|push|pull|status]
#
# 首次使用:
#   1. 在 GitHub 上创建一个私有仓库（比如 workbuddy-sync）
#   2. 修改下面的 REMOTE_URL
#   3. 运行: wb-sync init
#   4. 在另一台电脑上: wb-sync pull
#
# 日常使用:
#   离开当前电脑时: wb-sync push
#   到达另一台电脑时: wb-sync pull

# ====== 配置（必填）======
REMOTE_URL="${WORKBUDDY_SYNC_REPO:-git@github.com:zengx/WorkBuddy.git}"
BRANCH="main"
# ==========================

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

WORKBUDDY_DIR="$HOME/.workbuddy"

# 检查 workbuddy 目录
if [ ! -d "$WORKBUDDY_DIR" ]; then
    echo "${RED}❌ 找不到 $WORKBUDDY_DIR${NC}"
    exit 1
fi

cd "$WORKBUDDY_DIR" || exit 1

# 创建 .gitignore
ensure_gitignore() {
    if [ -f .gitignore ]; then
        return
    fi
    echo "${BLUE}创建 .gitignore...${NC}"
    cat > .gitignore << 'EOF'
# 运行时临时文件
logs/
traces/
shell-snapshots/
*.db-wal
*.db-shm
.DS_Store
*.tmp
*.log

# 应用自身（不需要同步）
app/
binaries/

# 市场缓存
connectors-marketplace/
plugin-marketplace-state-new
.plugin-stats-cache.json
.connectors-marketplace.meta.json

# 启动相关
install-timing-reported
tencent-docs-engine.port
last-launch.json
EOF
}

# 初始化 git
ensure_git_repo() {
    if [ -d .git ]; then
        return
    fi

    echo "${YELLOW}首次使用，初始化 git 仓库...${NC}"
    git init -q
    git branch -M "$BRANCH"
    ensure_gitignore

    if ! git remote get-url origin &>/dev/null; then
        if [[ "$REMOTE_URL" == *"YOUR_USERNAME"* ]]; then
            echo "${RED}❌ 请先修改脚本顶部的 REMOTE_URL，填入你的 GitHub 仓库地址${NC}"
            echo "   或者设置环境变量: export WORKBUDDY_SYNC_REPO=git@github.com:xxx/yyy.git"
            exit 1
        fi
        git remote add origin "$REMOTE_URL"
        echo "${GREEN}已关联远程仓库: $REMOTE_URL${NC}"
    fi
}

# 询问 WorkBuddy 是否已关闭
confirm_close_workbuddy() {
    echo "${YELLOW}⚠️  请确认 WorkBuddy 已完全退出（不是最小化窗口）${NC}"
    read -p "WorkBuddy 退出了吗？[y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "${RED}请先退出 WorkBuddy（macOS: Cmd+Q，Windows: 文件→退出），再重试${NC}"
        exit 1
    fi
}

# 检查是否有 WorkBuddy 进程在运行
check_workbuddy_running() {
    if pgrep -f "WorkBuddy" &>/dev/null || pgrep -f "workbuddy" &>/dev/null; then
        echo "${RED}❌ 检测到 WorkBuddy 还在运行${NC}"
        echo "   请先完全退出 WorkBuddy，再执行同步"
        exit 1
    fi
}

# 询问路径差异处理
handle_path_diff() {
    echo "${BLUE}💡 提示: 如果两台电脑的 macOS 用户名不同，${NC}"
    echo "${BLUE}   同步完成后可能需要在 WorkBuddy 里重新指定工作目录${NC}"
    echo "${BLUE}   路径差异在 .workbuddy/projects/ 下的子目录名中${NC}"
}

# ====== 子命令 ======

action_init() {
    ensure_git_repo
    ensure_gitignore

    if git rev-parse --verify HEAD &>/dev/null && [ -n "$(git log --oneline 2>/dev/null)" ]; then
        echo "${YELLOW}已经初始化过了${NC}"
        git status -s
        return
    fi

    check_workbuddy_running

    echo "${BLUE}添加文件并首次提交...${NC}"
    git add -A
    if git diff --cached --quiet; then
        echo "${YELLOW}没有可同步的内容（目录是空的）${NC}"
        return
    fi

    git commit -q -m "initial sync from $(hostname) at $(date '+%Y-%m-%d %H:%M:%S')"
    git push -u origin "$BRANCH"
    echo "${GREEN}✅ 初始化完成！${NC}"
    echo "${BLUE}在另一台电脑上执行: wb-sync pull${NC}"
}

action_push() {
    ensure_git_repo

    check_workbuddy_running
    confirm_close_workbuddy

    git add -A
    if git diff --cached --quiet; then
        echo "${YELLOW}没有新内容需要同步${NC}"
        return
    fi

    git commit -q -m "sync from $(hostname) at $(date '+%Y-%m-%d %H:%M:%S')"

    if ! git push origin "$BRANCH" 2>&1 | tee /tmp/wb-sync-push.log; then
        echo "${RED}❌ 推送失败${NC}"
        if grep -q "non-fast-forward" /tmp/wb-sync-push.log; then
            echo "${YELLOW}提示: 远程有新提交。先 pull 一下：wb-sync pull --force-overwrite${NC}"
        fi
        exit 1
    fi

    echo "${GREEN}✅ 推送完成${NC}"
}

action_pull() {
    ensure_git_repo

    check_workbuddy_running

    # 备份本地配置
    BACKUP_DIR="$HOME/.workbuddy.backup.$(date '+%Y%m%d_%H%M%S')"
    echo "${BLUE}📦 备份本地配置到 $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR"
    cp -R "$WORKBUDDY_DIR"/. "$BACKUP_DIR"/ 2>/dev/null

    git fetch origin

    # 检查本地是否有未推送的提交
    LOCAL_AHEAD=$(git rev-list --count origin/"$BRANCH"..HEAD 2>/dev/null || echo 0)
    if [ "$LOCAL_AHEAD" -gt 0 ]; then
        echo "${YELLOW}⚠️  本地有 $LOCAL_AHEAD 个未推送的提交${NC}"
        echo "请选择:"
        echo "  1) 先 push（推荐）→  wb-sync push"
        echo "  2) 放弃本地更改，用远程覆盖 →  wb-sync pull --force-overwrite"
        exit 1
    fi

    # 拉取
    if ! git pull --rebase origin "$BRANCH" 2>&1; then
        echo "${YELLOW}rebase 失败，尝试普通 merge...${NC}"
        git pull origin "$BRANCH" || {
            echo "${RED}❌ 拉取失败，可能有冲突。请检查后手动处理${NC}"
            exit 1
        }
    fi

    echo "${GREEN}✅ 拉取完成${NC}"
    handle_path_diff
    echo "${BLUE}现在可以打开 WorkBuddy 了${NC}"
}

action_force_pull() {
    ensure_git_repo
    check_workbuddy_running

    BACKUP_DIR="$HOME/.workbuddy.backup.$(date '+%Y%m%d_%H%M%S')"
    echo "${BLUE}📦 备份到 $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR"
    cp -R "$WORKBUDDY_DIR"/. "$BACKUP_DIR"/ 2>/dev/null

    echo "${YELLOW}强制重置到远程版本...${NC}"
    git fetch origin
    git reset --hard origin/"$BRANCH"

    echo "${GREEN}✅ 完成${NC}"
    handle_path_diff
}

action_status() {
    if [ ! -d .git ]; then
        echo "${YELLOW}还没初始化。运行: wb-sync init${NC}"
        return
    fi

    echo "${BLUE}=== 仓库信息 ===${NC}"
    echo "远程: $(git remote get-url origin 2>/dev/null || echo '未配置')"
    echo "分支: $BRANCH"
    echo ""
    echo "${BLUE}=== 状态 ===${NC}"
    git status
    echo ""
    echo "${BLUE}=== 同步状态 ===${NC}"
    LOCAL=$(git rev-parse HEAD 2>/dev/null)
    REMOTE=$(git rev-parse origin/"$BRANCH" 2>/dev/null)
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "${GREEN}✅ 本地与远程一致${NC}"
    else
        AHEAD=$(git rev-list --count origin/"$BRANCH"..HEAD 2>/dev/null)
        BEHIND=$(git rev-list --count HEAD..origin/"$BRANCH" 2>/dev/null)
        [ "$AHEAD" -gt 0 ] && echo "${YELLOW}本地领先远程 $AHEAD 个提交（需要 push）${NC}"
        [ "$BEHIND" -gt 0 ] && echo "${YELLOW}本地落后远程 $BEHIND 个提交（需要 pull）${NC}"
    fi
}

# ====== 入口 ======
case "${1:-status}" in
    init)     action_init ;;
    push)     action_push ;;
    pull)
        if [ "$2" = "--force-overwrite" ]; then
            action_force_pull
        else
            action_pull
        fi
        ;;
    status)   action_status ;;
    *)
        echo "用法: $0 [init|push|pull|status]"
        echo ""
        echo "命令:"
        echo "  init    首次使用，初始化仓库（只需要执行一次）"
        echo "  push    把当前电脑的更改推送到 GitHub"
        echo "  pull    从 GitHub 拉取最新内容到当前电脑"
        echo "  status  查看同步状态"
        exit 1
        ;;
esac
