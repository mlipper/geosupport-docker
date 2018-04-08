#!/bin/bash

GEOSUPPORT_RELEASE=$1
GEOSUPPORT_VERSION=$2
if [[ -n $3 ]] || [[ $3 == "latest" ]]; then
VERSION=$3
else
VERSION=${GEOSUPPORT_RELEASE}_${GEOSUPPORT_VERSION}
fi

docker build -t mlipper/geosupport-docker:${VERSION}-onbuild \
             -e GEOSUPPORT_RELEASE=${GEOSUPPORT_RELEASE} \
             -e GEOSUPPORT_VERSION=${GEOSUPPORT_VERSION} \
             -f Dockerfile.onbuild .

docker build --build-arg VERSION=${VERSION} \
             -t mlipper/geosupport-docker:${VERSION} \
             -f Dockerfile .

docker build --build-arg VERSION=${VERSION} \
             -t mlipper/geosupport-docker:${VERSION}-dvc \
             -f Dockerfile.dvc .

docker volume create --name gsvolume-${VERSION}

docker run -d --name geosupport-${VERSION} \
              --volume gsvolume-${VERSION}:/opt/geosupport
