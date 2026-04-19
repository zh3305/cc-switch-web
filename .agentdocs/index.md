## 前端文档
`frontend/web-fork-architecture.md` - Web fork 与上游 cc-switch 的分层边界、同步策略与平台适配约束；修改 Web 适配实现或规划同步方案时必读

## 当前任务文档
`workflow/260417-merge-upstream-cc-switch.md` - 同步合并上游 cc-switch main 到当前 Web fork，记录本次真实 merge、CI 修复结果与环境边界
`workflow/260418-release-pipeline-unification.md` - 统一 Web fork 的 GitHub 发版链路，修复 tag 指向旧提交、CI 校验失败与自动产包触发问题
`workflow/260418-upstream-sync-strategy.md` - 面向长期频繁合并的 Web fork 同步策略、分阶段抽离路线与标准同步流程
`workflow/260418-upstream-sync-execution-plan.md` - 长期频繁合并的实际执行计划与标准同步清单；准备再次 merge upstream 前优先阅读
`workflow/260419-merge-upstream-refresh.md` - 再次同步上游 cc-switch，记录本轮目标引用、风险边界与冲突处理结果

## 全局重要记忆
- 当前仓库是 `farion1231/cc-switch` 的 Web fork，正式发布以 Web 运行时为主，但仍保留 `src-tauri` 作为共享逻辑来源与上游同步抓手。
- 平台差异优先收敛到 Web 适配层与发布层，避免在高频上游文件中散落大量 fork 定制。
- Web/headless 运行时必须在进程启动早期显式初始化 rustls `CryptoProvider`；上游依赖树可能同时启用 `ring` 与 `aws-lc-rs`，若丢失该初始化会在首次 HTTPS/TLS 请求时 panic。
- `src-tauri/Cargo.toml` 中 `reqwest` 需保留 `default-features = false` 这个最小分叉，避免 Web/headless 构建重新引入 `native-tls/openssl` 和 `pkg-config` 系统依赖；其余特性尽量跟上游保持一致。
