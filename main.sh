#!/bin/bash

### Color
Green="\e[92;1m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
GREENBG="\033[42;37m"
REDBG="\033[41;37m"
OK="${Green}--->${FONT}"
ERROR="${RED}[ERROR]${FONT}"
GRAY="\e[1;30m"
NC='\e[0m'
red='\e[1;31m'
green='\e[0;32m'

### System Information
TANGGAL=$(date '+%Y-%m-%d')
TIMES="10"
NAMES=$(whoami)
IMP="wget -q -O"    
CHATID="-4785848676"
LOCAL_DATE="/usr/bin/"
MYIP=$(wget -qO- ipinfo.io/ip)
CITY=$(curl -s ipinfo.io/city)
TIME=$(date +'%Y-%m-%d %H:%M:%S')
RAMMS=$(free -m | awk 'NR==2 {print $2}')
KEY="7768764548:AAGS1Bv7kdUDQ6hq7OHUi521jxUcgbMFYp8"
URL="https://api.telegram.org/bot$KEY/sendMessage"
REPO="https://github.com/kaccang/pintu/raw/refs/heads/main/"
APT="apt-get -y install "
domain=$(cat /root/domain)
start=$(date +%s)
secs_to_human() {
    echo "Installation time : $((${1} / 3600)) hours $(((${1} / 60) % 60)) minute's $((${1} % 60)) seconds"
}
### Status
function print_ok() {
    echo -e "${OK} ${BLUE} $1 ${FONT}"
}
function print_install() {
	echo -e "${YELLOW} ============================================ ${FONT}"
    echo -e "${YELLOW} # $1 ${FONT}"
	echo -e "${YELLOW} ============================================ ${FONT}"
    sleep 1
}

function print_error() {
    echo -e "${ERROR} ${REDBG} $1 ${FONT}"
}

function print_success() {
    if [[ 0 -eq $? ]]; then
		echo -e "${Green} ============================================ ${FONT}"
        echo -e "${Green} # $1 berhasil dipasang"
		echo -e "${Green} ============================================ ${FONT}"
        sleep 2
    fi
}

### Cek root
function is_root() {
    if [[ 0 == "$UID" ]]; then
        print_ok "Root user Start installation process"
    else
        print_error "The current user is not the root user, please switch to the root user and run the script again"
    fi

}
function nginx_install() {
    # // Checking System
    if [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "ubuntu" ]]; then
        judge "Setup nginx For OS Is $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')"
        # // sudo add-apt-repository ppa:nginx/stable -y 
        sudo apt-get install nginx -y 
    elif [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "debian" ]]; then
        judge "Setup nginx For OS Is $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')"
        apt -y install nginx 
    else
        judge "${ERROR} Your OS Is Not Supported ( ${YELLOW}$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${FONT} )"
        # // exit 1
    fi

}

### Change Environment System
function first_setup(){
    timedatectl set-timezone Asia/Jakarta
    wget -O /etc/banner ${REPO}config/banner >/dev/null 2>&1
    chmod +x /etc/banner
    wget -O /etc/ssh/sshd_config ${REPO}config/sshd_config >/dev/null 2>&1
    chmod 644 /etc/ssh/sshd_config

    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
    
}

### Update and remove packages
function base_package() {
    sudo apt-get autoremove -y man-db apache2 ufw exim4 firewalld snapd* -y
    clear
    print_install "Menggupdate file Repository"
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1  >/dev/null 2>&1
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:vbernat/haproxy-2.7 -y
    sudo apt update && apt upgrade -y
    # linux-tools-common util-linux gnupg gnupg2 gnupg1  \
    sudo apt install squid nginx zip pwgen openssl netcat bash-completion  \
    curl socat xz-utils wget apt-transport-https dnsutils socat chrony \
    tar wget curl ruby zip unzip p7zip-full python3-pip haproxy libc6  \
    msmtp-mta ca-certificates bsd-mailx iptables iptables-persistent netfilter-persistent \
    net-tools  jq openvpn easy-rsa python3-certbot-nginx p7zip-full tuned fail2ban -y
    apt-get clean all; sudo apt-get autoremove -y
    print_ok "Update file repository selesai"
}
clear

