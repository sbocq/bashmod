################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

if [ -z ${__MOD+x} ]; then
  __MOD=

  function getlibdir {
    echo ${LIBDIR:-$( cd $(dirname ${BASH_SOURCE[0]}) > /dev/null; pwd -P )}
  }


  ###
  ### MODULE DEBUG/TRACE FUNCTIONS LOGGING TO STDERR
  ###

  function qdebug {
    # Quick debug, to add and remove from code like printfs
    echo "-- $*" >&2
    return 0
  }

  function qtrace {
    # Quick trace, to add and remove from code like printfs
    local -r cmd="$1"
    shift;
    local -r args=$(IFS=','; echo "$*")
    qdebug "TRACE[$$]: ${cmd}(${args})"
    ${cmd} "$@"
  }

  function mod::debug_on {
    # Enable debug info on some modules
    local -r mods="$@"
    for mod in "$@"; do
      declare -g "${mod}_DEBUG=true"
    done
  }

  function mod::debug_off {
    # Disable debug info on some modules
    local -r mods="$@"
    for mod in "$@"; do
      declare -g "${mod}_DEBUG=false"
    done
  }

  function mod::debug {
    # Write module debug message
    local -r mod=$1 sym="${1}_DEBUG"
    shift;
    if [[ -n ${!sym+x} && ${!sym+x} ]]; then
      echo "-${mod}- '$*'" >&2
    fi
  }


  ###
  ### PROVIDE and REQUIRE
  ###

  function provide {
    local -r __LIB_NAME="__${1^^}"
    declare -g "${__LIB_NAME}=${1}"
  }

  function require {
    local -r __LIB_NAME="__${1^^}"
    [ -z ${!__LIB_NAME+x} ] \
      && $(mod::debug mod "require ${1}") \
      && source $(getlibdir)/${1}.sh
  }


  ###
  ### TRAPPING
  ###

  __EXIT_HOOKS=()

  function on_exit {
    __EXIT_HOOKS+=("$*")
  }

  function __trap {
    mod::debug mod "trapped exit $1"
    if (( ${#__EXIT_HOOKS[@] > 0} )); then
      mod::debug mod "exit hooks: "$(IFS=';';echo "${__EXIT_HOOKS[*]}")
      eval $(IFS=$';';echo "${__EXIT_HOOKS[*]}")
    fi
  }
  trap '__trap $?' EXIT INT TERM


  ###
  ### POOR MAN's UNIT TESTING FUCTIONS
  ###

  function assertEq {
    local -r msg=$1 expected=$2 actual=$3
    if [[ ${expected} != ${actual} ]]; then
      echo "FAIL[${msg}]! \"${expected}\" vs. \"${actual}\""
      return 1
    fi
  }

fi
