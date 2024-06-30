#!/bin/bash

#------------------#
KULLANICI=eros
SIFRE=eros
#------------------#

#------------------#
IPV4_PORT=3310
#------------------#

#------------------#
renkreset='\e[0m'
mavi='\e[1;94m'
cyan='\e[1;96m'
yesil='\e[1;92m'
kirmizi='\e[1;91m'
beyaz='\e[1;77m'
sari='\e[1;93m'
mor='\e[0;35m'
#------------------#

rastgele() {
    tr </dev/urandom -dc A-Za-z0-9 | head -c5
    echo
}

veri_olustur() {
    for ip in 5.180.155.17 5.180.155.220 5.180.155.227 5.180.155.228 5.180.155.244 5.180.155.248; do
        echo ${KULLANICI}$(rastgele)/${SIFRE}$(rastgele)/$ip/$IPV4_PORT
    done
}

squid_yukle() {
    echo -e "\n\n\t$yesil Squid Yükleniyor..\n$renkreset\n"
    apt-get update
    apt-get install nano dos2unix squid apache2-utils -y

    htpasswd -bc /etc/squid/passwd $KULLANICI $SIFRE

    cat >/etc/squid/squid.conf <<EOF
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated

http_port 0.0.0.0:${IPV4_PORT}
forwarded_for delete
http_access deny all
EOF

    systemctl restart squid.service && systemctl enable squid.service

    iptables -I INPUT -p tcp --dport $IPV4_PORT -j ACCEPT
    iptables-save
}

proxy_txt() {
    cat >proxy.txt <<EOF
$(awk -F / '{print $3 " : " $4 " : " $1 " : " $2 }' ${VERI})
EOF
}

jq_yukle() {
    wget -qO jq https://github.com/c70b65b1ddd9/ipv4/raw/main/Paketler/jq-linux64
    chmod +x ./jq
    mv jq /usr/bin
}

file_io_yukle() {
    echo -e "\n\n\t$yesil Zip Yükleniyor..\n$renkreset\n"

    local PASS=$(rastgele)
    zip --password $PASS proxy.zip proxy.txt
    JSON=$(curl -sF file=@proxy.zip https://file.io)
    URL=$(echo $JSON | jq --raw-output '.link')

    clear
    echo -e "\n\n\t$yesil Proxyler Hazır!$mor Format »$sari :$renkreset"
    echo -e "\n$mor IPv4 Zip İndirme Bağlantısı:$yesil ${URL}$renkreset"
    echo -e "$mor IPv4 Zip Şifresi:$yesil ${PASS}$renkreset"
}

# Main
VERI=$(mktemp)
veri_olustur >${VERI}
squid_yukle
proxy_txt
jq_yukle
file_io_yukle
rm -f ${VERI}
