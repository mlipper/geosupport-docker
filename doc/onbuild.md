# Using ONBUILD Dockerfiles

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
```
#
# Example: build version 1.0.11
#
$ docker build -t mlipper/geosupport-docker:1.0.11-onbuild --build-arg GSD_VERSION=1.0.11 -f Dockerfile.onbuild .
```

**BUILD ARGUMENTS:**
```
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
```
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

> See http://www1.nyc.gov/site/planning/data-maps/open-data.page

**USAGE:**
Base image to install and configure a provided Geosupport Linux distribution on with sensible defaults.

This image does NOT declare a volume which can be useful given the uncompressed size of Geosupport tends to be over 2G (e.g., for use with --volumes-from).

With that in mind, consider adding the following to your Dockerfile which uses this as its base image:

```
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

```
# Uses 'latest' for parent image by default
$ docker build -t mlipper/geosupport-docker .

# Uses '1.0.11' for parent image
$ docker build --build-arg GSD_VERSION=1.0.11 -t mlipper/geosupport-docker:1.0.11 .
```

**RUN:**

```
# Run the Geosupport CLI (i.e. "goat") using version 1.0.11 of this image
$ docker run -it --rm mlipper/geosupport-docker:1.0.11 goat

# Create a "data volume container" to populate a shareable volume and exit
$ docker run --name geosupport --mount src=vol-geosupport,target=/opt/geosupport mlipper/geosupport-docker:1.0.11

# Same as above but use -it switches for interactive bash shell (from parent's default CMD)
$ docker run -it --name geosupport --mount src=vol-geosupport,target=/opt/geosupport mlipper/geosupport-docker:1.0.11
```

See [Dockerfile](./Dockerfile) for the source.
