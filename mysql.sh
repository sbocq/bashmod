################################################################################
# The contents of this file is free and unencumbered software released into
# the public domain. For more information, please refer to
# <http://unlicense.org/>
################################################################################

###
# Create a persistent MySQL connection to a database DB
#
# These global variables are updated after each query:
#
# - ${DB}_RC stores the last count of updated rows.
#
# - ${DB}_RS stores the last result set in an array.
#
###
source ${LIB_DIR:-$(cd $(dirname "${BASH_SOURCE[0]}")>/dev/null;pwd -P)}/mod.sh
###

require opts
require log

__MYSQL_ERC_MARK="__rows="              # ending ROW_COUNT() mark (see MySQL ref)


function mysql::exit {
  local -r db=$1
  declare -n fds=${db} pid="${db}_PID"

  # No need to send "exit" in non-interactove mode
  if [[ -n ${pid+x} ]] && ps -p ${pid} > /dev/null; then
    exec {fds[1]}>&-
    exec {fds[0]}>&-
  fi
}

# Coproc can't be started in a subshell!
function mysql::connect {
  local -r defaults_file=$1
  local -r db=$(grep database ${defaults_file}|cut -d'=' -f2)

  on_exit "mysql::exit ${db}"
  eval "coproc ${db} {
    mysql --defaults-file=${defaults_file} -sss -n
  }"

  declare -n fds=${db} pid="${db}_PID"

  if ! ps -p ${pid} > /dev/null; then
    log::die "Can't start mysql" \
               "host" $host "port" $port "user" $user "db" ${db}
  fi
  mod::debug mysql "coproc fds=${#fds[@]}, pid=${pid}"
  declare -ag "${db}_RS=()"
  declare -ig "${db}_RC=0"

  db_name=${db}
}

function mysql::sql {
  local stmt=$1
  local -r db=$2

  mod::debug mysql "> ${stmt}"

  if [[ ! "${stmt}" =~ \;\$ ]]; then
    stmt+=";"
  fi

  stmt+='select concat("'${__MYSQL_ERC_MARK}'",ROW_COUNT());'

  declare -n fds=${db} rs="${db}_RS" rc="${db}_RC"
  rs=()
  rc=0

  echo "${stmt}" >&${fds[1]}

  local line status errno
  while true; do
    read -t 1 -ru ${fds[0]} line
    status=$?

    if [[ $status -gt 128 ]]; then
      errno=E_READ_TIMEOUT
    elif [[ $status -gt 0 ]]; then
      errno=E_READ_ERROR
    else
      errno=""
    fi
    if [[ -n ${errno} ]]; then
      log::error ${errno} "db" ${db} "status" $status
      return ${errno};
    fi

    if [[ ${line} == ${__MYSQL_ERC_MARK}* ]]; then
      rc=${line#${__MYSQL_ERC_MARK}}
      mod::debug mysql " < Affected rows ${rc}";
      return 0;
    else
      mod::debug mysql " ${line}"
      rs+=(${line})
    fi
  done
}

provide mysql

if [ "$0" = "$BASH_SOURCE" ]; then
  mod::debug_on mysql
  mysql::connect ~/.my-datacollector.cnf
  mysql::sql "show databases" datacollector
  kdebug $(IFS=';';echo "${datacollector_RS[*]}")
  mysql::sql "show databases" datacollector
  kdebug $(IFS=';';echo "${datacollector_RS[*]}")
  mysql::sql "show databases" datacollector
  mysql::sql "set @query_cache_size=0" datacollector
fi
