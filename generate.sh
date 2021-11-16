#!/usr/bin/env bash

set -e

declare -A confmap
BUILD_DIR=./build
DIST_DIR=./dist
GSD_VERSION="${GSD_VERSION:-latest}"

die() {
    echo "$*" 1>&2
    exit 1
}

usage() {
local this_file
this_file="$(basename "${BASH_SOURCE[0]}")"
cat <<- EOF

    Usage: ${this_file} [OPTIONS] [ACTIONS]

    Options:
      -d string     Local directory containing Geosupport zip file
                    (default "dist")
      -f string     Geosupport distro file name
                    (default "linux_geo<major><release><patch>_<major>_<minor>.zip")
      -h            Show this usage message and exit

    Actions:
      clean         Remove the local build directory
                    If given, always first action to execute.

      generate      Generate project source using *.template files.

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
    printf '%s [%s] %s\n' "$(date "+%Y-%m-%d %H:%M:%S")" "${category}" "${message}"
}

clean() {
    log "CLEAN" "Removing build directory ${BUILD_DIR}..."
    rm -rf "${BUILD_DIR}" || die "Error: could not remove build directory ${BUILD_DIR}."
    log "CLEAN" "Build directory ${BUILD_DIR} removed."
}

initialize_confmap() {
    # Create an associative array where the keys are "@<propname>@" and values are the property
    # values from the conf file.
    #
    [[ -f "$1" ]] || die "File $1 does not exist."
    local conf="$1"
    local key
    local val
    # Note: The test of the line var insures last line is read even if
    #       there's no trailing newline.
    while IFS= read -r line || [ -n "$line" ]; do
        if ! [[ "$line" =~ ^\# ]] && ! [[ "$line" =~ ^$ ]]; then # Skip comments, blank lines
            key="${line%%=*}"
            val="${line#*=}"
            confmap["${key}"]="${val}"
            #echo "value: ${val}"
        fi
    done < "${conf}"

    #DISTFILE="geosupport-server-${MAJOR}${RELEASE}_${MAJOR}.${MINOR}.tgz"
    #DISTFILE="linux_geo${MAJOR}${RELEASE}_${MAJOR}_${MINOR}.zip"

}

conf2sedf() {
    [[ -z "$1" ]] && die "Function onf2sedf requires the path to the generated sed file as an argument."

    local v
    local pattern
    local sedf="$1"

    # Create a file with sed replacement commands where the keys are "@<propname>@" and values are the property
    # values read from the global "confmap" associative array.
    for token in "${!confmap[@]}"; do
        v="${confmap[${token}]}"
        pattern="@${token}@"
        echo "s|${pattern}|${v}|g" >> "${sedf}"
    done
}

generate() {
    log "GENERATE" "Generating templated Docker files..."
    initialize_confmap release.conf
    #echo "${confmap[@]}"
    mkdir -p "${BUILD_DIR}"
    local sedf="${BUILD_DIR}/release.sed"
    conf2sedf "$sedf"
    sed -f "${sedf}" <Dockerfile.template >"${BUILD_DIR}/Dockerfile"
    sed -f "${sedf}" <geosupport.env.template >"${BUILD_DIR}/geosupport.env"
    log "GENERATE" "Generation of templated Docker files complete."
}

[ $# -eq 0 ] && usage

while [ $# -gt 0 ]; do
	# Necessary!
	OPTIND=1
    while getopts ":d:fh" opt; do
        case "${opt}" in
        d)
            geosupport_dist_dir=${OPTARG}
            ;;
        f)
            geosupport_dist_file=${OPTARG}
            ;;
        h)
            usage
            exit 0
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
    case "$1" in
        clean)
            doclean=$1; shift
            ;;
        generate)
            dogenerate=$1; shift
            ;;
        *)
            die "Invalid command: $1"; shift
            ;;
    esac
done

[[ -n "$doclean" ]] && clean
[[ -n "$dogenerate" ]] && generate