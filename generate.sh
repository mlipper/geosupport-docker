#!/usr/bin/env bash

# ./generate.sh -a foo=bar -a cow=truck -b /usr/local -c tgz -d distro -e duh.env -f Linux_GEO.zip -i 2 -l -m 21 -o out -p 4 -q -r b -s -u http://example.com -v 1.1.0

set -e

printf "Using bash version: %s\n" $BASH_VERSION

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

#declare -A BUILD_ARGS

BUILD_DIR="$THIS_DIR/build"
GEO_H_PATCH_FILE="geo_h.patch"
GEOSUPPORT_MAJOR="21"
GEOSUPPORT_MINOR="2"
GEOSUPPORT_PATCH=
GEOSUPPORT_RELEASE="b"
GSD_VERSION="${GSD_VERSION:-latest}"

# Get rid of these?
COMPRESSION_FORMAT="tgz"
GEOSUPPORT_BASEDIR="/opt/geosupport"
GEOSUPPORT_DISTDIR="dist"

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
    #printf '%s [%s] %s\n' "$(date --rfc-3339=seconds)" "$1" "$2"
    printf '%s [%s] %s\n' "$(date "+%Y-%m-%d %H:%M:%S")" "$1" "$2"
}

clean() {
    log "CLEAN" "Removing build directory ${BUILD_DIR}..."
    rm -rf "${BUILD_DIR}" || die "Error: could not remove build directory ${BUILD_DIR}."
    log "CLEAN" "Build directory ${BUILD_DIR} removed."
}

deploy() {
    die "Warning: "deploy" action has not been implemented yet."
}

