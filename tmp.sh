################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
#
# Managing temp files
#
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

TMP_DIR=${TMP_DIR:-"$(dirname $(mktemp -u))/${PRG_NAME:-$(basename "$0")}/$$"}
mkdir -p ${TMP_DIR}
mod::on_exit 'rm -rf '"${TMP_DIR}"

function tmp::make {
  local -r template="$1"
  echo $(mktemp -p "${TMP_DIR}" "${template}")
}

provide tmp
