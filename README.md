# dsh arm64 一键部署包

> 由大肥鱼（AI）打包：dsh 0.1.0-rc.6 + arm64 修复版 node-pty + dsh-ask 快捷调用脚本
> 适用于 **arm64 (aarch64) Linux** 环境（Ubuntu、Termux proot 等），Node.js >= 22

---

## 📦 包内容

```
dsh-arm64-pack/
├── install.sh           # 一键安装脚本（核心）
├── dsh-core.tar.gz      # dsh 完整安装包（含依赖 + arm64 pty.node）
├── dsh-ask              # AI/命令行快捷调用脚本
├── dsh-conf-template/   # 配置模板（profiles: headless/web）
└── README.md
```

**最大卖点**：内置了 arm64 编译好的 `pty.node`（node-pty 原生模块），
新设备**不需要 g++/make 编译工具链**，解压即用，全功能保留（终端面板等）。

---

## 🚀 快速部署（新设备上粘贴这几行）

把整个 `dsh-arm64-pack` 目录传到新设备（U盘/网盘/QQ传输均可），然后：

```bash
# 1. 进入包目录
cd dsh-arm64-pack

# 2. 一键安装（带 API Key）
bash install.sh sk-你的DeepSeekAPIKey

# 3. 或不带 Key 安装，之后再配
# bash install.sh
# echo "DEEPSEEK_API_KEY: sk-xxx" > ~/.dsh/.credentials.yaml
```

安装脚本会自动完成：
- ✅ 检查 Node 环境与 ABI 兼容性
- ✅ 解压 dsh 到 npm 全局目录
- ✅ 创建 `dsh` 命令
- ✅ 验证 node-pty（PTY_LOAD_OK）
- ✅ 安装 `dsh-ask` 快捷脚本
- ✅ 初始化 profiles 配置 + 写入 API Key

---

## 🎮 使用方式（大肥鱼同款）

```bash
# Web UI（浏览器界面）
dsh web                              # → http://127.0.0.1:7860

# 一句话干活（AI 智能体，答完即退）
dsh-ask "用 Python 写个网络爬虫"      # 默认 90 秒超时
dsh-ask "分析这份数据" 180            # 自定义超时

# 原生 headless 调用
dsh --profile headless "你的任务"

# 交互式 TUI
dsh --profile tui
```

---

## ⚠️ 注意事项

1. **Node 版本兼容**：内置 pty.node 编译于 **Node v24 (ABI 137)**。
   已验证兼容 ABI: 127(Node22) / 131(Node23) / 133 / 137(Node24)。
   其他版本安装时会有警告，可能需要重新编译 node-pty：
   ```bash
   cd /usr/lib/node_modules/@deepseek-ai/dsh/node_modules/node-pty
   npm rebuild node-pty  # 需要 g++/make/python
   ```
2. **安全限制**：`dsh web` **禁止绑定 0.0.0.0**（防远程代码执行暴露），
   只能 `--host 127.0.0.1`。
3. **API Key 安全**：请勿把含 Key 的安装包公开分享。

---

*打包日期: 2026-08-15 · 由大肥鱼精心打包 🐋*