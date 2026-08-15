#!/bin/bash
# ============================================================
# dsh arm64 一键部署脚本 (install.sh)
# ------------------------------------------------------------
# 适用: arm64 Linux (Ubuntu/Termux proot 等), Node.js >= 22
# 用法: bash install.sh [DEEPSEEK_API_KEY]
#   或: DEEPSEEK_API_KEY=sk-xxx bash install.sh
# 说明: 本包已内置 arm64 编译好的 node-pty (pty.node)，
#       无需安装编译工具链即可直接使用完整功能。
# ============================================================

set -u
PACK_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE_TGZ="$PACK_DIR/dsh-core.tar.gz"
ASK_SCRIPT="$PACK_DIR/dsh-ask"
TPL_DIR="$PACK_DIR/dsh-conf-template"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERR]${NC} $1"; }

echo "=============================================="
echo "  dsh (DeepSeek Harness) arm64 一键部署"
echo "=============================================="

# ---------- 1. 环境检查 ----------
echo "[1/6] 检查环境..."
if ! command -v node >/dev/null 2>&1; then
    err "未找到 node，请先安装 Node.js (>=22): https://nodejs.org/"
    exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
    err "未找到 npm，请先安装 Node.js (>=22)"
    exit 1
fi
NODE_V=$(node -v)
ARCH=$(node -e "console.log(process.arch)")
ABI=$(node -e "console.log(process.versions.modules)")
ok "Node $NODE_V (arch=$ARCH, ABI=$ABI)"
if [ "$ARCH" != "arm64" ] && [ "$ARCH" != "aarch64" ]; then
    warn "当前架构是 $ARCH，本包为 arm64 编译产物，可能不兼容"
fi
# node-pty 对 ABI 敏感: 137=Node24, 127=Node22, 131=Node23
case "$ABI" in
    137|131|127|133) ok "ABI $ABI 与内置 pty.node 兼容" ;;
    *) warn "ABI $ABI 未内置，node-pty 可能需重新编译 (见 README)" ;;
esac

# ---------- 2. 解压 dsh 主包 ----------
echo "[2/6] 解压 dsh 主包..."
if [ ! -f "$CORE_TGZ" ]; then
    err "缺少 $CORE_TGZ"
    exit 1
fi
NPM_DIR="$(npm root -g)"
mkdir -p "$NPM_DIR/@deepseek-ai"
tar xzf "$CORE_TGZ" -C "$NPM_DIR/@deepseek-ai/"
ok "dsh 已解压到 $NPM_DIR/@deepseek-ai/dsh"

# ---------- 3. 创建 dsh 命令 ----------
echo "[3/6] 创建 dsh 命令..."
DASH_BIN="$(command -v node | xargs dirname)/dsh"
if [ -e "$DASH_BIN" ]; then rm -f "$DASH_BIN"; fi
ln -s "$NPM_DIR/@deepseek-ai/dsh/lib/bin.js" "$DASH_BIN" 2>/dev/null || \
    ln -s "$NPM_DIR/@deepseek-ai/dsh/lib/bin.js" /usr/local/bin/dsh
ok "dsh 命令 -> $DASH_BIN"

# ---------- 4. 验证 node-pty ----------
echo "[4/6] 验证 node-pty..."
PTY_DIR="$NPM_DIR/@deepseek-ai/dsh/node_modules/node-pty"
if [ -f "$PTY_DIR/build/Release/pty.node" ]; then
    PTY_OK=$(node -e "const p=require('$PTY_DIR'); console.log(typeof p.spawn === 'function' ? 'PTY_LOAD_OK' : 'PTY_FAIL')" 2>&1)
    if [ "$PTY_OK" = "PTY_LOAD_OK" ]; then
        ok "node-pty 加载成功 (PTY_LOAD_OK)"
    else
        warn "node-pty 加载异常: $PTY_OK"
        # 尝试 prebuilds 副本
        mkdir -p "$PTY_DIR/prebuilds/linux-arm64"
        cp "$PTY_DIR/build/Release/pty.node" "$PTY_DIR/prebuilds/linux-arm64/pty.node" 2>/dev/null
        PTY_OK2=$(node -e "const p=require('$PTY_DIR'); console.log(typeof p.spawn === 'function' ? 'PTY_LOAD_OK' : 'PTY_FAIL')" 2>&1)
        [ "$PTY_OK2" = "PTY_LOAD_OK" ] && ok "node-pty 通过 prebuilds 加载成功" || warn "node-pty 仍异常，可参考 README 重新编译"
    fi
else
    warn "未找到 pty.node，参考 README 重新编译"
fi

# ---------- 5. 安装 dsh-ask 快捷脚本 ----------
echo "[5/6] 安装 dsh-ask..."
if [ -f "$ASK_SCRIPT" ]; then
    cp "$ASK_SCRIPT" /usr/local/bin/dsh-ask 2>/dev/null
    chmod +x /usr/local/bin/dsh-ask 2>/dev/null
    ok "dsh-ask -> /usr/local/bin/dsh-ask"
else
    warn "未找到 dsh-ask 脚本"
fi

# ---------- 6. 初始化配置与 API Key ----------
echo "[6/6] 初始化配置..."
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
mkdir -p "$DSH_HOME/profiles"
if [ -d "$TPL_DIR/profiles" ]; then
    cp -rn "$TPL_DIR/profiles/headless" "$DSH_HOME/profiles/" 2>/dev/null
    cp -rn "$TPL_DIR/profiles/web" "$DSH_HOME/profiles/" 2>/dev/null
    ok "profiles 已初始化 (headless/web)"
fi

API_KEY="${1:-${DEEPSEEK_API_KEY:-}}"
if [ -n "$API_KEY" ]; then
    printf 'DEEPSEEK_API_KEY: %s\n' "$API_KEY" > "$DSH_HOME/.credentials.yaml"
    chmod 600 "$DSH_HOME/.credentials.yaml"
    ok "DEEPSEEK_API_KEY 已写入 $DSH_HOME/.credentials.yaml"
else
    if [ -f "$DSH_HOME/.credentials.yaml" ] && grep -q 'DEEPSEEK_API_KEY' "$DSH_HOME/.credentials.yaml"; then
        ok "已存在凭据文件"
    else
        warn "未提供 API Key，请手动创建: $DSH_HOME/.credentials.yaml"
        warn '内容格式: DEEPSEEK_API_KEY: sk-你的key'
    fi
fi

# ---------- 验证 ----------
echo "----------------------------------------------"
DSH_VER=$(dsh --version 2>&1 | head -1)
ok "dsh 版本: $DSH_VER"
echo "----------------------------------------------"
echo -e "${GREEN}✔ 部署完成！使用方式:${NC}"
echo "  dsh web                        # 启动 Web UI (127.0.0.1:7860)"
echo "  dsh-ask \"你的任务\" [超时秒数]  # 直接调用 dsh 智能体干活"
echo "  dsh --profile headless \"任务\"  # 或原生 headless 调用"
echo "  DSH_HOME=$DSH_HOME"
echo "=============================================="