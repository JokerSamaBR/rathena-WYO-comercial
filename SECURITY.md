# Security policy — World Yggdrasil Online rAthena fork

This repository is a WYO-modified rAthena server tree. Security-sensitive production values (database passwords, inter-server passwords, private IPs/tokens) must not be committed.

For deployment guidance see `doc/WYO/WYO_SECURITY_HARDENING.md` and `doc/WYO/WYO_LINUX_INSTALL.md`.

If a vulnerability is found in upstream rAthena, verify whether it also affects the WYO baseline and apply a reviewed/tested patch. If a vulnerability is specific to WYO custom code, do not publish working exploit details before the affected production servers are patched.

Upstream security/project information: https://github.com/rathena/rathena
