#!/usr/bin/env bash
#
# 2016-12-21 08:52
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
ss_libev="shadowsocks-libev"
ss_libev_init="/etc/init.d/shadowsocks-libev"
ss_libev_config="/etc/shadowsocks-libev/config.json"
limits_conf="/etc/security/limits.conf"
sysctl_conf="/etc/sysctl.d/local.conf"

ss_libev_url="https://codeload.github.com/shadowsocks/shadowsocks-libev/zip/master"
ss_libev_init_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-libev/master/etc/init.d/shadowsocks-libev"
ss_libev_config_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-libev/master/etc/shadowsocks-libev/config.json"
limits_conf_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-libev/master/etc/security/limits.conf"
sysctl_conf_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-libev/master/etc/sysctl.d/local.conf"

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

download_files(){
# get shadowsocks-libev latest version
if ! wget "${ss_libev_url}" -O "${tmp_dir}/${ss_libev}.zip"; then
        echo -e "${red}Error:${plain} Failed to download ${ss_libev}.zip"
        exit 1
fi

# /etc/shadowsocks-libev/config.json
mkdir -p /etc/shadowsocks-libev
if ! wget "${ss_libev_config_url}" -O "${ss_libev_config}"; then 
    echo -e "${red}Error:${plain} Failed to download ${ss_libev_config}"
fi

# /etc/init.d/shadowsocks-libev
if ! wget "${ss_libev_init_url}" -O "${ss_libev_init}"; then 
    echo -e "${red}Error:${plain} Failed to download ${ss_libev_init}"
fi

# /etc/security/limits.conf
if ! wget "${limits_conf_url}" -O "${limits_conf}"; then 
    echo -e "${red}Error:${plain} Failed to download ${limits_conf}"
fi

# /etc/sysctl.d/local.conf
if ! wget "${sysctl_conf_url}" -O "${sysctl_conf}" && sysctl --system|sysctl -p; then 
    echo -e "${red}Error:${plain} Failed to download ${sysctl_conf}"
fi
}

install_yum(){
yum install -y unzip gzip openssl openssl-devel gcc swig python python-devel python-setuptools libtool libevent xmlto
yum install -y autoconf automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel asciidoc
}

install_shadowsocks_libev() {
cd /var/root/tmp
unzip shadowsocks-libev.zip
cd /var/root/tmp/shadowsocks-libev-master
./configure && make && make install
if [ $? -eq 0 ]; then
        chmod +x ${ss_libev_init}
        chkconfig --add ${ss_libev}
        chkconfig ${ss_libev} on
        ${ss_libev_init} start
        echo -e "${green}install successfully${plain}"
        rm -rf /var/root/tmp
    else
        echo
        echo -e "${red}${ss_libev}${plain} install failed."
        rm -rf /var/root/tmp
fi
}

check_root
set_timezone
disable_selinux
download_files
install_yum
install_shadowsocks_libev