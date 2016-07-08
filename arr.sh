################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
# arr.sh : Array utils
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

function arr::show {
  local -r array="$1[*]"
  echo $(IFS=','; echo "[${!array}]")
}

function arr::pos {
  local -r array="$1[@]" v=$2
  local -i pos=0
  for e in "${!array}"; do
    if [[ $e == $v ]]; then
      echo ${pos}
      return 0
    fi
    (( pos++ ))
  done
  echo -1
  return 1
}

function arr::contains? {
  arr::pos $1 "$2" > /dev/null
}

provide arr

if [ "$0" = "$BASH_SOURCE" ]; then
  set -e
  function with_local_test {
    local -r arr=(a b c "d e" f g)
    assert "$(arr::show arr) must not contain 'a b'" \
           $(! arr::contains? arr "a b")
    assert "$(arr::show arr) has no pos for 'a b'" \
           $(! arr::pos arr "a b")
    assertEq "$(arr::show arr) has no pos 'a b'" \
             "-1" $(arr::pos arr "a b")
    assert "$(arr::show arr) must contain 'd e'" \
           $(arr::contains? arr "d e")
    assert "$(arr::show arr) has pos for 'd e'" \
           $(arr::pos arr "d e")
    assertEq "$(arr::show arr) has pos 'd e'" \
           "3" $(arr::pos arr "d e")
  }
  with_local_test
fi
