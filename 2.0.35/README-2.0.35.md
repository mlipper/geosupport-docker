# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

The latest news about this project.

### November 12, 2026

* **Version 2.0.35 available.** This release wraps `Geosupport 26d_26.4`.
* The Department of City Planning provides detailed information about this release in the [Geosupport System User Bulletin](https://www.nyc.gov/content/planning/pages/resources/geocoding/geosupport-desktop-edition).

  **CHANGES:**

  *Features*

  * `exportdist` now builds with `docker build --platform=linux/amd64`, matching `buildImage`, so images can be built from non-`amd64` hosts (e.g., Apple Silicon) without a custom `buildx` driver. The `builddrv_name` property is removed from `release.conf`.
  * `README.md` template documents the `build/README.md` copy step and is updated to reference the `ubuntu:noble` base image.
  * Removed the outdated "Building on platforms other than `amd64`" section from `README.md`.

  *Fixes*

  * `release.sh` now forwards `--variant=<name>` to `build.sh` unchanged. Previously it was stripped to a bare name, which `build.sh` rejected as an invalid command.
  * `release.sh` omits the volume name when `--volname` is not given so `build.sh` applies its default instead of failing on an empty argument to `createvol`.
  * `release.sh` writes `build/.dockerignore` once, after the `chmod` loop. Previously it was truncated on each iteration, leaving only `custombasedir.sh`.
  * `custombasedir.sh` uses `|` as the `sed` delimiter so `--path` values containing underscores work.
  * `custombasedir.sh` regenerates `checklist.chk` after rewriting `geosupport` and `geosupport.env` so the packaged checklist script still passes.
  * Fixed nested double quotes in a `custombasedir.sh` logging statement introduced by the previous fix.
