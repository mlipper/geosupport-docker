# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

The latest news about this project.

### August 08, 2024

* **Version 2.0.19 available.** This release wraps `Geosupport 24c1_24.3`.

  Note that this project skipped the release of `Geosupport 24c_24.3` due
  to an issue with the `THINED` file in the Linux distribution.

  **CHANGES:**

  * Upgrade to DCP's latest Geosupport release: `24c1_24.3`
  * Feature: Upgrade base image from `ubuntu:jammy` to `ubuntu:noble`.
  * Update generated `Dockerfile` to fix deprecated syntax.
  * Issue: Fix `README.md` text to use latest `distfile` naming convention.
