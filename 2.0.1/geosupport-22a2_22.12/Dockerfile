# syntax=docker/dockerfile:1
ARG VARIANT=debian:bullseye-slim
FROM ${VARIANT}

LABEL com.digitalclash.gsd.image=geosupport-docker
LABEL com.digitalclash.gsd.tag=2.0.1
LABEL com.digitalclash.gsd.vcs.ref=11e142c
LABEL com.digitalclash.gsd.geosupport.major=22
LABEL com.digitalclash.gsd.geosupport.minor=12
LABEL com.digitalclash.gsd.geosupport.patch=2
LABEL com.digitalclash.gsd.geosupport.release=a

ENV GEOSUPPORT_BASEDIR="${GEOSUPPORT_BASEDIR:-/opt/geosupport}"
ENV GEOSUPPORT_FULL_VERSION 22a2_22.12
ENV GEOSUPPORT_HOME="${GEOSUPPORT_HOME:-${GEOSUPPORT_BASEDIR}/current}"
ENV GEOFILES="${GEOFILES:-${GEOSUPPORT_HOME}/fls/}"
ENV GS_LIBRARY_PATH="${GS_LIBRARY_PATH:-${GEOSUPPORT_HOME}/lib}"
ENV GS_INCLUDE_PATH="${GS_INCLUDE_PATH:-${GEOSUPPORT_HOME}/include}"
ENV PATH="${GEOSUPPORT_HOME}/bin:$PATH"

ENV LANG C.UTF-8

COPY --from=geosupport-docker:2.0.1-dist /dist/geosupport-${GEOSUPPORT_FULL_VERSION}.tgz /geosupport.tgz

WORKDIR "${GEOSUPPORT_BASEDIR}"

RUN set -eux; \
        \
        tar xzvf /geosupport.tgz; \
        ln -s "version-${GEOSUPPORT_FULL_VERSION}" "${GEOSUPPORT_HOME}"; \
        rm /geosupport.tgz; \
        "${GEOSUPPORT_HOME}/bin/geosupport" install

CMD ["geosupport", "-v"]
