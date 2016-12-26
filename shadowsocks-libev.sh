#!/usr/bin/env bash
#
# 2016-12-24 04:20
#
#     by:   fish
# mailto:   fishdev@qq.com
#

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

tmp_dir="/var/root/tmp"
mkdir -p ${tmp_dir}

#shadowsocks_libev
shadowsocks_libev="shadowsocks-libev"
shadowsocks_libev_init="/etc/init.d/shadowsocks-libev"
shadowsocks_libev_config="/etc/shadowsocks-libev/config.json"
limits_conf="/etc/security/limits.conf"
sysctl_conf="/etc/sysctl.conf"

shadowsocks_libev_url="https://codeload.github.com/shadowsocks/shadowsocks-libev/zip/master"
shadowsocks_libev_init_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-libev/master/etc/init.d/shadowsocks-libev"
shadowsocks_libev_config_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-libev/master/etc/shadowsocks-libev/config.json"
limits_conf_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-libev/master/etc/security/limits.conf"
sysctl_conf_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-libev/master/etc/sysctl.conf"

check_root(){
[[ $EUID -ne 0 ]] && echo -e "${red}Error:${plain} This script must be run as root!" && exit 1
}

disable_selinux() {
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
fi
}

set_timezone(){
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate 1.cn.pool.ntp.org
}

install_yum(){
yum install -y unzip gzip openssl openssl-devel gcc swig python python-devel python-setuptools libtool libevent xmlto
yum install -y autoconf automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel asciidoc
}

optimized_conf(){
sed -i '$a\ulimit -SHn 65535' /etc/profile;
# /etc/security/limits.conf
if ! wget "${limits_conf_url}" -O "${limits_conf}"; then 
    echo -e "${red}Error:${plain} Failed to download ${limits_conf}"
fi
# /etc/sysctl.d/local.conf
if ! wget "${sysctl_conf_url}" -O "${sysctl_conf}" && sysctl --system|sysctl -p; then 
    echo -e "${red}Error:${plain} Failed to download ${sysctl_conf}"
fi
if [ $? -eq 0 ]; then
       echo -e "${green}optimized config successfully${plain}"
    else
        echo -e "${red}optimized config${plain} install failed."
fi
}

download_shadowsocks_libev(){
# get shadowsocks-libev latest version
if ! wget "${shadowsocks_libev_url}" -O "${tmp_dir}/${shadowsocks_libev}.zip"; then
        rm -rf ${tmp_dir}
        echo -e "${red}Error:${plain} Failed to download ${shadowsocks_libev}.zip"
        exit 1
fi
# /etc/shadowsocks-libev/config.json
mkdir -p /etc/shadowsocks-libev
if ! wget "${shadowsocks_libev_config_url}" -O "${shadowsocks_libev_config}"; then 
    echo -e "${red}Error:${plain} Failed to download ${shadowsocks_libev_config}"
fi
# /etc/init.d/shadowsocks-libev
if ! wget "${shadowsocks_libev_init_url}" -O "${shadowsocks_libev_init}"; then 
    echo -e "${red}Error:${plain} Failed to download ${shadowsocks_libev_init}"
fi
}

install_shadowsocks_libev() {
cd ${tmp_dir}
unzip -q ${shadowsocks_libev}.zip
if [ $? -ne 1 ];then
        rm -rf ${shadowsocks_libev}.zip
    else
        echo "unzip ${shadowsocks_libev}.zip failed, please check unzip command."
fi

cd shadowsocks*
./configure && make && make install
if [ $? -eq 0 ]; then
        chmod +x ${shadowsocks_libev_init}
        chkconfig --add ${shadowsocks_libev}
        chkconfig ${shadowsocks_libev} on
        ${shadowsocks_libev_init} start
        echo -e "${green}install successfully${plain}"
    else
        echo -e "${red}${shadowsocks_libev}${plain} install failed."
fi
}


check_root
set_timezone
disable_selinux
install_yum
optimized_conf
download_shadowsocks_libev
install_shadowsocks_libev
rm -rf /var/root/tmp