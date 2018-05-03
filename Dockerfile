#
# EXAMPLES:
#
# Runs latest version in a bash shell using existing volume 'vol-geosupport'
# (assumes parent was built with GEOSUPPORT_HOME=/opt/geosupport).
#
#     $ docker run -ti --name geosupport -v vol-geosupport:/opt/geosupport mlipper/geosupport-docker bash 
#
# Runs the default 'goat' command with r18a1/v18.1 (assumes you are also
# invoking Docker from a bash-like shell).
# 
#     $ V=18a1_18.1; docker run --rm -ti --build-arg GSD_VERSION=$V mlipper/geosupport-docker:$V
#
ARG GSD_VERSION=latest
FROM mlipper/geosupport-docker:${GSD_VERSION}-onbuild
LABEL maintainer "Matthew Lipper <mlipper@gmail.com>"

VOLUME ["$GEOSUPPORT_HOME"]

CMD ["goat"]
