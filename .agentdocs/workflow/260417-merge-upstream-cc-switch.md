# 同步上游 cc-switch main

## 背景

当前仓库需要从上游 `farion1231/cc-switch` 持续同步更新，并保留现有 Web-only 运行时能力。本次任务目标是在独立同步分支上完成一次真实合并，明确冲突面，并在解决后通过必要验证。

## 目标

- 将上游 `cc-switch` 的 `main` 合并到当前仓库。
- 保留现有 Web fork 的发布与运行能力。
- 明确并记录后续长期同步时的冲突处理边界。

## 非目标

- 不在本次任务中重构全部 Web 架构。
- 不删除 `src-tauri` 或改造为纯 Web 独立项目。

## 阶段计划

### 阶段 1：准备

- [x] 建立 `.agentdocs` 索引与基础架构文档
- [x] 创建本任务文档并记录边界
- [x] 创建独立同步分支

### 阶段 2：合并上游

- [x] 添加或确认 `upstream` 指向 `farion1231/cc-switch`
- [x] 获取上游最新 `main`
- [x] 执行合并并收集冲突文件

### 阶段 3：解决冲突

- [x] 按共享层、Web 适配层、发布层分类处理冲突
- [x] 必要时补充文档/记忆
- [x] 保证 Web fork 差异仍集中在适配层

### 阶段 4：验证与回顾

- [x] 运行类型检查、前端测试、Rust 侧关键测试
- [x] 更新任务文档 TODO 状态
- [x] 总结结果并提醒人工验收

## 当前结果

- 已在分支 `codex/merge-upstream-20260417` 上完成一次真实的上游 `main` 合并。
- 已解决合并冲突，并保留 Web fork 的文档、Web 发布脚本与 headless/Web 适配方向。
- 合并后的 `main` 已修复 Rust `fmt`、`clippy` 与测试编译问题，GitHub `CI` 已重新通过。
- 已补齐 Web/headless 运行时的 rustls `CryptoProvider` 启动初始化，修复 Ubuntu 服务版在首次 HTTPS/TLS 请求时因 provider 歧义导致的 panic。
- 前端格式检查已通过：`npx prettier --check "src/**/*.{js,jsx,ts,tsx,css,json}"`。
- TypeScript 类型检查已通过：`corepack pnpm typecheck`。
- 前端单元与集成测试已通过：`corepack pnpm test:unit`，共 `34` 个测试文件、`210` 个测试用例通过。
- 已补齐 merge 后新增认证、窗口 API 与技能查询对应的测试支撑，入口/集成测试已按真实初始化成本调整为更稳定的用例级超时。
- 当前 WSL 已补齐 `rustup`、`cargo`、`rustfmt`、`clippy` 与 `rsproxy` 配置，可执行基础 Rust 本地检查。
- 当前 WSL 账号仍缺少 `sudo` 权限，无法安装 `pkg-config`、`libssl-dev`、`libgtk-3-dev` 等系统库，因此桌面依赖相关的全量 Rust 构建仍需依赖 CI 环境完成。
- 已确认 `src-tauri/Cargo.toml` 中 `reqwest` 对 Web fork 仍需保留 `default-features = false` 这一个最小差异；若完全改回上游默认特性，会重新引入 `native-tls/openssl` 并在当前 headless/Linux 环境卡在 `pkg-config`。

## 后续待补验

- 如需在本地完整复现 CI 的后端检查，需要为当前 WSL 账号补齐系统依赖安装能力，或切换到已具备桌面构建依赖的 Linux 环境。
- 如需发布桌面端或继续增强上游新能力，需要进一步核对 `src-tauri/src/proxy/forwarder.rs`、`src-tauri/src/services/proxy.rs` 等 headless/desktop 双模式兼容性。
- 后续每次 merge 上游后，都需要确认 `src-tauri` 与 `crates/server` 的启动入口仍保留 rustls provider 初始化，避免依赖树变化重新触发 TLS panic。

## 冲突处理原则

- 对于纯上游业务迭代，优先接受上游实现，再补回 Web 适配需要的薄层差异。
- 对于现有 Web-only 能力，优先保留 `crates/server` 与传输适配相关实现。
- 对于发布脚本与 CI，保留当前 fork 的 Web 发布目标，但吸收上游通用改进。
