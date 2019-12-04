#!/bin/bash


gsrelease="19c"
gsversion="19.3"
pversion="1.0.5"
newgsrelease="19.d"
newgsversion="19.4"
newpversion="1.0.6"
notgitdir="-not -path '*/\.git/*'"
notdotsdir="-not -path '*/\.*'"
notthisfile="-not -path '*/${BASH_SOURCE[0]}'"
notreadme="-not -path '*/README.md'"
excludes="${notgitdir} ${notdotsdir} ${notreadme} ${notthisfile}"

function usage() {
cat <<EOF

# Exclude patterns
#   notgitdir="-not -path '*/\.git/*'"
#   notdotsdir="-not -path '*/\.*'"
#   notthisfile="-not -path '${BASH_SOURCE[0]}'"
#   notreadme="-not -path '*/README.md'"
#   excludes="${notgitdir} ${notdotsdir} ${notreadme} ${notthisfile}"

#
# Find Geosupport release ${gsrelease} or version ${gsversion}

  find . -type f -not -path '*/\.git/*' -exec grep -Iq . {} \; -print | xargs egrep -Hin --color '(${gsrelease}|${gsversion})' \$1

#
# Find Geosupport release and version ${gsrelease}_${gsversion}

  find . -type f -not -path '*/\.git/*' -exec grep -Iq . {} \; -print | xargs egrep -Hin --color '${gsrelease}_${gsversion}' \$1

#
# Find project version ${pversion}

  find . -type f -not -path '*/\.git/*' -exec grep -Iq . {} \; -print | xargs egrep -Hin --color '${pversion}' \$1

#
# Find and replace (on stdout only) Geosupport release and version ${gsrelease}_${gsversion} with ${newgsrelease}_${newgsversion}
# Ignore patterns:
#     ' ${excludes} '

find . -type f ${excludes} -exec grep -Iq . {} \; -print \
   | xargs sed 's/${gsrelease}_${gsversion}/${newgsrelease}_${newgsversion}/g' \$1

#
# Find and replace (on stdout only) project version ${pversion} with ${newpversion}

find . -type f -not -path '*/\.git/*' -exec grep -Iq . {} \; -print | xargs sed 's/${pversion}/${newpversion}/g' \$1

EOF
}

usage

