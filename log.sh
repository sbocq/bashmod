################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
# log.sh : Logging utils based on contextes (see ctx.sh)
#
# Uses filedescriptor 106 to regirect logs to stdout.
#
# MODULE VARIABLES:
#
# - LOG_JSON_FULL(default:false): A log line is a full JSON message when
# LOG_JSON_FULL=true, otherwise only the context passed as argument after the
# messages to log functions is jsonified.
#
# - LOG_FD(default:106): Copy of stdout descriptor descriptor used to do
# uninterpreted output of debug and info messages, unless LOG_FILE is set.
#
# - LOG_FILE(default: none): File to log debug and info messages. If unset, logs
# will be outupt to stdout. See LOG_FD.
#
# - LOG_LVL(default: Inf): Min log level, one of Dbg, Inf, Wrn, Err
#
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

require errs
require ctx

readonly __LOG_LVLS=(Dbg Inf Wrn Err)
for i in ${!__LOG_LVLS[@]}; do
  declare -ig "${__LOG_LVLS[i]}=$i"
done

LOG_JSON_FULL=${LOG_JSON_FULL:-false}
LOG_FD=${LOG_FD:-106}
LOG_LVL=Inf

# Duplicate stdout into a new file descriptor that to output strings that are not
# interpreted as commands by bash
if [ -z ${LOG_FILE+x} ]; then
  exec {LOG_FD}>&1
fi

function log::log {
  local -r lvl=${1^} msg="$2"
  if (( lvl < ${!LOG_LVL} )); then
     return 0
  fi

  shift;shift;
  local -r ctx=$(ctx::make "$@")

  local line
  local -r date="$(date +"%FT%T")" pid=$$
  if ${LOG_JSON_FULL}; then
    local -r base_ctx=$(ctx::make "date" "${date}" \
                                  "pid" ${pid} \
                                  "lvl" ${lvl} \
                                  "msg" "${msg}")
    line=$(ctx::jsonify $(ctx::add "${base_ctx}" "${ctx}"))
  else
    line="${date} ${pid} ${lvl} \"${msg}\""
    if ! ctx::empty? ${ctx}; then
      line+=" "$(ctx::jsonify "${ctx}")
    fi
  fi

  case ${lvl} in
    Dbg|Inf)
      if [ -z ${LOG_FILE+x} ]; then
        echo ${line} >&${LOG_FD}
      else
        echo ${line} >> ${LOG_FILE}
      fi
      ;;
    *)
      echo ${line} >&2
      ;;
  esac
}

function log::debug {
  local -r msg=$1
  shift;
  log::log dbg "${msg}" "$@"
}

function log::info {
  local -r msg=$1
  shift;
  log::log inf "${msg}" "$@"
}

function log::warn {
  local -r msg=$1
  shift;
  log::log wrn "${msg}" "$@"
}

function log::error {
  local -r msg=$1
  shift;
  log::log err "${msg}" "$@"
}

function log::die {
  local -r msg="$1"
  local -r re='^[0-9]+$'
  if [[ ${msg} == E_* ]]; then
    shift;
    log::error "$@"
    exit ${!msg:-$E_ERROR}
  elif [[ ${msg} =~ ${re} ]]; then
    shift;
    log::error "$@"
    exit ${msg}
  else
    log::error "$@"
    exit ${E_ERROR}
  fi
}

provide log

###
### Visual tests
###

if [ "$0" = "$BASH_SOURCE" ]; then
  LOG_LVL=Dbg
  log::debug "a message" a "some data" n 1
  # => 2016-07-08T11:37:13 13383 Dbg "a message" {"a":"some data","n":1}

  LOG_JSON_FULL=true
  log::debug "a message" a "some data" n 1
  # => {"date":"2016-07-08T11:37:13","pid":13383,"lvl":"Dbg","msg":"a message","a":"some data","n":1}
fi
