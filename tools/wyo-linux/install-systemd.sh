#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVICE_USER="${WYO_USER:-rathena}"
TARGET_ROOT="${WYO_ROOT:-$ROOT}"
UNIT_DIR="/etc/systemd/system"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo WYO_USER="$SERVICE_USER" WYO_ROOT="$TARGET_ROOT" bash "$0" "$@"
  fi
  echo "ERROR: systemd installation requires root." >&2
  exit 1
fi

id "$SERVICE_USER" >/dev/null 2>&1 || { echo "ERROR: service user '$SERVICE_USER' does not exist." >&2; exit 1; }
if [[ "$TARGET_ROOT" =~ [[:space:]] ]]; then
  echo "ERROR: WYO_ROOT containing whitespace is not supported by this installer." >&2
  exit 1
fi
[[ -x "$TARGET_ROOT/login-server" && -x "$TARGET_ROOT/char-server" && -x "$TARGET_ROOT/map-server" ]] || {
  echo "ERROR: build WYO first; expected server binaries in $TARGET_ROOT" >&2; exit 1;
}

mkdir -p "$TARGET_ROOT/log" "$TARGET_ROOT/generated"
chown "$SERVICE_USER":"$(id -gn "$SERVICE_USER")" "$TARGET_ROOT/log" "$TARGET_ROOT/generated"

for src in "$ROOT"/tools/wyo-linux/systemd/*.service "$ROOT"/tools/wyo-linux/systemd/*.target; do
  name=$(basename "$src")
  sed -e "s|@WYO_ROOT@|$TARGET_ROOT|g" -e "s|@WYO_USER@|$SERVICE_USER|g" "$src" > "$UNIT_DIR/$name"
done
systemctl daemon-reload
if command -v systemd-analyze >/dev/null 2>&1; then
  systemd-analyze verify "$UNIT_DIR"/wyo-login.service "$UNIT_DIR"/wyo-char.service "$UNIT_DIR"/wyo-map.service "$UNIT_DIR"/wyo-web.service "$UNIT_DIR"/wyo-rathena.target
fi
systemctl enable wyo-rathena.target

echo "Installed systemd units. Start with: systemctl start wyo-rathena.target"
