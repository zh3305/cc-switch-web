#!/usr/bin/env bash

# 构建 CC-Switch Web 的 Debian 安装包，并把 systemd service 一起打入包中。

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"

VERSION="${1:?usage: build-web-deb-package.sh <version> <binary-path> <output-dir> [arch]}"
BINARY_PATH="${2:?usage: build-web-deb-package.sh <version> <binary-path> <output-dir> [arch]}"
OUTPUT_DIR="${3:?usage: build-web-deb-package.sh <version> <binary-path> <output-dir> [arch]}"
ARCH="${4:-amd64}"
PACKAGE_NAME="cc-switch-web_${VERSION}_${ARCH}.deb"
PACKAGE_ROOT="$(mktemp -d)"

cleanup() {
    rm -rf "$PACKAGE_ROOT"
}
trap cleanup EXIT

if [[ ! -f "$BINARY_PATH" ]]; then
    echo "❌ Error: binary not found at $BINARY_PATH" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
cp -a "$PROJECT_ROOT/packaging/deb/." "$PACKAGE_ROOT/"

find "$PACKAGE_ROOT" -type d -exec chmod 755 {} +
find "$PACKAGE_ROOT" -type f -exec chmod 644 {} +

install -Dm755 "$BINARY_PATH" "$PACKAGE_ROOT/usr/lib/cc-switch-web/cc-switch-web"
chmod 755 \
    "$PACKAGE_ROOT/DEBIAN/postinst" \
    "$PACKAGE_ROOT/DEBIAN/prerm" \
    "$PACKAGE_ROOT/DEBIAN/postrm"

sed \
    -e "s/__VERSION__/${VERSION}/g" \
    -e "s/__ARCH__/${ARCH}/g" \
    "$PACKAGE_ROOT/DEBIAN/control" > "$PACKAGE_ROOT/DEBIAN/control.rendered"
mv "$PACKAGE_ROOT/DEBIAN/control.rendered" "$PACKAGE_ROOT/DEBIAN/control"

dpkg-deb --root-owner-group --build "$PACKAGE_ROOT" "$OUTPUT_DIR/$PACKAGE_NAME" >/dev/null
echo "📦 Debian package created: $OUTPUT_DIR/$PACKAGE_NAME"
