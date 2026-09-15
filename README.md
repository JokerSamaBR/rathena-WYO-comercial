<img src="doc/logo.png" align="right" height="90" />

# World Yggdrasil Online — rAthena WYO

WYO-maintained rAthena server tree used by **World Yggdrasil Online**. This repository preserves the project's approved source/NPC/database customizations and adds a reviewed Linux/Debian build and deployment path.

> This is a modified rAthena derivative, not the upstream clean tree. Upstream rAthena remains the reference project: https://github.com/rathena/rathena

## WYO baseline and compatibility

- WYO client packet version: `20260107`.
- English is the base language with WYO Portuguese/Spanish support enabled in custom definitions/scripts.
- The source contains WYO AutoAttack, Autofarm, Population Engine, custom rate/season logic, custom NPC/database overlays and website marketplace integration points.
- Windows project metadata is retained, but generated Visual Studio artifacts are not part of the source release.
- Linux build tested on Debian 13 x86-64; Debian 12 is the intended production target.

## Linux quick start

```bash
sudo tools/wyo-linux/bootstrap-debian.sh
# switch back to a normal/non-root rAthena user
WYO_COMPILER=clang JOBS=1 tools/wyo-linux/build.sh
tools/wyo-linux/configure-production.sh
tools/wyo-linux/verify.sh
```

Then import the standard rAthena SQL plus the WYO local schemas described in:

**`doc/WYO/WYO_LINUX_INSTALL.md`**

For systemd deployment:

```bash
sudo WYO_USER=rathena WYO_ROOT=/opt/wyo-rathena tools/wyo-linux/install-systemd.sh
sudo systemctl start wyo-rathena.target
```

## Important production rules

Do not expose a server still using the upstream `s1/p1` inter-server defaults or MariaDB `root` with an empty password. Do not run rAthena as root. Keep the rAthena web-server on loopback unless a reviewed deployment requires otherwise.

See **`doc/WYO/WYO_SECURITY_HARDENING.md`**.

## Port audit

The uploaded Windows tree was treated as the WYO source of truth. The Linux port does not blindly replace WYO code with current rAthena `master`. A key Linux build correction was required for the WYO Population Engine unity-build layout, and parser-invalid custom YAML entries were minimally repaired.

See **`doc/WYO/WYO_LINUX_PORT_AUDIT.md`**.

Final build/security audit: **`doc/WYO/WYO_FINAL_LINUX_AUDIT.md`**.

## Upstream documentation

- rAthena: https://github.com/rathena/rathena
- Wiki: https://github.com/rathena/rathena/wiki/
- Debian install guide: https://github.com/rathena/rathena/wiki/Install-on-Debian

## License

rAthena and this derivative are distributed under the GNU General Public License v3.0. Preserve the upstream copyright notices and `LICENSE` file. See the upstream project for original authors/contributors and project support channels.
