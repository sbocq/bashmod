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
  # Wait for one child to finish and set its pid (don't spawn in a subshell
  # else ctrl-C will interrupt it!)
  declare -n pid_var=$1
  shift;
  if (( $# == 0 )); then
    return
  fi
  local ppid
  while :; do
    for pid in "$@"; do
      ppid=$(ps -o ppid= -p ${pid} 2>&-)
      # If pid does not exist or has been reused (i.e. its parent pid is not
      # this process), then wait for it.
      if [[ $? != "0" || ${ppid} != "$$" ]]; then
        #http://unix.stackexchange.com/questions/116098/\
        #reliable-return-code-of-background-process - When many processes are
        #spawned, 'wait' may prints 'pid xxxx is not a child of this shell' on
        #stderr and return a status=127. Parent and children must agree on a
        #location to store the return status such that the parent can retrieve
        #it reliably.
        wait ${pid} 2>&-
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

