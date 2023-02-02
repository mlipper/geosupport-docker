# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

The latest news about this project.

### February 10th, 2023

* **Version 2.0.8 available.** This release wraps `Geosupport 23a_23.1`.

  **CHANGES:**

  * Switch base image to `ubuntu:jammy` from `debian:bookworm-slim`.
  * Change the path of the DEFAULT_EXPORTDIR to `<projectdir>/out/<version>`.
  * New `custombasedir.sh` script generated which allows creating a new distribution with a different `GEOSUPPORT_BASEDIR` path.