conf2sedf() {

    [[ $# -eq 2 ]] || die "Function conf2sedf requires 2 arguments."
    [[ -f "$1" ]] || die "File ${conf} does not exist."
    local conf="$1"
    local sedf="$2"
    local key
    local val
    declare -A confmap

    # Create an associative array where the keys are "@<propname>@" and values are the property
    # values from the conf file.
    while read -r line; do
        if ! [[ "$line" =~ ^\# ]] && ! [[ "$line" =~ ^$ ]]; then # Skip comments, blank lines
            key="${line%%=*}"
            val="${line#*=}"
            confmap["${key}"]="${val}"
        fi
    done < "${conf}"

    local v
    local pattern

    # Using the associative array above, create a file with sed replacement commands.
    for token in "${!confmap[@]}"; do
        v="${confmap[${token}]}"
        pattern="@${token}@"
        echo "s|${pattern}|${v}|g" >> "${sedf}"
    done
}

generate() {
    log "GENERATE" "Generating Dockerfile from Dockerfile.template & release.conf files..."
    mkdir -p "${BUILD_DIR}"
    local sedf="${BUILD_DIR}/release.sed"
    conf2sedf release.conf "$sedf"
    sed -f "${sedf}" <Dockerfile.template >"${BUILD_DIR}/Dockerfile"
    sed -f "${sedf}" <geosupport.env.template >"${BUILD_DIR}/geosupport.env"
    # NOTE: The sed in-place switch (-i) requires a file extension argument on macos and BSD
    #sed -i.tmp "s|@geosupport_basedir@|XXXX${foo}XXXX|g" "${BUILD_DIR}/Dockerfile"
    log "GENERATE" "Dockerfile generation complete."

    exit 0

    sed "s|${pattern}|${v}|g" "${BUILD_DIR}/geosupport.env"
    cp Dockerfile.template "${BUILD_DIR}/Dockerfile"
    cp geosupport.env.template "${BUILD_DIR}/geosupport.env"

    log "GENERATE" "Generating Docker files for version ${GSD_VERSION}..."
    mkdir -p "${BUILD_DIR}"
    cp -v Dockerfile.template "${BUILD_DIR}/Dockerfile"
    foo="AAAAAA"
    # NOTE: The sed in-place switch (-i) requires a file extension argument on macos and BSD
    sed -i.tmp "s|@geosupport_basedir@|XXXX${foo}XXXX|g" "${BUILD_DIR}/Dockerfile"
    sed -i.tmp "s|@GEOFILES@|${GEOFILES}|g" "${BUILD_DIR}/Dockerfile"
    sed -i "s|@GS_LIBRARY_PATH@|${GS_LIBRARY_PATH}|g" "${BUILD_DIR}/Dockerfile"
    sed -i "s|@GEOSUPPORT_LDCONFIG@|${GEOSUPPORT_LDCONFIG}|g" "${BUILD_DIR}/Dockerfile"
    sed -i "s|@PATH@|${PATH}|g" "${BUILD_DIR}/Dockerfile"
    sed -i "s|@GEO_H_PATCH_FILE@|${GEO_H_PATCH_FILE}|g" "${BUILD_DIR}/Dockerfile"
    sed -i "s|@GEOSUPPORT_MAJOR@|${GEOSUPPORT_MAJOR}|g" "${BUILD_DIR}/Dockerfile"
    sed -i "s|@GEOSUPPORT_MINOR@|${GEOSUPPORT_MINOR}|g" "${BUILD_DIR}/Dockerfile"
    sed -i "s|@GEOSUPPORT_PATCH@|${GEOSUPPORT_PATCH}|g" "${BUILD_DIR}/Dockerfile"
    sed -i "s|@GEOSUPPORT_RELEASE@|${GEOSUPPORT_RELEASE}|g" "${BUILD_DIR}/Dockerfile"
    sed -i "s|@GSD_VERSION@|${GSD_VERSION}|g" "${BUILD_DIR}/Dockerfile"
    log "GENERATE" "Generated Docker files geosupport-deploy version ${GSD_VERSION}."
}

repackage() {
    log "REPACKAGE" "Repackaging DCP zip file."
}

run() {
    log "RUN" "Begining regeneration process."
}

add_build_arg() {
    local k="$1"
    local v="$2"
    #echo "Adding k: $k v: $v to BUILD_ARGS"
    mkdir -p $BUILD_DIR
    echo "$k $v" >> $BUILD_DIR/ba.txt
    #printf 'BUILD_ARGS length=%s\n' "$((( ${#BUILD_ARGS[@]} > 0 )))"
    #for key in "${!BUILD_ARGS[@]}"; do
    #    echo -n "key: $key, "
    #    echo "value: ${BUILD_ARGS[$key]}"
    #done
}

while [ $# -gt 0 ]; do
	# Necessary!
	OPTIND=1
    # See this page for the tricky details of using Bash associative arrays:
    # https://www.shell-tips.com/bash/arrays/
    while getopts ":a:b:c:d:e:f:hi:lm:o:p:qr:su:v:" opt; do
        case "${opt}" in
        a)
            # echo "foo=bar" | while IFS= read -r barg; do echo "key: ${barg%%=*}, value: ${barg#*=}"; done
            # https://unix.stackexchange.com/questions/146942/how-can-i-test-if-a-variable-is-empty-or-contains-only-spaces
            #
            if [[ ! -z "${OPTARG// }" ]]; then             # Make sure the value provided for -a is not null, the empty string, or only spaces
                key="${OPTARG%%=*}"
                value="${OPTARG#*=}"
                if [[ ! -n "${build_args_string}" ]]; then # build_args_string variable is null or empty. initialize it without a leading space
                    build_args_string="${key}=${value}"
                else                                       # build_args_string variable has been initialized with a value so prepend a leading space
                    build_args_string+="|${key}=${value}"
                fi
                build_args_string="$(echo -n "$build_args_string" | sed -e 's/ *$//')" # Trim any trailing whitespace
            fi

            # barg=${OPTARG}
            # echo "$barg" | while IFS= read -r arg; do
            #     #key=${arg%%=*}
            #     #echo "key=$key"
            #     #if [[ $arg =~ ,$ ]]; then
            #     #    value=""
            #     #else
            #     #    value=${arg#*=}
            #     #fi
            #     #echo "--build-arg ${key}=${value}"
            #     if [[ $arg =~ ,$ ]]; then
            #         add_build_arg ${arg%%=*} ""
            #     else
            #         add_build_arg ${arg%%=*} ${arg#*=}
            #     fi
            #done
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
            log "GSD_VERSION=${GSD_VERSION}"
            gsd_version=${OPTARG:-${GSD_VERSION}}
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

    # -b <basedir>
    geosupport_basedir=${geosupport_basedir:-${GEOSUPPORT_BASEDIR}}
    # -c <compression_format>
    compression_format=${compression_format:-${COMPRESSION_FORMAT}}
    # -d <distdir>
    geosupport_distdir=${geosupport_distdir:-${GEOSUPPORT_DISTDIR}}
    # -e <envfile>
    envfile=${envfile:-geosupport.env}
    # -l (<download_from_dcp> is only set if this flag is given)
    # -v <gsd_version>
    gsd_version=${gsd_version:-${GSD_VERSION}}

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

#echo "       build_args_string: ->${build_args_string}<-"
#echo "      compression_format=${compression_format}"
#echo "       download_from_dcp=${download_from_dcp}"
#echo "                 envfile=${envfile}"
#echo "      geosupport_basedir=${geosupport_basedir}"
#echo "      geosupport_distdir=${geosupport_distdir}"
#echo "     geosupport_distfile=${geosupport_distfile}"
#echo " geosupport_distfile_url=${geosupport_distfile_url}"
#echo "geosupport_major_version=${geosupport_major_version}"
#echo "geosupport_minor_version=${geosupport_minor_version}"
#echo "geosupport_patch_version=${geosupport_patch_version}"
#echo "      geosupport_release=${geosupport_release}"
#echo "             gsd_version=${gsd_version}"
#echo "      local_bindmountdir=${local_bindmountdir}"
#echo "                   quiet=${quiet}"
#echo "            skip_headers=${skip_headers}"

[[ -n "$doclean" ]] && clean
[[ -n "$dogenerate" ]] && generate

exit 0

# while read -r line; do l="${line}"; ! [[ "$l" =~ ^# ]] && echo "->${l}<-"; done < geosupport.env.template

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
