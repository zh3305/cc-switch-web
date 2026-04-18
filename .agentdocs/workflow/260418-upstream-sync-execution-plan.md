# 长期频繁合并执行计划

## 目标

在不进行一次性完整重构的前提下，逐步降低当前 Web fork 与上游 `cc-switch` 的耦合成本，让未来的上游同步主要集中在少量适配层和发布层文件。

## 约束

- 当前仓库已经有一次大规模 upstream merge 正在整理中，短期内不应再叠加大重构。
- 当前环境已补齐 `rustup` / `cargo` / `rustfmt` / `clippy` 与前端检查能力，但当前 WSL 账号仍缺少 `sudo` 权限，无法安装完整桌面构建所需系统库。
- 因此，本计划可以落地前端检查、Rust 格式检查与部分 headless 验证，但完整桌面相关后端校验仍需依赖具备系统依赖的 CI 或 Linux 环境。
- 任何改动都必须优先降低未来 merge 冲突面，而不是追求抽象上“最优”的结构。

## 阶段概览

### 阶段 1：稳定当前合并结果

目标：先把当前同步分支整理为“可验证、可提交、可继续跟进”的状态。

#### 重点文件

- `src-tauri/src/proxy/forwarder.rs`
- `src-tauri/src/services/proxy.rs`
- `src-tauri/src/proxy/failover_switch.rs`
- `src-tauri/src/commands/mod.rs`
- `src-tauri/src/lib.rs`
- `src/lib/api/auth.ts`
- `vite.config.ts`

#### 需要完成的动作

- 补跑 TypeScript 编译检查
- 补跑前端单元测试
- 补跑 `crates/server` 的 Tauri/RPC 一致性测试
- 确认 `headless` 模式下不会被桌面特有状态、命令或 OAuth 逻辑误伤

#### 完成标准

- 当前 merge 分支可以通过最小验证基线
- 没有残留“只为过合并而加上的临时兼容逻辑”

---

### 阶段 2：继续收敛 Web 平台差异

目标：让未来上游前端改动尽量只影响共享 UI，而不反复冲击 Web 平台判断。

#### 应保留为适配层的文件

- `src/lib/transport/index.ts`
- `src/lib/transport/transport.impl.tauri.ts`
- `src/lib/transport/transport.impl.web.ts`
- `src/lib/platform-paths.ts`
- `src/lib/platform-paths.tauri.ts`
- `src/lib/platform-paths.web.ts`
- `src/lib/updater.ts`
- `src/lib/updater.tauri.ts`
- `src/lib/updater.web.ts`
- `src/platform/bootstrap.tauri.ts`
- `src/platform/bootstrap.web.ts`

#### 建议动作

- 检查新增前端代码是否仍然绕开适配层直接依赖 Tauri API
- 将平台差异继续从业务组件与 hooks 中移出，统一回收至上述文件
- 为这些适配点补充最小测试或至少补充稳定文档说明

#### 完成标准

- 业务组件不直接知道运行在 Web 还是桌面
- 平台差异只在适配层发生，不向上层界面蔓延

---

### 阶段 3：把 `crates/core` 从薄封装变成稳定核心层

目标：降低 `crates/core -> src-tauri` 的穿透依赖深度，但不做一次性“彻底拆库”。

#### 当前关键依赖点

- `crates/core/Cargo.toml`
- `crates/core/src/lib.rs`
- `src-tauri/Cargo.toml`

#### 建议优先抽离的子模块

1. 配置读写的纯逻辑
2. 数据库与 DAO 的纯逻辑
3. Provider 领域服务
4. Import / Export 纯逻辑

#### 建议落位

- 优先继续沉到 `crates/core` 或新的小型内部 crate
- 不要一开始就试图把整个 `src-tauri` 的纯逻辑一次性搬空

#### 实施原则

- 一次只处理一个子模块
- 先让 `src-tauri` 自己改用新抽出的实现
- 再让 `crates/core` 改用同一实现
- 每完成一个子模块，都重新评估 merge 冲突是否真的减少

#### 完成标准

- `crates/core/src/lib.rs` 不再以“大量 re-export + 薄包装”为主
- `src-tauri` 中剩余内容更多是桌面壳层、命令注册、UI 运行时能力

---

### 阶段 4：建立同步操作规范

目标：让以后每次 merge upstream 都可重复、可回顾、可验收。

#### 固定流程

1. 从最新主线创建同步分支
2. `git fetch upstream main --tags`
3. `git merge --no-ff upstream/main`
4. 先解决文档/发布冲突，再解决适配层，再解决共享逻辑
5. 跑固定验证集
6. 记录本次冲突点和后续应继续收敛的区域

#### 每次同步后必须回顾

- 本次冲突最多的文件有哪些
- 哪些冲突是由 Web fork 差异散落造成的
- 哪些冲突值得通过下一阶段抽离解决

## 最近两轮建议执行顺序

### 第 1 轮

- 完成当前 merge 分支验证
- 修正 `headless` / `desktop` 双模式相关风险
- 形成一次可提交的上游同步提交

### 第 2 轮

- 审查并继续收敛前端平台适配边界
- 清点 `crates/core` 中最值得优先下沉的纯逻辑入口
- 只启动第一个“小模块抽离”任务

## 标准同步清单

每次从上游 `cc-switch` 合并时，按以下顺序执行：

1. `git switch main && git pull --ff-only`
2. `git switch -c codex/merge-upstream-YYYYMMDD`
3. `git fetch upstream main --tags`
4. `git merge --no-ff upstream/main`
5. 优先解决发布层、Web 适配层、`headless/desktop` 双模式相关冲突
6. 运行前端验证：
   `corepack pnpm typecheck`
   `corepack pnpm test:unit`
7. 运行 Rust 可执行验证：
   `cargo fmt --check --manifest-path src-tauri/Cargo.toml`
   如环境允许，再运行 `cargo clippy --manifest-path src-tauri/Cargo.toml -- -D warnings`
8. 若本地缺系统库或桌面依赖，必须等待 GitHub `CI` 通过后再继续发布动作
9. 更新 `.agentdocs` 中的任务文档，记录本次冲突热点与新增环境约束

## 暂时不要做的事

- 不要把 Web server 改成通过子进程调用桌面应用
- 不要立即创建完整独立的“大核心库”并大规模迁移全仓
- 不要在当前未完整验证的 merge 分支上继续叠加大量业务功能

## 交付判断

当满足以下条件时，可以认为“长期频繁合并”策略已经进入可持续状态：

- 每次同步的主要冲突集中在少量适配层和发布层
- `crates/core` 逐步接住稳定纯逻辑，而不是继续完全依赖 `src-tauri`
- Web fork 差异没有继续向上游高频热点文件扩散