### Buat direktori xray
function dir_xray() {
    print_install "Membuat direktori xray"
    mkdir -p /etc/{xray,vmess,websocket,vless,trojan,shadowsocks}
    # mkdir -p /usr/sbin/xray/
    mkdir -p /var/log/xray/
    mkdir -p /var/www/html/
    mkdir -p /etc/Hemat3D/
#    chmod +x /var/log/xray
    touch /var/log/xray/{access.log,error.log}
    chmod 777 /var/log/xray/*.log
    touch /etc/vmess/.vmess.db
    touch /etc/vless/.vless.db
    touch /etc/trojan/.trojan.db
    touch /etc/ssh/.ssh.db
    touch /etc/shadowsocks/.shadowsocks.db
    clear
}

### Tambah domain
function add_domain() {
    echo "`cat /etc/banner`"
    read -rp "Input Your Domain For This Server :" -e SUB_DOMAIN
    echo "Host : $SUB_DOMAIN"
    echo $SUB_DOMAIN > /root/domain
    cp /root/domain /etc/xray/domain
}

### Pasang SSL
function pasang_ssl() {
    print_install "Memasang SSL pada domain"
    domain=$(cat /root/domain)
    STOPWEBSERVER=$(lsof -i:80 | cut -d' ' -f1 | awk 'NR==2 {print $1}')
    rm -rf /root/.acme.sh
    mkdir /root/.acme.sh
    systemctl stop $STOPWEBSERVER
    systemctl stop nginx
    curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
    /root/.acme.sh/acme.sh --upgrade --auto-upgrade
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
    chmod 777 /etc/xray/xray.key
    print_success "SSL Certificate"
}

### Install Xray
mkdir -p /usr/bin/xray
mkdir -p /etc/websocket
mkdir -p /etc/systemd/system
function install_xray() {
    judge "Core Xray 1.6.5 Version installed successfully"
    curl -s ipinfo.io/city >>/etc/xray/city
    curl -s ipinfo.io/org | cut -d " " -f 2-10 >>/etc/xray/isp
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version 1.6.5
    curl https://rclone.org/install.sh | bash
    printf "q\n" | rclone config
    cat /etc/xray/xray.crt /etc/xray/xray.key | tee /etc/haproxy/yha.pem
    wget -O /etc/xray/config.json "${REPO}xray/config.json" >/dev/null 2>&1 
    wget -O /usr/bin/xray/xray "${REPO}bin/xray" >/dev/null 2>&1
    wget -O /usr/sbin/websocket "${REPO}bin/ws" >/dev/null 2>&1
    wget -O /etc/websocket/tun.conf "${REPO}xray/tun.conf" >/dev/null 2>&1 
    wget -O /etc/systemd/system/ws.service "${REPO}xray/ws.service" >/dev/null 2>&1 
    wget -q -O /etc/ipserver "${REPO}server/ipserver" && bash /etc/ipserver >/dev/null 2>&1
    chmod +x /usr/bin/xray/xray
    chmod +x /etc/systemd/system/ws.service
    chmod +x /usr/bin/ws
    chmod 644 /usr/bin/tun.conf
    cat >/etc/msmtprc <<EOF
defaults
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
account default
host smtp.gmail.com
port 587
auth on
user testhemat@gmail.com
from testhemat@gmail.com
password 123Testaja
logfile ~/.msmtp.log
EOF

    rm -rf /etc/systemd/system/xray.service.d
    cat >/etc/systemd/system/xray.service <<EOF
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target
[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
#ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
ExecStart=/usr/bin/xray/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000
[Install]
WantedBy=multi-user.target
EOF

}
### Pasang OpenVPN
function install_ovpn(){
    print_install "Memasang modul Openvpn"
    source <(curl -sL ${REPO}openvpn/openvpn)
    wget -O /etc/pam.d/common-password "${REPO}openvpn/common-password" >/dev/null 2>&1
    chmod +x /etc/pam.d/common-password
    # > BadVPN
    source <(curl -sL ${REPO}badvpn/setup.sh)
    print_success "OpenVPN"
}

### Pasang SlowDNS
function install_slowdns(){
    print_install "Memasang modul SlowDNS Server"
    wget -q -O /tmp/nameserver "${REPO}slowdns/nameserver" >/dev/null 2>&1
    chmod +x /tmp/nameserver
    bash /tmp/nameserver | tee /root/install.log
    print_success "SlowDNS"
}

### Pasang Rclone
function pasang_rclone() {
    print_install "Memasang Rclone"
    print_success "Installing Rclone"
    curl "${REPO}bin/rclone" | bash >/dev/null 2>&1
    print_success "Rclone"
}

### Ambil Konfig
function download_config(){
    print_install "Memasang konfigurasi paket konfigurasi"
    wget -O /etc/haproxy/haproxy.cfg "${REPO}config/haproxy.cfg" >/dev/null 2>&1
    wget -O /etc/nginx/conf.d/Hemat3D.conf "${REPO}config/Hemat3D.conf" >/dev/null 2>&1
    sed -i "s/xxx/${domain}/g" /etc/nginx/conf.d/Hemat3D.conf
    wget -O /etc/nginx/nginx.conf "${REPO}config/nginx.conf" >/dev/null 2>&1
    wget -q -O /etc/squid/squid.conf "${REPO}config/squid.conf" >/dev/null 2>&1
    echo "visible_hostname $(cat /etc/xray/domain)" /etc/squid/squid.conf
    mkdir -p /var/log/squid/cache/
    chmod 777 /var/log/squid/cache/
    echo "* - nofile 65535" >> /etc/security/limits.conf
    mkdir -p /etc/sysconfig/
    echo "ulimit -n 65535" >> /etc/sysconfig/squid

    # > Add Dropbear
    apt install dropbear -y
    wget -q -O /etc/default/dropbear "${REPO}config/dropbear" >/dev/null 2>&1
    chmod 644 /etc/default/dropbear
    wget -q -O /etc/banner "${REPO}config/banner" >/dev/null 2>&1
    
    # > Add menu, thanks to Bhoikfost Yahya <3
    wget -O /tmp/menu-master.zip "${REPO}config/menu.zip" >/dev/null 2>&1
    mkdir /tmp/menu
    7z e  /tmp/menu-master.zip -o/tmp/menu/ >/dev/null 2>&1
    chmod +x /tmp/menu/*
    mv /tmp/menu/* /usr/sbin/


    cat >/root/.profile <<EOF
# ~/.profile: executed by Bourne-compatible login shells.
if [ "$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi
mesg n || true
menu
EOF

cat >/etc/cron.d/xp_all <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
2 0 * * * root /usr/bin/xp
EOF

chmod 644 /root/.profile

cat >/etc/cron.d/daily_reboot <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 5 * * * root /sbin/reboot
EOF

echo "*/1 * * * * root echo -n > /var/log/nginx/access.log" >/etc/cron.d/log.nginx
echo "*/1 * * * * root echo -n > /var/log/xray/access.log" >>/etc/cron.d/log.xray
service cron restart
cat >/home/daily_reboot <<EOF
5
EOF

cat >/etc/systemd/system/rc-local.service <<EOF
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
EOF

echo "/bin/false" >>/etc/shells
echo "/usr/sbin/nologin" >>/etc/shells
cat >/etc/rc.local <<EOF
#!/bin/sh -e
# rc.local
# By default this script does nothing.
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
systemctl restart netfilter-persistent
exit 0
EOF
    chmod +x /etc/rc.local
    print_ok "Konfigurasi file selesai"
}

