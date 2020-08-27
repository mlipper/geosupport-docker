#
# BUILD
#
#   # Uses 'latest' for parent image by default
#   $ docker build -t mlipper/geosupport-docker .
#
#   # Uses '1.0.10' for parent image
#   $ docker build --build-arg GSD_VERSION=1.0.10 -t mlipper/geosupport-docker:1.0.10 .
#
# RUN
#
#   # Run the Geosupport CLI (i.e. "goat") using version 1.0.10 of this image
#   $ docker run -it --rm mlipper/geosupport-docker:1.0.10 goat
#
#   # Create a "data volume container" to populate a shareable volume and exit
#   $ docker run --name geosupport --mount src=vol-geosupport,target=/opt/geosupport mlipper/geosupport-docker:1.0.10
#
#   # Same as above but use -it switches for interactive bash shell (from parent's default CMD)
#   $ docker run -it --name geosupport --mount src=vol-geosupport,target=/opt/geosupport mlipper/geosupport-docker:1.0.10
#
ARG GSD_VERSION=latest
FROM mlipper/geosupport-docker:${GSD_VERSION}-onbuild
LABEL maintainer "Matthew Lipper <mlipper@gmail.com>"
VOLUME ["$GEOSUPPORT_HOME"]
