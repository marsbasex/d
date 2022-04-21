#!/bin/bash

# prepare commands
apt-get install -y curl net-tools

# get
# static
# recover

File="/etc/netplan/88-ip-config.yaml"

#Check NetWork
function network()
{
    local timeout=1
    local target=www.baidu.com
    local ret_code=`curl -I -s --connect-timeout ${timeout} ${target} -w %{http_code} | tail -n1`
    if [ "x$ret_code" = "x200" ]; then
        return 1
    else
        return 0
    fi
    return 0
}

function get() {
    # echo run get $1
    netplan get
}

function static() {
    # echo run static $1

    # check network
    network
    if [ $? -eq 0 ];then
        echo "请检查您的网络，服务器无网络"
        exit -1
    fi

    IPAndMASK=`ip addr |awk '/inet /' |sed -n '2p' |awk -F' ' '{print $2}' `
    if [ "$IPAndMASK" = "" ]; then
        echo "获取IP出错"
        exit -1
    fi
    Name=`route | grep 'default' | awk '{print $8}'`
    if [ "$Name" = "" ]; then
        echo "获取网卡出错"
        exit -1
    fi
    GATEWAY=`route -n| grep ${Name} |grep 'UG'| awk '{print $2}'`
    if [ "$GATEWAY" = "" ]; then
        echo "获取GATEWAY出错"
        exit -1
    fi

    if [  -f ${File} ];then
        echo "IP曾固定过，具体如下："
    else
        echo "IP固定成功："
        cat > $File <<EOF
network:
    version: 2
    ethernets:
        $Name:
            addresses:
                - $IPAndMASK
            dhcp4: false
            gateway4: $GATEWAY
            nameservers:
                addresses:
                    - 223.5.5.5
                    - 119.29.29.29
EOF
    fi
    netplan apply
    get
}

function recover() {
    if [  -f ${File} ];then
        rm -f $File
        netplan apply
        echo "IP配置已恢复"
    else
        echo "未曾用该脚本配置IP"
    fi
    get
}

function help() {
    echo "Usage: $0 <command>"
    echo "commands:"
    echo "    get    : list current ip config"
    echo "    static : Fix ip config"
    echo "    recover: recover ip config"
}

function main() {
    cmd=$1
    if [ "$cmd" = "" ]; then
        help
        exit -1
    fi
    # echo start $cmd $arg
    $cmd
}

# command arg
main $1 $2
