#!/usr/bin/env bash

# 轻量验证 Debian 打包模板：systemd 服务应以 root 运行，且安装脚本不再创建专用服务用户。

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/cc-switch-web"
OUT_DIR="$TMP_DIR/out"
DEB_PATH="$OUT_DIR/cc-switch-web_9.9.9_amd64.deb"
EXTRACT_DIR="$TMP_DIR/extracted"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cp /bin/true "$FAKE_BIN"
chmod 755 "$FAKE_BIN"

"$PROJECT_ROOT/scripts/build-web-deb-package.sh" "9.9.9" "$FAKE_BIN" "$OUT_DIR"

test -f "$DEB_PATH"

mkdir -p "$EXTRACT_DIR"
dpkg-deb -x "$DEB_PATH" "$EXTRACT_DIR"

SERVICE_FILE="$EXTRACT_DIR/usr/lib/systemd/system/cc-switch-web.service"
CONTROL_TMP="$TMP_DIR/control"
mkdir -p "$CONTROL_TMP"
dpkg-deb --control "$DEB_PATH" "$CONTROL_TMP"

! grep -q '^User=' "$SERVICE_FILE"
! grep -q '^Group=' "$SERVICE_FILE"
grep -q '^Environment=HOME=/var/lib/cc-switch-web$' "$SERVICE_FILE"
grep -q '^WorkingDirectory=/var/lib/cc-switch-web$' "$SERVICE_FILE"
! grep -q 'adduser' "$CONTROL_TMP/postinst"
! grep -q 'addgroup' "$CONTROL_TMP/postinst"
! dpkg-deb -f "$DEB_PATH" Depends | grep -q 'adduser'