### Tambahan
function tambahan(){
    print_install "Memasang modul tambahan"
    wget -O /usr/sbin/speedtest "${REPO}bin/speedtest" >/dev/null 2>&1
    chmod +x /usr/sbin/speedtest

    # > pasang gotop
    gotop_latest="$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
    gotop_link="https://github.com/xxxserxxx/gotop/releases/download/v$gotop_latest/gotop_v"$gotop_latest"_linux_amd64.deb"
    curl -sL "$gotop_link" -o /tmp/gotop.deb
    dpkg -i /tmp/gotop.deb >/dev/null 2>&1

    # > Pasang BBR Plus
    wget -qO /tmp/bbr.sh "${REPO}server/bbr.sh" >/dev/null 2>&1
    chmod +x /tmp/bbr.sh && bash /tmp/bbr.sh

    # > Buat swap sebesar 1G
    dd if=/dev/zero of=/swapfile bs=1024 count=1048576
    mkswap /swapfile
    chown root:root /swapfile
    chmod 0600 /swapfile >/dev/null 2>&1
    swapon /swapfile >/dev/null 2>&1
    sed -i '$ i\/swapfile      swap swap   defaults    0 0' /etc/fstab

    # > Singkronisasi jam
    chronyd -q 'server 0.id.pool.ntp.org iburst'
    chronyc sourcestats -v
    chronyc tracking -v

    # > Tuned Device
    tuned-adm profile network-latency
    cat >/etc/msmtprc <<EOF
defaults
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
account default
host smtp.gmail.com
port 587
auth on
user testhemat@gmail.com
from testhemat@gmail.com
password Pwtest1234aja
logfile ~/.msmtp.log
EOF

chgrp mail /etc/msmtprc
chown 0600 /etc/msmtprc
touch /var/log/msmtp.log
chown syslog:adm /var/log/msmtp.log
chmod 660 /var/log/msmtp.log
ln -s /usr/bin/msmtp /usr/sbin/sendmail >/dev/null 2>&1
ln -s /usr/bin/msmtp /usr/bin/sendmail >/dev/null 2>&1
ln -s /usr/bin/msmtp /usr/lib/sendmail >/dev/null 2>&1
print_ok "Selesai pemasangan modul tambahan"
}


