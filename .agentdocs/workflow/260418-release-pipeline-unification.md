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
- [ ] 在当前 `main` 提交上创建新 tag
- [ ] 观察 GitHub Actions，确认 `Build Web Release` 触发并生成 Release 资产

## 决策记录

- 正式自动发版以 Web-only 产物为准。
- 已存在的 `v3.13.0` 保持历史不变，避免污染既有发布记录。
- 今后每次从上游合并后，如需正式发布，应在验证通过的 `main` 提交上创建新的 release tag。

## 当前执行结果

- 已修复 `main` 上导致 GitHub `CI` 失败的前端与 Rust 格式问题。
- 已通过本地验证：
  - `corepack pnpm format:check`
  - `corepack pnpm typecheck`
  - `corepack pnpm test:unit`
- 单元与集成测试结果为 `34` 个测试文件、`210` 个测试全部通过。
- 下一步为提交当前修复、推送 `main`，并在当前主线提交上创建新的 Web release tag。
