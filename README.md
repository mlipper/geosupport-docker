# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## Latest Release

**Version 2.0.5** [release notes](./2.0.5/README-2.0.5.md).

## Dockerfile.dist

Provides distribution image built from `scratch` which contains only a patched and repackaged version of Geosupport allowing for full control and configuration from an unrelated Dockerfile. E.g., simplified creation of volumes and "data-packed volume containers".

```Dockerfile
FROM some-image:latest

ENV GEOSUPPORT_FULL_VERSION "22c_22.3"

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
$ docker run -it --rm geosupport-docker:latest geosupport-docker goat


------------------------------------------------------------------------------------------
*****  Enter a function code or 'X' to exit:  hr
You entered hr


Function HR GRC = 00
...etc.
```

However, the most common usage of this `Dockerfile` is for creating a volume containing a complete Geosupport installation directory.

```sh
# Create a named volume using the Docker CLI
$ docker volume create geosupport-22c_22.3
geosupport-22c_22.3

# Populate the volume with the contents of GEOSUPPORT_BASE (replace the default CMD with a simple no-op command)
$ docker run -it --rm --mount source=geosupport-22c_22.3,target=/opt/geosupport geosupport-docker:latest /bin/true

# Run an interactive bash shell in a new container to test the named volume
$ docker run -it --rm --mount source=geosupport-22c_22.3,target=/opt/geosupport debian:bullseye-slim bash
root@fc1d63c26dca# cd /opt/geosupport
root@fc1d63c26dca# ls -l
total 4
lrwxrwxrwx 1 root root   18 Nov 21 18:20 current -> version-22c_22.3
drwxr-xr-x 6 root root 4096 Nov 21 18:55 version-22c_22.3
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
   baseimage                      debian:bullseye-slim
   builddir                       build
   buildtimestamp                 Thu Jun 30 15:33:02 EDT 2022
   buildtz                        America/New_York
   dcp_distfile                   linux_geo22a2_22_11.zip
   distdir                        dist
   geosupport_basedir             /opt/geosupport
   geosupport_fullversion         22a2_22.11
   geosupport_major               22
   geosupport_minor               11
   geosupport_patch               2
   geosupport_release             a
   image_name                     geosupport-docker
   image_tag                      2.0.0
   vcs_ref                        9a6f56e
   ```

1. Generate a clean build:

   ```sh
   $ ./release.sh clean generate
   2022-06-30 15:43:28 [CLEAN] Removing build directory build...
   2022-06-30 15:43:28 [CLEAN] Build directory build removed.
   2022-06-30 15:43:28 [GENERATE] Generating source files from templates...
   2022-06-30 15:43:29 [GENERATE] Source file generation complete.
   ```

1. Review usage of the generated build script in the `build` directory:

   ```sh
   $ build/build.sh help

   Usage: build.sh COMMAND [OPTIONS]

   Build or remove geosupport-docker v2.0.0 images.
   Create or remove geosupport-docker v2.0.0 volumes.

   Commands:

     build         Builds geosupport-docker v2.0.0 to the local
                   registry using the following template:

                   [<repository>/]geosupport-docker:2.0.0[-<variant>]

               NOTES:

                   The --variant=default option is a special case in
                   which the template will be:

                   [<repository>/]geosupport-docker:2.0.0

                   Builds are always done against the local repository.
                   If the --repository option is not specified, the
                   image will be built as described above except the template
                   will not include a '<repository>/' prefix.

     createvol     Creates one or more named volumes whose names and
                   container directories are determined by the specified
                   --variants option.

     help          Show this usage message and exit.

     removeimage   Deletes one or more whose names are determined by the
                   specified --variants and/or --repository options.

     removevol     Deletes one or more named volumes whose names are
                   determined by the specified --variants option.

   Options:

     --latest      When given with the 'build' command, successfully built images
                   and image variants will then be tagged as 'latest(-<variant>)'.

                   When given with the 'removeimage' command, any image with a
                   matching 'latest(-<variant>)' tag will be removed.

                   Adding this argument takes into account whether '--repository'
                   arguments have been given by prefixing image names with the
                   specified repository values.

     --repository  Repository prefix to use. If not specified, 'local' is assumed.

     --tag         Image tag to use with build command. If not specified, image is
                   built with tag 2.0.0. If the '--latest' argument has
                   been provided, this image will also be tagged as
                   'latest(-<variant>)'.

     --variant     Image variant to build. This option can be specified
                   multiple times and order is important: see the DEPENDENCIES
                   note below.

                   The following variants are supported:

                   dist
                          image name: geosupport-docker:2.0.0-dist
                         volume name: geosupport-dist-22a2_22.11
                       volume source: /dist

                   default
                          image name: geosupport-docker:2.0.0
                         volume name: geosupport-dist-22a2_22.11
                       volume source: $GEOSUPPORT_HOME

                   If this option is not given, the specified action(s) is applied
                   to both 'dist' and 'default' variants. For the 'build' command,
                   order is: 'dist', 'default'. For the 'removeimage' command,
                   is: 'default', 'dist'.

               DEPENDENCIES:

                   Building the default variant requires that the dist variant
                   be available from the local repository. If dist is not available
                   already, use the following when building the variant:

                   build.sh --variant=dist --variant=default
   ```

## About Geosupport

Geosupport is the City of New York's official geocoder of record. The Geosupport application (for Linux, Windows and z/OS) is written and maintained by the New York City [Department of City Planning](http://www1.nyc.gov/site/planning/index.page).
