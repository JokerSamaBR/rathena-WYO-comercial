#!/usr/bin/env bash
set -euo pipefail

# World Yggdrasil Online / rAthena - Debian dependency bootstrap.
# This script installs build/runtime dependencies only. It does not touch the DB.

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo --preserve-env=DEBIAN_FRONTEND bash "$0" "$@"
  fi
  echo "ERROR: run as root or install sudo first." >&2
  exit 1
fi

export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}
apt-get update
apt-get install -y \
  ca-certificates git make gcc g++ clang cmake pkg-config python3 python3-yaml rsync xz-utils \
  mariadb-server mariadb-client libmariadb-dev libmariadb-dev-compat \
  zlib1g-dev libssl-dev

# rAthena's PCRE support is optional. Debian releases differ on availability
# of the legacy PCRE1 development package, so install it only if available.
if apt-cache show libpcre3-dev >/dev/null 2>&1; then
  apt-get install -y libpcre3-dev
else
  echo "INFO: libpcre3-dev is not available on this Debian release; WYO builds without optional PCRE support."
fi

echo "Dependencies installed. Build the emulator as a non-root user with:"
echo "  tools/wyo-linux/build.sh"
