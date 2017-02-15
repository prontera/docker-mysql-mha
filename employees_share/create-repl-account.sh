#!/bin/bash
# usage: 生成MySQL的复制账户
# author: prontera@github

#set -x
set -eo pipefail
shopt -s nullglob

if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
    echo "$HOSTNAME please set the environment variable MYSQL_ROOT_PASSWORD first!"
    exit 1
fi

mysql=( mysql -p"$MYSQL_ROOT_PASSWORD" )

for i in {30..0}; do
	if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
		break
	fi
	echo "$HOSTNAME MySQL init process in progress..."
	sleep 2
done
if [ "$i" = 0 ]; then
	echo >&2 "$HOSTNAME MySQL init process failed."
	exit 1
fi

"${mysql[@]}" <<-EOSQL
	GRANT REPLICATION SLAVE ON *.* TO "$MYSQL_REPL_NAME"@"172.%" IDENTIFIED BY "${MYSQL_REPL_PASSWORD:-}";
	GRANT ALL PRIVILEGES ON *.* TO "$MYSQL_MHA_NAME"@"172.%" IDENTIFIED BY "${MYSQL_MHA_PASSWORD:-}";
	GRANT REPLICATION SLAVE ON *.* TO "$MYSQL_REPL_NAME"@"192.%" IDENTIFIED BY "${MYSQL_REPL_PASSWORD:-}";
	GRANT ALL PRIVILEGES ON *.* TO "$MYSQL_MHA_NAME"@"192.%" IDENTIFIED BY "${MYSQL_MHA_PASSWORD:-}";
	FLUSH PRIVILEGES;
EOSQL
