# Copilot Instructions

## Repository role

This repository generates and publishes Docker images that package the NYC DCP Geosupport Linux distribution.

- `release.conf` is the source of truth for the Geosupport release/version and the project image tag.
- `templates/*.template` are source templates. `release.sh generate` renders them into `build/` by replacing `@property@` tokens with values from `release.conf`.
- `build/` is generated and ignored by Git; do not make persistent source changes there.
- The build context uses the DCP zip from `dist/` (normally `dist/linux_geo<release>_<version>.zip` or `dist/geo<release>_<version>.zip`, as derived by `dcp_distfile`).
- `Dockerfile.dist` creates a `scratch` distribution image containing `/dist/geosupport.tgz`; `Dockerfile` copies that artifact and installs Geosupport under `/opt/geosupport` by default.
- Versioned release directories such as `2.0.35/` and entries under `archive/` preserve published releases and their Dockerfiles. Change current sources under `templates/` and `release.conf`, not historical copies.

## Build and verification

When starting work in this repository, run `./release.sh clean generate` from the repository root to regenerate `./build` from the templates. After generation, run `./release.sh show` to inspect the generated build's customization, most of which is configured in `./release.conf`. Use Bash. Geosupport binaries are `amd64` only, even on Apple Silicon; Docker build/run commands in this repository use or should receive `--platform linux/amd64`.

```sh
./release.sh clean generate
./release.sh show
./release.sh helpbuild
./release.sh build --latest
```

Build only one image variant while iterating:

```sh
./release.sh build --variant=dist
./release.sh build --variant=default
```

The generated script can also be called directly after generation:

```sh
./build/build.sh build --variant=dist
./build/build.sh build --variant=default
```

Useful release operations:

```sh
./release.sh createvol --volname=geosupport-latest
./release.sh exportdist
./release.sh custombasedir --path=/gis/geosupport/server
./release.sh release
```

There is no unit-test suite or configured linter. Perform focused runtime smoke tests after a build:

```sh
docker run --platform linux/amd64 --rm mlipper/geosupport-docker:<tag>
docker run --platform linux/amd64 --rm mlipper/geosupport-docker:<tag> geosupport version
docker run --platform linux/amd64 --rm mlipper/geosupport-docker:<tag> geosupport help
docker run --platform linux/amd64 --rm mlipper/geosupport-docker:<tag>-dist
```

Inside the generated/installed distribution, checksum validation is:

```sh
./build/checklist.sh
```

For a generated image/container, run the same `checklist` script from the installed version directory, for example:

```sh
/opt/geosupport/version-<release>_<version>/checklist
```

## Source conventions

- Update README content in `templates/README.md.template`, then run generation and copy the generated `build/README.md` to the root when updating current documentation. `release.sh release` updates only the root README's "Latest Release" line.
- Keep version-specific values in `release.conf` or template placeholders. Do not hardcode a new release in templates, Dockerfiles under `build/`, or shell output.
- The release identifier is `${major}${release}${patch}_${major}.${minor}`. Keep `geosupport_patch` empty when the DCP release has no patch component.
- Docker builds must pin the repository's amd64 platform; `Dockerfile.dist` should remain usable through multi-stage `COPY --from`, and `Dockerfile` consumes `/dist/geosupport.tgz` from the dist image.
- The dist Dockerfile extracts DCP files, renames `c_client` to `goat`, patches `geo.h`, adds wrapper scripts, and writes `checklist.chk` with SHA-256 checksums. Changes to packaged files must preserve checksum regeneration.
- `geosupport.sh.template` and `geosupport.env.template` define `/opt/geosupport`, `/opt/geosupport/current`, and the versioned `version-*` layout used by installation and volume use.
- `custombasedir.sh.template` is also used to repackage distributions for an alternate base directory; it rewrites `geosupport` and `geosupport.env`, then regenerates `checklist.chk`.
- Generated shell scripts use Bash and generally assume `set -Eeuo pipefail`. macOS builds may need GNU `readlink`/`sha256sum` support as handled by the scripts.
