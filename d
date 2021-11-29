#!/bin/bash

apt-get purge -y unattended-upgrades update-manager-core
apt-get install -y vim && update-alternatives --set editor /usr/bin/vim.basic
locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

dpkg -l|grep -q "^ii  docker-ce"

if [[ $? != 0 ]]; then
    # Offical
    #curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    #echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

    # ustc mirror
    #curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
    #echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

    # Aliyun mirror
    curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
    echo "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
fi

if [[ `docker ps -a |grep SUPERMINER_MANAGE|wc -l` > 0 ]]; then
    docker stop SUPERMINER_MANAGE && docker rm SUPERMINER_MANAGE && docker rmi solarshipx/manage:latest
fi

docker pull solarshipx/manage

docker run -d --restart always --name SUPERMINER_MANAGE --network host -v /var/run/docker.sock:/var/run/docker.sock -v /usr/local/superminer:/usr/local/superminer solarshipx/manage manage
