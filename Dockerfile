ARG BUILD_DIR="/var/tmp/geosupport"
ARG GEOSUPPORT_MAJOR_VERSION="20"
ARG GEOSUPPORT_MINOR_VERSION="3"
ARG GEOSUPPORT_RELEASE="20c"

# File name of the compressed Geosupport for Linux x64 distribution
ARG GEOSUPPORT_DISTFILE
# Target installation directory
ARG GEOSUPPORT_HOME
# To enable use of ldconfig for adding libs to system library path add
# '--build-arg GEOSUPPORT_LDCONFIG=1' when invoking the docker build command
ARG GEOSUPPORT_LDCONFIG=0

FROM debian:buster-slim AS build

LABEL maintainer "Matthew Lipper <mlipper@gmail.com>"
LABEL version 1.1.0

LABEL geosupport.release ${GEOSUPPORT_RELEASE}
LABEL geosupport.major.version ${GEOSUPPORT_MAJOR_VERSION}
LABEL geosupport.minor.version ${GEOSUPPORT_MINOR_VERSION}

ENV GEOSUPPORT_DISTFILE "${GEOSUPPORT_DISTFILE:-linux_geo${GEOSUPPORT_RELEASE}_${GEOSUPPORT_MAJOR_VERSION}_${GEOSUPPORT_MINOR_VERSION}.zip}"
ENV GEOSUPPORT_LDCONFIG "${GEOSUPPORT_LDCONFIG:+true}"

ENV GEOSUPPORT_HOME "${GEOSUPPORT_HOME:-/opt/geosupport}"
# Trailing '/' is required!
ENV GEOFILES "${GEOFILES:-${GEOSUPPORT_HOME}/fls/}"
ENV GS_LIBRARY_PATH "${GS_LIBRARY_PATH:-${GEOSUPPORT_HOME}/lib}"

ENV LANG C.UTF-8

RUN set -ex; \
    suffix=$(echo "${GEOSUPPORT_DISTFILE}" | tail -c 4 | tr '[:upper:]' '[:lower:]'); \
    if [ "$suffix" = "zip" ]; then \
    # Dist file is in .zip format: install unzip
    apt-get update; \
    apt-get install -y --no-install-recommends \
    unzip \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    fi

COPY initenv ${BUILD_DIR}/initenv
RUN set -eux; \
    sed -i "s|@GEOSUPPORT_HOME@|$GEOSUPPORT_HOME|g" ${BUILD_DIR}/initenv; \
    sed -i "s|@GEOFILES@|$GEOFILES|g" ${BUILD_DIR}/initenv; \
    sed -i "s|@GS_LIBRARY_PATH@|$GS_LIBRARY_PATH|g" ${BUILD_DIR}/initenv; \
    sed -i "s|@GEOSUPPORT_LDCONFIG@|$GEOSUPPORT_LDCONFIG|g" ${BUILD_DIR}/initenv; \
    sed -i "s|@PATH@|$PATH|g" ${BUILD_DIR}/initenv; \
    chmod 755 ${BUILD_DIR}/initenv

COPY "${GEOSUPPORT_DISTFILE}" "${BUILD_DIR}/${GEOSUPPORT_DISTFILE}"
RUN set -eux; \
    echo "Re-packaging Geosupport"; \
    mkdir -p "${BUILD_DIR}/dist"; \
    suffix=$(echo "${GEOSUPPORT_DISTFILE}" | tail -c 4 | tr '[:upper:]' '[:lower:]'); \
    if [ "$suffix" = "zip" ]; then \
        # unzip
        echo "Extracting zip file ${BUILD_DIR}/${GEOSUPPORT_DISTFILE} to ${BUILD_DIR}/dist."; \
        unzip -qj "${BUILD_DIR}/${GEOSUPPORT_DISTFILE}" "**/bin/*" -d "${BUILD_DIR}/dist/bin"; \
        unzip -qj "${BUILD_DIR}/${GEOSUPPORT_DISTFILE}" "**/lib/*" -d "${BUILD_DIR}/dist/lib"; \
        unzip -qj "${BUILD_DIR}/${GEOSUPPORT_DISTFILE}" "**/fls/*" -d "${BUILD_DIR}/dist/fls"; \
    else \
        # untar
        echo "Extracting gzipped tar file ${BUILD_DIR}/${GEOSUPPORT_DISTFILE} to ${BUILD_DIR}/dist."; \
        tar xzvf "${BUILD_DIR}/${GEOSUPPORT_DISTFILE}" -C "${BUILD_DIR}/dist" --strip-components 1; \
    fi; \
    mv "${BUILD_DIR}/dist/bin/c_client" "${BUILD_DIR}/dist/bin/goat"; \
    mv "${BUILD_DIR}/initenv" "${BUILD_DIR}/dist/bin/initenv"; \
    rm "${BUILD_DIR}/${GEOSUPPORT_DISTFILE}"

RUN ["/bin/bash", "-c", "ls -l ${BUILD_DIR}/dist"]

FROM debian:buster-slim
ENV BUILD_DIR="/var/tmp/version-20c_20.3"
RUN ["/bin/bash", "-c", "env"]
COPY --from=build "${BUILD_DIR}/dist" "/opt/geosupport"
#
RUN ["/bin/bash", "-c", "ls -l /opt/geosupport"]
#RUN ["/bin/bash", "-c", "source ${GEOSUPPORT_HOME}/bin/initenv"]