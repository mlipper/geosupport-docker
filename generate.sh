#!/usr/bin/env bash

set -Eeuo pipefail

#
# Globals
#

# CLI non-option parameters
declare -a actions

# Hashtable of build properties-to-values
declare -A confmap

# Default property values
BUILD_DIR=

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
      clean         Remove the local build directory.

      generate      Generate project source using *.template files release.conf.

      show          Print build properties and their values, sorted, to stdout. 

EOF
}

#
# Print log messages to stdout.
#
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

#
# Deletes the build directory.
#
clean() {
    log "CLEAN" "Removing build directory ${BUILD_DIR}..."
    rm -rf "${BUILD_DIR}" || die "Error: could not remove build directory ${BUILD_DIR}."
    log "CLEAN" "Build directory ${BUILD_DIR} removed."
}

#
# Create an associative array using the keys and values from the file
# argument passed to this function.
#
_init_confmap() {
    [[ -f "$1" ]] || die "File $1 does not exist."
    local conf="$1"
    local key
    local val
    while IFS= read -r line || [ -n "$line" ]; do # non-empty test insures last
                                                  # line is read even without a
                                                  # trailing newline.
        if ! [[ "$line" =~ ^\# ]] \
          && ! [[ "$line" =~ ^$ ]]; then # Skip comments, blank lines
            key="${line%%=*}"
            val="${line#*=}"
            confmap["${key}"]="${val}"
            #log "DEBUG" "${key}: ${val}"
        fi
    done < "${conf}"
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
_conf2sedf() {
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

#
# Initializes any derived properties which have not been set from the
# configuration file or script parameters but are required.
#
# NOTE: Global variables (e.g., BUILD_DIR) are _not_ available yet
#       when this function gets called.
#
_set_missing_props() {
    local version_prefix="${confmap[geosupport_major]}${confmap[geosupport_release]}${confmap[geosupport_patch]}_${confmap[geosupport_major]}"
    if [[ ! -n "${confmap[geosupport_fullversion]}" ]]; then
        # Uses '.' to separate major and minor version (unlike 'gsd_dcp_distfile' below)
        confmap["geosupport_fullversion"]="${version_prefix}.${confmap[geosupport_minor]}"
    fi
    if [[ ! -n "${confmap[gsd_dcp_distfile]}" ]]; then
        # Uses '_' to separate major and minor version (unlike 'geosupport_fullversion' above)
        confmap["gsd_dcp_distfile"]="linux_geo${confmap[geosupport_major]}${confmap[geosupport_release]}${confmap[geosupport_patch]}_${confmap[geosupport_major]}_${confmap[geosupport_minor]}.zip"
    fi
}

_prepare_build_dir() {
    # Create the build directory
    mkdir -p "${BUILD_DIR}"
    # Copy non-templated files to build directory
    cp geo_h.patch "${BUILD_DIR}"
    cp "${confmap[gsd_distdir]}/${confmap[gsd_dcp_distfile]}" "${BUILD_DIR}"
}

#
# Generates a script for invoking 'docker build' from the $BUILD_DIR.
#
# TODO Add error handling for macos if GNU readlink isn't available.
#
#      # Better:
#      Error: GNU readlink required. Install coreutils with brew and
#      see 'Caveats' message to place gnubin first on the PATH.
#        or
#      # Worse:
#      if [[ \$(uname) =~ Darwin ]]; then
#        cd "\$(dirname "\$(greadlink -f "\$BASH_SOURCE")")"
#      else
#        cd "\$(dirname "\$(readlink -f "\$BASH_SOURCE")")"
#      fi
#
_gen_build_script() {
    local scriptf="${BUILD_DIR}/build-image.sh"
    cat <<- EOF > "${scriptf}"
#!/usr/bin/env bash

set -Eeuo pipefail

cd "\$(dirname "\$(readlink -f "\$BASH_SOURCE")")"

docker build -t "geosupport_docker:${confmap[gsd_version]}"  .

EOF
    chmod +x "${scriptf}"
    echo "$(basename "${scriptf}")" > "${BUILD_DIR}/.dockerignore"
}

generate() {
    log "GENERATE" "Generating source files from templates..."
    _prepare_build_dir
    local sedf="${BUILD_DIR}/release.sed"
    # Generate sedfile from key-value pairs in release.conf
    _conf2sedf "${sedf}"
    # Run sed against all *.template files to replace token strings (@<string>@)
    # with configuration values using the patterns in the generated sedfile
    for tplf in $(ls *.template); do
        sed -f "${sedf}" <"${tplf}" >"${BUILD_DIR}/${tplf%%.template}"
    done
    rm "${sedf}"
    _gen_build_script
    log "GENERATE" "Source file generation complete."
}

show() {
    declare -a keys
    printf '\n'
    printf ' %-30s %-40s\n' 'Property' 'Value'
    printf ' %-30s %-40s\n' '------------------------------' '----------------------------------------'
    keys=$(echo ${!confmap[@]} | tr ' ' '\012' | sort | tr '\012' ' ')
    for property in ${keys}; do
        value="${confmap[${property}]}"
        printf ' %-30s %-40s\n' "${property}" "${value}"
    done
    printf '\n'
    printf ' %-30s\n' 'Actions'
    printf ' %-30s\n' '------------------------------'
    for a in "${actions[@]}"; do
        printf ' %-30s\n' "${a}"
    done
    printf '\n'
}

main() {

    [ $# -eq 0 ] && usage

    # Initialize confmap from from file __first__. This way, properties
    # from the commandline will have precedence over those that
    # also exist in the file.
    _init_confmap release.conf

    while [ $# -gt 0 ]; do
        # Necessary!
        OPTIND=1
        while getopts "hp:" opt; do
            case "${opt}" in
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

    # Default optional properties not given at the commandline
    _set_missing_props

    BUILD_DIR="${confmap[gsd_builddir]}"

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
