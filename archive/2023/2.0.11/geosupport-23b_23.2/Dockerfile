# syntax=docker/dockerfile:1
ARG VARIANT=ubuntu:jammy
FROM ${VARIANT}

LABEL com.digitalclash.gsd.image=geosupport-docker
LABEL com.digitalclash.gsd.tag=2.0.11
LABEL com.digitalclash.gsd.vcs.ref=4e088cf
LABEL com.digitalclash.gsd.geosupport.major=23
LABEL com.digitalclash.gsd.geosupport.minor=2
LABEL com.digitalclash.gsd.geosupport.patch=
LABEL com.digitalclash.gsd.geosupport.release=b

ENV LANG C.UTF-8

WORKDIR /opt/geosupport

COPY --from=mlipper/geosupport-docker:2.0.11-dist /dist/geosupport.tgz /opt/geosupport/geosupport.tgz

RUN set -eux \
  && tar xzvf /opt/geosupport/geosupport.tgz \
  && /opt/geosupport/version-23b_23.2/bin/geosupport install \
  && rm /opt/geosupport/geosupport.tgz

CMD ["geosupport", "version"]
