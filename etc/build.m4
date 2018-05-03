#!/bin/bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.6.1
# ARG_OPTIONAL_SINGLE([tag], t, [Tag to use when building or referencing images. Defaults to 'latest'], [latest])
# ARG_OPTIONAL_SINGLE([volume], l, [Name of volume to use when creating or referencing volumes. Defaults to 'vol-geosupport'], [vol-geosupport])
# ARG_OPTIONAL_SINGLE([flavor], f, [Flavor of image to operate on. Possible values are 'all','onbuild','dvc','default'. Defaults to 'all'], [all])
# ARG_OPTIONAL_BOOLEAN([print], , [Print commands to stdout instead of running them (default: on).], [on])
# ARG_OPTIONAL_BOOLEAN([debug], , [Enable debug information (default: off).], [off])
# ARG_POSITIONAL_SINGLE([geosupport-release], [Geosupport release. E.g., 18a], )
# ARG_POSITIONAL_SINGLE([geosupport-version], [Geosupport version. E.g., 18.1], )
# ARG_DEFAULTS_POS
# ARG_HELP([Minimal script for reviewing and executing image, volume and container commands for geoclient-docker])
# ARG_VERSION([echo $0 v1.0.0-SNAPSHOT])
# ARGBASH_SET_INDENT([  ])
# ARGBASH_GO

# [ <-- needed because of Argbash

if [[ $_arg_debug == on ]]; then
  printf '%s: %s\n' 'geosupport-release' "$_arg_geosupport_release"
  printf '%s: %s\n' 'geosupport-version' "$_arg_geosupport_version"
  printf '%18s: %s\n' 'tag' "$_arg_tag"
  printf '%18s: %s\n' 'volume' "$_arg_volume"
  printf '%18s: %s\n' 'flavor' "$_arg_flavor"
  printf '%18s: %s\n' 'print' "$_arg_print"
  printf '%18s: %s\n' 'debug' "$_arg_debug"
fi

# ] <-- needed because of Argbash
