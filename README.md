# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## Latest Release

**Version 2.0.33** [release notes](./2.0.33/README-2.0.33.md).

## Dockerfile.dist

Provides distribution image built from `scratch` which contains only a patched and repackaged version of Geosupport allowing for full control and configuration from an unrelated Dockerfile. E.g., simplified creation of volumes and "data-packed volume containers".

```Dockerfile
FROM someimage:latest

# Get the Geosupport distro
COPY --from=mlipper/geosupport-docker:latest-dist \
                  /dist/geosupport.tgz \
                  /opt/geosupport/geosupport.tgz

# Do whatever I want with it...
...
```

## Dockerfile

Provides a fully functional Geosupport installation which, by default, is built from image `ubuntu:jammy`. This `Dockerfile` unpacks, installs and configures Geosupport.

The default `CMD` simply prints Geosupport and geosupport-docker version information.

```sh
docker run -it --rm geosupport-docker:latest
```

To run DCP's CLI application for interacting with Geosupport from the command line, use the `geosupport` command with the `goat` argument:

```sh
docker run -it --rm geosupport-docker:latest geosupport goat


------------------------------------------------------------------------------------------
*****  Enter a function code or 'X' to exit:  hr
You entered hr


Function HR GRC = 00
...etc.
```

To see what other functionality the `geosupport` command provides, run:

```sh
docker run -it --rm geosupport-docker:latest geosupport help
```

However, the most common usage of this `Dockerfile` is for creating a volume containing a complete Geosupport installation directory.

```sh
# Create a named volume using the Docker CLI
$ docker volume create geosupport-26b_26.2
geosupport-26b_26.2

# Populate the volume with the contents of GEOSUPPORT_BASE (replace the default CMD with a simple no-op command)
$ docker run -it --rm --mount source=geosupport-26b_26.2,target=/opt/geosupport geosupport-docker:latest /bin/true

# Run an interactive bash shell in a new container to test the named volume
$ docker run -it --rm --mount source=geosupport-26b_26.2,target=/opt/geosupport ubuntu:jammy bash
root@fc1d63c26dca# cd /opt/geosupport
root@fc1d63c26dca# ls -l
total 4
lrwxrwxrwx 1 root root   18 Nov 21 18:20 current -> version-26b_26.2
drwxr-xr-x 6 root root 4096 Nov 21 18:55 version-26b_26.2
```

### About Geosupport Versions

The Department of City Planning uses the term "release" to refer to data changes and the term "version" to refer to code changes.

The final Geosupport distriubtion is identified as follows:

```text
# Note the underscore and period literals

                             underscore
                                 |
<major_rel><minor_rel><patch_rel>_<major_ver>.<minor_ver>
                                             |
                                           period
```

* `major_rel` - Two-digit year
* `minor_rel` - Lowercase letter
* `patch_rel` - Zero or more digits (Optional postfix modifier)
* `major_ver` - Two-digit year
* `minor_ver` - One or more digits

For example, in the first quarter of 2022, DCP published the distribution for "Geosupport release 22a2 / version 22.11". In this case, the template above has the following values:

```text
22a2_22.11
```

* `major_rel`: "22"
* `minor_rel`: "a"
* `patch_rel`: "2"
* `major_ver`: "22"
* `minor_ver`: "11"

This project captures this information in the file `<project_dir>/release.conf`. Here are the relevant properties:

```properties
# Used for BOTH <major_rel> and <major_ver>
geosupport_major=22
# <minor_rel>
geosupport_release=a
# <patch_rel>
geosupport_patch=2
# <minor_ver>
geosupport_minor=11
```

**NOTE:** The `geosupport_patch` property in `<project_dir>/release.conf` is the only one of these properties that can be (and often is) empty.

## Building `geosupport-docker`

