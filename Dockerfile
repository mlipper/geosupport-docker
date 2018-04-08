#
# EXAMPLES:
#
# Runs latest version in a bash shell using existing volume 'vol-geosupport'
# (assumes parent was built with GEOSUPPORT_HOME=/opt/geosupport).
#
#     $ docker run -ti --name geosupport -v vol-geosupport:/opt/geosupport mlipper/geosupport-docker bash 
#
# Runs the default 'goat' command with r18a/v18.1 (assumes you are also
# invoking Docker from a bash-like shell).
# 
#     $ V=18a_18.1; docker run --rm -ti --build-arg VERSION=$V mlipper/geosupport-docker:$V
#
ARG VERSION=latest

FROM mlipper/geosupport-docker:${VERSION}-onbuild

LABEL maintainer "Matthew Lipper <mlipper@gmail.com>"

ARG VERSION

VOLUME ["$GEOSUPPORT_HOME"]

CMD ["goat"]
