# Web Fork 长期同步策略

## 结论

当前仓库的首要目标是“能够持续、低成本地频繁合并上游 `farion1231/cc-switch`”，因此应采用以下策略：

- 保留当前基于 `src-tauri` 的同步抓手，不做一次性大重构。
- 将 Web fork 差异持续收敛到适配层与发布层。
- 仅按模块渐进式抽离纯业务逻辑，避免长时间偏离上游。

## 为什么不做一次性大重构

### 不适合当前阶段的原因

- 上游活跃，功能和结构变化频繁，完整重构会让分叉面在短期内迅速扩大。
- 当前仓库刚完成一次真实的上游合并，说明首要任务是先把同步节奏稳定下来，而不是立即引入更大的结构性变化。
- 一次性拆出完整独立核心 crate 虽然理论上更“干净”，但会在短期内制造大量与业务无关的差异，反而提高后续 merge 冲突成本。

### 当前真实问题

当前问题不是“`headless` 仍然触发 `tauri-build` 导致无法构建”，因为 `src-tauri/build.rs` 已经按 `desktop` feature 做了条件短路。

当前真正的问题是：

- `crates/core` 仍然直接依赖 `src-tauri`
- `crates/core` 目前主要是对 `src-tauri` 的轻量封装，而不是稳定的独立核心层
- Web 运行时虽然能构建，但仍然会受到 `src-tauri` 内部结构变化影响

## 长期策略

### 总体原则

- 上游共享逻辑优先保留在与上游一致的位置，避免无必要搬迁。
- Web 专有逻辑优先收敛在 `crates/server`、`crates/core`、前端平台适配层。
- 每次架构调整都必须以“降低未来 merge 成本”为第一目标，而不是以“理论最优分层”为第一目标。

### 目录边界

#### 应尽量少改的上游高频区域

- `src/` 中大部分业务 UI、provider 配置表单、列表与通用 hook
- `src-tauri/src/commands/` 中桌面命令注册与大量上游业务命令
- `src-tauri/src/services/` 中仍与上游快速演进绑定的部分

#### Web fork 差异收敛区

- `crates/server/`
- `crates/core/`
- `src/lib/transport/`
- `src/lib/platform-paths.*`
- `src/lib/updater.*`
- `src/platform/bootstrap.*`
- Web 运行脚本、Web 发布脚本、Web README 与 workflow

## 分阶段实施路线

### 阶段 0：稳定同步流程

目标：先让“合并上游”成为可重复动作。

- 固定使用独立同步分支，例如 `codex/merge-upstream-YYYYMMDD`
- 每次同步后优先处理：
  - 发布与文档冲突
  - Web 适配层冲突
  - `headless` / `desktop` 双模式冲突
- 每次同步都补跑最小验证集

### 阶段 1：加固适配边界

目标：减少 Web 差异渗透到上游热点文件。

- 前端平台差异继续集中在 `transport`、`platform-paths`、`updater`、`bootstrap`
- 服务端差异继续集中在 `crates/server`
- 对必须跨平台共享的逻辑，优先增加接口或中间层，而不是直接在业务文件里加更多分支判断

### 阶段 2：渐进式下沉稳定核心

目标：让 `crates/core` 逐步从“转发封装层”变成“稳定核心层”。

建议优先顺序：

1. 配置读写与路径无关的纯逻辑
2. 数据库访问与数据模型
3. Provider 领域服务
4. Import / Export 纯逻辑
5. 不依赖 Tauri 运行时的通用服务

要求：

- 每次只下沉一个子模块
- 下沉后先让 `src-tauri` 改为依赖新位置，再让 `crates/core` 使用同一实现
- 不为“抽层”而抽层，必须以减少重复依赖和冲突面为前提

### 阶段 3：评估是否需要独立核心 crate

只有在满足以下条件时，才考虑从 `src-tauri` 进一步演化出真正独立的核心 crate：

- `crates/core` 已经承接了大部分稳定纯逻辑
- `src-tauri` 中剩余内容主要是 Tauri 壳层、桌面 UI 能力与命令注册
- 多次上游合并已经证明当前仍存在明显的结构性冲突瓶颈

在此之前，不建议直接发起“完整拆分 `cc-switch-lib`”工程。

## 每次同步的标准流程

### Git 流程

1. 确保 `main` 已推送并记录当前状态
2. 创建同步分支：`git switch -c codex/merge-upstream-YYYYMMDD`
3. 获取上游：`git fetch upstream main --tags`
4. 合并：`git merge --no-ff upstream/main`
5. 按冲突分类处理
6. 跑本地验证
7. 形成合并提交

### 冲突处理顺序

1. 文档与发布脚本
2. 前端平台适配
3. `src-tauri` 的 `desktop/headless` 分歧
4. 核心业务逻辑

### 验证基线

- `pnpm typecheck`
- `pnpm test:unit`
- `cargo test -p cc-switch-server tauri_rpc_consistency --manifest-path crates/server/Cargo.toml`

如环境允许，建议继续补：

- `cargo test --manifest-path src-tauri/Cargo.toml --no-default-features --features headless`
- `cargo fmt --check --manifest-path src-tauri/Cargo.toml`
- `cargo clippy --manifest-path src-tauri/Cargo.toml -- -D warnings`

### 本地环境约束

- 当前仓库已验证：仅安装 Rust 工具链还不够，`src-tauri` 的完整后端检查还依赖 `pkg-config`、`libssl-dev`、`libgtk-3-dev`、`librsvg2-dev`、`libayatana-appindicator3-dev`、`libwebkit2gtk`、`libsoup` 等系统库。
- 若在 WSL 中执行本地验证，建议先确认当前账号具备 `sudo` 权限；否则只能完成前端检查、Rust 格式检查和部分无系统库依赖的步骤。
- 若本地访问 `crates.io` 不稳定，优先为 `cargo` 配置 sparse 镜像，避免把网络抖动误判为代码问题。

## 不推荐的方案

### 方案：Web server 通过子进程调用桌面应用

不推荐，原因：

- 运行时耦合替代了编译期耦合，没有真正降低复杂度
- 会提高进程管理、协议兼容、部署与故障定位成本
- 不符合当前仓库“Web-only 正式发布”的目标

## 决策记录

当前正式采纳的策略是：

- 频繁 merge 上游
- 保持 fork 差异轻量
- 采用渐进式抽离，而不是一次性完整重构

后续如果出现新的结构性瓶颈，再重新评估是否升级为独立核心 crate 方案。
