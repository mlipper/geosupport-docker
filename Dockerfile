FROM debian:stretch
LABEL maintainer "Matthew Lipper <mlipper@gmail.com>"

#
# BUILD:
#         $ docker build -t mlipper/geosupport-docker:<rel>_<ver> \
#               --build-arg gsrelease=<rel> \
#               --build-arg gsversion=<ver> \
#               --build-arg distfile=<zip>
#
#         <rel> Geosupport release (required)
#         <ver> Geosupport version (required)
#         <zip> Zip file (defaults to 'gdelx_<rel>.zip' in this directory)
#
#   USE:
#         # 1. Create a "data-packed volume container"
#         $ docker run -d --name geosupport-17c_17.3 mlipper/geosupport-docker:17c_17.3
#
#         # 2. Create your own container and reference the volume container
#         $ docker run --rm -it --name my-geocoder --volumes-from geosupport-17c_17.3 ubuntu:latest bash
#
#         # 3. Setup your container with the Geosupport environment variables
#              (GEOSUPPORT_HOME, GEOFILES, and GS_LIBRARY_PATH);
#              
#         #   3a. Just set Geosupport runtime variables and nothing else:
#             $ . /opt/geosupport/bin/initenv
#
#         #   3b. Set Geosupport runtime variables and add/export to LD_LIBRARY_PATH
#             $ . /opt/geosupport/bin/initenv libpath
#
#         #   3c. Set Geosupport runtime variables and use ldconfig (as root)
#             $ . /opt/geosupport/bin/initenv ldconfig
#
#      
ARG gsrelease="17c"
ARG gsversion="17.3"
ARG distfile="gdelx_${gsversion}.zip"

ENV DISTFILE ${DISTFILE:-$distfile}
ENV GEOSUPPORT_HOME ${GEOSUPPORT_HOME:-/opt/geosupport}
ENV GEOSUPPORT_RELEASE ${GEOSUPPORT_RELEASE:-$gsrelease}
ENV GEOSUPPORT_VERSION ${GEOSUPPORT_VERSION:-$gsversion}
ENV LANG C.UTF-8

COPY $DISTFILE /$DISTFILE

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR $GEOSUPPORT_HOME
RUN set -o errexit -o nounset \
  && echo "Installing Geosupport" \
  && unzip -qj /$DISTFILE "**/bin/*" -d $GEOSUPPORT_HOME/bin \
  && unzip -qj /$DISTFILE "**/lib/*" -d $GEOSUPPORT_HOME/lib \
  && unzip -qj /$DISTFILE "**/fls/*" -d $GEOSUPPORT_HOME/fls \
  && rm /$DISTFILE

ENV PATH $GEOSUPPORT_HOME/bin:$PATH
# Trailing backslash is required!
ENV GEOFILES $GEOSUPPORT_HOME/fls/

RUN set -o errexit -o nounset \
  && { \
    echo '#!/bin/bash'; \
    echo; \
    echo "export GEOSUPPORT_HOME=${GEOSUPPORT_HOME}"; \
    echo "export GEOFILES=${GEOFILES}"; \
    echo "export GS_LIBRARY_PATH=${GEOSUPPORT_HOME}/lib"; \
    echo; \
  } >> $GEOSUPPORT_HOME/bin/initenv \
  && chmod 755 $GEOSUPPORT_HOME/bin/initenv

VOLUME ["$GEOSUPPORT_HOME"]
