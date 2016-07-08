################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
# PS: Utility functions for working with processes
#
# MODULE VARIABLES:
#
# - CTX_CFS: The default key-value separator char
#
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

function ps::wait1 {
  # Wait for one child to finish and echo its pid (don't spawn in a subshell
  # else ctrl-x will interrupt it!)
  declare -n pid_var=$1
  shift;
  while :; do
    for pid in "$@"; do
      if ! kill -0 ${pid} 2> /dev/null; then
        wait ${pid}
        pid_var=${pid}
        return 0
      fi
      sleep 0.5
    done
  done
}

provide ps

if [ "$0" = "$BASH_SOURCE" ]; then
  set -e
  function foo {
    sleep 2;
  }
  function bar {
    sleep 3;
  }
  declare -A pids=()
  foo &
  pids[$!]="foo"
  bar &
  pids[$!]="bar"

  pid=$(ps::wait1 ${!pids[@]})
  assertEq "foo must terminate first" "foo" ${pids[$pid]}
  unset pids[${pid}]
  pid=$(ps::wait1 ${!pids[@]})
  assertEq "bar must terminate second" "bar" ${pids[$pid]}
  wait
fi

