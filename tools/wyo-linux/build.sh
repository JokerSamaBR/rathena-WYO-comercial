#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [[ ${EUID:-$(id -u)} -eq 0 && "${ALLOW_ROOT_BUILD:-0}" != "1" ]]; then
  echo "ERROR: do not build/run rAthena as root. Use a normal service/build user." >&2
  echo "Set ALLOW_ROOT_BUILD=1 only for a disposable CI/container build." >&2
  exit 1
fi

JOBS="${JOBS:-1}"
COMPILER="${WYO_COMPILER:-gcc}"
case "$COMPILER" in
  gcc)
    CC_BIN="${CC:-gcc}"
    CXX_BIN="${CXX:-g++}"
    ;;
  clang)
    CC_BIN="${CC:-clang}"
    CXX_BIN="${CXX:-clang++}"
    command -v "$CC_BIN" >/dev/null 2>&1 || { echo "ERROR: clang is not installed." >&2; exit 1; }
    command -v "$CXX_BIN" >/dev/null 2>&1 || { echo "ERROR: clang++ is not installed." >&2; exit 1; }
    ;;
  *)
    echo "ERROR: WYO_COMPILER must be gcc or clang." >&2
    exit 1
    ;;
esac

if ! [[ "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: JOBS must be a positive integer." >&2
  exit 1
fi

chmod +x configure athena-start function.sh uninstall.sh 2>/dev/null || true

# PACKETVER is intentionally NOT overridden here. WYO currently defines it in
# src/custom/defines_pre.hpp so the Linux build matches the approved Windows build.
CONFIGURE_ARGS=(--enable-epoll)
if [[ -n "${WYO_CONFIGURE_EXTRA:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA=( ${WYO_CONFIGURE_EXTRA} )
  CONFIGURE_ARGS+=("${EXTRA[@]}")
fi

CC="$CC_BIN" CXX="$CXX_BIN" ./configure "${CONFIGURE_ARGS[@]}"
make clean
make -j"$JOBS" server

for bin in login-server char-server map-server web-server; do
  [[ -x "$bin" ]] || { echo "ERROR: expected binary '$bin' was not built." >&2; exit 1; }
done

echo
file login-server char-server map-server web-server || true
echo
printf 'WYO Linux build complete.\n'
printf 'Tip: JOBS=1 is the safe default. If GCC runs out of memory on the large WYO skill unity unit, use WYO_COMPILER=clang.\n'
