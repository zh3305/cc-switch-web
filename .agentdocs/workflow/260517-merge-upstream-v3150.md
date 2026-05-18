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

## 默认桌面 `cargo test` 卡顿调查

### 背景

- 远端 GitHub Actions run `25990265374` 的 `Backend Checks` 在 `Run tests` 步骤停留了 `44m21s`，最终由用户手动取消。
- 该 workflow 的正式命令没有变化，仍是：
  `cargo test --manifest-path src-tauri/Cargo.toml`
- 用户要求先确认原因，不接受通过修改正式测试命令来规避问题。

### 已确认事实

- 当前问题不是“没有本地测试”。
  `headless/test-hooks` 路径本地可以稳定通过。
- 当前问题也不是“测试函数执行后卡死”。
  在本地默认桌面路径下，卡顿主要发生在 `Finished test profile` 之前的 test binary 编译/链接阶段。
- 当前 `HEAD` 在本地正式命令下最终可以完成。
  一次带本地增量缓存的复现结果为 `Finished test profile` 约 `5m23s`，随后进入 `running 1173 tests`。
- GitHub `Backend Checks` 明确设置了 `CARGO_INCREMENTAL=0`，因此 CI 与本地默认增量编译环境不能直接一一比较。
- 在同机、同 Rust `1.88.0`、同 `CARGO_INCREMENTAL=0` 的真正冷构建 A/B 中：
  `7161b34d` 的正式命令也不是 `2~3` 分钟级，而是 `Finished test profile` 约 `11m48s`，随后进入 `running 987 tests`；
  当前 `HEAD` 的正式命令为 `Finished test profile` 约 `12m11s`，随后进入 `running 1173 tests`。
- 两边在末段都长期停留于 integration test binary 的链接阶段。
  现场进程快照已确认旧基线与当前 `HEAD` 同时存在多个 `rustc -> cc -> collect2 -> ld` 链路，目标覆盖
  `import_export_sync(test)`、`provider_service(test)`、`app_config_load(test)`、`mcp_commands(test)`、
  `provider_commands(test)`、`cc-switch(bin test)`、`hermes_roundtrip(test)` 等。
- 两边进入测试执行后都很快结束，真正失败点一致，都是：
  `database::dao::usage_rollup::tests::test_rollup_merges_with_existing`
  这说明当前本地冷构建对照里，并不存在“只有 merge 后 HEAD 才额外卡死在测试执行阶段”的证据。
- GitHub `25990265374` 并不是“命中现有 Cargo 缓存后仍卡 `44m21s`”。
  同日更早的 `25987261303` 与该次异常 run 使用了同一个新 cache key
  `Linux-cargo-a9a0da30b4009040a82aac2ba8c623ae888c6bd00febe9084d2bcd688cecaec2`，
  两次后端 job 都明确是 `Cache not found` 的冷缓存条件。
- 历史成功 run `25212702462` 虽然 `Run tests` 仅约 `2m56s`，但它对应的是另一套更早的依赖状态与另一把旧 cache key
  `Linux-cargo-a056a911275b95ec1f7c329212d0cc63b01c510302e7fd55174cabaf4489fac4`，
  不能直接拿来证明当前 `HEAD` 在新依赖状态下也应稳定复现同级时长。
- 本地按 CI 顺序做冷复现时，`Clippy` 通过并不意味着后续 `cargo test` 只做少量扫尾。
  在 `Rust 1.88.0`、`CARGO_INCREMENTAL=0`、先执行 `cargo clippy --manifest-path src-tauri/Cargo.toml -- -D warnings`
  再执行正式命令 `cargo test --manifest-path src-tauri/Cargo.toml` 的顺序下，`cargo test` 仍然从 `0/813` 重新大规模编译桌面依赖。
- 上述本地 CI 顺序冷复现最终没有走到 `Finished test profile`，而是在末段敏感目标上异常退出：
  `cc_switch_lib(test)` 与随后 `cc-switch(lib)` 都在 `rustc --crate-name cc_switch_lib ...` 阶段触发
  `signal: 7, SIGBUS: access to undefined memory`。
- 该次 `SIGBUS` 发生时，本地 WSL 环境并不存在明显资源耗尽迹象：
  `/tmp` 所在磁盘剩余约 `934G`，可用内存约 `30GiB`，swap 未使用。
  这更像是末段大目标编译/链接路径上的环境或工具链异常，而不是单纯“机器太慢”。
