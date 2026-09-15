#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail=0
pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*" >&2; }
bad()  { printf 'FAIL  %s\n' "$*" >&2; fail=1; }

for f in tools/wyo-linux/*.sh; do
  if bash -n "$f"; then pass "shell syntax: $f"; else bad "shell syntax: $f"; fi
done

if grep -Eq '^#define[[:space:]]+PACKETVER[[:space:]]+20260107\b' src/custom/defines_pre.hpp; then
  pass 'PACKETVER 20260107 is preserved'
else
  bad 'PACKETVER 20260107 not found in src/custom/defines_pre.hpp'
fi

if command -v python3 >/dev/null 2>&1 && python3 - <<'PY'
try:
    import yaml
except Exception:
    raise SystemExit(2)
from pathlib import Path
files=[]
for root in (Path('db/import'), Path('db/custom')):
    if root.exists(): files.extend(root.rglob('*.yml'))
for p in files:
    raw=p.read_bytes()
    for enc in ('utf-8-sig','cp1252'):
        try:
            text=raw.decode(enc); break
        except UnicodeDecodeError:
            text=None
    if text is None:
        raise SystemExit(f'cannot decode {p}')
    yaml.safe_load(text)
print(len(files))
PY
then
  pass 'custom/import YAML parses successfully'
else
  rc=$?
  if [[ $rc -eq 2 ]]; then warn 'python3-yaml not installed; skipped YAML parser validation'; else bad 'custom/import YAML parser validation failed'; fi
fi

# Production secrets must live in ignored import files. Empty/missing files are fine
# for a source checkout, but warn when defaults would still be active.
if [[ -s conf/import/char_conf.txt ]] && ! grep -Eq '^[[:space:]]*passwd:[[:space:]]*p1[[:space:]]*$' conf/import/char_conf.txt; then
  pass 'private char inter-server configuration exists'
else
  warn 'production char inter-server override not configured; run configure-production.sh before public use'
fi
if [[ -s conf/import/inter_conf.txt ]] && ! grep -Eq '^[[:space:]]*login_server_id:[[:space:]]*root[[:space:]]*$' conf/import/inter_conf.txt; then
  pass 'private database configuration exists'
else
  warn 'production database override not configured; run configure-production.sh before public use'
fi

for bin in login-server char-server map-server web-server; do
  if [[ -x "$bin" ]]; then
    desc=$(file -b "$bin" 2>/dev/null || true)
    if [[ "$desc" == *'ELF 64-bit'* ]]; then pass "$bin is a Linux ELF binary"; else bad "$bin is executable but not the expected Linux ELF build"; fi
  else
    warn "$bin not present (normal for a clean source checkout; run build.sh)"
  fi
done

# The Linux build fix is deliberate and must not disappear in a later merge.
if grep -Fq -- '-not -path "./population_engine/*"' src/map/Makefile.in; then pass 'Population Engine unity-build Make exclusion present'; else bad 'Population Engine Make exclusion missing'; fi
if grep -Fq 'population_engine/.*' src/map/CMakeLists.txt; then pass 'Population Engine unity-build CMake exclusion present'; else bad 'Population Engine CMake exclusion missing'; fi

if [[ $fail -ne 0 ]]; then
  echo 'WYO verification FAILED.' >&2
  exit 1
fi

echo 'WYO verification completed.'
