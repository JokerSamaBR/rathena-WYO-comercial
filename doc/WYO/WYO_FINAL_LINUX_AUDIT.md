# WYO rAthena — Final Linux Port & Security Audit

Audit date: 2026-09-15
Target: World Yggdrasil Online rAthena tree supplied as `rathena.zip`
Intended production OS: Debian 12 x86-64
Build validation host: Debian 13 x86-64

## Scope and source of truth

The uploaded WYO tree was treated as authoritative. Upstream rAthena was used as a reference for baseline structure/build behavior only. WYO gameplay/source/NPC/database changes were preserved unless a concrete portability, parser, security or correctness defect was identified.

The WYO skill layout matches the rAthena generation around upstream commit `b59092dfc6a4ab9bb5dd3aa633c257924be873a7` (2026-05-21), where `skill.cpp` still unity-included the skill factory implementation. The port intentionally does not migrate WYO to the later upstream split-translation-unit skill architecture.

## Linux build result

A clean-from-scratch Make build using Clang 17 and `JOBS=1` completed successfully and produced:

- `login-server` — ELF 64-bit x86-64 PIE
- `char-server` — ELF 64-bit x86-64 PIE
- `map-server` — ELF 64-bit x86-64 PIE
- `web-server` — ELF 64-bit x86-64 PIE

All runtime shared libraries resolved in the audit environment. The distributed source archive does not ship these locally built binaries; it rebuilds them on the Debian target to avoid glibc/runtime compatibility problems.

GCC compiled the normal units but was OOM-killed by WYO's very large unity `skill.cpp` on the 5.8 GiB audit host. Clang 17 completed the same unit. The supplied helper therefore supports the audited path:

```bash
WYO_COMPILER=clang JOBS=1 tools/wyo-linux/build.sh
```

## Portability defects fixed

### Population Engine Unix build

`src/map/population_engine.cpp` already unity-includes its implementation modules. The original Unix Make source discovery recursively compiled those child `.cpp` files again, which can create duplicate symbols on Linux.

Fix: `src/map/Makefile.in` now excludes `./population_engine/*` from separate translation units. The uploaded WYO `src/map/CMakeLists.txt` already contained the corresponding exclusion and was preserved unchanged.

### YAML parser defects

Minimal parser-only fixes were applied to:

- `db/import/quest_db.yml`
  - fixed indentation for quests 8784 and 11794;
  - quoted two titles containing `:`.
- `db/import/pet_db.yml`
  - fixed indentation in a folded `Script: >` block.

Custom/import validation passed for 51 YAML files.

## Security/correctness defects fixed during compiler audit

### 1. Login console buffer bounds

`src/login/logincnslif.cpp` declared `type[64]` and `command[64]` but used `sscanf` widths of 127 and 255. This could overwrite the stack if a long local console command were supplied.

Fix: widths reduced to 63/63, matching the buffers and preserving NUL termination.

Severity: Medium locally; not a normal remote-client packet path.

### 2. WYO Autofarm command buffer bound

`src/custom/atcommand.inc` declared `name[NAME_LENGTH]` (24 bytes in this tree) but allowed a 31-character scanset in `@autofarm monsters ...`.

Fix: scanset limited to 23 characters.

Severity: Medium because atcommands can be player-originated when permission is granted.

### 3. Marriage-ring weight precedence bug

`src/map/atcommand.cpp` assigned the boolean result of a combined `&&` expression into `w` rather than assigning the ring's actual weight first. This could make the weight check incorrect.

Fix: ring weight is now assigned explicitly before each comparison.

Severity: Low security / Medium correctness.

### 4. Population command formatting

A custom Population Engine status message used `sprintf` into a fixed 256-byte buffer. The current format was bounded by numeric inputs, so exploitation was not demonstrated, but the call was hardened to `snprintf` as a defensive improvement.

Severity: Low.

## WYO custom-code attack-surface scan

The targeted WYO source scan covered `src/custom`, AutoAttack, Autofarm and Population Engine code.

No calls were found to high-risk process/dynamic-loading primitives such as:

