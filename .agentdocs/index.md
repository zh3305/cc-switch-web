## 前端文档
`frontend/web-fork-architecture.md` - Web fork 与上游 cc-switch 的分层边界、同步策略与平台适配约束；修改 Web 适配实现或规划同步方案时必读

## 当前任务文档
`workflow/260417-merge-upstream-cc-switch.md` - 同步合并上游 cc-switch main 到当前 Web fork，记录本次真实 merge、CI 修复结果与环境边界
`workflow/260418-release-pipeline-unification.md` - 统一 Web fork 的 GitHub 发版链路，修复 tag 指向旧提交、CI 校验失败与自动产包触发问题
`workflow/260418-upstream-sync-strategy.md` - 面向长期频繁合并的 Web fork 同步策略、分阶段抽离路线与标准同步流程
`workflow/260418-upstream-sync-execution-plan.md` - 长期频繁合并的实际执行计划与标准同步清单；准备再次 merge upstream 前优先阅读

## 全局重要记忆
- 当前仓库是 `farion1231/cc-switch` 的 Web fork，正式发布以 Web 运行时为主，但仍保留 `src-tauri` 作为共享逻辑来源与上游同步抓手。
- 平台差异优先收敛到 Web 适配层与发布层，避免在高频上游文件中散落大量 fork 定制。
