# 统一 Web 发版链路并修复自动产包

## 背景

当前仓库已经完成一次上游 `farion1231/cc-switch` 合并，并将结果并回 `main`。但在推送 `v3.13.0` 后，GitHub 实际触发的是旧的桌面 `Release` workflow，而不是当前仓库新增的 `Build Web Release` workflow，导致自动产包失败。

同时，`main` 上的 `CI` 也因为前端与 Rust 格式检查失败而变红，阻断了后续统一发布流程。

## 目标

- 统一当前仓库的正式自动发布入口为 Web 发布链路。
- 修复当前 `main` 上会导致 CI 失败的格式问题。
- 在不重写既有发布历史的前提下，通过新 tag 触发正确的 Web Release 自动产包。
- 将本次处理沉淀为后续频繁合并上游后的标准动作。

## 非目标

- 不回写或强推覆盖已有 `v3.13.0` tag。
- 不将当前 Web-only 发布重新改回桌面 Tauri 自动发布。
- 不在本轮引入大规模架构重构。

## 问题确认

- `v3.13.0` 远端 tag 指向旧提交，不是当前 `main`。
- 旧提交上的 workflow 仍包含旧桌面发布逻辑，因此推 tag 后跑错流程。
- 当前 `main` 的 `CI` 失败原因包括：
  - 前端 `prettier --check` 失败
  - Rust `cargo fmt --check` 失败

## 执行计划

### 阶段 1：整理发布规则

- [x] 检查当前 `.github/workflows/` 下的触发条件与职责分工
- [x] 确认 `Build Web Release` 为正式自动发布入口
- [x] 保持桌面 `Release` 仅用于手动触发，避免未来 tag 再次误触发旧逻辑

### 阶段 2：修复主线校验

- [x] 修复前端格式问题
- [x] 修复 Rust 格式问题
- [x] 补跑本地 `format` / `typecheck` / `test`

### 阶段 3：完成正式发版

- [ ] 提交并推送 `main`
- [ ] 在当前 `main` 提交上创建新 tag（`v3.13.3` 已失败，下一次应使用新的 release tag）
- [ ] 观察 GitHub Actions，确认 `Build Web Release` 触发并生成 Release 资产

## 决策记录

- 正式自动发版以 Web-only 产物为准。
- 已存在的 `v3.13.0` 保持历史不变，避免污染既有发布记录。
- 今后每次从上游合并后，如需正式发布，应在验证通过的 `main` 提交上创建新的 release tag。

## 当前执行结果

- 已修复 `main` 上导致 GitHub `CI` 失败的前端与 Rust 格式问题。
- 已定位 `Build Web Release` 首次失败根因为 `src-tauri` 在 `headless` 构建路径下仍残留裸 `#[tauri::command]` 与 `tauri::async_runtime` 调用。
- 已在以下文件完成最小隔离修复，避免 `crates/server` 构建时误要求桌面 `tauri` 依赖：
  - `src-tauri/src/commands/deeplink.rs`
  - `src-tauri/src/commands/misc.rs`
  - `src-tauri/src/commands/model_fetch.rs`
  - `src-tauri/src/commands/session_manager.rs`
- 在上游继续演进后，又发现 `crates/core` 与 `crates/server` 的 Web 适配层仍有一轮接口签名滞后，具体包括：
  - `ProviderService::{add, update}` 参数签名变化
  - `StreamCheckService::check_with_retry` 与 `StreamCheckResult` 字段扩展
  - `UsageStatsService` 查询接口新增 `app_type` 过滤参数
  - `SkillService::import_from_apps` 改为接收结构化 `ImportSkillSelection`
- 本轮已完成以下对齐修复：
  - `crates/core/src/lib.rs` 对齐上游新接口签名，并补齐 `ImportSkillSelection` / `SkillApps` 的 re-export
  - `crates/server/src/api/dispatch.rs` 同时兼容新的 `imports` 结构与旧的 `directories` 结构
  - `src-tauri/Cargo.toml` 将 `reqwest` 调整为 `rustls` 路径，避免本地 `cargo check` 再被 `openssl-sys` 卡住
- 本轮新增本地测试：
  - `parse_skill_imports_supports_new_imports_shape`
  - `parse_skill_imports_supports_legacy_directories_shape`
- 当前已确认通过的本地验证：
  - `corepack pnpm build:web`
  - `~/.cargo/bin/cargo fmt --check --manifest-path crates/core/Cargo.toml`
  - `~/.cargo/bin/cargo fmt --check --manifest-path crates/server/Cargo.toml`
  - `~/.cargo/bin/cargo check --manifest-path crates/core/Cargo.toml`
  - `~/.cargo/bin/cargo check --manifest-path crates/server/Cargo.toml`
  - `~/.cargo/bin/cargo test --manifest-path crates/core/Cargo.toml --lib`
  - `~/.cargo/bin/cargo test --manifest-path crates/server/Cargo.toml parse_skill_imports`
  - `bash tests/test-web-deb-package.sh`
- 新确认的环境事实：
  - 目前本地 `crates/server` 的失败点已不再是 Rust 接口错误，而是构建前必须先生成前端 `dist/`，否则 `RustEmbed` 会因为目录不存在而失败。
  - `reqwest` 切到 `rustls` 后，本机已能完成 `crates/core` 与 `crates/server` 的 `cargo check`，不再受这条 OpenSSL 依赖链阻塞。
- 下一步应先整理并提交当前修复，再在该提交上创建新的 Web release tag；由于 `v3.13.3` 已失败，后续必须使用新的 tag，而不是复用旧 tag。
- 本地已验证 `build-web-release.sh` 能真实产出以下 Linux 资产：
  - 独立二进制：`release-web-test/cc-switch-web-v3.13.3-linux-x86_64-ubuntu20.04`
  - Debian 安装包：`release-web-test/cc-switch-web_3.13.3_amd64.deb`
  - `.deb` 内已包含 `systemd` service、默认环境文件与安装后的主程序路径。