_For building these images on an architecture other than `amd64`, see section [Building on platforms other than `amd64`](#building-on-platforms-other-than-amd64) below._

This project is built using the `release.sh` script in the root project directory (`<project_dir>`). Most of the real work happens in other scripts which are built from templates in the `<project_dir>/templates` directory and generated to the `<project_dir>/build` directory.

**NOTE**: All build instructions that follow assume you are using `bash` and your current working directory is `<project_dir>` unless otherwise noted.

### Build Summary

Some build steps rely on the output of previous steps and must be built in a specifc order which will be noted. Some steps are not required to push built images to a registry and will marked optional.

| Step | Action                                                                                   | Dependencies | Required |
| ---- | ---------------------------------------------------------------------------------------- | ------------ | -------- |
| 1.   | Put the new Geosupport distribution in the `<project_dir>/dist` directory.               |              | true     |
| 2.   | Configure `<project_dir>/release.conf`.                                                  | step 1.      | true     |
| 3.   | Clean and regenerate the build script.                                                   | step 2.      | true     |
| 4.   | Build the distribution.                                                                  | step 3.      | true     |
| 5.   | Generate a new project release folder.                                                   | step 4.      | true     |
| 6.   | Create a volume.                                                                         | step 4.      | false    |
| 7.   | Export the distribution from the image/container to a compressed file on the filesystem. | step 4.      | false    |
| 8.   | Create a custom distribution and export it to a compressed file on the filesystem.       | step 7.      | false    |

### Build Details

1. **STEP 1.** - Put the new Geosupport distribution in the `<project_dir>/dist` directory:
   1. Create the `dist` directory if necessary:

      ```sh
      mkdir -p dist
      ```

   2. Download the Linux distribution of Geosupport from the Department of City Planning's [Open Data](https://www1.nyc.gov/site/planning/data-maps/open-data.page#geocoding_application) page into the `dist` directory.
   3. If necessary, rename the downloaded `zip` file to follow the expected naming convention `geo<release_version>.zip`. The convention is that all alphabetic characters are lowercase. For example, building Geosupport release 26b and version 26.2:

      ```sh
      mv dist/foo-GEO26B-26.2 dist/geo26b_26.2.zip
      ```

2. **STEP 2.** - Configure `<project_dir>/release.conf`:
   1. Update the Geosupport version information. See section [About Geosupport Versions](#about-geosupport-versions) above for details.
   2. Update the version of this project.

   **IMPORTANT**: Every new Geosupport version or alteration requires a new version of this project before it is pushed to a remote registry.

3. Clean and regenerate the build script:

   ```sh
   $ ./release.sh clean generate
   2026-05-03 13:27:55 [CLEAN] Removing build directory build...
   2026-05-03 13:27:55 [CLEAN] Build directory build removed.
   2026-05-03 13:27:55 [GENERATE] Generating source files from templates...
   2026-05-03 13:27:56 [GENERATE] Source file generation complete.
   ```

   Verify the configuration:

   ```sh
   $ ./release.sh show

   Property                       Value
   ------------------------------ ----------------------------------------
   baseimage                      ubuntu:noble
   builddir                       build
   builddrv_name                  amd64-driver
   buildtimestamp                 Sun May  3 13:51:05 EDT 2026
   buildtz                        America/New_York
   dcp_distfile                   geo26b_26.2.zip
   distdir                        dist
   geosupport_basedir             /opt/geosupport
   geosupport_fullversion         26b_26.2
   geosupport_major               26
   geosupport_minor               2
   geosupport_patch
   geosupport_release             b
   image_name                     geosupport-docker
   image_tag                      2.0.33
   release_date                   May 03, 2026
   release_majorminor             2.0
   repo_name                      mlipper

   Actions
   ------------------------------
   show
   ```

4. **STEP 4.** - Build the distribution:

   1. Review usage of the generated build script in the `build` directory:

      ```bash
      ./release.sh helpbuild
      ```

      **NOTE**: This is equivalent to running the help command directly using the generated build/build.sh file.

      ```man

      Usage: build.sh COMMAND [OPTIONS]

      Build images, create or export volumes for mlipper/geosupport-docker v2.0.33.

      Commands:

      build         Builds image version 2.0.33 of mlipper/geosupport-docker.

         Options:    --variant=<name> (optional)

                     Specifies that only variant "<name>" be built.

                     If the --variant option has not been given, both are built.
                     Builds are always done against the local repository.

                     --variant=dist
                     Builds image mlipper/geosupport-docker:2.0.33-dist

                     --variant=default
                     Builds image mlipper/geosupport-docker:2.0.33

                     When specifying only the "default" variant,
                     the "dist" variant must be available from the
                     local repository or the build will fail.

                     --latest (optional)

                     When given, tags built variants using the "latest" naming
                     convention.

                     If the "dist" has been built, creates tag
                     mlipper/geosupport-docker:latest-dist.

                     If the "default" has been built, creates tag
                     mlipper/geosupport-docker:latest.

      createvol     Creates a volume from the contents of the $GEOSUPPORT_BASEDIR
                     directory in image mlipper/geosupport-docker:2.0.33
                     (i.e., the "default" variant).

         Options:    --volname=<name> (optional)

                     The "<name>" to use when creating the volume.
                     If --volname is not given, the name is defaulted to
                     "geosupport-26b_26.2".

      exportdist    Copy repackaged Geosupport distribution file from image
                     mlipper/geosupport-docker:2.0.33-dist
                     to a host directory.

         Options:    --exportdir=<name> (optional)

                     The host directory where the repackaged Geosupport distribution
                     file will be copied when running the "exportdist" command.

                     If not given, defaults to "<root-project-dir>/out/2.0.33".

      help          Show this usage message and exit.

      ```

   2. Run the `build` command, optionally but typically with the `--latest` switch

      ```sh
      $ ./release.sh build --latest
      ```

5.   **STEP 5.** (Optional) - Generate a new project release folder

     ```sh
     ./release.sh release
     ```

6.   **STEP 6.** (Optional) - Create a volume

     ```sh
     ./release.sh createvol --volname=geosupport-latest
     ./release.sh custombasedir
     ```

7.   **STEP 7.** (Optional) - Export the distribution

     ```sh
     ./release.sh exportdist
     ```

8.   **STEP 8.** (Optional) - Create a custom distribution

     ```sh
     ./release.sh custombasedir
     ```

## Building on platforms other than `amd64`

> **WARNING**: THIS SECTION IS OUT OF DATE

If you are building this project on a platform other than `amd64` (e.g., macOS/Apple M-series chip: `arm64`), you may need to configure a new Docker `build driver` and update the `release.conf` file with it's name.

Here's an example using this project's default build driver name, "amd64-driver", and default build driver image option, "amd64/ubuntu":

```sh
docker buildx create \
--name=amd64-driver \
--driver=docker-container \
--driver-opt=image=amd64/ubuntu \
--use \
--bootstrap
```

If you use a different name, be sure to update the `release.conf` file property `builddrv_name`.

See [Docker container build driver](https://docs.docker.com/build/builders/drivers/docker-container/) for more details.

## About Geosupport

Geosupport is the City of New York's official geocoder of record. The Geosupport application (for Linux, Windows and z/OS) is written and maintained by the New York City [Department of City Planning](http://www1.nyc.gov/site/planning/index.page).
