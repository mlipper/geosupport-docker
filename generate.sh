#!/usr/bin/env bash

# ./generate.sh -a foo=bar -a cow=truck -b /usr/local -c tgz -d distro -e duh.env -f Linux_GEO.zip -i 2 -l -m 21 -o out -p 4 -q -r b -s -u http://example.com -v 1.1.0

set -e

die() {
    echo "$*" 1>&2
    exit 1
}

#
# Prefer readlink from GNU coreutils to set current working directory.
#
# NOTE to macos users:
#
#   On the macos, the BSD version of readlink is already installed
#   and used by the operating system. Sadly, this script is not designed
#   to work with the BSD version and this script will bail if the
#   GNU readlink (greadlink) is not available.
#
#   The good new is that GNU readlink is available from Homebrew which
#   install prepends a 'g' before adding it to the PATH.
#
if [[ -n "$(command -v greadlink)" ]]; then
  THIS_DIR="$(cd "$(dirname "$(greadlink -f "$BASH_SOURCE")")" && pwd)"
elif [[ "$(uname -s)" =~ Darwin* ]]; then
  die "[ERROR] GNU readlink (greadlink) not found."
else
  THIS_DIR="$(cd "$(dirname "$(readlink -f "$BASH_SOURCE")")" && pwd)"
fi

THIS_FILE="$(basename "${BASH_SOURCE[0]}")"

declare -A BUILD_ARGS

BUILD_DIR="$THIS_DIR/build"
GEO_H_PATCH_FILE="geo_h.patch"
GEOSUPPORT_MAJOR="21"
GEOSUPPORT_MINOR="2"
GEOSUPPORT_PATCH=
GEOSUPPORT_RELEASE="b"
GSD_VERSION="${GSD_VERSION:-latest}"

usage() {
cat <<- EOF

    Usage: ${THIS_FILE} [OPTIONS] [ACTIONS]

    Options:
      -a list       Docker build argument key=value pairs
      -b string     Geosupport base install directory (default /opt/geosupport)
      -c string     Compression format for repackaging the DCP Geosupport distro
                    'tgz':  gzip'd tar file (default)
                    'zip':  zip file
      -d string     Local directory containing DCP Geosupport distro zip files (default "dist")
      -e string     Environment file (default "release.env" if it exists)
      -f string     Name of Geosupport distro file (default "linux_geo<major><release><patch>_<major>_<minor>.zip")
      -h            Show this usage message and exit
      -i string     Geosupport minor version (required)
      -l            Download the Geosupport distro from DCP site. If given, takes precedence over "-d"
      -m string     Geosupport major version (required)
      -o string     Local bind mount directory for release artifacts (default "out")
      -p string     Geosupport patch version
      -q            Supress script output
      -r string     Geosupport release modifier (required)
      -s            Skip patching and inclusion of Geosupport header files
      -u string     URL of the Geosupport distro. If given, takes precedence over "-d" and "-l"
      -v string     Version of this project (default "latest")

    Actions:
      clean         Remove the local bind mount directory (see "-o" option).
                    If given, always first action to execute.

      deploy        [Not implemented] Deploy built image version to DockerHub.
                    If specified, always causes build action to run first, even
                    if not given on the command line.

      generate      Generate project source using *.template files.

      repackage     Repackage the Geosupport distro.

      run           Build and run generated source for pre-release verification.

EOF
}

