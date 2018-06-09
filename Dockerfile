#
# BUILD
#
#   # Uses 'latest' for parent image by default
#   $ docker build -t mlipper/geosupport-docker .
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
