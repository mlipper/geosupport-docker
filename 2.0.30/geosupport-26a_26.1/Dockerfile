# syntax=docker/dockerfile:1
ARG VARIANT=ubuntu:noble
FROM ${VARIANT}

LABEL com.digitalclash.gsd.image=geosupport-docker
LABEL com.digitalclash.gsd.tag=2.0.30
LABEL com.digitalclash.gsd.geosupport.major=26
LABEL com.digitalclash.gsd.geosupport.minor=1
LABEL com.digitalclash.gsd.geosupport.patch=
LABEL com.digitalclash.gsd.geosupport.release=a

ENV LANG=C.UTF-8

WORKDIR /opt/geosupport

COPY --from=mlipper/geosupport-docker:2.0.30-dist /dist/geosupport.tgz /opt/geosupport/geosupport.tgz

RUN set -eux \
  && tar xzvf /opt/geosupport/geosupport.tgz \
  && /opt/geosupport/version-26a_26.1/bin/geosupport install \
  && rm /opt/geosupport/geosupport.tgz

CMD ["geosupport", "version"]