log() {
    local category="INFO"
    local message=""
    if [ $# -eq 1 ]; then
        message="$1"
    fi
    if [ $# -eq 2 ]; then
        category="$1"
        message="$2"
    fi
    printf '%s [%s] %s\n' "$(date --rfc-3339=seconds)" "$1" "$2"
}

clean() {
    log "CLEAN" "Removing build directory ${BUILD_DIR}..."
    rm -rf "${BUILD_DIR}" || die "Error: could not remove build directory ${BUILD_DIR}."
    log "CLEAN" "Build directory ${BUILD_DIR} removed."
}

deploy() {
    die "Warning: "deploy" action has not been implemented yet."
}

generate() {
    log "GENERATE" "Generating Docker files for version ${GSD_VERSION}..."
    log "GENERATE" "Generated  Docker files geosupport-deploy version ${GSD_VERSION}."
}

repackage() {
    log "REPACKAGE" "Repackaging DCP zip file."
}

run() {
    log "RUN" "Begining regeneration process."
}

while [ $# -gt 0 ]; do
	# Necessary!
	OPTIND=1
    while getopts ":a:b:c:d:e:f:hi:lm:o:p:qr:su:v:" opt; do
        case "${opt}" in
        a)
            # echo "foo=bar" | while IFS= read -r barg; do echo "key: ${barg%%=*}, value: ${barg#*=}"; done
            barg=${OPTARG}
            echo "$barg" | \
            while IFS= read -r arg; do
                key=${arg%%=*}
                echo "key=$key"
                if [[ $arg =~ ,$ ]]; then
                    value=""
                else
                    value=${arg#*=}
                fi
                echo "--build-arg ${key}=${value}"
                BUILD_ARGS["${key}"]="${value}"
            done
            ;;
        b)
            geosupport_basedir=${OPTARG}
            ;;
        c)
            compression_format=${OPTARG}
            ;;
        d)
            geosupport_distdir=${OPTARG}
            ;;
        e)
            envfile=${OPTARG}
            ;;
        f)
            geosupport_distfile=${OPTARG}
            ;;
        h)
            usage
            exit 0
            ;;
        i)
            geosupport_minor_version=${OPTARG}
            ;;
        l)
            download_from_dcp="yes"
            ;;
        m)
            geosupport_major_version=${OPTARG}
            ;;
        o)
            local_bindmountdir=${OPTARG}
            ;;
        p)
            geosupport_patch_version=${OPTARG}
            ;;
        q)
            quiet="yes"
            ;;
        r)
            geosupport_release=${OPTARG}
            ;;
        s)
            skip_headers="yes"
            ;;
        u)
            geosupport_distfile_url=${OPTARG}
            ;;
        v)
            gsd_version=${OPTARG}
            ;;
        \?)
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
        :)
            echo "Invalid Option: -$OPTARG requires an argument" 1>&2
            exit 1
            ;;
        esac
    done


	# Remove already processed arguments
	shift "$((OPTIND-1))"

	# Access remaining positional parameters.
    # Important: remember to use regular shift command to progress through
    # remaining args in outer loop (while [ $# -gt 0 ]; do ...).
    case "$1" in
        clean)
            doclean=$1; shift
            ;;
        deploy)
            dodeploy=$1; shift
            ;;
        generate)
            dogenerate=$1; shift
            ;;
        repackage)
            dorepackage=$1; shift
            ;;
        run)
            dorun=$1; shift
            ;;
       # TODO Figure out why '*)' does not work and if we care.
       #*)
       #   echo "[WARNING] Invalid Command: "$1""; shift # Remove invalid command from the argument list
       #     ;;
    esac
done


echo "              BUILD_ARGS"
for i in "${!BUILD_ARGS[@]}"; do
echo "                        ${i}=${BUILD_ARGS[$i]}"
done

echo "      compression_format=${compression_format}"
echo "       download_from_dcp=${download_from_dcp}"
echo "                 envfile=${envfile}"
echo "      geosupport_basedir=${geosupport_basedir}"
echo "      geosupport_distdir=${geosupport_distdir}"
echo "     geosupport_distfile=${geosupport_distfile}"
echo " geosupport_distfile_url=${geosupport_distfile_url}"
echo "geosupport_major_version=${geosupport_major_version}"
echo "geosupport_minor_version=${geosupport_minor_version}"
echo "geosupport_patch_version=${geosupport_patch_version}"
echo "      geosupport_release=${geosupport_release}"
echo "             gsd_version=${gsd_version}"
echo "      local_bindmountdir=${local_bindmountdir}"
echo "                   quiet=${quiet}"
echo "            skip_headers=${skip_headers}"



exit 0


# Docker build arguments
#DISTFILE="geosupport-server-${MAJOR}${RELEASE}_${MAJOR}.${MINOR}.tgz"
DISTFILE="linux_geo${MAJOR}${RELEASE}_${MAJOR}_${MINOR}.zip"
DOWNLOAD=
ENVFILE="${ENVFILE:-geosupport.env}"
INSTALLDIR="/opt/geosupport"
LINKNAME="current"
UPDATE_LD_LIBRARY_PATH="true"
USE_LDCONFIG=

declare -A props

parse_props() {
    if [[ -n "${1}" ]]; then
        echo "[ERROR] Call to parse_props() missing required file argument."
        exit 1
    fi
    file="${1}"
    while IFS= read -r line; do
        key=${line%%=*}
        if [[ $line =~ ,$ ]]; then
            value=""
        else
            value=${line#*=}
        fi
        echo "${key}=${value}"
        props["${key}"]="${value}"
    done < <(cat "${file}" | grep -v '^#' | cut -f 1,2 -d '=' -s)
}

declare -a excludes=("./README.md" "./initenv" "./build.sh")

while IFS= read -r file; do
    # Do not modify files in excludes
    for exclude in "${excludes[@]}"
    do
        if [[ "${file}" == "${exclude}" ]]; then
            echo "Skipping property substitution in file ${exclude}."
            continue 2
        fi
    done
    echo "Found substitution property in file ${file}."
done < <(find . -type f -not -path '*/\.git/*' -exec egrep -Il -e '@[^@]+@' {} \;)

if [[ -n "${debug}" ]]; then
    echo "Building version ${version} using file ${envfile}."
    echo
    echo "[properties]"
    echo
fi
