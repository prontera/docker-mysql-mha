#!/bin/bash
# usage: 容器之间的ssh-copy-id
# author: prontera@github

#set -x
set -eo pipefail
shopt -s nullglob

var_pass=SSH_ROOT_PASSWORD

# 检测调用者是否有传入参数
check_args_empty(){
    if [[ "$#" == 0 ]]; then
        echo >&2 "$HOSTNAME option can not be an empty list when processing sshpass command!"
    fi
}

# 检测是否已经初始化ssh
check_ssh_init(){
    if [[ ! -e "$HOME/.ssh/id_rsa.pub" ]]; then
        echo >&2 "$HOSTNAME please generate ssh key first before processing sshpass command!"
        exit 1
    fi
}

# 多参函数
# 迭代参数中的container id, 使用ssh-copy-id实现无密码登录
ssh-copy(){
    local password=${!var_pass:-}
    for ip do
        sshpass &> /dev/null -p "$password" ssh-copy-id -o StrictHostKeyChecking=no root@"$ip" \
            && echo "$HOSTNAME copy ssh key to $ip successfully." || echo &>2 "$HOSTNAME fail to copy ssh key to $ip !"
    done
}

check_args_empty "$@"
check_ssh_init
ssh-copy "$@"
exit 0
