# Upstream Sync Runbook

This runbook describes how `zh3305/cc-switch-web` follows upstream `farion1231/cc-switch` tags while preserving the fork's Web-only runtime and release policy.

## Goals

- Keep shared CC Switch product behavior close to upstream.
- Preserve the fork's Web runtime and release deliverables.
- Avoid repeatedly re-solving the same merge conflicts.
- Make upstream tag updates auditable.

## Repositories

- Fork: `zh3305/cc-switch-web`
- Upstream: `farion1231/cc-switch`
- Fork default branch: `main`
- Upstream default branch: `main`

## Pre-sync checklist

Before syncing a new upstream tag:

1. Read the upstream release notes.
2. Confirm the upstream package version from upstream `package.json`.
3. Confirm the fork package version from this repository's `package.json`.
4. Review `docs-dev/WEB_DELTA.md`.
5. Identify whether the upstream change is shared, Web-owned, adapter-owned, or desktop-only.

## Sync buckets

Classify every upstream change into one of these buckets.

### Port

Port these changes into the fork.

- Provider logic and presets
- Proxy and protocol transforms
- Auth flows
- MCP, prompts, skills, sessions, usage
- Database migrations and schema changes
- Shared UI and i18n
- Bug fixes that affect Web runtime behavior

### Adapt

Port the behavior, but adapt the runtime boundary.

- Tauri commands that need Web HTTP route equivalents
- Native file/dialog/window behavior that needs a browser-safe implementation
- App lifecycle events that need a Web runtime equivalent

### Keep fork version

Do not replace these with upstream desktop behavior.

- Web release workflows
- `crates/server` Web runtime behavior
- Web start/stop scripts
- Web-only README positioning
- Runtime defaults and release asset naming

### Skip

Default skip unless explicitly required.

- Tauri tray/window/updater/installer changes
- Desktop-only platform fixes
- macOS signing/notarization changes
- Desktop protocol registration changes

## Recommended local workflow

The GitHub connector can write files, but full upstream code merging should be done in a real local checkout so conflicts can be compiled and tested.

```bash
git remote add upstream https://github.com/farion1231/cc-switch.git 2>/dev/null || true
git fetch origin
git fetch upstream --tags

git switch main
git pull --ff-only origin main

git config rerere.enabled true
git config merge.conflictstyle zdiff3
```

Generate a file-level upstream diff:

```bash
OLD_TAG=v3.13.5
NEW_TAG=v3.14.1
mkdir -p docs-dev/upstream-sync

git diff --name-status upstream/$OLD_TAG..upstream/$NEW_TAG \
  > docs-dev/upstream-sync/$NEW_TAG-files.txt
```

If the upstream tag does not exist for the exact fork version, compare the nearest upstream baseline or compare upstream `main` against the fork manually.

## Manual review paths

Always inspect these paths during a sync:

```text
package.json
CHANGELOG.md
src/config/**
src/components/**
src/lib/**
src-tauri/src/commands/**
src-tauri/src/proxy/**
src-tauri/src/database/**
crates/core/**
crates/server/**
README.md
README_ZH.md
README_JA.md
```

## Validation checklist

At minimum run:

```bash
pnpm install
pnpm typecheck
pnpm test:unit
pnpm build:web
cargo test --manifest-path crates/core/Cargo.toml
cargo build --release --manifest-path crates/server/Cargo.toml
```

Then launch the Web runtime:

```bash
./start-web.sh
curl --fail http://127.0.0.1:17666
./stop-web.sh
```

## Documentation checklist

After syncing an upstream tag, update or add:

- `docs-dev/upstream-sync-<tag>.md`
- `docs-dev/WEB_DELTA.md` if ownership boundaries changed
- `CHANGELOG.md` if user-visible behavior changed
- README files only when release/runtime instructions changed

## Commit style

Use focused commits:

- `docs: record upstream v3.14.1 sync plan`
- `sync: port upstream provider and proxy fixes`
- `sync: port upstream skills fixes`
- `sync: align schema with upstream v3.14.1`
- `web: adapt upstream command for web runtime`

Avoid mixing unrelated upstream feature ports, Web runtime refactors, and release documentation in one commit.
