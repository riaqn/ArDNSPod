#!/bin/sh

#################################################
# AnripDdns v5.07.07
# 基于DNSPod用户API实现的动态域名客户端
# 作者: 若海[mail@anrip.com]
# 介绍: http://www.anrip.com/ddnspod
# 时间: 2015-07-07 10:25:00
#################################################

# 全局变量表
arPass=arMail=""

# 获得外网地址
arIpAdress() {
    local inter="http://members.3322.org/dyndns/getip"
    wget --quiet --output-document=- $inter
}

# 读取接口数据
# 参数: 接口类型 待提交数据
arApiPost() {
    local agent="AnripDdns/5.07(mail@anrip.com)"
    local inter="https://dnsapi.cn/${1:?'Info.Version'}"
    local param="login_email=${arMail}&login_password=${arPass}&format=json&${2}"
    wget --quiet --no-check-certificate --output-document=- --user-agent=$agent --post-data $param $inter
}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
    local domainID recordID recordRS recordCD
    # 获得域名ID
    domainID=$(arApiPost "Domain.Info" "domain=${1}")
    domainID=$(echo $domainID | sed 's/.\+{"id":"\([0-9]\+\)".\+/\1/')
    # 获得记录ID
    recordID=$(arApiPost "Record.List" "domain_id=${domainID}&sub_domain=${2}")
    recordID=$(echo $recordID | sed 's/.\+\[{"id":"\([0-9]\+\)".\+/\1/')
    # 获得旧记录IP
    lastIP=$(arApiPost "Record.Info" "domain_id=${domainID}&record_id=${recordID}")
    lastIP=$(echo $lastIP | sed 's/.\+"value":"\([.0-9]\+\)".\+/\1/')
    echo "lastIP $lastIP"
    hostIP=$(arIpAdress)
    echo "hostIP $hostIP"
    if [ "$lastIP" != "$hostIP" ]; then
        
        # 更新记录IP
        recordRS=$(arApiPost "Record.Ddns" "domain_id=${domainID}&record_id=${recordID}&sub_domain=${2}&record_line=默认")
        recordCD=$(echo $recordRS | sed 's/.\+{"code":"\([0-9]\+\)".\+/\1/')
        # 输出记录IP
        if [ "$recordCD" == "1" ]; then
            echo $recordRS | sed 's/.\+,"value":"\([0-9\.]\+\)".\+/\1/'
            return 1
        fi
        # 输出错误信息
        echo $recordRS | sed 's/.\+,"message":"\([^"]\+\)".\+/\1/'
    fi
}

###################################################

# 设置用户参数
arMail="user@anrip.com"
arPass="anrip.net"

# 检查更新域名
arDdnsCheck "anrip.com" "lab"
arDdnsCheck "anrip.net" "lab"
