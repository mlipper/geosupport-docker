# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## Latest Release

**Version 2.0.17** [release notes](./2.0.17/README-2.0.17.md).

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
$ docker volume create geosupport-23c_23.3
geosupport-23c_23.3

# Populate the volume with the contents of GEOSUPPORT_BASE (replace the default CMD with a simple no-op command)
$ docker run -it --rm --mount source=geosupport-23c_23.3,target=/opt/geosupport geosupport-docker:latest /bin/true

# Run an interactive bash shell in a new container to test the named volume
$ docker run -it --rm --mount source=geosupport-23c_23.3,target=/opt/geosupport ubuntu:jammy bash
root@fc1d63c26dca# cd /opt/geosupport
root@fc1d63c26dca# ls -l
total 4
lrwxrwxrwx 1 root root   18 Nov 21 18:20 current -> version-23c_23.3
drwxr-xr-x 6 root root 4096 Nov 21 18:55 version-23c_23.3
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

This project is built using the `release.sh` script in the root project directory (`<project_dir>`).

These instructions assume you are using `bash` and your current working directory is `<project_dir>`:

1. Configure `release.conf` with the correct Geosupport version information. See section "About Geosupport Versions" above for details.

1. Create the `dist` directory:

   ```sh
   mkdir -p dist
   ```

1. Download the Linux distribution of Geosupport from the Department of City Planning's [Open Data](https://www1.nyc.gov/site/planning/data-maps/open-data.page#geocoding_application) page into the `dist` directory.

1. If necessary, rename the downloaded `zip` file to follow the expected naming convention:

   ```sh
   mv dist/geo23c_23.3.zip dist/linux_geo23c_23_3.zip
   ```

1. Verify the configuration:

   ```sh
   $ ./release.sh show

   Property                       Value
   ------------------------------ ----------------------------------------
   baseimage                      ubuntu:jammy
   builddir                       build
   buildtimestamp                 Fri Apr 28 13:28:42 EDT 2023
   buildtz                        America/New_York
   dcp_distfile                   linux_geo23c_23_3.zip
   distdir                        dist
   geosupport_basedir             /opt/geosupport
   geosupport_fullversion         23c_23.3
   geosupport_major               23
   geosupport_minor               2
   geosupport_patch
   geosupport_release             b
   image_name                     geosupport-docker
   image_tag                      2.0.12
   repo_name                      mlipper
   vcs_ref                        e3c2622

   Actions
   ------------------------------
   show
   ```

1. Generate a clean build:

   ```sh
   $ ./release.sh clean generate
   2022-12-21 14:43:28 [CLEAN] Removing build directory build...
   2022-12-21 14:43:28 [CLEAN] Build directory build removed.
   2022-12-21 14:43:28 [GENERATE] Generating source files from templates...
   2022-12-21 14:43:29 [GENERATE] Source file generation complete.
   ```

1. Review usage of the generated build script in the `build` directory:

   ```bash
   build/build.sh help
   ```

   ```man

   Usage: build.sh COMMAND [OPTIONS]

   Build images, create or export volumes for mlipper/geosupport-docker v2.0.12.

   Commands:

     build         Builds image version 2.0.12 of mlipper/geosupport-docker.

       Options:    --variant=<name> (optional)

                   Specifies that only variant "<name>" be built.

                   If the --variant option has not been given, both are built.
                   Builds are always done against the local repository.

                   --variant=dist
                   Builds image mlipper/geosupport-docker:2.0.12-dist

                   --variant=default
                   Builds image mlipper/geosupport-docker:2.0.12

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
                   directory in image mlipper/geosupport-docker:2.0.12
                   (i.e., the "default" variant).

       Options:    --volname=<name> (optional)

                   The "<name>" to use when creating the volume.
                   If --volname is not given, the name is defaulted to
                   "geosupport-23c_23.3".

     exportdist    Copy repackaged Geosupport distribution file from image
                   mlipper/geosupport-docker:2.0.12-dist
                   to a host directory.

       Options:    --exportdir=<name> (optional)

                   The host directory where the repackaged Geosupport distribution
                   file will be copied when running the "exportdist" command.

                   If not given, defaults to "/Users/mlipper/Workspace/github.com/mlipper/geosupport-docker/out/2.0.12".

     help          Show this usage message and exit.

   ```

## About Geosupport

Geosupport is the City of New York's official geocoder of record. The Geosupport application (for Linux, Windows and z/OS) is written and maintained by the New York City [Department of City Planning](http://www1.nyc.gov/site/planning/index.page).
