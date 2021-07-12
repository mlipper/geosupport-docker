#!/usr/bin/env bash

MAJOR="${MAJOR:-21}"
MINOR="${MINOR:-2}"
RELEASE="${RELEASE:-b}"

FILE_NAME="linux_geo${MAJOR}${RELEASE}_${MAJOR}_${MINOR}.zip"
DOWNLOAD="$(echo -n ${TMPDIR})${FILE_NAME}"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/Workspace/Volumes/geosupport}"
VERSION_DIR="${INSTALL_DIR}/version-${MAJOR}${RELEASE}_${MAJOR}.${MINOR}"

set -o errexit -o nounset

#echo "Downloading ${FILE_NAME} to ${DOWNLOAD}"
#
#curl -o "${DOWNLOAD}" "https://www1.nyc.gov/assets/planning/download/zip/data-maps/open-data/${FILE_NAME}"
#
#unzip -d "${INSTALL_DIR}" "${DOWNLOAD}"
#
#rm "${DOWNLOAD}"
#
#if [[ ! -d "${VERSION_DIR}" ]]; then
#  echo "Error: Could not unzip ${DOWNLOAD} to ${VERSION_DIR}."
#  exit 1
#fi

GEOSUPPORT_HOME="${INSTALL_DIR}/current"

#ln -s "${VERSION_DIR}" "${GEOSUPPORT_HOME}"

if [[ ! -d "${GEOSUPPORT_HOME}" ]]; then
  echo "Error: Could not create symlink ${GEOSUPPORT_HOME} to ${VERSION_DIR}."
  exit 1
fi

{
  echo '#!/usr/bin/env bash'
  echo
  echo "export GEOSUPPORT_HOME="${INSTALL_DIR}/current""
  # Trailing slash ('/') is required
  echo "export GEOFILES="${GEOSUPPORT_HOME}/fls/""
  echo "export GS_LIBRARY_PATH="${GEOSUPPORT_HOME}/lib""
  # Surrounded by single quotes because variables should be evaluated at runtime
  echo 'export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${GS_LIBRARY_PATH}"'
} > "${GEOSUPPORT_HOME}/bin/initenv"

chmod 755 "${GEOSUPPORT_HOME}/bin/initenv"
