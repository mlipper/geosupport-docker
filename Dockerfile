#
# BUILD
#
#   # Uses 'latest' for parent image by default
#   $ docker build -t mlipper/geosupport-docker .
#
#   # Uses '1.0.1' for parent image
#   $ docker build --build-arg GSD_VERSION=1.0.1 -t mlipper/geosupport-docker:1.0.1 .
#
# RUN
#
#   # Run the Geosupport CLI (i.e. "goat")
#   $ docker run -it --rm geosupport mlipper/geosupport-docker goat
#
#   # Create a "data volume container" to populate a shareable volume
#   $ docker run -d --name geosupport \
#                   --mount src=vol-geosupport,target=/opt/geosupport \
#                   mlipper/geosupport-docker
#
ARG GSD_VERSION=latest
FROM mlipper/geosupport-docker:${GSD_VERSION}-onbuild
LABEL maintainer "Matthew Lipper <mlipper@gmail.com>"
VOLUME ["$GEOSUPPORT_HOME"]
