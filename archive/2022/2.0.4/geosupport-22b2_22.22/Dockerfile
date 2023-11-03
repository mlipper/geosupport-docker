# syntax=docker/dockerfile:1
ARG VARIANT=debian:bullseye-slim
FROM ${VARIANT}

LABEL com.digitalclash.gsd.image=geosupport-docker
LABEL com.digitalclash.gsd.tag=2.0.4
LABEL com.digitalclash.gsd.vcs.ref=5a21fce
LABEL com.digitalclash.gsd.geosupport.major=22
LABEL com.digitalclash.gsd.geosupport.minor=22
LABEL com.digitalclash.gsd.geosupport.patch=2
LABEL com.digitalclash.gsd.geosupport.release=b

ENV LANG C.UTF-8

WORKDIR /opt/geosupport

COPY --from=geosupport-docker:2.0.4-dist /dist/geosupport-22b2_22.22.tgz /opt/geosupport/geosupport.tgz

RUN set -eux \
  && tar xzvf /opt/geosupport/geosupport.tgz \
  && /opt/geosupport/version-22b2_22.22/bin/geosupport install \
  && rm /opt/geosupport/geosupport.tgz

CMD ["geosupport", "version"]
