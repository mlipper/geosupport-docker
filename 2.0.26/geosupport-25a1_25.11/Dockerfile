# syntax=docker/dockerfile:1
ARG VARIANT=ubuntu:noble
FROM ${VARIANT}

LABEL com.digitalclash.gsd.image=geosupport-docker
LABEL com.digitalclash.gsd.tag=2.0.26
LABEL com.digitalclash.gsd.geosupport.major=25
LABEL com.digitalclash.gsd.geosupport.minor=11
LABEL com.digitalclash.gsd.geosupport.patch=1
LABEL com.digitalclash.gsd.geosupport.release=a

ENV LANG=C.UTF-8

WORKDIR /opt/geosupport

COPY --from=mlipper/geosupport-docker:2.0.26-dist /dist/geosupport.tgz /opt/geosupport/geosupport.tgz

RUN set -eux \
  && tar xzvf /opt/geosupport/geosupport.tgz \
  && /opt/geosupport/version-25a1_25.11/bin/geosupport install \
  && rm /opt/geosupport/geosupport.tgz

CMD ["geosupport", "version"]
