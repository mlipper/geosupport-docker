# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## Latest Release

**Version 2.0.8** [release notes](./2.0.8/README-2.0.8.md).

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

Provides a fully functional Geosupport installation which, by default, is built from image `debian:bookworm-slim`. This `Dockerfile` unpacks, installs and configures Geosupport.

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
$ docker volume create geosupport-23a_23.1
geosupport-23a_23.1

# Populate the volume with the contents of GEOSUPPORT_BASE (replace the default CMD with a simple no-op command)
$ docker run -it --rm --mount source=geosupport-23a_23.1,target=/opt/geosupport geosupport-docker:latest /bin/true

# Run an interactive bash shell in a new container to test the named volume
$ docker run -it --rm --mount source=geosupport-23a_23.1,target=/opt/geosupport debian:bookworm-slim bash
root@fc1d63c26dca# cd /opt/geosupport
root@fc1d63c26dca# ls -l
total 4
lrwxrwxrwx 1 root root   18 Nov 21 18:20 current -> version-23a_23.1
drwxr-xr-x 6 root root 4096 Nov 21 18:55 version-23a_23.1
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
   mv dist/geo22a2_22.11.zip dist/linux_geo22a2_22_11.zip
   ```

1. Verify the configuration:

   ```sh
   $ ./release.sh show

   Property                       Value
   ------------------------------ ----------------------------------------
   baseimage                      debian:bookworm-slim
   builddir                       build
   buildtimestamp                 Wed Dec 21 14:28:15 EST 2022
   buildtz                        America/New_York
   dcp_distfile                   linux_geo22c_22_3.zip
   distdir                        dist
   geosupport_basedir             /opt/geosupport
   geosupport_fullversion         23a_23.1
   geosupport_major               22
   geosupport_minor               3
   geosupport_patch
   geosupport_release             c
   image_name                     geosupport-docker
   image_tag                      2.0.8
   repo_name                      mlipper
   vcs_ref                        c109251

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

   Build or remove mlipper/geosupport-docker v2.0.8 images.
   Create or remove mlipper/geosupport-docker v2.0.8 volumes.

   Commands:

     build         Builds mlipper/geosupport-docker v2.0.8 to the local
                   registry using the following template:

                   mlipper/geosupport-docker:2.0.8[-<variant>]

               NOTES:

                   The --variant=default option is a special case in
                   which the template will be:

                   mlipper/geosupport-docker:2.0.8

                   Builds are always done against the local repository.

     createvol     Creates one or more named volumes whose names are
                   specified by --volname for the "default" variant
                   and/or --distvolname for the "dist".

                   If --volname is not given and a volume is being created for
                   "default" variant, the name is defaulted to
                   "geosupport-23a_23.1".

                   If --distvolname is not given and a volume is being created
                   for "dist" variant, the name is defaulted to
                   "geosupport-dist-23a_23.1".

                   Volumes are created for images/container directories
                   specified or defaulted using the logic described below
                   for the --variants option.

     exportdist    Copy repackaged Geosupport distribution file
                   /dist/geosupport-23a_23.1.tgz to the
                   host directory specified by the --exportdir=<hostdir>
                   option.

                   If the --exportdir=<hostdir> option is not given, <hostdir>
                   defaults to '/path/to/geosupport-docker/out'.

     help          Show this usage message and exit.

     removeimage   Deletes one or more whose names are determined by the
                   specified --variants.

     removevol     Deletes one or more named volumes whose names are
                   specified by --volname for the "default" variant
                   and/or --distvolname for the "dist".

                   If --volname is not given and a volume is being deleted for
                   "default" variant, the name is defaulted to
                   "geosupport-23a_23.1".

                   If --distvolname is not given and a volume is being deleted
                   for "dist" variant, the name is defaulted to
                   "geosupport-dist-23a_23.1".

                   Volumes are deleted based on names specified and/or
                   default names generated using the logic described below
                   when using the --variants option.

   Options:

     --volname      The name for the volume created from the 'default'
                    variant.

     --distvolname  The name for the volume created from the 'dist'
                    variant.

     --exportdir    The host directory where the Geosupport distribution
                    file will be copied when running the 'exportdist' command.

                    If not given, defaults to '/path/to/geosupport-docker/out'.

     --latest       When given with the 'build' command, successfully built images
                    and image variants will then be tagged as 'latest(-<variant>)'.

                    When given with the 'removeimage' command, any image with a
                    matching 'latest(-<variant>)' tag will be removed.

     --variant      Image variant commands will operate on, dist or default.
                    When this option is not given, the default behavior is to
                    apply commands to both variants.

                    The default image variant is built from the dist image variant
                    and must be available from the local repository for certain
                    commands. See the DEPENDENCIES section below for more details.

                    Commands work as follows for each variant:

                    dist
                       build, removeimage
                           name: mlipper/geosupport-docker:2.0.8-dist
                       createvol, removevol
                           name: geosupport-dist-23a_23.1
                                 Use --distvolname=<name> to override
                         source: /dist


                    default
                       build, removeimage
                           name: mlipper/geosupport-docker:2.0.8
                       createvol, removevol
                           name: geosupport-23a_23.1
                                 Use --volname=<name> to override
                         source: $GEOSUPPORT_HOME

               DEPENDENCIES:

                   build
                       Order: build dist, build default

                       Building the default image variant requires that the
                       dist variant be available from the _local_ repository.
                       If it is not, the build will fail.

                   removeimage
                       Order: removeimage default, removeimage dist

                       Removing the dist image variant requires that the
                       default image variant be removed first because it
                       built from the dist variant. Trying to delete the
                       dist image variant when the default image variant
                       still exists will fail.

   ```

## About Geosupport

Geosupport is the City of New York's official geocoder of record. The Geosupport application (for Linux, Windows and z/OS) is written and maintained by the New York City [Department of City Planning](http://www1.nyc.gov/site/planning/index.page).
