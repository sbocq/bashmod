################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
# STR
# String utilities
#
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

function str::trim {
  # Remove leading & trailing whitespace from a Bash variable
  local var="$*"
  var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
  var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
  echo -n "$var"
}

function str::md5sum {
  local -a arr=( $(md5sum - <<< "$*") )
  echo ${arr[0]}
}

provide str

if [ "$0" = "$BASH_SOURCE" ]; then
  set -e
  assertEq "trim" "ba   ba" "$(str::trim "  ba   ba  ")"
fi
