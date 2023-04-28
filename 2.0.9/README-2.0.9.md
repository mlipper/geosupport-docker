# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

The latest news about this project.

### May 8th, 2023

* **Version 2.0.9 available.** This release wraps `Geosupport 23b_23.2`.

  **CHANGES:**

  * Simplify the generated `build.sh` script.
    * Remove commands `removeimage` and `removevol` which are just as easily accomplished using built-in Docker CLI.
    * Change behavior of the `createvol` command so that it only creates a volume for the `default` variant since command `exportdist` already provides the ability to export the repackaged distribution to the host file system. This command now only accepts the `--volname=<name>` option and no longer supports `--variant=<name>`.
  * Generate the main project `README.md` from a template.
