# 合并上游 v3.15.0 tag

- [x] 确认上游目标 tag 与同步策略
- [x] 创建独立同步分支并拉取上游 tag
- [x] 合并上游 v3.15.0
- [x] 解决冲突并保留 Web fork 关键差异
- [x] 运行前端与 Rust 必要验证
- [x] 修复同步引入的编译/测试问题
- [x] 更新文档并整理结论
- [x] 在验证通过前不推送、不创建新的 Web release tag

## 背景

用户要求将当前 Web fork 同步到上游新 tag，并特别强调：**不要先推送 tag，必须先确认编译没有问题**。

结合既有同步策略，本轮目标不是追 `upstream/main`，而是同步到上游最新稳定发布 tag，并在本地完成必要验证后，再决定是否推送与创建 Web fork 自己的 release tag。

## 目标

- 将当前仓库同步至上游 `farion1231/cc-switch` 的 `v3.15.0`
- 保留现有 Web/headless 架构与发布链路
- 先完成本地编译/测试验证，再决定后续推送与打 tag

## 非目标

- 不直接追踪 `upstream/main` 的未发版提交
- 不在同步前创建或推送新的 Web release tag
- 不在本轮发起大规模核心层重构

## 已知约束

- 当前仓库是长期维护的 Web fork，不能直接 fast-forward 到上游 tag
- `src-tauri/Cargo.toml` 中 `reqwest = { default-features = false, ... }` 仍需保留
- Web/headless 运行时必须保留 rustls `CryptoProvider` 启动初始化
- `crates/core` 目前仍是对 `src-tauri` 的轻量封装，不是完全独立 core

## 风险重点

- `src-tauri/src/lib.rs`
- `src-tauri/Cargo.toml`
- `src-tauri/src/commands/`
- `src-tauri/src/services/`
- `src/lib/transport/`
- `src/lib/platform-paths.*`
- `src/lib/updater.*`
- `src/platform/bootstrap.*`
- `crates/core/`
- `crates/server/`
- `.github/workflows/build-web-release.yml`
- `build-web-release.sh`
- `scripts/build-web-deb-package.sh`
- `packaging/deb/`

## 验收标准

- 上游 `v3.15.0` 已合并到独立同步分支
- 关键 Web fork 差异未丢失
- 必要的前端/Rust 编译与测试在本地通过，或清楚记录剩余环境阻塞
- 在未完成验证前，不进行推送与新 tag 创建

## 同步策略结论

- 本轮继续采用“独立同步分支 + merge upstream tag”的既定策略，不改成 fast-forward 或 rebase。
- 原因不是 Git 技术偏好，而是当前仓库仍是长期维护的 Web fork，存在必须保留的 Web/headless 差异；直接快进到上游 tag 会丢失 fork 侧能力，也不符合既有维护计划。
- 这也延续了 `260418-upstream-sync-strategy.md` 与 `260418-upstream-sync-execution-plan.md` 的结论：短期先把差异收敛到少量适配点，而不是假装 fork 已经可以无差别追上游。

## 关于“轻量模式”的判断

- 上游新增的 lightweight mode 不是“后台逻辑与前端 UI 已完全分层”的同义词。
- 它更接近“桌面窗口可关闭 / 可隐藏，但后台服务继续存活”的运行时能力。
- `crates/core` 目前仍然只是对 `src-tauri` 的轻量封装，尚未演进成真正稳定、完全独立的纯核心层，因此本轮同步仍需要继续维护 `headless/desktop` 双模式适配。

## 本轮保留的 Web fork 关键差异

- `src-tauri/Cargo.toml` 中 `reqwest` 继续保留 `default-features = false`，避免 Web/headless 构建重新引入 `native-tls/openssl` 依赖。
- `src-tauri` 的 `desktop/headless` 特性边界继续保留，不能为了让测试通过而把整套桌面命令模块强行开放给 headless。
- `UiAppHandle` 与既有 Web/headless 路径适配逻辑继续保留。
- `src/hooks/useDirectorySettings.ts` 的平台路径兼容逻辑继续保留，没有被上游实现覆盖掉。

## 编译问题与处理结论

### Rust 工具链

