# World Yggdrasil Online (WYO) — Linux / Debian installation

This repository is the WYO rAthena tree ported from the project's working Windows build to Linux while preserving WYO gameplay/source customizations.

## Supported target

- Debian 12 (bookworm): intended production target.
- Debian 13 (trixie): build-tested on 2026-09-15.
- Architecture tested: x86-64.
- Database: MariaDB.
- Client packet version: `20260107` (from `src/custom/defines_pre.hpp`).

The installation flow intentionally stays close to the official rAthena Debian guide: install dependencies, run `./configure`, `make clean`, then `make server`. WYO adds helper scripts so the approved custom code is built consistently.

Official references:

- https://github.com/rathena/rathena
- https://github.com/rathena/rathena/wiki/
- https://github.com/rathena/rathena/wiki/Install-on-Debian

## 1. Create a dedicated service user

Do not run the emulator as root.

```bash
sudo useradd --system --create-home --home-dir /opt/wyo-rathena --shell /bin/bash rathena
sudo chown -R rathena:rathena /opt/wyo-rathena
```

If you clone elsewhere, use a normal unprivileged user and adjust `WYO_ROOT` when installing systemd units.

## 2. Install build/runtime dependencies

From the repository root:

```bash
sudo tools/wyo-linux/bootstrap-debian.sh
```

The helper installs GCC/G++, Make, CMake, MariaDB client/development packages, zlib and other required packages. Legacy PCRE1 support is enabled only if the Debian release provides `libpcre3-dev`.

## 3. Build WYO

As the unprivileged rAthena user:

```bash
tools/wyo-linux/build.sh
```

The default is `JOBS=1`. The WYO skill unity translation unit is large, and aggressive parallel builds can exhaust RAM on smaller VPS instances.

For the audited low-memory-safe build path:

```bash
WYO_COMPILER=clang JOBS=1 tools/wyo-linux/build.sh
```

GCC is still supported, but this WYO tree has a very large unity `skill.cpp`; on memory-constrained VPS hosts GCC may be killed by the kernel. For a larger host you can also increase parallelism carefully:

```bash
JOBS=2 tools/wyo-linux/build.sh
```

Successful output must include these Linux ELF binaries:

- `login-server`
- `char-server`
- `map-server`
- `web-server`

## 4. Create/import the MariaDB database

Start from the standard rAthena schemas:

```bash
mariadb -u root -p ragnarok < sql-files/main.sql
mariadb -u root -p ragnarok < sql-files/logs.sql
mariadb -u root -p ragnarok < sql-files/web.sql
```

WYO source systems also include these local schemas:

```bash
mariadb -u root -p ragnarok < sql-files/autoattack.sql
mariadb -u root -p ragnarok < sql-files/autofarm_rewards.sql
mariadb -u root -p ragnarok < sql-files/population_engine/cp_population_stats.sql
```

`CharSell`, `ItemSell` and related website marketplace/support tables belong to the WYO FluxCP addon side. Do not invent replacement schemas in rAthena; deploy the approved FluxCP addon schemas that match the website version.

## 5. Generate production configuration

Never run production with upstream defaults `s1/p1` or MariaDB `root` with an empty password.

Run:

```bash
tools/wyo-linux/configure-production.sh
```

This creates ignored private files under `conf/import/` with mode `0600` and a generated SQL update for the inter-server login account.

After importing `main.sql`, execute the generated account update:

```bash
mariadb -u root -p ragnarok < tools/wyo-linux/generated/wyo-server-account.sql
```

The WYO web-server helper binds to `127.0.0.1:8888` by default. Keep it private unless you intentionally place a trusted reverse proxy in front of it.

## 6. Validate before first start

```bash
tools/wyo-linux/verify.sh
```

The verifier checks Linux scripts, custom YAML, PACKETVER, obvious production-default credentials and the presence/type of compiled server binaries.

## 7. Install systemd units

After a successful build and configuration:

```bash
sudo WYO_USER=rathena WYO_ROOT=/opt/wyo-rathena tools/wyo-linux/install-systemd.sh
sudo systemctl start wyo-rathena.target
```

Check status with:

```bash
systemctl status wyo-login.service wyo-char.service wyo-map.service wyo-web.service
journalctl -u wyo-map.service -f
```

The service templates use a non-root account and a conservative set of systemd hardening options. The repository's `log/` and `generated/` directories are the only application paths explicitly prepared for runtime writes by the installer.

## 8. Network exposure

Typical rAthena game ports should be exposed only as required by the client/server architecture. Do not expose MariaDB (`3306`) publicly. Keep the WYO web-server on loopback unless a reviewed reverse proxy requires it.

Use host/provider firewall rules and, where appropriate, upstream DDoS protection. Source-level packet validation cannot replace network-layer protection.

## Updating the WYO tree

WYO contains extensive source, NPC, database and FluxCP integration changes. Do **not** blindly merge the latest rAthena `master` into production. Review upstream changes against the WYO baseline, test Linux compilation, YAML parsing, login/char/map startup, and the WYO systems before merging.
