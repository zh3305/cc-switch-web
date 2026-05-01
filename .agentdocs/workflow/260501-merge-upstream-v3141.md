# 合并上游 v3.14.1 tag

## 背景

用户要求将 Web fork 同步至上游 `farion1231/cc-switch` 的最新 tag `v3.14.1`。

## 执行结果

### 合并分支

`codex/merge-upstream-20260501`

### 冲突解决（共 12 个文件）

| 文件 | 处理方式 |
|------|----------|
| `README.md` / `README_JA.md` / `README_ZH.md` | 采用上游内容 |
| `package.json` | 版本号 → `3.14.1` |
| `src-tauri/Cargo.toml` | 版本号 → `3.14.1`，保留 `reqwest` 的 `default-features = false` |
| `src-tauri/Cargo.lock` | 采用上游 |
| `src-tauri/tauri.conf.json` | 版本号 → `3.14.1` |
| `src-tauri/src/lib.rs` | 同时保留 `hermes_config`（上游新增）和 `import_export_support`（Web fork 自有） |
| `src-tauri/src/commands/mod.rs` | 新增 `hermes` 模块声明与导出 |
| `src-tauri/src/proxy/handlers.rs` | 合并两侧测试：保留 Web fork 的 log_usage 测试 + 上游的 SSE/streaming 测试 |
| `src/hooks/useDirectorySettings.ts` | 删除上游重复的本地函数定义，保留 Web fork 从 `platform-paths` 导入的方式 |
| `src/hooks/useProxyStatus.ts` | 采用上游简化的 toast 调用方式（去掉 `fillMessageTemplate` 包装） |

### 额外修复

- `src/lib/api/auth.ts`：`CombinedAuthApi` 接口声明缺少 `githubDomain` 可选参数，与上游实际函数签名不一致。已修复。

### 验证结果

- ✅ `tsc --noEmit` 通过
- ✅ `vitest run` 通过（35 文件 / 217 用例）
- ⚠️ Rust 编译仍受本地环境 ICE 影响（已知问题，非本轮引入）

### Web fork 关键差异确认保留

- `src-tauri/src/lib.rs` 中的 rustls `CryptoProvider` 初始化
- `src-tauri/Cargo.toml` 中 `reqwest = { default-features = false, ... }`
- `.github/workflows/build-web-release.yml`
- `build-web-release.sh`
- `scripts/build-web-deb-package.sh`
- `packaging/deb/`
- `crates/core/`、`crates/server/`

## 上游 v3.14.1 新增亮点

- **Hermes 配置模块**：`hermes_config` + `commands/hermes` — 新增 Hermes 应用支持
- **SSE 聚合器**：`responses_sse_to_response_value` — Codex OAuth 场景下将 SSE 流聚合为完整 Responses JSON
- **流式路径判断**：`should_use_claude_transform_streaming` — 统一流式/非流式路径决策

## 后续操作

- 待用户确认后将 `codex/merge-upstream-20260501` 合并到 `main`
- Rust 后端校验依赖 GitHub Actions CI

## 状态：🔄 待合并到 main
