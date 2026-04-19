# 再次同步上游 cc-switch

## 背景

当前仓库刚完成 `v3.13.5` Web 发布，但用户要求再次从上游 `farion1231/cc-switch` 拉取并合并，且明确不能丢失现有 Web fork 功能，也不能引入新的逻辑错误。

用户提供的链接是 `https://github.com/farion1231/cc-switch/tree/v3.13.0`，但该引用对应的是固定 tag，而不是“更新中的”主线，因此本轮需要先核对引用，再按真实的上游最新提交执行同步。

## 目标

- 从上游最新主线同步到当前仓库。
- 保留已验证通过的 Web 发布链路。
- 保留 Debian 安装包产物与 systemd 服务模板。
- 保留 headless/Web 运行时的 rustls provider 初始化与最小依赖分叉。

## 非目标

- 不回退到上游旧 tag `v3.13.0`。
- 不在本轮做大规模重构。
- 不删除现有 Web-only 发布能力。

## 当前事实

- 本地 `main` 当前在提交 `8220ab4c`，已发布 `v3.13.5`。
- 上游 `refs/heads/main` 当前是 `9871d3d1ebe698a5793ddbb94a941790f657a911`。
- 上游 `refs/tags/v3.13.0` 当前是 `5fa0c22760f6d9b394f6ab4f4b571eec986abc8a`。
- 因此“已更新”与 `v3.13.0` 这两个条件互相冲突；按任务意图，本轮默认同步 `upstream/main`。

## 风险边界

- `src-tauri/src/lib.rs`
  这里承载了 rustls `CryptoProvider` 初始化，merge 时不能丢。
- `src-tauri/Cargo.toml`
  `reqwest` 需保留 `default-features = false` 这个 Web/headless 最小分叉。
- `.github/workflows/build-web-release.yml`
  这是当前正式 Web 发版入口，不能被上游桌面发布逻辑覆盖。
- `build-web-release.sh`
- `scripts/build-web-deb-package.sh`
- `packaging/deb/`
  这几处是 Debian 安装包链路核心文件，merge 时必须保留。

## 执行计划

### 阶段 1：准备

- [x] 抓取上游最新 `main`
- [x] 创建独立同步分支
- [x] 记录 merge 前差异面

### 阶段 2：执行合并

- [x] 合并 `upstream/main`
- [x] 解决冲突
- [x] 保留 Web fork 关键差异

### 阶段 3：验证

- [x] 运行 headless/TLS 最小验证
- [x] 运行 Web Debian 打包验证
- [x] 视情况补跑前端类型与单测

### 阶段 4：回写文档

- [x] 更新本任务文档
- [x] 记录本轮新增冲突热点与后续注意事项

## 本轮实际结果

- 已在分支 `codex/merge-upstream-20260419` 上成功合并 `upstream/main`，merge commit 为 `a144d531`。
- 本轮上游新增内容仅落在 4 个文件：
  - `src-tauri/src/database/dao/failover.rs`
  - `src-tauri/src/services/skill.rs`
  - `src/components/proxy/FailoverQueueManager.tsx`
  - `src/types/proxy.ts`
- Web fork 关键差异仍保留：
  - `src-tauri/src/lib.rs` 中的 rustls `CryptoProvider` 初始化
  - `src-tauri/Cargo.toml` 中 `reqwest = { default-features = false, ... }`
  - `.github/workflows/build-web-release.yml`
  - `build-web-release.sh`
  - `scripts/build-web-deb-package.sh`
  - `packaging/deb/`
  - `crates/core/`、`crates/server/`

## 本轮新增发布层调整

- Debian 安装包继续保持 `systemd` system service 形态，但已改为默认以 `root` 运行。
- 已删除打包层对 `cc-switch-web` 专用服务用户的创建与依赖：
  - `packaging/deb/usr/lib/systemd/system/cc-switch-web.service`
  - `packaging/deb/DEBIAN/postinst`
  - `packaging/deb/DEBIAN/control`
- 保留 `HOME=/var/lib/cc-switch-web`、`XDG_CONFIG_HOME=/var/lib/cc-switch-web/.config`、`XDG_DATA_HOME=/var/lib/cc-switch-web/.local/share`，确保应用自身状态仍集中在系统目录。
- 真实用户目录（例如 `/home/<user>/.claude`）不做自动探测，仍需通过应用已有目录覆盖配置显式指定。

## 本地验证结果

- 已通过：
  - `corepack pnpm typecheck`
  - `corepack pnpm test:unit`
  - `bash -n scripts/build-web-deb-package.sh tests/test-web-deb-package.sh tests/test-web-deb-root-service.sh`
  - `sh -n packaging/deb/DEBIAN/postinst packaging/deb/DEBIAN/prerm packaging/deb/DEBIAN/postrm`
  - `bash tests/test-web-deb-root-service.sh`
- 已确认基线问题仍存在：
  - `cargo test --manifest-path crates/server/Cargo.toml --test rustls_provider_init`
  - `bash tests/test-web-deb-package.sh`
  - `build-web-release.sh`
- 上述 Rust 相关命令仍然会在 `rustc 1.95.0` 下触发编译器 ICE，栈继续落在 `src-tauri/src/proxy/forwarder.rs`，并且 `main@8220ab4c` 与当前 merge 分支都会复现，因此不是本轮 merge 或本轮 Debian 权限调整引入的新逻辑错误。

## 后续注意事项

- 在当前 WSL Rust 工具链仍会 ICE 的前提下，发布层改动只能通过轻量 Debian 打包测试与 CI 继续验证，不能把本地 `build-web-release.sh` 失败误判为这轮打包调整回归。
- 后续若继续从上游合并，只要未触碰 `packaging/deb/`、`build-web-release.sh`、`.github/workflows/build-web-release.yml` 这些 Web 发布层文件，本轮 root service 策略应能稳定保留。
