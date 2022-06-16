#!/usr/bin/env bash
set -Eeuo pipefail

thisDir="$(readlink -vf "$BASH_SOURCE")"
thisDir="$(dirname "$thisDir")"

ver="$("$thisDir/scripts/geosupport-docker-version")"
ver="${ver%% *}"
dockerImage="mlipper/geosupport-docker:$ver"

echo "$dockerImage"