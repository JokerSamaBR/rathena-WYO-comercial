# WYO rAthena — production security notes

This file covers deployment security for the emulator itself. It does not replace firewall, operating-system, MariaDB, reverse-proxy or DDoS controls.

## Critical production rules

1. Never run login/char/map/web-server as root.
2. Replace the default inter-server account `s1/p1` before exposing the service.
3. Never use MariaDB `root` with an empty password from rAthena.
4. Keep MariaDB on a private/loopback interface unless a reviewed network design requires otherwise.
5. Keep `web-server` bound to loopback by default.
6. Keep secrets only in ignored `conf/import/*_conf.txt` files (mode 0600) or an equivalent secrets mechanism.
7. Restrict game ports with host/provider firewalls to only what is necessary.
8. Back up the database before schema changes and before upgrading WYO source.

## External attack surface

The public login/map listeners parse untrusted client packets by design. Keep the operating system and compiler/runtime libraries patched. Do not treat custom script or packet-level checks as DDoS protection.

The rAthena web-server is an HTTP API component and should not be placed directly on the public Internet without a specific requirement, authentication review and reverse-proxy controls.

## WYO custom systems

Population Engine administrative commands can create substantial server load if exposed to ordinary accounts. Keep population reload/spawn commands restricted to trusted Staff/Admin groups.

AutoAttack/Autofarm server-side checks should remain authoritative; NPC/UI scripts are convenience layers, not security boundaries.

Marketplace delivery NPCs operate against website-managed tables. Database grants should follow least privilege and the website/emulator table schemas must be deployed from matching approved versions.

## Logging and permissions

Production configuration files containing credentials should be `0600`. Runtime logs should be writable by the rAthena service account, not world-writable. Avoid publishing production `conf/import` secret files to Git.

## Update policy

Do not automatically merge upstream rAthena into this commercial WYO branch. Review and test changes because WYO modifies source areas that upstream also changes frequently (map/pc/status/script/skill/build files).
