# syntax=docker/dockerfile:1
ARG VARIANT=ubuntu:noble
FROM ${VARIANT}

LABEL com.digitalclash.gsd.image=geosupport-docker
LABEL com.digitalclash.gsd.tag=2.0.24
LABEL com.digitalclash.gsd.geosupport.major=24
LABEL com.digitalclash.gsd.geosupport.minor=42
LABEL com.digitalclash.gsd.geosupport.patch=2
LABEL com.digitalclash.gsd.geosupport.release=d

ENV LANG=C.UTF-8

WORKDIR /opt/geosupport

COPY --from=mlipper/geosupport-docker:2.0.24-dist /dist/geosupport.tgz /opt/geosupport/geosupport.tgz

RUN set -eux \
  && tar xzvf /opt/geosupport/geosupport.tgz \
  && /opt/geosupport/version-24d2_24.42/bin/geosupport install \
  && rm /opt/geosupport/geosupport.tgz

CMD ["geosupport", "version"]
