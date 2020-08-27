FROM debian:buster-slim AS builder

LABEL maintainer "Matthew Lipper <mlipper@gmail.com>"
LABEL version $GSD_VERSION

ARG DISTRO_DIR
ARG DISTRO_FILE
ARG GEOSUPPORT_DISTFILE
ARG GEOSUPPORT_HOME
ARG GEOSUPPORT_LDCONFIG

ENV DISTRO_DIR "${DISTRO_DIR:-/dist}"
ENV DISTRO_FILE "${DISTRO_FILE:-geosupport-server-${GEOSUPPORT_RELEASE}_${GEOSUPPORT_VERSION}.tgz}"

ENV GEOSUPPORT_RELEASE "20b"
ENV GEOSUPPORT_VERSION "20.2"
ENV GEOSUPPORT_DISTFILE "${GEOSUPPORT_DISTFILE:-linux_geo${GEOSUPPORT_RELEASE}_${GEOSUPPORT_VERSION}.zip}"
ENV GEOSUPPORT_LDCONFIG "${GEOSUPPORT_LDCONFIG:-true}"

ENV GEOSUPPORT_HOME "${GEOSUPPORT_HOME:-/opt/geosupport}"
# Trailing '/' is required!
ENV GEOFILES "${GEOFILES:-${GEOSUPPORT_HOME}/fls/}"
ENV GS_LIBRARY_PATH "${GS_LIBRARY_PATH:-${GEOSUPPORT_HOME}/lib}"

ENV PATH "${GEOSUPPORT_HOME}/bin:$PATH"

ENV LANG C.UTF-8

LABEL gsrelease $GEOSUPPORT_RELEASE
LABEL gsversion $GEOSUPPORT_VERSION

RUN set -eu; \
    suffix=$(echo "${GEOSUPPORT_DISTFILE}" | tail -c 4 | tr '[:upper:]' '[:lower:]'); \
    if [ "$suffix" = "zip" ]; then \
    # Dist file is in .zip format: install unzip \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            unzip \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi

COPY initenv /initenv
RUN set -eu; \
    sed -i "s|@GEOSUPPORT_HOME@|$GEOSUPPORT_HOME|g" /initenv; \
    sed -i "s|@GEOFILES@|$GEOFILES|g" /initenv; \
    sed -i "s|@GS_LIBRARY_PATH@|$GS_LIBRARY_PATH|g" /initenv; \
    sed -i "s|@GEOSUPPORT_LDCONFIG@|$GEOSUPPORT_LDCONFIG|g" /initenv; \
    sed -i "s|@PATH@|$PATH|g" /initenv; \
    chmod 755 /initenv

COPY "$GEOSUPPORT_DISTFILE" "/$GEOSUPPORT_DISTFILE"
RUN set -eu; \
    echo "Packaging Geosupport"; \
    mkdir -p "${GEOSUPPORT_HOME}"; \
    suffix=$(echo "${GEOSUPPORT_DISTFILE}" | tail -c 4 | tr '[:upper:]' '[:lower:]'); \
    if [ "$suffix" = "zip" ]; then \
    # unzip \
        echo "Extracting zip file /${GEOSUPPORT_DISTFILE} to ${GEOSUPPORT_HOME}."; \
        unzip -qj "/${GEOSUPPORT_DISTFILE}" "**/bin/*" -d "${GEOSUPPORT_HOME}/bin"; \
        unzip -qj "/${GEOSUPPORT_DISTFILE}" "**/lib/*" -d "${GEOSUPPORT_HOME}/lib"; \
        unzip -qj "/${GEOSUPPORT_DISTFILE}" "**/fls/*" -d "${GEOSUPPORT_HOME}/fls"; \
    else \
    # untar \
        echo "Extracting gzipped tar file /${GEOSUPPORT_DISTFILE} to ${GEOSUPPORT_HOME}."; \
        tar xzvf "/${GEOSUPPORT_DISTFILE}" -C "${GEOSUPPORT_HOME}" --strip-components 1; \
    fi; \
    mv "${GEOSUPPORT_HOME}/bin/c_client" "${GEOSUPPORT_HOME}/bin/goat"; \
    mv /initenv "${GEOSUPPORT_HOME}/bin/initenv"; \
    rm "/${GEOSUPPORT_DISTFILE}"

WORKDIR $DISTRO_DIR
RUN set -eu; \
    echo "Packaging Geosupport distribution /$DISTRO_DIR/$DISTRO_FILE"; \
    echo ${GEOSUPPORT_RELEASE} >> $GEOSUPPORT_HOME/release; \
    echo ${GEOSUPPORT_VERSION} >> $GEOSUPPORT_HOME/version; \
    tar czvf /$DISTRO_DIR/$DISTRO_FILE $GEOSUPPORT_HOME

FROM scratch AS distributor
ARG DISTRO_DIR
ARG DISTRO_FILE
ARG GEOSUPPORT_DISTFILE
ARG GEOSUPPORT_HOME
ARG GEOSUPPORT_LDCONFIG
COPY --from=builder /$DISTRO_DIR/$DISTRO_FILE /$DISTRO_DIR/$DISTRO_FILE
VOLUME ["$DISTRO_DIR"]

FROM debian:buster-slim AS installer
ARG DISTRO_DIR
ARG DISTRO_FILE
ARG GEOSUPPORT_DISTFILE
ARG GEOSUPPORT_HOME
ARG GEOSUPPORT_LDCONFIG
COPY --from=builder /$DISTRO_DIR/$DISTRO_FILE /$DISTRO_FILE
RUN set -eu; \
    echo "Installing Geosupport"; \
    tar xzvf /$DISTRO_FILE $GEOSUPPORT_HOME
VOLUME ["$GEOSUPPORT_HOME"]
RUN ["/bin/bash", "-c", "set -euo pipefail; source $GEOSUPPORT_HOME/bin/initenv;"]
CMD ["goat"]
