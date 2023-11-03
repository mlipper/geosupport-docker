# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

The latest news about this project.

### July 1st, 2022

* **Version 2.0.0 available.** This release wraps `Geosupport 22a2_22.11`.

  **CHANGES:**

  Implement clearer separation of project, build, and container runtime configuration.

  > * Favor build-time configuration over runtime logic.
  > * Simplify build with templates using `<project_dir>/templates`.
  > * Automate project build and release tasks with `<project_dir>/release.sh`.
  > * Externalize build-time configuration with `<project_dir>/release.conf`.
  > * Reduce excessive use of environment variables.

  Reorganize project layout to clarify relationship between project and Geosupport versions.

  > * Easier navigation of project artifacts and corresponding Geosupport distributions using versioned directories.

  Refine configuration to more accurately reflect Geosupport release/versioning semantics.

  > * New `geosupport-docker:<version>-dist` image
  > * New `geosupport_basedir` property and `GEOSUPPORT_BASE` environment variable:
  >   * Default value: `/opt/geosupport`.
  > * New `geosupport_home` property and updated `GEOSUPPORT_HOME` environment variable:
  >   * Default value (updated): `${GEOSUPPORT_BASE}/current`
  >   * `current` directory is a symlink: helpful for certain volume and bind mount scenarios to allow quit switching between side-by-side Geosupport distributions.
  >   * `GEOSUPPORT_HOME` still refers to the actual installation directory of the `current` Geosupport. I.e.,
  >     * `$GEOSUPPORT_HOME/bin` - Added to the container runtime `PATH` environment variable
  >     * `$GEOSUPPORT_HOME/fls/` - Default value for `GEOFILES` environment variable
  >     * `$GEOSUPPORT_HOME/include` - Default value for `GS_INCLUDE_PATH` environment variable
  >     * `$GEOSUPPORT_HOME/lib` - Default value for `GS_LIBRARY_PATH` which is used to set as a source directory for `ldconfig`
