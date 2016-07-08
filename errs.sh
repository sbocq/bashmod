################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

readonly E_ERROR=1                      # Some error
readonly E_INIT=2                       # Initialization error
readonly E_READ_ERROR=11                # Some read error occured
readonly E_READ_TIMEOUT=12              # A read timeout occured

provide errs
