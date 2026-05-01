#!/usr/bin/env bash

# 验证 Web 发布脚本会产出 Debian 安装包，并包含 systemd 服务文件。

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/release-web-test"
VERSION="$(node -p "require('$PROJECT_ROOT/package.json').version")"
DEB_PATH="$OUTPUT_DIR/cc-switch-web_${VERSION}_amd64.deb"
EXTRACT_DIR="$OUTPUT_DIR/extracted"

rm -rf "$OUTPUT_DIR"

(
    cd "$PROJECT_ROOT"
    WEB_RELEASE_DIR="$OUTPUT_DIR" ./build-web-release.sh
)

test -f "$DEB_PATH"

dpkg-deb -c "$DEB_PATH" | grep -F "./usr/lib/systemd/system/cc-switch-web.service"
dpkg-deb -c "$DEB_PATH" | grep -F "./etc/default/cc-switch-web"
dpkg-deb -c "$DEB_PATH" | grep -F "./usr/lib/cc-switch-web/cc-switch-web"

mkdir -p "$EXTRACT_DIR"
dpkg-deb -x "$DEB_PATH" "$EXTRACT_DIR"

! grep -q '^User=' "$EXTRACT_DIR/usr/lib/systemd/system/cc-switch-web.service"
! grep -q '^Group=' "$EXTRACT_DIR/usr/lib/systemd/system/cc-switch-web.service"
! dpkg-deb -f "$DEB_PATH" Depends | grep -q 'adduser'

rm -rf "$OUTPUT_DIR"
