#!/bin/bash
# usage: 在MHA manager上运行, 用于初始化配置文件
# author: prontera@github

#set -x
set -eo pipefail
shopt -s nullglob
dir_cnf=/mha_share
file_cnf="$dir_cnf"/application.cnf
generated_flag="# generated"

# 传输需要检测的参数的名称, 如果不存在则抛出异常
check_env(){
    local var="$1"
    if [[ -z ${!var:-} ]]; then
        echo >&2 "$HOSTNAME the environment variable \"$var\" do not exist!"
    fi
}

append_to_conf(){
    echo "$@" >> "$file_cnf"
}

init_conf(){
    check_env "MYSQL_REPL_NAME"
    check_env "MYSQL_REPL_NAME"
    check_env "MYSQL_REPL_NAME"
    check_env "MYSQL_REPL_PASSWORD"
    check_env "MYSQL_MHA_NAME"
    check_env "MYSQL_MHA_PASSWORD"

    append_to_conf "$generated_flag"
    append_to_conf "user=${MYSQL_MHA_NAME}"
    append_to_conf "password=${MYSQL_MHA_PASSWORD}"
    append_to_conf "repl_user=${MYSQL_REPL_NAME}"
    append_to_conf "repl_password=${MYSQL_REPL_PASSWORD}"

    i=1
    for arg; do
        if [[ "$arg" != "manager" ]]; then
            append_to_conf "[server$i]"
            append_to_conf "hostname=$arg"
            append_to_conf "candidate_master=1"
            echo "added host \"$arg\" to mha configuration file."
            ((i++))
        fi
    done
}

if grep "$generated_flag" "$file_cnf" >& /dev/null; then
    echo "\"$file_cnf\" has been modified, skipping..."
else
    echo "mha configuration \"$file_cnf\" is not initialized."
    init_conf "$@"
fi

echo "**********************************************"
echo "checking mha ssh..."
masterha_check_ssh --conf="$file_cnf"
echo "**********************************************"
echo "checking mha repl to mysql..."
masterha_check_repl --conf="$file_cnf"

if [ "$(ps aux | pgrep '/usr/local/bin/masterha_manager' || echo $?)" == 1 ]; then
    echo "**********************************************"
    echo "starting mha manager with file \"$file_cnf\"..."
    nohup masterha_manager --conf="$file_cnf" >>$dir_cnf/mha.log &
    sleep 1
else
    echo "**********************************************"
    echo "mha manager process has been running already..."
fi
exit 0
