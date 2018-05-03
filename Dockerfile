#
# EXAMPLES:
#
#   BUILD `latest`
#
#     # Uses 'latest' for parent image by default
#     $ docker build -t mlipper/geosupport-docker .
#
#   RUN `latest`
#
#     # Run the Geosupport CLI
#     $ docker run -d --name geosupport mlipper/geosupport-docker:latest
#
#   BUILD `<version>`
#
#     # Use '--build-arg' to reference the correct parent image
#     $ docker build -t mlipper/geosupport-docker:18a1_18.1 --build-arg GSD_VERSION=18a1_18.1 .
#
#   RUN `<version>`
#
#     # Run the Geosupport CLI 'goat'
#     $ docker run -d --name geosupport mlipper/geosupport-docker:18a1_18.1
#
ARG GSD_VERSION=latest
FROM mlipper/geosupport-docker:${GSD_VERSION}-onbuild
LABEL maintainer "Matthew Lipper <mlipper@gmail.com>"

VOLUME ["$GEOSUPPORT_HOME"]

CMD ["goat"]
