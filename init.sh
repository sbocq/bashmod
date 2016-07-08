################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
# init.sh : common init utilities
#
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

require errs
require log

function init::chk_req_parms {
  local -r req_parms="$@"
  local missing=()
  local parm_name
  for parm_name in "${req_parms[@]}"; do
    if [[ -z "${!parm_name:=}" ]]; then
      missing+=("'${parm_name}'")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    log::die E_INIT "Required option parameters not specified" \
             "parms" $(IFS=","; echo "${missing[*]}")
  fi
}

###
###
###

function init::chk_req_progs {
  # Required program(s)
  local -r req_progs="$@"
  local missing=()
  for prog_name in ${req_progs[@]}; do
    if ! hash "${prog_name}" 2>&-; then
      missing+=("'${prog_name}'")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    log::die E_INIT "Required programs not installed or in search PATH." \
             "progs" $(IFS=","; echo "${missing[*]}")
  fi
}

provide init

if [ "$0" = "$BASH_SOURCE" ]; then
  set -e
  FOO=X
  BAR=Y
  init::chk_req_parms FOO BAR
  init::chk_req_progs bash
fi
