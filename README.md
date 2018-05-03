# geosupport-docker

Dockerfiles for installing, configuring and using the NYC Department of City
Planning's Geosupport application from a Docker container.

Provides `ONBUILD` base image, standalone installation and simplified creation
of volumes and "data-packed volume containers" with Docker.

## About Geosupport

Geosupport is the City of New York's official geocoder of record. The
Geosupport application (for Linux, Windows and z/OS) is written and maintained
by the New York City [Department of City Planning](http://www1.nyc.gov/site/planning/index.page).

### Download Geosupport for Linux from DCP Site

For most scenarios, working with `geosupport-docker` requires that you have a
copy of the compressed Geosupport for Linux distribution in the build directory
in order to have the application copied/installed to/on whatever image/container
you are working on.

Geosupport is free to downloaded from the [Open Data -> Geocoding Application](http://www1.nyc.gov/site/planning/data-maps/open-data.page#geocoding_application)"
section of DCP's site. **Note:** *DCP requires a form be filled out **every**
time you download anything.*

Remember to download the **Linux** distribution as the Windows flavors will
not work for this project. Don't be surprised if the description refers to the
"Geosupport Desktop Edition&trade;". As long as it's the Linux 64 bit
distribution (`gdelx_<version>.zip`), you are good to go.

**IMPORTANT:** Save the downloaded zip file (`gdelx_<version>.zip`) to the
directory containing the Dockerfile for the image/container you are going to
buid/run.

## Dockerfile.onbuild

Base `ONBUILD` image which defers the decompression and configuration
of a Geosupport Linux distribution (`DISTFILE`) to the extending image.

This image requires that the `DISTFILE` be supplied by the extending image author
and that the file be in the same directory as that author's Dockerfile (build 
context).

This image intentionally does NOT declare a volume so that extending images
can further modify the filesystem and/or decide whether or not to persist the
`GEOSUPPORT_HOME` as a `VOLUME`.

    Note: The compressed Geosupport Linux zip file is almost 200M and the 
          uncompressed size of the installation is over 2G.

Dockerfile which uses this as its base image:

    FROM geoclient-docker-onbuild:latest
    ...
    # Commands that change the filesystem under GEOSUPPORT_HOME you want
    # included in the resulting volume
    ...
    VOLUME ["$GEOSUPPORT_HOME"]
    ...

BUILD:

  ARG [OPTIONAL]:

    [--build-arg GEOSUPPORT_RELEASE=<release>]  # Geosupport data release
                                                # If not set/given, an
                                                # environment variable
                                                # of the same name is used.

    [--build-arg GEOSUPPORT_VERSION=<version>]  # Geosupport code version
                                                # If not set/given, an
                                                # environment variable
                                                # of the same name is used.

  EXAMPLES:

    # Defaulted latest, stable GEOSUPPORT_VERSION and GEOSUPPORT_RELEASE
    $ docker build -t mlipper/geosupport-docker:latest-onbuild
    ...

    # "Pre-baked" Geosupport distribution
    $ docker build -t mlipper/geosupport-docker:<gs_release_gs_version>-onbuild \
                  --build-arg GEOSUPPORT_RELEASE=<gs_release> \
                  --build-arg GEOSUPPORT_VERSION=<gs_version>
    ...
RUN:

  ENV:

    -e GEOSUPPORT_RELEASE=<release>   # Geosupport data release.
                                      # Can also be given as a build arg.

    -e GEOSUPPORT_VERSION=<version>   # Geosupport code version.
                                      # Can also be given as a build arg.

    -e GEOSUPPORT_HOME=<path>         # Defaults to /opt/geosupport

    -e DISTFILE=<file>                # DCP's compressed (.zip) Geosupport
                                      # for Linux. Defaults to:
                                      # gdelx_${GEOSUPPORT_RELEASE}.zip

Because Docker's `COPY` instruction is used to copy the specified `DISTFILE`
into the container, it must be in or under the extending image's build context
directory.

## Dockerfile.dvc

Dockerfile which simplifies creating and/or populating Docker `VOLUME`s meant to be shared by multiple containers. This is often helpful in production environments; e.g., to upgrade Geosupport library and data files without stopping app containers using these volumes via Docker's logical reference functionality.

Inspired by the ["data-packed volume container"](https://medium.com/on-docker/data-packed-volume-containers-distribute-configuration-c23ff80> as described by author Jeff Nickoloff in his book [Docker in Action](https://www.manning.com/books/docker-in-action).

EXAMPLES:

  BUILD `latest-dvc`

    # Uses 'latest' for parent image by default                          
    $ docker build -t mlipper/geosupport-docker:latest-dvc -f Dockerfile.dvc .

  RUN `latest-dvc`
  
    # Start a "data volume container" which creates and populates a shareable volume
    $ docker run -d --name geosupport \
                    --mount src=vol-geosupport,target=/opt/geosupport mlipper/geosupport-docker:latest-dvc

  BUILD `<version>-dvc`

    # Use '--build-arg' to reference the correct parent image
    $ V=18a1_18.1; docker build -t mlipper/geosupport-docker:${V}-dvc \
                    --build-arg GSD_VERSION=${V} -f Dockerfile.dvc .

  RUN `version>-dvc`

    # Start a "data volume container" which creates and populates a shareable volume
    $ V=18a1_18.1; docker run -d --name geosupport \
                    --mount src=vol-geosupport,target=/opt/geosupport mlipper/geosupport-docker:${V}-dvc

## Dockerfile

EXAMPLES:

  BUILD `latest`

    # Uses 'latest' for parent image by default                        
    $ docker build -t mlipper/geosupport-docker .

  RUN `latest`

    # Run the Geosupport CLI
    $ docker run -d --name geosupport mlipper/geosupport-docker:latest

  BUILD `<version>`

    # Use '--build-arg' to reference the correct parent image
    $ docker build -t mlipper/geosupport-docker:18a1_18.1 --build-arg GSD_VERSION=18a1_18.1 .

  RUN `<version>`

    # Run the Geosupport CLI
    $ docker run -d --name geosupport mlipper/geosupport-docker:18a1_18.1
