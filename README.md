<div align="center">

# CC Switch Fork

English | [中文](README_ZH.md) | [日本語](README_JA.md)

This repository is a fork of `cc-switch`. This README is intentionally trimmed to the parts that are still relevant for this fork: local development, build, and runtime workflow.

</div>

## Scope

This fork is used for local customization and ongoing development. The current codebase supports:

- Configuration management for Claude Code, Codex, Gemini, OpenCode, and OpenClaw
- MCP, prompts, skills, proxy, failover, and usage-related features
- Tauri desktop mode and a single-port web mode

## Screenshots

|                  Main Interface                   |                  Add Provider                  |
| :-----------------------------------------------: | :--------------------------------------------: |
| ![Main Interface](assets/screenshots/main-en.png) | ![Add Provider](assets/screenshots/add-en.png) |

## Local Development

### Requirements

- Node.js 18+
- pnpm 8+
- Rust 1.85+
- Tauri CLI 2.8+

### Common Commands

```bash
# Install dependencies
pnpm install

# Desktop development
pnpm dev

# Type checking
pnpm typecheck

# Frontend unit tests
pnpm test:unit

# Desktop build
pnpm build
```

### Rust Backend

```bash
cd src-tauri

cargo fmt
cargo clippy
cargo test
```

## Web Mode

### Single-Port Launch

```bash
./start-web.sh
```

Then open:

```text
http://localhost:17666
```

Stop the service:

```bash
./stop-web.sh
```

Runtime files are written to `./.run/web/` by default:

- log: `backend.log`
- pid: `backend.pid`

To override the runtime directory:

```bash
CC_SWITCH_RUNTIME_DIR=/tmp/cc-switch-web ./start-web.sh
```

### Manual Debugging

```bash
# Start the web backend
pnpm dev:server

# Start the frontend dev server with hot reload
pnpm dev:web
```

Notes:

- `17666`: backend, Web UI, `/api`, `/api/ws`
- `3000`: Vite dev server only for manual frontend debugging

### Manual Web Build

```bash
pnpm build:web
cargo build --release --manifest-path crates/server/Cargo.toml
./crates/server/target/release/cc-switch-web
```

## Tech Stack

- Frontend: React 18, TypeScript, Vite, TailwindCSS, TanStack Query
- Backend: Tauri 2, Rust, tokio, serde
- Testing: vitest, MSW, @testing-library/react

## Project Layout

```text
src/                 frontend code
src-tauri/           Tauri desktop backend
crates/server/       web server
crates/core/         shared core logic
tests/               frontend tests
assets/              screenshots and assets
docs/                supplementary documentation
```

## License

See [LICENSE](LICENSE).
