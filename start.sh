#!/bin/bash
#set -x
set -eo pipefail
shopt -s nullglob

declare -a container_id;
#declare -a container_ip;
declare -a service_name;

# 无参函数
# 用于获取当前Docker compose下的所有container id和ip地址, 执行容器内的SSH免密登录脚本
ssh-interconnect(){
    local ssh_init_path=/preparation/ssh-init.sh
    local ssh_pass_path=/preparation/ssh-pass.sh
    # 将该project下的container name置于数组
    for con in $(docker-compose ps | sed -n '3,$p' | sed -n '/Up/p' | awk '{print $1}'); do
        # 获取正在运行的container id
        cid=$(docker ps | grep "$con" | awk '{print $1}')
        container_id+=( "$cid" )
        # 获取容器ip
        #container_ip+=("$(docker inspect "$cid" | grep -o -E '\"IPAddress": ".+"' \
        #    | grep -o -E '(\d+[.]*)+\"' | sed "s/\"//g")")
        # 获取docker compose的service名, 限制一个service对应一个container
        service_name+=("$(docker inspect "$cid" | sed -n 's/\"com\.docker\.compose\.service\": \"//gp' \
            | sed -n 's/\",//gp')")
    done

    for c_id in ${container_id[*]}; do
        echo "$c_id initializing SSH..."
        docker exec "$c_id" "$ssh_init_path"
    done

    for c_id in ${container_id[*]}; do
        for c_name in ${service_name[*]}; do
            docker exec "$c_id" "$ssh_pass_path" "$c_name"
        done
    done
}

# 将接收到的参数使用ANSI颜色打印到控制台
aprint(){
    echo "$(tput setaf 2)>>> $1 $(tput sgr0)"
}

aprint "Docker Compose starting..."
docker-compose up -d

aprint "Setting ssh..."
ssh-interconnect

aprint "Creating mysql user for replication named 'repl' on master container..."
docker-compose exec master /mha_share/create-repl-account.sh

aprint "Configuring replication with GTID mode..."
for c_name in ${service_name[*]}; do
    if [[ "$c_name" =~ slave_.* ]]; then
        echo "configuring $c_name $c_id ..."
        docker exec "$c_id" /mha_share/change-master.sh
    fi
done
sleep 7

aprint "Initializing MHA configuration..."
docker-compose exec manager /preparation/bootstrap.sh ${service_name[*]}

aprint "Done!"
