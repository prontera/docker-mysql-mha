#!/bin/bash
# usage: 从环境变量中读取SSH_ROOT_PASSWORD的值, 用于设置容器中的root用户密码
# author: prontera@github

#set -x
set -eo pipefail
shopt -s nullglob

var_pass=SSH_ROOT_PASSWORD

# 无参函数
# 根据环境变量SSH_ROOT_PASSWORD修改当前的root密码
change_password(){
    local password=${!var_pass:-}
    # 检测是否存在对应的环境变量
    if [[ ! "$password" ]]; then
        echo "$(tput setaf 1)" "$HOSTNAME please set the environment variable SSH_ROOT_PASSWORD first!" "$(tput sgr0)"
        exit 1
    fi
    # 修改密码
    echo "root:$password" | chpasswd && echo "$HOSTNAME change the password of root successfully."
}

restart_ssh(){
    service ssh restart > /dev/null && echo "$HOSTNAME SSH service has been restarted." || echo "$HOSTNAME fail to restart SSH service!"
}

# 无参函数
# 生成ssh密钥对, 如果已经存在则忽略
generate_key(){
    if [[ ! -e "$HOME/.ssh/id_rsa.pub"  ]]; then
        ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa > /dev/null && echo "$HOSTNAME succeed in generating ssh key." || echo "$HOSTNAME fail to generate ssh key."
    fi
}

change_password
restart_ssh
generate_key
exit 0
