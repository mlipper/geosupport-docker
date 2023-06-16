# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

The latest news about this project.

### June 16, 2023

* **Version 2.0.10 available.** This release wraps `Geosupport 23b_23.2`.

  **CHANGES:**

  * New features for generated `geosupport` script:

    > * Ability to dynamically determine Geosupport environment based on filesystem location.
    > * Ability to create 'current' symlink for GEOSUPPORT_HOME without having to install in /usr/local.

  * Automate creation of release folder. Note, this `README-<version>.md` file still needs the actual content to be updated manually.
