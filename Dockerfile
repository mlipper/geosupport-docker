ARG VERSION=latest

FROM mlipper/geosupport-docker:${VERSION}-onbuild

LABEL maintainer "Matthew Lipper <mlipper@gmail.com>"

ARG VERSION

VOLUME ["$GEOSUPPORT_HOME"]

CMD ["goat"]
