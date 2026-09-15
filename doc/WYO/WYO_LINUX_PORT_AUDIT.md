# WYO rAthena — Windows to Linux port audit

Audit date: 2026-09-15

## Source of truth

The uploaded WYO tree was treated as the authoritative gameplay/server implementation. The upstream rAthena repository was used only to identify standard files, build behavior and the likely historical baseline.

The WYO tree's skill architecture matches the rAthena generation around commit `b59092dfc6a4ab9bb5dd3aa633c257924be873a7` (2026-05-21), where `src/map/skill.cpp` still unity-includes `skills/skill_factory.cpp`. Current upstream later changed that build architecture. The Linux port therefore preserves WYO's existing unity model instead of forcing the newest upstream architecture onto modified code.

## Linux build issue found and fixed

WYO's Population Engine is also implemented as a unity build. `src/map/population_engine.cpp` includes `population_engine/population_engine_factory.cpp`, and that factory includes its implementation `.cpp` files.

The original Unix Make discovery also found those submodule `.cpp` files recursively, causing duplicate translation units/symbols on Linux. The uploaded WYO `CMakeLists.txt` already excluded the Population Engine subdirectory correctly, so it was preserved unchanged. The port adds the equivalent exclusion only to `src/map/Makefile.in`, while keeping `src/map/population_engine.cpp` as the parent translation unit.

Build file changed for this:

- `src/map/Makefile.in`

Existing WYO CMake exclusion verified and preserved:

- `src/map/CMakeLists.txt`

## Data validation fixes

Two custom/import YAML files contained parser-invalid structure in the uploaded tree and were minimally repaired:

- `db/import/quest_db.yml`
  - corrected indentation for quest IDs 8784 and 11794;
  - quoted two titles containing `:` so they parse as scalar strings.
- `db/import/pet_db.yml`
  - corrected indentation under a folded `Script: >` block.

No gameplay values were intentionally redesigned in these fixes.

## Build result

A clean-from-scratch Make build using Clang 17 succeeded on Debian 13 x86-64 for:

- login-server
- char-server
- map-server
- web-server

The generated executables were confirmed as 64-bit Linux ELF PIE binaries and dynamically linked against the platform MariaDB/zlib/OpenSSL runtime libraries. The source release intentionally excludes these local test binaries so it can be rebuilt against the target Debian host libraries.

GCC can compile most of the tree, but the WYO unity `skill.cpp` may exceed memory on smaller hosts. On the 5.8 GiB audit environment GCC was OOM-killed on that translation unit; Clang 17 completed it successfully. The supplied build helper therefore supports `WYO_COMPILER=clang` with `JOBS=1`.

CMake configuration and the existing Population Engine CMake exclusion were also verified.

## Windows artifacts

The uploaded ZIP contained large Visual Studio/build artifacts (`.vs`, `.obj`, `.pdb`, `.ilk`, `.exe`, generated build directories). These are not part of the Linux source release and are excluded from the clean distribution/repository by `.gitignore` and release tooling.

Visual Studio solution/project source files are intentionally retained so the WYO tree does not lose its existing Windows build metadata.

## Text encodings

The source contains legacy rAthena/NPC files in non-UTF-8 encodings, including some WYO NPCs that were explicitly authored as Windows-1252. They were not mass-converted because doing so can change client-visible bytes and create a large unsafe gameplay diff. Linux shell/configuration files added by this port use LF endings.

## Preserved WYO systems observed during the port

The port keeps the uploaded implementations for WYO custom rate/season handling, AutoAttack, Autofarm, Population Engine, custom NPC content, multilingual scripts, custom database overlays, marketplace delivery integration and other source modifications. No attempt was made to replace these with upstream defaults.