- `system()`
- `popen()`
- `fork()/exec*()`
- `CreateProcess` / `ShellExecute` / `WinExec`
- `dlopen()` / `LoadLibrary()`

The reviewed AutoAttack/Autofarm/Population Engine SQL writes use numeric server-side values in their formatted queries. No direct player-supplied free-form string interpolation was identified in those reviewed paths.

Population Engine reload/spawn commands are not explicitly granted to normal groups in `conf/groups.yml`; the Admin group has `all_commands: true`. Keep these commands restricted to trusted staff because they can create significant server load.

## Credentials and deployment hardening

The source tree still contains standard upstream development defaults, including the inter-server `s1/p1` pattern and standard database examples. Production must override them.

The Linux port adds `tools/wyo-linux/configure-production.sh`, which creates private ignored files under `conf/import/`, mode `0600`, and generates an SQL update for the inter-server account.

Production rules:

- never run login/char/map/web as root;
- do not expose MariaDB publicly;
- replace `s1/p1` before public use;
- do not use MariaDB `root` with an empty password;
- keep `web-server` on `127.0.0.1:8888` unless intentionally reverse-proxied;
- keep production secrets out of Git;
- restrict game ports with host/provider firewall controls.

No private keys, GitHub tokens, Discord webhook tokens or bearer credentials were found in the final source tree scan. Private-IP matches were only documentation/example values in the reviewed WYO configuration path.

## systemd validation

Four hardened service templates plus a target are included. They run under a dedicated unprivileged user and apply:

- `NoNewPrivileges=true`
- `PrivateTmp=true`
- `PrivateDevices=true`
- `ProtectSystem=full`
- `ProtectHome=read-only`
- kernel/control-group restrictions
- SUID/SGID restrictions
- address-family restriction
- `UMask=0027`

The generated units were checked with `systemd-analyze verify` using a simulated installation root.

## Release hygiene

The uploaded Windows archive included large Visual Studio/build artifacts. The Linux source release excludes generated/runtime artifacts, including:

- `.exe`, `.dll`, `.lib`, `.pdb`, `.obj`, `.ilk`, `.exp`, `.idb`
- `.vs/`, build/cbuild/CMake build output
- generated Linux object/archive files
- local ELF test binaries
- `config.log`, `config.status`, generated Makefiles
- generated production credentials

The final source archive contains 5,555 paths and its forbidden-artifact scan returned 0 matches.

## Files intentionally modified from the uploaded WYO tree

Eight existing source/repository files were intentionally modified:

- `README.md`
- `.gitignore`
- `db/import/quest_db.yml`
- `db/import/pet_db.yml`
- `src/login/logincnslif.cpp`
- `src/map/Makefile.in`
- `src/map/atcommand.cpp`
- `src/custom/atcommand.inc`

Linux deployment documentation/scripts/workflow were added separately under `doc/WYO/`, `tools/wyo-linux/`, `SECURITY.md`, and `.github/workflows/wyo-linux-build.yml`.

No broad upstream merge was performed.

## Known observations not changed automatically

Clang reports a number of warnings in legacy rAthena/WYO code (large enum switches, signed/unsigned comparisons and other historical patterns). They do not prevent compilation. They were not mass-fixed because doing so would create a large gameplay/source diff without individual behavioral validation.

One example still reported in `atcommand.cpp` compares unsigned save coordinates against `-1`. It is recorded for future review rather than altered blindly in this Linux-port release.

## Final status

- Linux source port: PASS
- Clean Clang build: PASS
- Post-hardening rebuild: PASS
- 4 Linux ELF servers produced in audit environment: PASS
- WYO PACKETVER `20260107`: PASS
- Custom/import YAML parsing: PASS (51 files)
- systemd syntax/verification: PASS
- targeted secret scan: PASS
- targeted WYO dangerous-process API scan: PASS
- Windows-build artifact scan of release: PASS (0 forbidden artifacts)
- production credentials embedded in release: NONE generated

This release is ready for installation testing on the user's Debian 12 production/staging server. Database backups and a staging smoke test are still recommended before replacing an active server.
