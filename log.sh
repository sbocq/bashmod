################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
# log.sh : Logging utils based on contextes (see ctx.sh)
#
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

require errs
require ctx
require arr

#global scope even to other files ssuch that we can use 'arr' module methods
declare -rg __LOG_LVLS=(Dbg Inf Wrn Err)
for i in ${!__LOG_LVLS[@]}; do
  declare -ig "${__LOG_LVLS[i]}=$i"
done

LOG_JSON_FULL=${LOG_JSON_FULL:-false}
LOG_LVL=${LOG_LVL:-Inf}

function log::set_lvl {
  local lvl=${1^}
  if [[ ${lvl:0:1} == "V" ]]; then
    lvl=${lvl:0:3}
    lvl=${__LOG_LVLS[- (${#lvl} + 1)]}
  fi
  if ! arr::contains? __LOG_LVLS ${lvl}; then
    echo "log.sh: Err - Log level ${lvl} not in $(arr::show __LOG_LVLS)" >&2
    exit ${E_ERROR}
  fi
  LOG_LVL=${lvl}
}

function log::debug? {
    [ ${LOG_LVL} = Dbg ]
}

function log::set_file {
  local -r log_file=$1
  ensure $(dirname ${log_file})
  LOG_FILE=${log_file}
  LOG_ERROR_FILE=${log_file}
}

function log::set_error_file {
  local -r log_file=$1
  ensure $(dirname ${log_file})
  LOG_ERROR_FILE=${log_file}
}

function log::to_stderr {
  unset LOG_FILE
  unset LOG_ERROR_FILE
}

function log::set_pid_name {
  LOG_PID_NAME=$1
}

function log::log {
  local -r lvl=${1^} msg="$2"
  if (( lvl < ${!LOG_LVL} )); then
     return 0
  fi

  shift;shift;
  local -r ctx=$(ctx::make "$@") date="$(date +"%FT%T")"

  local line pid=$$
  [ ! -z ${LOG_PID_NAME+x} ] && pid+="/${LOG_PID_NAME}"

  if ${LOG_JSON_FULL}; then
    local -r base_ctx=$(ctx::make "date" "${date}" \
                                  "pid" ${pid} \
                                  "lvl" ${lvl} \
                                  "msg" "${msg}")
    line=$(ctx::jsonify "$(ctx::add "${base_ctx}" "${ctx}")")
  else
    line="${date} ${pid} ${lvl} \"${msg}\""
    if ! ctx::empty? ${ctx}; then
      line+=" "$(ctx::jsonify "${ctx}")
    fi
  fi

  case ${lvl} in
    Dbg|Inf)
      if [ -z ${LOG_FILE+x} ]; then
        echo ${line} >&2
      else
        echo ${line} >> ${LOG_FILE}
      fi
      ;;
    *)
      echo ${line} >&2
      if [ ! -z ${LOG_FILE+x} ]; then
        echo ${line} >> ${LOG_FILE}
      fi
      if [ ! -z ${LOG_ERROR_FILE+x} ]; then
        echo ${line} >> ${LOG_ERROR_FILE}
      fi
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
  log::set_lvl Inf
  log::debug "a message not visible" a "some data" n 1

  log::set_lvl v
  log::debug "a message not visible" a "some data" n 1

  log::set_lvl vv
  log::debug "a message not visible" a "some data" n 1

  log::set_lvl vvv
  log::debug "a message" a "some data" n 1
  # => 2016-07-08T11:37:13 13383 Dbg "a message" {"a":"some data","n":1}

  log::set_lvl Dbg
  log::debug "a message" a "some data" n 1
  # => 2016-07-08T11:37:13 13383 Dbg "a message" {"a":"some data","n":1}

  LOG_JSON_FULL=true
  log::error "a message" a "some data" n 1
  # => {"date":"2016-07-08T11:37:13","pid":13383,"lvl":"Dbg","msg":"a message","a":"some data","n":1}
fi
