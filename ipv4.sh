#!/bin/sh

#------------------#
KULLANICI="eros"
SIFRE="eros"
#------------------#

#------------------#
IPV4_PORT=3310
#------------------#

#------------------#
renkreset='\e[0m'
yesil='\e[1;92m'
kirmizi='\e[1;91m'
sari='\e[1;93m'
mor='\e[0;35m'
#------------------#

# Function to install and configure Squid
squid_yukle() {
    echo -e "\n\n\t$yesil Squid Yükleniyor..\n$renkreset\n"
    apt update
    apt install -y squid

    htpasswd -bc /etc/squid/passwd $KULLANICI $SIFRE

    cat >/etc/squid/squid.conf <<EOF
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
acl smtp port 25
http_access allow authenticated

http_port 0.0.0.0:${IPV4_PORT}

http_access deny smtp
http_access deny all
forwarded_for delete
EOF

    systemctl restart squid
    systemctl enable squid

    iptables -I INPUT -p tcp --dport $IPV4_PORT -j ACCEPT
    iptables-save
}

# Function to generate proxy.txt file
proxy_txt() {
    cat >proxy.txt <<EOF
${IP4}:${IPV4_PORT}:${KULLANICI}:${SIFRE}
EOF
}

IP4=$(curl -4 -s icanhazip.com)

echo -e "\n\t$sari IPv4 »$yesil ${IP4}$renkreset"

echo -e "\n\n\t$yesil Gerekli Paketler Yükleniyor..$renkreset\n"
apt update
apt install -y wget bsdtar zip apache2-utils

squid_yukle
proxy_txt

echo -e "\n$sari IPv4 Proxy »$yesil ${IP4}:${IPV4_PORT}:${KULLANICI}:${SIFRE}$renkreset\n"

rm -rf /dev/null
