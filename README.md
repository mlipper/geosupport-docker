# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## Dockerfile.dist

Provides distribution image built from `scratch` which contains only a patched and repackaged version of Geosupport allowing for full control and configuration from an unrelated Dockerfile. E.g., simplified creation of volumes and "data-packed volume containers".

```Dockerfile
FROM some-image:latest

ENV GEOSUPPORT_FULL_VERSION "22a2_22.11"

# Get the Geosupport distro
COPY --from=geosupport-docker:latest-dist /dist/geosupport-${GEOSUPPORT_FULL_VERSION}.tgz /geosupport.tgz

# Do whatever I want with it...
...
```

## Dockerfile

Provides a fully functional Geosupport installation which, by default, is built from image `debian:bullseye-slim`. This `Dockerfile` unpacks, installs and configures Geosupport.

The default `CMD` simply prints Geosupport and geosupport-docker version information.

```sh
docker run -it --rm geosupport-docker:latest
```

To run DCP's CLI application for interacting with Geosupport from the command line, use the following:

```sh
$ docker run -it --rm geosupport-docker:latest geosupport goat


------------------------------------------------------------------------------------------
*****  Enter a function code or 'X' to exit:  hr
You entered hr


Function HR GRC = 00
...etc.
```

However, the most common usage of this `Dockerfile` is for creating a volume containing a complete Geosupport installation directory.

```sh
# Create a named volume using the Docker CLI
$ docker volume create geosupport-22a2_22.11
geosupport-22a2_22.11

# Populate the volume with the contents of GEOSUPPORT_BASE (replace the default CMD with a simple no-op command)
$ docker run -it --rm --mount source=geosupport-22a2_22.11,target=/opt/geosupport geosupport-docker:latest /bin/true

# Run an interactive bash shell in a new container to test the named volume
$ docker run -it --rm --mount source=geosupport-22a2_22.11,target=/opt/geosupport debian:bullseye-slim bash
root@fc1d63c26dca# cd /opt/geosupport 
root@fc1d63c26dca# ls -l
total 4
lrwxrwxrwx 1 root root   18 Jun 13 18:20 current -> version-22a2_22.11
drwxr-xr-x 6 root root 4096 Jun 13 18:55 version-22a2_22.11
```

## About Geosupport

Geosupport is the City of New York's official geocoder of record. The Geosupport application (for Linux, Windows and z/OS) is written and maintained by the New York City [Department of City Planning](http://www1.nyc.gov/site/planning/index.page).

### NEWS

The latest news about this project.

#### June 22nd, 2022

* **Version 2.0.0 available.** This release wraps `Geosupport 22a2_22.11`.

  **CHANGES:**

  > * Implement clearer separation of project, Docker build, and container runtime configuration:
  >   * Use templates to generate artifacts in versioned directories which are commited to git (starting with versions >= `2.0.0`)
  >   * Inspired by the [Docker Official Images](https://github.com/docker-library/official-images) repo, its use of [bashbrew](https://github.com/docker-library/bashbrew) and, e.g., [Tomcat](https://github.com/docker-library/tomcat).
  >   * Automate project build and release tasks with `<project_dir>/generate.sh`.
  >   * Create `<project_dir>/templates` for better sharing of common build/run logic.
  >   * Move variable configuration to `<project_dir>/release.conf`
  > * Further refine `ARG`/`ENV` variables to more accurately reflect Geosupport release/versioning semantics:
  >   * `GEOSUPPORT_MAJOR` - Two-digit year (used for both Geosupport major release and version)
  >   * `GEOSUPPORT_MINOR` - zero or more digits (minor point version of Geosupport version)
  >   * `GEOSUPPORT_PATCH` - Zero or more digits digit (used as a postfix modifier for `GEOSUPPORT_RELEASE` when needed)
  >   * `GEOSUPPORT_RELEASE` - Lowercase letter (postfix modifier for `GEOSUPPORT_MAJOR` as part of the Geosupport release)
  > * Previously, `Geosupport 22a2_22.11` was composed of the following:
  >   * Old semantics:
  >     * `<GEOSUPPORT_RELEASE>_<GEOSUPPORT_VERSION>`
  >     * `GEOSUPPORT_RELEASE` = 22a2
  >     * `GEOSUPPORT_VERSION` = 22.11
  > * With this release of `geosupport-docker`, `Geosupport 22a2_22.11` is now broken down into the following variables:
  >   * New semantics:
  >     * `<GEOSUPPORT_MAJOR><GEOSUPPORT_RELEASE><GEOSUPPORT_PATCH>_<GEOSUPPORT_MAJOR>.<GEOSUPPORT_MINOR>`
  >     * `RELEASE` = a
  >     * `MAJOR` = 22
  >     * `MINOR` = 11
  >     * `PATCH` = 2
  > * Remove `GEOSUPPORT_DISTFILE` from `geosupport.env` file
  > * `geosupport-docker:<version>-dist` image writes the repackaged Geosupport distribution to
  >   * `/dist/geosupport-${GEOSUPPORT_FULL_VERSION}.tgz`
  > * Replace `GEOSUPPORT_DISTFILE` with `DISTFILE` build argument.
  > * New `GEOSUPPORT_BASE` variable which defaults to `/opt/geosupport`.
  > * Change default value of `GEOSUPPORT_HOME` from `/opt/geosupport` to `${GEOSUPPORT_BASE}/current`.
  > * The `current` directory is usually implemented as a symlink allowing for multiple Geosupport versions on the file system for quit version switching.
  >   * `GEOSUPPORT_HOME` still refers to the actual installation directory of the `current` Geosupport. I.e.,
  >     * `$GEOSUPPORT_HOME/bin` - Added to the container runtime `PATH` environment variable
  >     * `$GEOSUPPORT_HOME/fls/` - Default value for `GEOFILES` environment variable
  >     * `$GEOSUPPORT_HOME/include` - Default value for `GS_INCLUDE_PATH` environment variable
  >     * `$GEOSUPPORT_HOME/lib` - Default value for `GS_LIBRARY_PATH` which is used to set `LD_LIBRARY_PATH` and/or as a source directory for `ldconfig`
