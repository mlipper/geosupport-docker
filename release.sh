#!/usr/bin/env bash

set -Eeuo pipefail

#
# Globals
#

# CLI non-option parameters
declare -a actions

# Hashtable of build properties-to-values
declare -A confmap

# Generated file names used for release
declare -a RELEASE_FILES=('README-release.md' 'Dockerfile' 'Dockerfile.dist')

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
      --property=<name>[=<value>]  Build property name and optional value.

                    --property=<name>=<value>
                        Everything after the first occurance of the '='
                        character (including other '=' characters) is
                        considered the value.
                        Surround the entire value with quotes
                        if it contains spaces.

                    --property=<name>
                        Property names cannot contain spaces. The value
                        will be defaulted to <name>.

                    The '--property' option may be specified multiple times.

    Actions:
      build         Runs "${BUILD_DIR}/build.sh build [--latest][--variant=<dist|default>]"

      clean         Remove the local build directory.

      createvol     Runs "${BUILD_DIR}/build.sh createvol [--volname=<name>]"

      custombasedir Runs ${BUILD_DIR}/custombasedir.sh [--path=<path>]

      exportdist    Runs "${BUILD_DIR}/build.sh exportdist [--exportdir=<path>]"

      generate      Generate project source using *.template files release.conf.

      help          Show this usage message and exit

      helpbuild     Show the usage message for ${BUILD_DIR}/build.sh and exit.

      helpcustom    Show the usage message for ${BUILD_DIR}/custombasedir.sh and exit.

      release       Create a new release folder and populate it with relevant
                    build artifacts.

      show          Print build properties and their values, sorted, to stdout.
    
    Notes:
      Actions which invoke the "${BUILD_DIR}/build.sh" script behave as
      follows:
                    Fails if the 'generate' command from this script hasn't
                    been run.
                    Accepts the same arguments as the actions in the
                    target script.

      Use 'helpbuild' from this script to see the usage of build.sh.
      If all else fails, run "${BUILD_DIR}/build.sh" directly.

      For information on the custombasedir action see the comments at the top
      of file:
      "${BUILD_DIR}/custombasedir.sh"

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
            _setc "${key}" "${val}"
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
# Echos the value of the given configuration key to stdout if
# it exists in the confmap global.
# $1 = Key string
#
_getc() {
    local key=$1
    [[ -z "${key}" ]] && return
    local value="${confmap[${key}]}"
    [[ -n "${value}" ]] && echo "${value}"
}

#
# Sets confmap value using the given key.
# $1 = Key string
# $2 = Value
#
_setc() {
    local key=$1
    local value=$2
    confmap["${key}"]="${value}"
}

#
# Initializes any derived properties which have not been set from the
# configuration file or script parameters but are required.
#
# NOTE: Global variables (e.g., BUILD_DIR) are _not_ available yet
#       when this function gets called.
#
_set_missing_props() {
    # Usually, buildtz property will not be set and the 'TZ=' date format
    # argument will be empty: i.e., timezone uses default value.
    local tz="$(_getc buildtz)"
    if [[ ! -n "$(_getc buildtimestamp)" ]]; then
        local timestamp="$(TZ="${tz}" date)"
        _setc "buildtimestamp" "${timestamp}"
    fi
    if [[ ! -n "$(_getc release_date)" ]]; then
        local releasedt="$(TZ="${tz}" date +"%B %d, %Y")"
        _setc "release_date" "${releasedt}"
    fi
    if [[ ! -n "$(_getc release_majorminor)" ]]; then
        local tagmajor
        local tagminor
        local tagpoint
        IFS=. read tagmajor tagminor tagpoint < <(echo "$(_getc image_tag)")
        _setc "release_majorminor" "${tagmajor}.${tagminor}"
    fi
    local major="$(_getc geosupport_major)"
    local release="$(_getc geosupport_release)"
    local patch="$(_getc geosupport_patch)"
    local minor="$(_getc geosupport_minor)"
    local version_prefix="${major}${release}${patch}_${major}"
    if [[ ! -n "$(_getc geosupport_fullversion)" ]]; then
        _setc "geosupport_fullversion" "${version_prefix}.${minor}"
    fi
    if [[ ! -n "$(_getc dcp_distfile)" ]]; then
        _setc "dcp_distfile" "geo${version_prefix}.${minor}.zip"
    fi
    # Set vcs_ref if it is available
    #local vcs_ref="unknown"
    #if command -v git &> /dev/null; then
    #    vcs_ref="$(git rev-parse --short HEAD)"
    #fi
    #_setc "vcs_ref" "${vcs_ref}"
}

_prepare_build_dir() {
    # Create the build directory
    mkdir -p "${BUILD_DIR}"
    # Copy non-templated files to build directory
    cp geo_h.patch "${BUILD_DIR}"
    cp "$(_getc distdir)/$(_getc dcp_distfile)" "${BUILD_DIR}"
}

#
# Runs housekeeping tasks once build generation is complete.
#
_post_generate() {
    # Declaring an array in a function automatically makes it local
    # unless the -g option is given.
    declare -a scripts=( "${BUILD_DIR}/build.sh" "${BUILD_DIR}/custombasedir.sh" )
    for script in "${scripts[@]}"; do
        chmod +x "${script}"
        echo "$(basename "${script}")" > "${BUILD_DIR}/.dockerignore"
    done
}