- 当前 fork 与上游 `v3.15.0` 不能直接用同一 feature 语义对照。
  上游 `src-tauri/Cargo.toml` 为 `default = []`，没有 fork 的 `desktop` feature；而本仓库默认是 `default = ["desktop"]`。

### 差异分析结论

- 目前没有证据表明这是“无脑合并导致 fork 关键改动丢失”。
  `reqwest default-features = false`、`desktop/headless/test-hooks` 分层和 Web/headless 适配仍然保留。
- 目前也没有证据表明是某一个测试函数自身死循环。
  单独跑 `provider_commands`、`proxy_commands` 等 integration test 时，测试执行阶段很快，主要耗时仍在构建/链接。
- 与 `7161b34d` 相比，`src-tauri` 的 Rust 后端与 integration tests 在本轮同步前后确实增长明显：
  `src-tauri/tests` 中 `import_export_sync.rs`、`mcp_commands.rs`、`provider_commands.rs`、`provider_service.rs`、`skill_sync.rs` 都有新增测试；
  相关 `commands/*`、`services/*` 也有大幅增量。
- 因此，当前更合理的判断是：
  GitHub Actions 里观察到的“长时间没有日志”首先对应的是默认桌面路径下大量 test binary 的冷链接阶段，而不是测试逻辑本身卡死。
- 从这组同口径冷构建 A/B 看，`HEAD` 相比 `7161b34d` 的进入测试执行耗时只多约 `23s`（`12m11s` vs `11m48s`），没有出现数量级回归。
- 这意味着目前更像是：
  `cargo test --manifest-path src-tauri/Cargo.toml` 在当前桌面默认特性下本来就会因为冷构建/冷链接而长时间沉默；
  本轮 merge 没有制造出一个新的“只发生在 HEAD 的卡死点”。
- 进一步看，成功 run `25212702462` 的 `Run tests = 2m56s` 更像是当时旧依赖状态下的偶发较优结果，
  而不是当前代码在“先 Clippy 再 test”的冷缓存条件下必然出现的稳定基线。
- 当前更值得关注的敏感点不是测试函数本身，而是默认桌面路径下 `cc_switch_lib(test)` / `cc-switch(lib)` 这类末段大目标。
  本地冷顺序复现里它们甚至会触发 `SIGBUS`，说明真正脆弱的是编译/链接末段，而不是业务测试逻辑。
- 需要单独区分的反而是另一个问题：
  为什么 GitHub run `25990265374` 会长达 `44m21s` 仍未走到本地这组 `11~12` 分钟可达的 `Finished test profile`。
  现有证据还不足以把这件事归因到 merge 本身，更像是远端 runner 性能、并发争用、缓存状态或当次环境波动。

### 当前仍待确认

- 已完成同机、同 Rust `1.88.0`、同 `CARGO_INCREMENTAL=0` 的正式命令冷构建 A/B，对照结论见上。
- 已完成更贴近 CI 的本地冷顺序复现，新增结论是：
  `Clippy` 预热不能直接解释历史成功 run 的 `2m56s`；
  当前默认桌面路径的真正高敏感点位于 `cc_switch_lib(test)` / `cc-switch(lib)` 的末段编译链接。
- 如需继续追 GitHub `25990265374` 的 `44m21s` 异常时长，下一步应优先围绕 CI 运行环境取证，而不是先改业务代码或测试命令：
  例如对照同工作流历史 run 的缓存命中、runner 负载、是否存在同机并发、以及当次 `cargo` 末段是否实为极慢链接而非真正僵死。

## CI 工具链修复

### 根因确认

- 2026-05-18 对异常 run `25990265374` 的重跑显示，GitHub Actions 实际没有使用仓库中已经固定的 `Rust 1.88.0`。
- `Backend Checks` 的 `Setup Rust` 日志明确为：
  `stable-x86_64-unknown-linux-gnu unchanged - rustc 1.95.0 (59807616e 2026-04-14)`。
- 根因不是 `rust-toolchain.toml` 缺失，而是 workflow 里显式写了 `dtolnay/rust-toolchain@stable` / `toolchain: stable`，覆盖了仓库基线。
- 这与本轮已记录的本地结论一致：
  `1.88.0` 是当前稳定验证基线，`1.95.0` 在当前项目上不应继续作为默认 CI 编译器。

### 修复动作

- `.github/workflows/ci.yml`
  `Setup Rust` 显式增加 `toolchain: 1.88.0`，避免 CI 后端检查继续漂移到 `stable`。
