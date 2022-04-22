#!/bin/bash

VERSION=v0.0.1

# prepare commands
if ! command -v curl &> /dev/null
then
    echo "curl could not be found"
    apt-get install -y curl
fi

if ! command -v route &> /dev/null
then
    echo "route could not be found"
    apt-get install -y net-tools
fi

StaticFile="/etc/netplan/88-ip-config.yaml"
DHCPConfigFile="/etc/netplan/77-dhcp-config.yaml"

function valid_ip() {
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    if [ $stat != 0 ]; then
        echo "IP $1 不合法"
        exit -1
    fi
}

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

function autostatic() {
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
    tmps=(${IPAndMASK//\// })
    valid_ip ${tmps[0]}
    if [ ${tmps[1]} = "" ]; then
        echo "无效的ip/mask $IPAndMASK"
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
    valid_ip $GATEWAY

    if [  -f ${StaticFile} ];then
        echo "IP曾固定过，具体如下："
    else
        echo "IP固定成功："
        cat > $StaticFile <<EOF
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

function static() {
    # check network
    network
    if [ $? -eq 0 ];then
        echo "请检查您的网络，服务器无网络"
        exit -1
    fi

    usage="Usage: static <ip/mask> <gateway> <dns>"

    IPAndMASK=$1
    if [ "$IPAndMASK" = "" ]; then
        echo "获取IP出错"
        echo $usage
        exit -1
    fi
    tmps=(${IPAndMASK//\// })
    valid_ip ${tmps[0]}
    if [[ ${tmps[1]} = "" ]]; then
        echo "无效的ip/mask $IPAndMASK"
        exit -1
    fi

    GATEWAY=$2
    if [ "$GATEWAY" = "" ]; then
        echo "获取GATEWAY出错"
        echo $usage
        exit -1
    fi
    valid_ip $GATEWAY

    DNS=$3
    if [ "$DNS" = "" ]; then
        echo "获取DNS出错"
        echo $usage
        exit -1
    fi
    dnslines=""
    for v in ${DNS//,/ }
    do
        valid_ip $v
        dnslines="$dnslines                    - $v\n"
    done

    Name=`route | grep 'default' | awk '{print $8}'`
    if [ "$Name" = "" ]; then
        echo "获取网卡出错"
        exit -1
    fi

    if [  -f ${StaticFile} ];then
        echo "IP曾固定过，具体如下："
    else
        echo "IP固定成功："
        cat > $StaticFile <<EOF
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
`echo -e "$dnslines"`
EOF
    fi
    netplan apply
    get
}

function recover() {
    if [  -f ${StaticFile} ];then
        rm -f $StaticFile
        netplan apply
        echo "IP配置已恢复"
    else
        echo "未曾用该脚本配置IP"
    fi
    get
}

function backallconfig() {
    backupdir=/etc/netplan/`date '+%Y%m%d_%H%M%S'`
    mkdir $backupdir
    mv /etc/netplan/*.yaml $backupdir
}

function dhcp() {
    Name=`route | grep 'default' | awk '{print $8}'`
    if [ "$Name" = "" ]; then
        echo "获取网卡出错"
        exit -1
    fi

    backallconfig
    echo "IP固定成功："
    cat > $DHCPConfigFile <<EOF
network:
    version: 2
    ethernets:
        $Name:
            dhcp4: true
EOF
    netplan apply
    get
}

function help() {
    echo "VERSION: $VERSION"
    echo "Usage: $0 <command>"
    echo "commands:"
    echo "    get    : list current ip config"
    echo "    autostatic : Fix ip config"
    echo "    recover: recover ip config"
    echo "    static: fix ip with specified IP and gateway"
    echo "    dhcp: remove all config and enable dhcp"
}

function main() {
    cmd=$1
    shift
    if [ "$cmd" = "" ]; then
        help
        exit -1
    fi
    $cmd $*
}

# command arg
#    static IPAndMASK GATEWAY dns
main $*
