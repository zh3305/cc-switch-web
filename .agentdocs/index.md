## 前端文档
`frontend/web-fork-architecture.md` - Web fork 与上游 cc-switch 的分层边界、同步策略与平台适配约束；修改 Web 适配实现、更新链路或规划同步方案时必读

## 当前任务文档
`workflow/260418-upstream-sync-strategy.md` - 面向长期频繁合并的 Web fork 同步策略、分阶段抽离路线与标准同步流程
`workflow/260418-upstream-sync-execution-plan.md` - 长期频繁合并的实际执行计划与标准同步清单；准备再次 merge upstream 前优先阅读
`workflow/260501-merge-upstream-v3141.md` - 合并上游 v3.14.1 tag，记录冲突解决与验证结果
`workflow/260517-merge-upstream-v3150.md` - 合并上游 v3.15.0 tag，记录同步策略判断、冲突解决与编译验证结果
`workflow/260602-merge-upstream-v3161.md` - 合并上游 v3.16.1 tag，记录 take theirs (forwarder.rs) 策略、冲突解决、CI 验证待跟进

## 已完成任务文档
`workflow/done/260417-merge-upstream-cc-switch.md` - 首次同步合并上游 cc-switch
`workflow/done/260418-release-pipeline-unification.md` - 统一 Web fork 的 GitHub 发版链路
`workflow/done/260419-merge-upstream-refresh.md` - 再次同步上游 cc-switch（v3.13.x 时期）

## 全局重要记忆
- 当前仓库是 `farion1231/cc-switch` 的 Web fork，正式发布以 Web 运行时为主，但仍保留 `src-tauri` 作为共享逻辑来源与上游同步抓手。
- 平台差异优先收敛到 Web 适配层与发布层，避免在高频上游文件中散落大量 fork 定制。
- Web/headless 运行时必须在进程启动早期显式初始化 rustls `CryptoProvider`；上游依赖树可能同时启用 `ring` 与 `aws-lc-rs`，若丢失该初始化会在首次 HTTPS/TLS 请求时 panic。
- `src-tauri/Cargo.toml` 中 `reqwest` 需保留 `default-features = false` 这个最小分叉，避免 Web/headless 构建重新引入 `native-tls/openssl` 和 `pkg-config` 系统依赖；其余特性尽量跟上游保持一致。
- 本仓库 `src-tauri/Cargo.toml` 的默认 feature 是 `["desktop"]`，而上游 `v3.16.1` 仍是 `default = []`；后续维护 CI / 本地验证命令时不能再依赖隐式默认 feature，需显式区分 `desktop` 编译检查与 `headless,test-hooks` 后端测试，避免把上游同一句 `cargo test` 放大成 fork 专属的重型桌面测试。
- 自 2026-05-17 的 `v3.15.0` 同步起，本仓库本地 Rust 验证基线调整为 `1.88.0`：`1.85.0` 已不满足 `image 0.25.10` 与 `time 0.3.47` 的 MSRV，`1.95.0` 会在 `src-tauri/src/proxy/forwarder.rs` 触发 rustc ICE；后续再次同步上游前，优先复用 `1.88.0` 直到重新验证编译器状态。
- 自 2026-06-02 的 `v3.16.1` 同步起，`src-tauri/src/proxy/forwarder.rs` 已跟随上游结构性重写：本仓库的 `UiAppHandle` 抽象在 `src-tauri/src/ui_runtime.rs` 中继续作为 type alias（desktop: `tauri::AppHandle`，headless: 空结构体）保留，但 `forwarder.rs` 内部直接用 `tauri::AppHandle`；后续如需再加 Web fork 抽象，应优先在适配层而非核心 proxy 路径。
- 自 2026-06-02 的 `v3.16.1` 同步起，上游已删除 `src/lib/updater.web.ts`、`platform-paths.web.ts`、`bootstrap.web.ts`、`start-web.sh` 等 Web 适配入口；本仓库"Web 正式发布"目标依赖这些入口，需要在下一轮专项重建。
- 若需在 WSL/Linux 本地复现 GitHub CI 的默认桌面 `cargo clippy -- -D warnings`，除 Rust 1.88.0 外还需预装 `pkg-config`、`libglib2.0-dev`、`libgtk-3-dev`、`libgdk-pixbuf-2.0-dev`、`libsoup-3.0-dev`、`libjavascriptcoregtk-4.1-dev`、`libwebkit2gtk-4.1-dev`；否则会在 `glib/gdk/libsoup/webkit2gtk` 的 `-sys` crate 阶段提前失败。
