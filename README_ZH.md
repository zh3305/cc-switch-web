<div align="center">

# CC Switch Fork

[English](README.md) | 中文 | [日本語](README_JA.md)

当前仓库是基于 `cc-switch` 的 fork，README 仅保留与本仓库当前开发、构建和运行方式直接相关的内容。

</div>

## 项目定位

这个 fork 主要用于本地定制和持续开发，核心能力包括：

- 管理 Claude Code、Codex、Gemini、OpenCode、OpenClaw 的配置
- 管理 MCP、Prompts、Skills、代理服务、故障转移和使用量功能
- 提供 Tauri 桌面端和单端口 Web 模式

## 界面预览

|                  主界面                   |                  添加供应商                  |
| :---------------------------------------: | :------------------------------------------: |
| ![主界面](assets/screenshots/main-zh.png) | ![添加供应商](assets/screenshots/add-zh.png) |

## 本地开发

### 环境要求

- Node.js 18+
- pnpm 8+
- Rust 1.85+
- Tauri CLI 2.8+

### 常用命令

```bash
# 安装依赖
pnpm install

# 桌面端开发
pnpm dev

# 类型检查
pnpm typecheck

# 前端单元测试
pnpm test:unit

# 构建桌面端
pnpm build
```

### Rust 后端

```bash
cd src-tauri

cargo fmt
cargo clippy
cargo test
```

## Web 模式

### 单端口启动

```bash
./start-web.sh
```

启动后访问：

```text
http://localhost:17666
```

停止服务：

```bash
./stop-web.sh
```

运行时文件默认写入 `./.run/web/`：

- 日志：`backend.log`
- PID：`backend.pid`

如需改到其他目录：

```bash
CC_SWITCH_RUNTIME_DIR=/tmp/cc-switch-web ./start-web.sh
```

### 手动调试

```bash
# 启动 Web 后端
pnpm dev:server

# 启动前端开发服务器（热重载）
pnpm dev:web
```

说明：

- `17666`：后端、Web UI、`/api`、`/api/ws`
- `3000`：仅手动前端开发时使用的 Vite dev server

### 手动构建 Web 版本

```bash
pnpm build:web
cargo build --release --manifest-path crates/server/Cargo.toml
./crates/server/target/release/cc-switch-web
```

## 技术栈

- 前端：React 18、TypeScript、Vite、TailwindCSS、TanStack Query
- 后端：Tauri 2、Rust、tokio、serde
- 测试：vitest、MSW、@testing-library/react

## 项目结构

```text
src/                 前端代码
src-tauri/           Tauri 桌面端后端
crates/server/       Web 服务端
crates/core/         共用核心逻辑
tests/               前端测试
assets/              截图等资源
docs/                补充文档
```

## 许可证

见 [LICENSE](LICENSE)。
