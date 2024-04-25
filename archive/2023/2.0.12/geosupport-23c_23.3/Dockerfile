# syntax=docker/dockerfile:1
ARG VARIANT=ubuntu:jammy
FROM ${VARIANT}

LABEL com.digitalclash.gsd.image=geosupport-docker
LABEL com.digitalclash.gsd.tag=2.0.12
LABEL com.digitalclash.gsd.geosupport.major=23
LABEL com.digitalclash.gsd.geosupport.minor=3
LABEL com.digitalclash.gsd.geosupport.patch=
LABEL com.digitalclash.gsd.geosupport.release=c

ENV LANG C.UTF-8

WORKDIR /opt/geosupport

COPY --from=mlipper/geosupport-docker:2.0.12-dist /dist/geosupport.tgz /opt/geosupport/geosupport.tgz

RUN set -eux \
  && tar xzvf /opt/geosupport/geosupport.tgz \
  && /opt/geosupport/version-23c_23.3/bin/geosupport install \
  && rm /opt/geosupport/geosupport.tgz

CMD ["geosupport", "version"]