########## SETUP FROM HERE ##########
# ORIGINAL SCRIPT BY HEMAT 3D       #
#####################################
echo "INSTALLING SCRIPT..."

touch /root/.install.log
cat >/root/tmp <<-END
#!/bin/bash
#vps
### Hemat3D $TANGGAL $MYIP
END
####
HEMAT3DKU() {
    data=($(cat /root/tmp | grep -E "^### " | awk '{print $2}'))
    for user in "${data[@]}"; do
        exp=($(grep -E "^### $user" "/root/tmp" | awk '{print $3}'))
        d1=($(date -d "$exp" +%s))
        d2=($(date -d "$Date_list" +%s))
        exp2=$(((d1 - d2) / 86400))
        if [[ "$exp2" -le "0" ]]; then
            echo $user >/etc/.$user.ini
        else
            rm -f /etc/.$user.ini
        fi
    done
    rm -f /root/tmp
}

function enable_services(){
    print_install "Restart servis"
    systemctl daemon-reload
    systemctl start netfilter-persistent
    systemctl enable --now nginx
    systemctl enable --now chronyd
    systemctl enable --now xray
    systemctl enable --now rc-local
    systemctl enable --now dropbear
    systemctl enable --now openvpn
    systemctl enable --now cron
    systemctl enable --now haproxy
    systemctl enable --now netfilter-persistent
    systemctl enable --now squid
    systemctl enable --now ws
    systemctl enable --now client
    systemctl enable --now server
    systemctl enable --now fail2ban
    wget -O /root/.config/rclone/rclone.conf "${REPO}rclone/rclone.conf" >/dev/null 2>&1
}

function install_all() {
    base_package
    # dir_xray
    # add_domain
    pasang_ssl 
    install_xray >> /root/install.log
    install_ovpn >> /root/install.log
    install_slowdns >> /root/install.log
    download_config >> /root/install.log
    enable_services >> /root/install.log
    tambahan >> /root/install.log
    pasang_rclone >> /root/install.log
}

