################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
# fs.sh : Filesystem utilities
#
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

function fs::du {
  du -s${2:-m} "$1" 2>&-|cut -d$'\t' -f1
}

function fs::mdate {
  local tmp=$(stat --printf "%y" $1)
  echo ${tmp%.*}
}

provide fs
