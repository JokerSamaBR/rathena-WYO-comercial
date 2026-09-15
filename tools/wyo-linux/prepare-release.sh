#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT/dist}"
NAME="${WYO_RELEASE_NAME:-rathena-WYO-linux}"
mkdir -p "$OUT_DIR"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/$NAME"
rsync -a \
  --exclude='.git/' --exclude='.vs/' --exclude='build/' --exclude='cbuild/' --exclude='CMakeFiles/' --exclude='autom4te.cache/' \
  --exclude='config.log' --exclude='config.status' --exclude='Makefile' --exclude='Makefile.cache' \
  --exclude='login-server' --exclude='char-server' --exclude='map-server' --exclude='web-server' --exclude='map-server-generator' \
  --exclude='*.o' --exclude='*.a' --exclude='*.obj' --exclude='*.pdb' --exclude='*.ilk' --exclude='*.idb' --exclude='*.log' --exclude='*.pid' \
  --exclude='*.exe' --exclude='*.dll' --exclude='*.lib' --exclude='*.exp' --exclude='*.VC.db' --exclude='*.VC.opendb' \
  --exclude='tools/wyo-linux/generated/' --exclude='dist/' \
  "$ROOT/" "$TMP/$NAME/"

# Never ship generated private configs even if someone created them locally.
rm -f "$TMP/$NAME"/conf/import/*_conf.txt "$TMP/$NAME"/conf/import/*.bak.* 2>/dev/null || true

( cd "$TMP" && tar -cJf "$OUT_DIR/$NAME.tar.xz" "$NAME" )
sha256sum "$OUT_DIR/$NAME.tar.xz" > "$OUT_DIR/$NAME.tar.xz.sha256"

echo "Created: $OUT_DIR/$NAME.tar.xz"
cat "$OUT_DIR/$NAME.tar.xz.sha256"