function finish(){
    TEXT="
<u>INFORMATION VPS INSTALL SC</u>
<code>TIME    : </code><code>${TIME}</code>
<code>IPVPS   : </code><code>${MYIP}</code>
<code>DOMAIN  : </code><code>${domain}</code>
<code>IP VPS  : </code><code>${MYIP}</code>
<code>LOKASI  : </code><code>${CITY}</code>
<code>USER    : </code><code>${NAMES}</code>
<code>RAM     : </code><code>${RAMMS}MB</code>
<code>LINUX   : </code><code>${OS}</code>
"
    curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
    cp /etc/openvpn/*.ovpn /var/www/html/
    # sed -i "s/xxx/${domain}/g" /var/www/html/index.html
    sed -i "s/xxx/${domain}/g" /etc/haproxy/haproxy.cfg
    sed -i "s/xxx/${MYIP}/g" /etc/squid/squid.conf
    chown -R www-data:www-data /etc/msmtprc


    # > Bersihkan History
    alias bash2="bash --init-file <(echo '. ~/.bashrc; unset HISTFILE')"
    clear
    echo "    ┌─────────────────────────────────────────────────────┐"
    echo "    │       >>> Service & Port                            │"
    echo "    │   - Open SSH                : 443, 80, 39           │"
    echo "    │   - DNS (SLOWDNS)           : 443, 80, 53           │"
    echo "    │   - Dropbear                : 443, 109, 80          │"
    echo "    │   - Dropbear Websocket      : 443, 109              │"
    echo "    │   - SSH Websocket SSL       : 443                   │"
    echo "    │   - SSH Websocket           : 80                    │"
    echo "    │   - OpenVPN SSL             : 1194                   │"
    echo "    │   - OpenVPN Websocket SSL   : 443                   │"
    echo "    │   - OpenVPN TCP             : 1194             │"
    echo "    │   - OpenVPN UDP             : 2200                  │"
    echo "    │   - Nginx Webserver         : 443, 80, 81           │"
    echo "    │   - Haproxy Loadbalancer    : 443, 80               │"
    echo "    │   - DNS Server              : 443, 53               │"
    echo "    │   - DNS Client              : 443, 88               │"
    echo "    │   - XRAY DNS (SLOWDNS)      : 443, 80, 53           │"
    echo "    │   - XRAY Vmess TLS          : 443                   │"
    echo "    │   - XRAY Vmess gRPC         : 443                   │"
    echo "    │   - XRAY Vmess None TLS     : 80                    │"
    echo "    │   - XRAY Vless TLS          : 443                   │"
    echo "    │   - XRAY Vless gRPC         : 443                   │"
    echo "    │   - XRAY Vless None TLS     : 80                    │"
    echo "    │   - Trojan gRPC             : 443                   │"
    echo "    │   - Trojan WS               : 443                   │"
    echo "    │   - Shadowsocks WS          : 443                   │"
    echo "    │   - Shadowsocks gRPC        : 443                   │"
    echo "    │                                                     │"
    echo "    │      >>> Server Information & Other Features        │"
    echo "    │   - Timezone                : Asia/Jakarta (GMT +7) │"
    echo "    │   - Autoreboot On           : $AUTOREB:00 $TIME_DATE GMT +7        │"
    echo "    │   - Auto Delete Expired Account                     │"
    echo "    │   - Fully automatic script                          │"
    echo "    │   - VPS settings                                    │"
    echo "    │   - Admin Control                                   │"
    echo "    │   - Restore Data                                    │"
    echo "    │   - Full Orders For Various Services                │"
    echo "    └─────────────────────────────────────────────────────┘"
    secs_to_human "$(($(date +%s) - ${start}))"
     echo -ne "         ${YELLOW}Please Reboot Your Vps${FONT} (y/n)? "
     read REDDIR
     if [ "$REDDIR" == "${REDDIR#[Yy]}" ]; then
         exit 0
     else
         reboot
     fi
}
cd /tmp
HEMAT3DKU
first_setup
dir_xray
add_domain
install_all
finish  

rm ~/.bash_history
sleep 10
reboot