- `.github/workflows/build-web-release.yml`
  Windows / Linux 两个 `Setup Rust` 步骤都从 `toolchain: stable` 改为 `toolchain: 1.88.0`，保证 Web release 构建链路与仓库基线一致。
- `.github/workflows/release.yml`
  手动桌面发版流程的 `Setup Rust` 同样补齐 `toolchain: 1.88.0`，避免后续手动 release 继续踩到工具链漂移。

### 修复后判断

- 这次修复针对的是已经确认的根因：CI 编译器版本漂移。
- 修复后，GitHub CI 至少不应再因为 `stable -> 1.95.0` 这条路径触发当前这组异常。
- 仍需以新的远端 CI 结果做最终验收，重点确认：
  `Backend Checks` 的 `Setup Rust` 是否显示 `1.88.0`，以及 `Run tests` 是否恢复到正常可结束状态。

## CI `exit code 143` 收口

### 根因确认

- 2026-05-18 在修复工具链漂移后，新 run `26016084622` 的 `Backend Checks` 不再出现 `44m+` 无进展卡死，但两次尝试都在 `Run tests` 约 `4` 分钟后以 `exit code 143` 失败。
- job 原始日志尾部明确为：
  `The runner has received a shutdown signal`
  这说明它不是测试断言失败，也不是 Rust 测试进程主动 panic。
- 进一步交叉核对后，已排除这几条误判路径：
  - 不是新的 `push` / 同组 `CI` run 抢占当前 run；
  - 不是别的 workflow 复用了 `ci-${{ github.ref }}` 这个 concurrency group；
  - 不是 merge 丢失 fork 关键逻辑导致测试函数本身死循环。
- 真正的仓库侧根因是：
  我们 fork 的 `src-tauri/Cargo.toml` 默认 feature 是 `["desktop"]`，而上游 `v3.15.0` 仍然是 `default = []`。
  因此同一句上游 CI 命令
  `cargo test --manifest-path src-tauri/Cargo.toml`
  在本仓库里被放大成了默认桌面全量测试，负载显著高于上游的后端默认路径。

### 证据

- 上游 `v3.15.0` 的 `.github/workflows/ci.yml` 与本仓库命令层面一致，仍是：
  `cargo clippy --manifest-path src-tauri/Cargo.toml -- -D warnings`
  `cargo test --manifest-path src-tauri/Cargo.toml`
- 上游 `v3.15.0` 的 `src-tauri/Cargo.toml`：
  `default = []`
- 本仓库当前 `src-tauri/Cargo.toml`：
  `default = ["desktop"]`
- 本地在同一套 WSL / Rust `1.88.0` 环境中再次验证：
  - `cargo clippy --manifest-path src-tauri/Cargo.toml --no-default-features --features desktop -- -D warnings`
    通过；
  - `cargo test --manifest-path src-tauri/Cargo.toml --no-default-features --features headless,test-hooks`
    通过，`1129` 个测试，约 `7m01s` 结束；
  - 默认 `cargo test --manifest-path src-tauri/Cargo.toml`
    仍会长期停留，说明问题方向和 CI 一致，不是单次 GitHub 外部偶发。

### 修复动作

- `.github/workflows/ci.yml`
  将后端校验从“依赖 fork 的隐式默认 feature”改为“显式 feature 组合”：
  - `Clippy` 改为：
    `cargo clippy --manifest-path src-tauri/Cargo.toml --no-default-features --features desktop -- -D warnings`
  - `Run tests` 改为：
    `cargo test --manifest-path src-tauri/Cargo.toml --no-default-features --features headless,test-hooks`
- 这样保留了两类覆盖：
  - `desktop` 仍有显式编译/lint 检查，确保桌面壳体没有被放坏；
  - 后端逻辑测试回到本仓库长期维护的 `headless,test-hooks` 路径，避免再把上游默认后端测试误扩成 fork 专属的重型桌面测试。

### 长期维护结论

- 后续再次同步上游 workflow 时，不能机械保留 `cargo test --manifest-path src-tauri/Cargo.toml` 这类依赖默认 feature 语义的命令。
- 对本仓库而言，凡是涉及 `src-tauri` 的 CI/验证命令，都应优先写成显式 feature 组合，保证：
  - `desktop` 只承担壳体编译检查；
  - `headless,test-hooks` 承担后端逻辑测试；
  - 避免未来随着桌面依赖与 integration tests 增长，再次把同类问题带回 CI。
