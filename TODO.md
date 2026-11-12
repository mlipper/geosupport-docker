# TODO

Findings from the 2026-10-20 review of `release.sh` and the generated `build/` directory that have not been implemented.

Already fixed that day: `--variant` forwarding, bare `createvol`, `build/.dockerignore` overwrite, `exportdist`/`buildx`/`builddrv_name` cleanup, `custombasedir.sh` sed delimiter and `checklist.chk` regeneration, `ubuntu:noble` in `templates/README.md.template`, and documentation of the README copy step.

## Documentation and templates

The root `README.md` is populated by copying `build/README.md`, which is generated from `templates/README.md.template`. Edit the template, not `README.md`.

- [ ] **Template is behind the root README.** `README.md` has been hand-edited since the template was last updated. Running `cp build/README.md README.md` now would lose:
  - the Build Summary dependency table
  - the step-by-step "Build Details" section
  - the updated `release.sh show` / `helpbuild` examples

  Port the root README's newer content into the template, using `@token@` placeholders where values are version-specific, before the next copy.
- [ ] **Stale example values in the template** (and therefore in the root README):
  - `release.sh show` example: `geosupport_major 23`, `vcs_ref`, `linux_geo...zip` file name, 2023 timestamps
  - `exportdist` help text contains a hardcoded `/Users/mlipper/...` path
  - volume example `ls -l` output has old dates
- [ ] **Step 5 label mismatch** in the Build Summary table: "Required: true" in the table, "(Optional)" in the details. Also, `release` only checks that files exist in `build/`, not that images were built, although the table lists step 4 as a dependency.

## Environment and configuration

- [ ] **No bash version check.** `release.sh` fails under macOS `/bin/bash` 3.2 at `declare -A` with a cryptic error. Add a version check with a clear message, and mention the Homebrew bash requirement in the README.
- [ ] **Missing property aborts under `set -u`.** `_getc` reads `${confmap[${key}]}` directly, so a property removed from `release.conf` crashes the script instead of defaulting or reporting a clear error.

## `release.sh`

- [ ] **`release` overwrites hand-edited notes.** It copies `build/README-release.md` over an existing `<tag>/README-<tag>.md` without asking, replacing filled-in release notes with the placeholder version. Consider refusing to overwrite an existing file.
- [ ] **Usage text with no arguments is wrong.** `./release.sh` prints `Runs "/build.sh ..."` because `BUILD_DIR` is not set yet when `usage` runs. `help` prints the correct paths.
- [ ] **`generate` copies the 204 MB DCP zip every time**, and it is sent as build context even for the default `Dockerfile`, which does not use it.

## Generated files

- [ ] `checklist.sh` and `geosupport.version` have no trailing newline.
- [ ] `geosupport.sh` loses its executable bit when generated (the template has it). `Dockerfile.dist` runs `chmod +x`, so this is cosmetic.
- [ ] Generated files embed a build timestamp (`geosupport.version`, `geosupport.sh`), so output is not reproducible between runs.
- [ ] `message.c` mixes tabs and spaces and hardcodes `GSD_ARCH` to `Linux x86-64 (amd64)`.
- [ ] `Dockerfile.dist` installs `g++`, which is not needed to compile a C file. Removing it changes the published image build, so hold off unless a rebuild is planned.

## Script robustness

`build.sh`:
- [ ] `DEFAULT_VOLUME_NAME` and `DIST_VOLUME_NAME` are unused.
- [ ] `exportdist` uses `docker run -it`, which fails without a TTY (for example, in CI).

`geosupport.sh`:
- [ ] `_install` relies on `${sofiles[$@]}` (subscripting a string) and `xargs basename -s $GEOSUPPORT_HOME`; both work by accident.
- [ ] `readlink -e` prints stray output in `_create_current_ln`.
- [ ] Usage text says `$GEOSUPPORT_BASE` where it means `GEOSUPPORT_BASEDIR`, and describes the `current` link relative to `${GEOSUPPORT_FULLVERSION}` where it means `${VERSION_DIR}`.

`custombasedir.sh`:
- [ ] `compress()` is called as `compress || die ...`, which disables `set -e` inside it, so a failed `sed`, `cd` or `tar` extract does not stop the script.
- [ ] Usage text names output files without the `.tgz` extension.
- [ ] `die` writes to stdout; the other scripts write to stderr.

## Unverified

- [ ] `exportdist` was changed to plain `docker build --platform=linux/amd64` (matching `buildImage`) but not run against Docker. Try `./release.sh exportdist` on an Apple Silicon Mac.
