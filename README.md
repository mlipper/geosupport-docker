# geosupport-docker

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

Provides `ONBUILD` base image and standalone installations which allow simplified creation of volumes and "data-packed volume containers".

## About Geosupport

Geosupport is the City of New York's official geocoder of record. The Geosupport application (for Linux, Windows and z/OS) is written and maintained by the New York City [Department of City Planning](http://www1.nyc.gov/site/planning/index.page).

### NEWS

The latest news about this project.

#### June 9th, 2018

* **Versioning policy changed:** this project will no longer mimic Geosupport's `<year>.<alpha><patch>_<year>.<quarter><patch>` release/version naming convention. Instead, Docker image versioning will follow the basic approach recommended by [Semantic Versioning](https://semver.org/). The next official release will be tagged version `1.0.0` and contain DCP's Geosupport `18a1_18.1`. Docker labels `gsrelease` and `gsversion` will be used to provide Geosupport version metadata.
* **ONBUILD and default `Dockerfile`s now include Geosupport install:** the `Dockerfile.onbuild` file has been updated so that the image now includes the ~300MB Geosupport Linux distribution zip file. When using this as a parent image or the default `Dockerfile` image definition, it is no longer necessary to download this file from DCP as described below.
* **New `alpine` based image:** the `Dockerfile.alpine` file defines a image based on the popular `alpine` project.

### Download Geosupport for Linux from DCP Site

For some image flavors, working with `geosupport-docker` requires that you have a copy of the compressed Geosupport for Linux distribution in the build directory in order to have the application copied/installed to/on whatever image/container you are working on.

Geosupport is free to downloaded from the [Open Data -> Geocoding Application](http://www1.nyc.gov/site/planning/data-maps/open-data.page#geocoding_application)" section of DCP's site. **Note:** *DCP requires a form be filled out **every** time you download anything.*

Remember to download the **Linux** distribution as the Windows flavors will not work for this project. Don't be surprised if the description refers to the "Geosupport Desktop Edition&trade;". As long as it's the Linux 64 bit distribution (`gdelx_<version>.zip`), you are good to go.

**IMPORTANT:** Save the downloaded zip file (`gdelx_<version>.zip`) to the directory containing the Dockerfile for the image/container you are going to build/run.

## Dockerfile.onbuild

Base `ONBUILD` image which defers the decompression and configuration of a Geosupport Linux distribution (`DISTFILE`) to the extending image.

This image now includes the `DISTFILE` containing the zipped Geosupport software and no longer needs to be in the same directory as that author's Dockerfile (build context).

This image intentionally does NOT declare a volume so that extending images can further modify the filesystem and/or decide whether or not to persist the `GEOSUPPORT_HOME` as a `VOLUME`.

    Note: The compressed Geosupport Linux zip file is almost 200M and the uncompressed size of the installation is over 2G.

Dockerfile which uses this as its base image:

    FROM geoclient-docker-onbuild:latest
    ...
    # Commands that change the filesystem under GEOSUPPORT_HOME you want
    # included in the resulting volume
    ...
    VOLUME ["$GEOSUPPORT_HOME"]
    ...

Because Docker's `COPY` instruction is used to copy the specified `DISTFILE` into the container, it must be in or under the extending image's build context directory.

See the comments in [Dockerfile.onbuild](https://github.com/mlipper/geosupport-docker/blob/master/Dockerfile.onbuild) for more details.

## Dockerfile

Dockerfile which can be used to run Geosupport interactively from the command line or to simplify the creation and population of Docker `VOLUME`s meant to be shared by multiple containers. This is often helpful in production environments; e.g., to upgrade Geosupport library and data files without stopping app containers using these volumes via Docker's logical reference functionality. Inspired by the ["data-packed volume container"](https://medium.com/on-docker/data-packed-volume-containers-distribute-configuration-c23ff80) as described by author Jeff Nickoloff in his book [Docker in Action](https://www.manning.com/books/docker-in-action).

See the comments in [Dockerfile.onbuild](https://github.com/mlipper/geosupport-docker/blob/master/Dockerfile) for more details.

## Dockerfile.apline

Similar to the pervious `Dockerfile` except built from `alpine:latest` parent image, offering a smaller footprint. Note, `apline` uses the `musl` C Runtime which do not seem to be a problem for the Geosupport libraries.
