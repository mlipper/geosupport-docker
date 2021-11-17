#!/usr/bin/env bash

set -e

#
# Globals
#

# Arguments from CLI
declare -a actions

# Hashtable of build properties-to-values
declare -A confmap

# Default property values
BUILD_DIR=./build
DIST_DIR=./dist
GSD_VERSION="${GSD_VERSION:-latest}"

#
# Functions
#

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
      -f string     Geosupport distro file name
                    (default "linux_geo<major><release><patch>_<major>_<minor>.zip")
      -h            Show this usage message and exit
      -p string     Build property name and optional value.

                    This option is accepted in the following formats:

                    -p <name>=<value>   # Everything after the first occurance of
                                        # the '=' character (including other '='
                                        # characters) is considered the value.
                                        # Surround the entire value with quotes
                                        # if it contains spaces.

                    -p <name>           # Property names cannot contain spaces.
                                        # The value will be defaulted to <name>.

                    The '-p' option may be specified multiple times on a commandline.

    Actions:
      clean         Remove the local build directory
                    If given, always first action to execute.

      generate      Generate project source using *.template files.

      show          Print build properties and their values, sorted, to stdout. 

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

#
# Creates a sed command file using the configmap global variable.
#
# This is implemented by writing a sed substitution command where
# each property (key) in configmap is surrounded by the "@" token
# (i.e., "@<propname>@") which the sed command replaces with the value.
#
# The sed coommand is then invoked against templated files (i.e., *.template)
# and the tokenized placeholder properties are replaced with their actual
# values.
#
conf2sedf() {
    [[ -z "$1" ]] && die "Function onf2sedf requires the path to the generated sed file as an argument."

    local v
    local pattern
    local sedf="$1"

    for token in "${!confmap[@]}"; do
        v="${confmap[${token}]}"
        pattern="@${token}@"
        echo "s|${pattern}|${v}|g" >> "${sedf}"
    done
}

generate() {
    log "GENERATE" "Generating templated Docker files..."
    local sedf="${BUILD_DIR}/release.sed"
    conf2sedf "$sedf"
    sed -f "${sedf}" <Dockerfile.template >"${BUILD_DIR}/Dockerfile"
    sed -f "${sedf}" <geosupport.env.template >"${BUILD_DIR}/geosupport.env"
    log "GENERATE" "Generation of templated Docker files complete."
}

show() {
    declare -a keys
    printf '\n%-30s %-40s\n' 'Property' 'Value'
    printf '%-30s %-40s\n' '------------------------------' '----------------------------------------'
    keys=$(echo ${!confmap[@]} | tr ' ' '\012' | sort | tr '\012' ' ')
    for property in ${keys}; do
        value="${confmap[${property}]}"
        printf '%-30s %-40s\n' "${property}" "${value}"
    done
    printf '\n'
}

main() {

    [ $# -eq 0 ] && usage

    # Initialize confmap from from file __first__. This way, properties
    # from the commandline will have precedence over those that
    # also exist in the file.
    initialize_confmap release.conf

    # Create the build directory so that actions like generate can
    # assume it exists.
    mkdir -p "${BUILD_DIR}"

    while [ $# -gt 0 ]; do
        # Necessary!
        OPTIND=1
        while getopts "f:hp:" opt; do
            case "${opt}" in
            f)
                confmap["local_geosupport_distfile"]="${OPTARG}"
                ;;
            h)
                usage
                exit 0
                ;;
            p)
                # TODO: Error handling
                prop="${OPTARG}"
                k="${prop%%=*}"
                v="${prop#*=}"
                confmap["${k}"]="${v:-true}"
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
                actions+=( "clean" ); shift
                ;;
            generate)
                actions+=( "generate" ); shift
                ;;
            show)
                actions+=( "show" ); shift
                ;;
            "")
                die "Missing command"; shift
                ;;
            *)
                die "Invalid command: $1"; shift
                ;;
        esac
    done

    for action in "${actions[@]}"; do
        case "${action}" in
            clean)
                clean ;;
            generate)
                generate ;;
            show)
                show ;;
            *)
                die "Unknown action "${action}"" ;;
        esac
    done
} # End main

main "$@"
