# CC Switch Web Delta

This document defines the long-term delta between this fork and upstream `farion1231/cc-switch`.

The purpose is to make every upstream tag update predictable: upstream supplies shared product behavior, command contracts, schema changes, proxy logic, and UI fixes; this fork preserves the Web runtime, release policy, and local customization layer.

## Current baseline

- Fork repository: `zh3305/cc-switch-web`
- Upstream repository: `farion1231/cc-switch`
- Current fork package version: `3.13.5`
- Latest upstream version observed: `3.14.1`
- Official release policy for this fork: Web runtime only
- Desktop/Tauri code policy: kept in-repo for local development only
- Web runtime layout:
  - `crates/server/` for the Web server binary
  - `crates/core/` for shared core logic
  - `src/` for React frontend code
  - `src-tauri/` for desktop-local development compatibility

## Ownership model

### Upstream-owned

Prefer keeping these areas close to upstream. When upstream changes them, evaluate and port the behavior unless it is desktop-only.

- Provider business rules, presets, model lists, and provider forms
- MCP, prompts, skills, proxy, failover, session, usage, and auth behavior
- Database schema and migrations
- Shared TypeScript types and Rust DTOs
- i18n keys and user-facing product copy
- Pricing and usage calculation logic
- Stream Check and proxy protocol transforms

### Web-owned

These belong to this fork and should not be overwritten by upstream desktop packaging changes.

- `crates/server/`
- Web runtime start/stop scripts
- Web release workflow and release asset naming
- Web runtime defaults such as host, port, and embedded frontend serving
- README sections that describe this fork's Web-only release policy
- Local customization needed by `zh3305/cc-switch-web`

### Adapter-owned

These files should absorb most fork-specific differences. Keep them thin and explicit.

- Frontend runtime bridge code that maps upstream-style calls to Web APIs
- Rust HTTP route handlers that wrap shared service logic
- DTO conversion between frontend, Web server, and shared core modules
- Browser-safe replacements for desktop-only capabilities

### Desktop-only upstream changes

Default action: do not port unless a Web equivalent is explicitly needed.

- Tray menu behavior
- Tauri window lifecycle and focus fixes
- Tauri updater and installer behavior
- macOS signing/notarization
- Desktop protocol registration
- Native title bar or drag-region fixes

## High-conflict areas

Review these manually on every upstream tag sync.

- `package.json` and version metadata
- `CHANGELOG.md`
- `src/config/**`
- provider presets and provider forms
- `src-tauri/src/commands/**`
- `src-tauri/src/proxy/**`
- database migrations
- `crates/core/**`
- `crates/server/**`
- runtime bridge/API files in `src/**`
- README files in all languages

## Required invariants

Do not merge an upstream tag until these remain true.

1. The Web runtime remains the only official GitHub Release deliverable.
2. `crates/server` can serve the embedded Web frontend.
3. Existing Web launch scripts still work.
4. Shared database migrations remain compatible with upstream schema changes.
5. Browser runtime code does not depend directly on desktop-only Tauri APIs.
6. Upstream command behavior is either implemented in Web, mapped to a safe Web equivalent, or explicitly documented as desktop-only.
7. Web-specific release naming and runtime defaults are preserved.

## Upstream tag sync decision table

| Upstream change type | Default action |
| --- | --- |
| Provider, proxy, auth, usage, session, skills, MCP, prompts | Port to fork |
| Database schema/migration | Port and test carefully |
| Shared UI and i18n | Port unless it is desktop-only |
| Tauri tray/window/updater/installer | Skip by default |
| Release workflow and packaging | Keep fork Web-only policy |
| README/docs | Merge only when compatible with fork positioning |
| New command contract | Add Web runtime mapping or mark unsupported |
| Removed upstream feature | Remove from Web unless explicitly Web-owned |

## Notes for v3.14.x

Upstream `3.14.x` introduces Hermes as a first-class app and several Codex OAuth, Skills, Gemini session, proxy, and UI fixes. The Web fork should treat Hermes support and schema compatibility as shared product changes, not as Web-only features.

If upstream removes a risky feature, such as the Hermes config health scanner removed in upstream `3.14.1`, prefer following upstream unless this fork has a documented Web-specific reason to keep it.
