# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

The latest news about this project.

### December 21st, 2022

* **Version 2.0.6 available.** This release wraps `Geosupport 22c_22.3`.

  **CHANGES:**

  * Upgraded the default base image for all variants from
    `debian:bullseye-slim` to `debian:bookworm-slim`.

  * Replaced use of `--repository` flag in the generated `build.sh` with
    `repo_name` property in `release.conf`.

    Use of `--repository` in the generated build script was problematic
    because the generated default variant of this project used the following
    instruction:

    ```Dockerfile
    ...
    COPY --from=geosupport-docker:<tag>-dist`
               ^
        # No repository prefix!
    ...
    ```

    No repository prefix was used and so was never available from
    Docker Hub.

    Instead, the `repo_name` property has been added to `release.conf`,
    thus allowing the generated build script to include a valid repository
    prefix.

    It is still possible to generate a build script using a custom
    repository prefix by using the `-p` flag to override the default:

    ```bash
    ./release.sh -p repo_name=abc generate
    ```

    The generated build script from above will build the following variants:

    * `abc/geosupport-docker:<tag>-dist`
    * `abc/geosupport-docker:<tag>`

  * Removed Geosupport version suffix from the compressed archive built by the `dist` variant.
    This allows for simpler use from other images since it no longer requires knowledge of the
    exact Geosupport release and version.

    Before (2.0.5 and earlier):

    ```Dockerfile
    FROM some-image:latest

    ENV GEOSUPPORT_FULL_VERSION "22c_22.3"

    # Get the Geosupport distro
    COPY --from=geosupport-docker:latest-dist /dist/geosupport-${GEOSUPPORT_FULL_VERSION}.tgz /geosupport.tgz

    # Do whatever I want with it...
    ...
    ```

    After (2.0.6+):

    ```Dockerfile
    FROM someimage:latest

    # Get the Geosupport distro
    COPY --from=mlipper/geosupport-docker:latest-dist /dist/geosupport.tgz /opt/geosupport/geosupport.tgz

    # Do whatever I want with it...
    ...
    ```

  * Moved `LABEL`s from `builder` stage to final stage in `dist` variant since
    they were not being included in the final image.
