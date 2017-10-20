FROM debian:stretch
LABEL maintainer "Matthew Lipper <mlipper@gmail.com>"
#
# BUILD:
#
#         $ docker build -t mlipper/geosupport-docker:<release>_<version>
#
# OPTIONAL:
#
#         -e DISTFILE=<file>        # Defaults to "gdelx_${GEOSUPPORT_RELEASE}.zip"
#                                   # in the current directory.
#
#         -e GEOSUPPORT_HOME=<path> # Defaults to /opt/geosupport
#
# USE:
#         Interactive Geosupport command line:
#
#         1. By default, this image runs the Geosupport CLI
#
#            $ docker run -it --name geosupport-17c_17.3 mlipper/geosupport-docker:17c_17.3
#
#         As a "volume container" (for programmatic access from another container):
#
#         2. Create your own container and reference the volume created by #1.
#
#            $ docker run --rm -it --name my-geocoder --volumes-from geosupport-17c_17.3 ubuntu:latest bash
#
#         3. Setup your container with the Geosupport environment variables
#            (GEOSUPPORT_HOME, GEOFILES, GS_LIBRARY_PATH, and LD_LIBRARY_PATH);
#
#            $ . /opt/geosupport/bin/initenv

#
# 17c_17.3: digest: sha256:1078c324663573ae77a04a27fe4e54427c266c25d05523bc3bd7968c38c07113 size: 1786
#
ENV GEOSUPPORT_RELEASE "17c"
ENV GEOSUPPORT_VERSION "17.3"
ENV LANG C.UTF-8

LABEL gsrelease $GEOSUPPORT_RELEASE
LABEL gsversion $GEOSUPPORT_VERSION

ENV DISTFILE "gdelx_${GEOSUPPORT_RELEASE}.zip"
ENV GEOSUPPORT_HOME ${GEOSUPPORT_HOME:-/opt/geosupport}

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
  && ln -nfs $GEOSUPPORT_HOME/bin/c_client $GEOSUPPORT_HOME/bin/goat \
  && rm /$DISTFILE

ENV PATH $GEOSUPPORT_HOME/bin:$PATH
# Trailing '/' is required!
ENV GEOFILES $GEOSUPPORT_HOME/fls/
ENV GS_LIBRARY_PATH $GEOSUPPORT_HOME/lib
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${GS_LIBRARY_PATH}

#
# Add a bash script which can be sourced by another container to setup the
# Geosupport shared library path and datafile environment variables.
#
# This is for applications which do not extend this image but want to mount
# the $GEOSUPPORT_HOME directory exposed as a volume by containers built
# from this image (e.g., using --volumes-from).
#
COPY initenv $GEOSUPPORT_HOME/bin/initenv

RUN set -o errexit -o nounset \
  && sed -i "s|@GEOSUPPORT_HOME@|$GEOSUPPORT_HOME|g" $GEOSUPPORT_HOME/bin/initenv \
  && chmod 755 $GEOSUPPORT_HOME/bin/initenv \
  && cat $GEOSUPPORT_HOME/bin/initenv

VOLUME ["$GEOSUPPORT_HOME"]
CMD ["goat"]
