################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
# DATE: Date utilities
#
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

function date::utcDate2epoch {
  date --utc -d "$1" +%s
}

function date::epoch2utcDate {
  local -r epoch=$1
  shift;
  date --utc -d @$epoch "$@"
}

provide date

###
### `bash date.sh` to launch tests
###

if [ "$0" = "$BASH_SOURCE" ]; then
  set -e
  assertEq "utcDate2epoch" 1451606400 $(date::utcDate2epoch "00:00 2016-01-01")
  assertEq "epoch2utcDate" "Fri Jan  1 00:00:00 UTC 2016" "$(date::epoch2utcDate 1451606400)"
  assertEq "epoch2utcDate2" "160101" "$(date::epoch2utcDate 1451606400 +%y%m%d)"
fi

