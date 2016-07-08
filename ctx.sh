################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
# CTX: Utility functions for manipulating flat contextes that are lists of key
# value pairs stored internally with first char separated strings.
#
# MODULE VARIABLES:
#
# - CTX_CFS: The default key-value separator char
#
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

require opts

CTX_CFS=$'\e'

function ctx::empty? {
  # An empty context contains only its sep char
  (( ${#1} == 1 ))
}

function ctx::make {
  if (( $# == 1 )); then
    #Assume it is already a context
    echo $1
  else
    echo ${CTX_CFS}$(IFS=${CTX_CFS};echo -nE "$*")
  fi
}

function ctx::add {
  local ctx0 ctx1
  if (( $# == 2 )); then
    # add two contextes
    ctx0=$1
    ctx1=$2
  else
    # append key-vals to the first context
    ctx0=$1
    shift;
    ctx1=$(ctx::make "$@")
  fi
  if ctx::empty? ${ctx0}; then
    echo ${ctx1}
  elif ctx::empty? ${ctx1}; then
    echo ${ctx0}
  else
    local cfs0=${ctx0:0:1}
    local cfs1=${ctx1:0:1}
    if [[ ${cfs0} != ${cfs1} ]]; then
      #TODO: Make sure the separator is not used or take the other one.
      ctx0+=${ctx1/${cfs1}/${cfs0}}
    else
      ctx0+=${ctx1}
    fi
    echo ${ctx0}
  fi
}

function ctx::get {
  local -r key=$1
  shift;
  local -r ctx="$@"

  local array
  IFS=${ctx:0:1} read -r -a array <<< "${ctx:1}"

  local found=""
  local -r len=${#array[@]}
  if (( len > 0 )); then
    local -i i=0
    while (( i < len )); do
      if [[ ${array[i++]} == ${key} ]]; then
        found=${array[i]}
      fi
      ((i++))
    done
  fi

  echo ${found}
}

function ctx::jsonify {
  local -r ctx="$@"
  local array
  IFS=${ctx:0:1} read -r -a array <<< "${ctx:1}"
  local -r re='^-?[0-9]+([.][0-9]+)?$'
  local r="{"
  if (( ${#array[@]} > 0 )); then
    local init=true is_key=true
    for kv in "${array[@]}"; do
      if ${is_key}; then
        if ${init}; then
          r+='"'${kv}'":'
          init=false
        else
          r+=',"'${kv}'":'
        fi
        is_key=false
      else
        if [[ ${kv} =~ ${re} ]]; then
          r+=${kv}
        else
          r+='"'${kv}'"'
        fi
        is_key=true
      fi
    done
  fi
  r+="}"

  echo $r
}

provide ctx

###
### `bash ctx.sh` to launch tests
###

if [ "$0" = "$BASH_SOURCE" ]; then
  set -e
  assertEq "assume ctx" "$(ctx::make a b)" "$(ctx::make $(ctx::make a b))"
  assertEq "0+0=0" "$(ctx::make)" "$(ctx::add $(ctx::make) $(ctx::make))"
  assertEq "preserve spaces" \
           "some data" "$(ctx::get a $(ctx::make a "some data"))"
  json=$(ctx::add "$(ctx::make "msg" "hi ho")" "$(ctx::make "ms" "ho hi")")
  jsona=$(ctx::add "$(ctx::make "msg" "hi ho")" ms "ho hi")
  assertEq "add and append" "${json}" "${jsona}"
  json=$(ctx::jsonify $(ctx::add "$(ctx::make "msg" "hi ho")" "ms" "ho hi"))
  assertEq "correct json" '{"msg":"hi ho","ms":"ho hi"}' "$json"
fi