generate() {
    log "GENERATE" "Generating source files from templates..."
    _prepare_build_dir
    local sedf="${BUILD_DIR}/release.sed"
    # Generate sedfile from key-value pairs in release.conf
    _conf2sedf "${sedf}"
    # Run sed against all *.template files to replace token strings (@<string>@)
    # with configuration values using the patterns in the generated sedfile
    for tplf in $(ls templates/*.template); do
        sed -f "${sedf}" <"${tplf}" >"${BUILD_DIR}/$(basename ${tplf%%.template})"
    done
    rm "${sedf}"
    _post_generate
    log "GENERATE" "Source file generation complete."
}

release() {
    log "RELEASE" "Creating release files from build..."
    [[ -d "${BUILD_DIR}" ]] ||
        die "Release error: ${BUILD_DIR} does not exist. Hint: Run generate command first."
    local img_tag="$(_getc image_tag)"
    local gs_fullversion="$(_getc geosupport_fullversion)"
    mkdir -p "${img_tag}/geosupport-${gs_fullversion}"
    for f in "${RELEASE_FILES[@]}"; do
        [[ -f "${BUILD_DIR}/${f}" ]] ||
            die "Release error: ${BUILD_DIR}/${f} does not exist. Hint: Run generate command first."
        if [[ "${f}" == "README-release.md" ]]; then
            cp "${BUILD_DIR}/${f}" "${img_tag}/README-${img_tag}.md"
        else
            cp "${BUILD_DIR}/${f}" "${img_tag}/geosupport-${gs_fullversion}/${f}"
        fi
    done
    sed -i.bak "s:^\*\*Version [0-9]\.[0-9]\.[0-9][0-9]*.*:**Version ${img_tag}** [release notes](./${img_tag}/README-${img_tag}.md).:g" README.md
    log "RELEASE" "Release file generation complete."
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

    local variant=
    local latest=
    local volname=
    local exportdir=
    local path=

    while [ $# -gt 0 ]; do

        # Access remaining positional parameters.
        case "$1" in
            build)
                actions+=( "build" ); shift
                ;;
            clean)
                actions+=( "clean" ); shift
                ;;
            createvol)
                actions+=( "createvol" ); shift
                ;;
            custombasedir)
                actions+=( "custombasedir" ); shift
                ;;
            exportdist)
                actions+=( "exportdist" ); shift
                ;;
            generate)
                actions+=( "generate" ); shift
                ;;
            help)
                actions+=( "help" ); shift
                ;;
            helpbuild)
                actions+=( "helpbuild" ); shift
                ;;
            helpcustom)
                actions+=( "helpcustom" ); shift
                ;;
            release)
                actions+=( "release" ); shift
                ;;
            show)
                actions+=( "show" ); shift
                ;;
            --property=*)
                local prop="${1##--property=}"
                local k="${prop%%=*}"
                local v="${prop#*=}"
                _setc "${k}" "${v:-true}"
                shift
                ;;
            --variant=*)
                variant="$1"; shift
                ;;
            --latest)
                latest="$1"; shift
                ;;
            --volname=*)
                volname="$1"; shift
                ;;
            --exportdir=*)
                exportdir="$1"; shift
                ;;
            --path=*)
                path="$1"; shift
                ;;
            "")
                die "Missing command"; shift
                ;;
            --*)
                die "Invalid option: $1"; shift
                ;;
            *)
                die "Invalid command: $1"; shift
                ;;
        esac
    done

    # Default optional properties not given at the commandline
    _set_missing_props

    BUILD_DIR="$(_getc builddir)"

    local build_exists=
    [[ -f "${BUILD_DIR}/build.sh" ]] && build_exists="true"

    local build_args=()
    for action in "${actions[@]}"; do
        case "${action}" in
            build)
                [[ -z "${build_exists}" ]] &&
                    die "[ERROR] Must run 'generate' before running 'build'.";
                [[ -n "${variant}" ]] && build_args+=( "${variant##--variant=}" )
                [[ -n "${latest}" ]] && build_args+=( "--latest" )
                echo "Running build with ${build_args[*]}"
                "${BUILD_DIR}"/build.sh build "${build_args[@]}"
                ;;
            clean)
                clean ;;
            createvol)
                [[ -z "${build_exists}" ]] &&
                    die "[ERROR] Must run 'generate' before running 'createvol'.";
                "${BUILD_DIR}"/build.sh createvol "${volname}"
                ;;
            custombasedir)
                [[ -z "${build_exists}" ]] &&
                    die "[ERROR] Must run 'generate' before running 'custombasedir'.";
                if [[ -n "${path}" ]]; then
                    echo "Running custombasedir with path: ${path}"
                    "${BUILD_DIR}"/custombasedir.sh --path="${path}"
                else
                    echo "Running custombasedir with default path."
                    "${BUILD_DIR}"/custombasedir.sh
                fi
                ;;
            exportdist)
                [[ -z "${build_exists}" ]] &&
                    die "[ERROR] Must run 'generate' before running 'exportdist'.";
                    if [[ -n "${exportdir}" ]]; then
                        "${BUILD_DIR}"/build.sh exportdist --exportdir="${exportdir}"
                    else
                        "${BUILD_DIR}"/build.sh exportdist
                    fi
                ;;
            generate)
                generate ;;
            help)
                usage | more && exit 0;
                ;;
            helpbuild)
                [[ -z "${build_exists}" ]] &&
                    die "[ERROR] Must run 'generate' before running 'helpbuild'.";
                "${BUILD_DIR}"/build.sh help;
                ;;
            helpcustom)
                [[ -z "${build_exists}" ]] &&
                    die "[ERROR] Must run 'generate' before running 'helpcustom'.";
                "${BUILD_DIR}"/custombasedir.sh help;
                ;;
            release)
                release ;;
            show)
                show ;;
            *)
                die "Unknown action "${action}"" ;;
        esac
    done
} # End main

main "$@"