- 2026-05-17 本地验证确认：
- `rustc 1.85.0` 已不再满足依赖的最低版本要求，`image 0.25.10` 与 `time 0.3.47` 都要求 `rustc 1.88.0`。
- `rustc 1.95.0` 会在 `src-tauri/src/proxy/forwarder.rs` 的 borrow checker 路径触发 rustc ICE，不能作为当前同步的稳定验证基线。
- `rustc 1.88.0` 可以完成本轮 `src-tauri` headless 编译与测试，因此把仓库默认工具链与 `src-tauri` 的 `rust-version` 一并调整到 `1.88.0`。

### 为通过 headless/test-hooks 所做的最小适配

- `src-tauri/src/commands/provider.rs`
  为 provider 相关测试 hook 放宽 `cfg`，允许 `desktop` 或 `test-hooks`。
- `src-tauri/src/commands/proxy.rs`
  为 pricing / default cost multiplier 测试 hook 放宽 `cfg`，允许 `desktop` 或 `test-hooks`。
- `src-tauri/src/commands/usage.rs`
  让模型定价写入逻辑在 headless 测试场景也可编译，同时补齐 `Decimal`/`FromStr` 导入。
- `src-tauri/src/lib.rs`
  新增 root-level `test-hooks` 包装函数，并导出 `get_config_library_path`，避免 headless 测试直接依赖桌面命令模块。
- `crates/core/src/lib.rs`
  补齐 `AppType::ClaudeDesktop` 的配置路径与存在性判断，适配上游新增 app type。

### 其他同步后收口

- `src-tauri/src/proxy/forwarder.rs`
  在保留上游逻辑的前提下完成格式化与编译收口，使其在 `1.88.0` 下可稳定通过 headless 测试。
- `src-tauri/src/services/proxy.rs`
  对 desktop-only 路径补上条件编译，避免 headless 编译误入桌面分支。
- `src-tauri/src/services/speedtest.rs`
  把测试改成 `tokio::test` 异步形式，避免对 `tauri::async_runtime::block_on` 的桌面运行时假设。

## 本地验证记录

### 前端验证

- `corepack pnpm typecheck`
  通过。
- `corepack pnpm test:unit`
  通过，`41` 个测试文件、`237` 个测试全部通过。

### Rust 验证

- `cargo fmt --manifest-path src-tauri/Cargo.toml`
  已在独立 `1.88.0` 工具链下执行。
- `cargo fmt --check --manifest-path src-tauri/Cargo.toml`
  通过。
- `cargo check --manifest-path src-tauri/Cargo.toml --no-default-features --features headless,test-hooks`
  通过。
- `cargo test --manifest-path crates/server/Cargo.toml tauri_rpc_consistency`
  通过。
- `cargo test --manifest-path src-tauri/Cargo.toml --no-default-features --features headless,test-hooks`
  通过；实际运行 `1129` 个 Rust 测试。
- `cargo clippy --manifest-path src-tauri/Cargo.toml -- -D warnings`
  通过；已按 GitHub CI 默认桌面特性在 WSL 下复现并清理本轮同步引入的 `uninlined_format_args` / `unused_mut` / 条件编译相关问题。
- 提交前再次复验：
  - `cargo test --manifest-path src-tauri/Cargo.toml --no-default-features --features headless,test-hooks -- --nocapture`
    再次通过；此前一次整套测试瞬时返回失败、但单独测试项正常，随后完整重跑未复现，最终仍以本次新鲜通过结果作为提交依据。
  - `corepack pnpm typecheck`
    通过。
  - `corepack pnpm test:unit`
    通过，`41` 个测试文件、`237` 个测试全部通过。

### 结果说明

- 本地验证期间仍能看到若干 warning，例如未使用代码、Vitest 中故意构造的 error log、Browserslist 数据过旧提示，但都不构成当前同步阻塞。
- 为复现默认桌面 `clippy`，本轮在 WSL 中补齐了 `pkg-config`、`libglib2.0-dev`、`libgtk-3-dev`、`libgdk-pixbuf-2.0-dev`、`libsoup-3.0-dev`、`libjavascriptcoregtk-4.1-dev`、`libwebkit2gtk-4.1-dev`。
- 当前没有发现新的编译失败、测试失败或未解决 merge 冲突。

## 当前状态

- 当前分支：`main`
- 上游 `v3.15.0` 已完成合并，且 `main` 已补齐默认桌面 CI/clippy 收口与本地验证
- 已具备直接提交并推送 `origin/main` 的条件
- 仍未创建新的 Web release tag
- 后续如需发版，应在远程 CI 再次确认无误后单独执行
