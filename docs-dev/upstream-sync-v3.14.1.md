# Upstream Sync Plan: v3.14.1

Date: 2026-04-24

## Scope

This document records the next upstream sync target for `zh3305/cc-switch-web`.

- Fork repository: `zh3305/cc-switch-web`
- Fork default branch: `main`
- Current fork package version observed: `3.13.5`
- Upstream repository: `farion1231/cc-switch`
- Upstream version observed from upstream `package.json`: `3.14.1`
- Sync target: upstream `3.14.1`

## Summary

The fork is behind upstream `3.14.1`. The next sync should port shared upstream behavior while preserving this fork's Web-only release policy.

The Web runtime should not be replaced by upstream desktop packaging. Treat upstream as the source for product behavior and shared core fixes, while keeping this fork's `crates/server` runtime and Web release workflow intact.

## Expected upstream areas to review

### Must review and likely port

- Hermes first-class app support and any related app registry/config changes
- Database schema and migrations for Hermes and Skills-related fields
- Codex OAuth proxy changes, including FAST mode and streaming/non-streaming compatibility
- Skills install/import reliability fixes
- Gemini session restore fixes
- Provider preset and model list updates
- Stream Check parity fixes
- i18n updates across supported locales

### Must preserve from this fork

- Web runtime as the only official GitHub Release deliverable
- `crates/server` Web server behavior
- `pnpm dev:server`, `pnpm dev:web`, `pnpm build:web`, and release helper behavior
- Web start/stop scripts and runtime defaults
- README positioning that desktop code is kept for local development only

### Desktop-only upstream changes to skip by default

- Tray menu behavior unless the underlying usage/provider logic is reusable
- Tauri window focus, drag-region, updater, installer, signing, and platform packaging changes
- Native desktop protocol registration changes

## Specific v3.14.1 decisions

### Hermes config health scanner

If upstream removed Hermes config health scanner behavior, follow upstream by default. Keeping it as Web-only would create a permanent command-contract and UI delta. Only keep it if there is a clear Web runtime requirement, and if so document that exception in `WEB_DELTA.md`.

### Codex OAuth

Port behavior that affects request routing, cache keys, streaming aggregation, non-streaming JSON responses, and model extraction. These affect Web runtime behavior and should not be treated as desktop-only.

### Skills

Port fixes related to duplicate import, pending state, root-level `SKILL.md` handling, and app enablement fields. Skills are shared product behavior.

### Gemini sessions

Port `.project_root` and restore-path fixes if missing. These affect Web session workflows.

### Tray usage

Do not port tray UI behavior. Reuse only underlying usage-query or cache logic if it fixes shared data behavior.

## Recommended sync order

1. Compare fork `main` against upstream `3.14.1` or upstream `main`.
2. Port schema and migration changes first.
3. Port shared Rust core logic.
4. Port proxy/auth/session/skills/provider behavior.
5. Adapt any new upstream command contract to the Web runtime.
6. Port shared frontend UI and i18n changes.
7. Re-run Web runtime validation.
8. Update `CHANGELOG.md` with fork-specific user-facing changes.

## Validation checklist

Run in a local checkout:

```bash
pnpm install
pnpm typecheck
pnpm test:unit
pnpm build:web
cargo test --manifest-path crates/core/Cargo.toml
cargo build --release --manifest-path crates/server/Cargo.toml
./start-web.sh
curl --fail http://127.0.0.1:17666
./stop-web.sh
```

## Status

- Documentation groundwork: started
- Code sync: not yet performed in this document
- Required next step: perform a real code sync in local checkout or through a reviewed PR/commit sequence
