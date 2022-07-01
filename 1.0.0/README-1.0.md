# geosupport-docker

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

Provides `ONBUILD` base image and standalone installations which allow simplified creation of volumes and "data-packed volume containers".

## About Geosupport

Geosupport is the City of New York's official geocoder of record. The Geosupport application (for Linux, Windows and z/OS) is written and maintained by the New York City [Department of City Planning](http://www1.nyc.gov/site/planning/index.page).

### NEWS

The latest news about this project.

#### August 27th, 2020

* **Version 1.0.11 available.** This release wraps `Geosupport 20c_20.3`.
* **Version 1.0.10 available.** This release wraps `Geosupport 20b_20.2`.

 **CHANGES:**

  > * Retroactive release of `Geosupport 20b_20.2`.
  > * Retroactive update of `README.md` file to clarify release history.

#### March 2nd, 2020

* **Version 1.0.9 available**

  **CHANGES:**

  > * Rename default Geosupport distribution file to `linux_geo<release>_<version>.zip` to match name when downloading from public DCP site.
  > * Add support for detecting distribution file compressed using tar and gzip (`.tgz`).
  > * Remove `etc` directory.
  > * Remove Docker build argument options `ARG GEOSUPPORT_RELEASE` and `ARG GEOSUPPORT_VERSION`.
  > * Add Docker build argument and environment variable `GEOSUPPORT_LDCONFIG` set to `true` by default.
  > * Move long comments in Dockerfiles to `README.md`.

  **NOTE:**

  > * _2020-08-27: added this section for clarity._
  > * This release is the same as `1.0.8` except as noted by above. The diff is available [here](https://github.com/mlipper/geosupport-docker/commit/3269bf2e41d8301c25d2a6d7e73e79e8dc3ccdab)

#### February 26th, 2020

* **Version 1.0.8 available.** This release wraps `Geosupport 20a_20.1`.

#### December 6th, 2019

* **Version 1.0.7 available**

  **CHANGES:**

  > * Upgrade base image from `debian:stretch` to `debian:buster-slim`

#### December 5th, 2019

* **Version 1.0.6 available.** This release wraps `Geosupport 19d_19.4`.

#### October 22nd, 2019

* **Version 1.0.5 available.** This release wraps `Geosupport 19c_19.3`.

  **CHANGES:**

  > * Renamed environment variable `DISTFILE` to `GEOSUPPORT_DISTFILE`.
  > * Added Docker label `version` to capture this project's version (as opposed to the Geosupport release/version).
  > * Created new Docker env file `geosupport.env` which can be referenced from the commandline with `docker-compose` and `docker run`. See [Declare default environment variables in file](https://docs.docker.com/compose/env-file/)

#### June 23rd, 2019

* **Version 1.0.4 available.** This release wraps `Geosupport 19b_19.2`.

#### April 23rd, 2019

* **Version 1.0.3 available.** This release wraps `Geosupport 19a1_19.1`.

#### February 24th, 2019

* **Version 1.0.2 available.** This release wraps `Geosupport 19a_19.1`.
* **Version 1.0.1 available.** This release wraps `Geosupport 18d_18.4`.

#### June 9th, 2018

* **Versioning policy changed:** this project will no longer mimic Geosupport's `<year>.<alpha><patch>_<year>.<quarter><patch>` release/version naming convention. Instead, Docker image versioning will follow the basic approach recommended by [Semantic Versioning](https://semver.org/). The next official release will be tagged version `1.0.0` and contain DCP's Geosupport `18a1_18.1`. Docker labels `gsrelease` and `gsversion` will be used to provide Geosupport version metadata.
* **ONBUILD and default `Dockerfile`s now include Geosupport install:** the `Dockerfile.onbuild` file has been updated so that the image now includes the ~300MB Geosupport Linux distribution zip file. When using this as a parent image or the default `Dockerfile` image definition, it is no longer necessary to download this file from DCP as described below.
* **New `alpine` based image:** the `Dockerfile.alpine` file defines a image based on the popular `alpine` project.

### Download Geosupport for Linux from DCP Site

For some image flavors, working with `geosupport-docker` requires that you have a copy of the compressed Geosupport for Linux distribution in the build directory in order to have the application copied/installed to/on whatever image/container you are working on.

Geosupport is free to downloaded from the [Open Data -> Geocoding Application](http://www1.nyc.gov/site/planning/data-maps/open-data.page#geocoding_application)" section of DCP's site. **Note:** _DCP requires a form be filled out **every** time you download anything._

Remember to download the **Linux** distribution as the Windows flavors will not work for this project. Don't be surprised if the description refers to the "Geosupport Desktop Edition&trade;". As long as it's the Linux 64 bit distribution (currently named something like `linux_geo<release>_<version>.zip`), you are good to go.

**IMPORTANT:** Save the downloaded zip file to the directory containing the Dockerfile for the image/container you are going to build/run. Pay attention to the file name because it may not match the default used when building the `-onbuild` image. In that case, use the `-e GEOSUPPORT_DISTFILE=<file>` argument when invoking `$ docker build ...`.

## Dockerfile.onbuild

Base `ONBUILD` image which defers the decompression and configuration of a Geosupport Linux distribution (`GEOSUPPORT_DISTFILE`) to the extending image.

This image now includes the `GEOSUPPORT_DISTFILE` containing the zipped Geosupport software and no longer needs to be in the same directory as that author's Dockerfile (build context).

This image intentionally does NOT declare a volume so that extending images can further modify the filesystem and/or decide whether or not to persist the `GEOSUPPORT_HOME` as a `VOLUME`.

    NOTE:  The compressed Geosupport Linux zip file is almost 200M and the uncompressed
           size of the installation is over 2G.

Dockerfile which uses this as its base image:

    FROM geoclient-docker-onbuild:latest
    ...
    # Commands that change the filesystem under GEOSUPPORT_HOME you want
    # included in the resulting volume
    ...
    VOLUME ["$GEOSUPPORT_HOME"]
    ...

Because Docker's `COPY` instruction is used to copy the specified `GEOSUPPORT_DISTFILE` into the container, it must be in or under the extending image's build context directory.

**BUILD:**

```sh
#
# Example: build version 1.0.11
#
$ docker build -t mlipper/geosupport-docker:1.0.11-onbuild --build-arg GSD_VERSION=1.0.11 -f Dockerfile.onbuild .
```

**BUILD ARGUMENTS:**

```sh
--build-arg GSD_VERSION=<project_version> # REQUIRED
                                          # Version of this project.

--build-arg GEOSUPPORT_LDCONFIG=true      # When specified with _any_value_
                                          # (e.g., specifiying "false" will be
                                          # interpereted as "true"),
                                          # the initenv shell script will use
                                          # ldconfig to make the Geoclient shared
                                          # libraries visible to the dynamic linker
                                          # at runtime. Any other value, including
                                          # an empty string or null will be
                                          # understood as "false".
                                          #
                                          # Defaults to true. To export the
                                          # LD_LIBRARY_PATH instead, supply
                                          # this build-arg as shown above except
                                          # remove the value 'true':
                                          # '--build-arg GEOSUPPORT_LDCONFIG='
                                          #
                                          # The value of environment variable
                                          # GS_LIBRARY_PATH (default: /opt/geosupport/lib)
                                          # is used when invoking ldconfig.

--build-arg GEOSUPPORT_VERSION=<version>  # Geosupport code version
                                          # If not set/given, an
                                          # environment variable
                                          # of the same name is used.
```

**ENVIRONMENT VARIABLES:**

```sh
-e GEOSUPPORT_RELEASE=<release>  # Geosupport data release.
                                 # Can also be given as a build arg.

-e GEOSUPPORT_VERSION=<version>  # Geosupport code version.
                                 # Can also be given as a build arg.

-e GEOSUPPORT_HOME=<path>        # Defaults to /opt/geosupport

-e GEOSUPPORT_DISTFILE=<file>    # DCP's compressed (.zip) Geosupport
                                 # for Linux. Defaults to:
                                 # linux_geo${GEOSUPPORT_RELEASE}_${GEOSUPPORT_VERSION}.zip

-e GEOSUPPORT_LDCONFIG=<true>    # See the description of the build argument with the same
                                 # above.
```

When building this image from source, the zip file downloaded from DCP's site may need to be renamed for the default `GEOSUPPORT_DISTFILE` name to match.

Because Docker's COPY instruction is used to copy the specified `GEOSUPPORT_DISTFILE` into the container, it must be in or under Docker's build context directory (i.e, the same directory as this file).

**NOTES:**
Geosupport is a free download from NYC Dept. of City Planning's site. Make sure to choose the 64 bit Linux version.

> See DCP's [Open Data](http://www1.nyc.gov/site/planning/data-maps/open-data.page) site.

**USAGE:**
Base image to install and configure a provided Geosupport Linux distribution on with sensible defaults.

This image does NOT declare a volume which can be useful given the uncompressed size of Geosupport tends to be over 2G (e.g., for use with --volumes-from).

With that in mind, consider adding the following to your Dockerfile which uses this as its base image:

```Dockerfile
FROM geoclient-docker:latest-onbuild
...
# Commands that change the filesystem you want in the volume
...
VOLUME ["$GEOSUPPORT_HOME"]
...
```

See [Dockerfile.onbuild](./Dockerfile.onbuild) for for the source.

## Dockerfile

Dockerfile which can be used to run Geosupport interactively from the command line or to simplify the creation and population of Docker `VOLUME`s meant to be shared by multiple containers. This is often helpful in production environments; e.g., to upgrade Geosupport library and data files without stopping app containers using these volumes via Docker's logical reference functionality. Inspired by the ["data-packed volume container"](https://medium.com/on-docker/data-packed-volume-containers-distribute-configuration-c23ff80) as described by author Jeff Nickoloff in his book [Docker in Action](https://www.manning.com/books/docker-in-action).

**BUILD:**

```sh
# Uses 'latest' for parent image by default
$ docker build -t mlipper/geosupport-docker .

# Uses '1.0.11' for parent image
$ docker build --build-arg GSD_VERSION=1.0.11 -t mlipper/geosupport-docker:1.0.11 .
```

**RUN:**

```sh
# Run the Geosupport CLI (i.e. "goat") using version 1.0.11 of this image
$ docker run -it --rm mlipper/geosupport-docker:1.0.11 goat

# Create a "data volume container" to populate a shareable volume and exit
$ docker run --name geosupport --mount src=vol-geosupport,target=/opt/geosupport mlipper/geosupport-docker:1.0.11

# Same as above but use -it switches for interactive bash shell (from parent's default CMD)
$ docker run -it --name geosupport --mount src=vol-geosupport,target=/opt/geosupport mlipper/geosupport-docker:1.0.11
```

See [Dockerfile](./geosupport-20c_20.3/onbuild/Dockerfile) for the source.
