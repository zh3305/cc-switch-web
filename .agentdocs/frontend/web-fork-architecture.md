## 项目定位

当前仓库基于上游 `farion1231/cc-switch` 演化，目标是保留与上游业务能力的同步，同时提供正式发布的 Web-only 运行形态。

## 分层约束

### 上游共享层

- `src/` 中与业务展示、配置模型、表单、状态管理直接相关的通用逻辑优先保持与上游一致。
- `src-tauri/` 虽然不作为正式发布目标，但仍是共享命令面和核心业务能力的重要来源，不应轻易删除。

### Web 适配层

- `crates/server/` 负责 Web 端单独的服务端入口、认证、上传下载与 RPC/WS 暴露。
- `src/lib/transport/*.web.ts`、`src/lib/platform-paths.web.ts`、`src/lib/updater.web.ts`、`src/platform/bootstrap.web.ts` 用于收敛 Web 平台差异。
- 新增 Web-only 行为时，应优先放在适配层，而不是直接修改通用业务代码。

### 发布与运维层

- `build-web-release.sh`、`start-web.sh`、`stop-web.sh`、GitHub Actions 与 README 负责 Web fork 的发布、运行与说明。

## 同步原则

- 优先通过 Git 合并上游 `main`，避免人工拷贝代码。
- 每次同步应尽量把冲突限制在 Web 适配层、发布层以及少量平台判断代码。
- 如果某项能力必须同时修改上游共享层与 Web 适配层，应优先抽象接口或共享实现，避免重复分叉。
- 保留并扩展自动校验，确保 Web 暴露的命令面与上游 Tauri 兼容命令面持续同步。
