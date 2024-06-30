#!/bin/bash

# Credentials
KULLANICI="eros"
SIFRE="eros"

# Ports
IPV4_PORT=3310
SOCKS5_PORT=5110

# Colors
renkreset='\e[0m'
yesil='\e[1;92m'
sari='\e[1;93m'
kirmizi='\e[1;91m'

# Function to install Squid
squid_yukle() {
    echo -e "\n\n\t$yesil Squid Yükleniyor..\n$renkreset\n"
    apt-get update && apt-get install -y squid httpd-tools

    # Setup Squid authentication
    htpasswd -bc /etc/squid/passwd $KULLANICI $SIFRE

    # Configure Squid
    cat >/etc/squid/squid.conf <<EOF
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
acl localnet src all
acl SSL_ports port 443
acl Safe_ports port 80      # http
acl Safe_ports port 21      # ftp
acl Safe_ports port 443     # https
acl Safe_ports port 70      # gopher
acl Safe_ports port 210     # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280     # http-mgmt
acl Safe_ports port 488     # gss-http
acl Safe_ports port 591     # filemaker
acl Safe_ports port 777     # multiling http
acl CONNECT method CONNECT

http_access allow authenticated
http_access deny all
http_port 0.0.0.0:${IPV4_PORT}
coredump_dir /var/spool/squid
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320

forwarded_for delete
request_header_access Via deny all
request_header_access X-Forwarded-For deny all
request_header_access From deny all
EOF

    systemctl restart squid
    systemctl enable squid

    # Allow Squid port in firewall
    ufw allow $IPV4_PORT/tcp
}

# Function to generate proxy.txt with IPv4 proxies
proxy_txt() {
    echo -e "\nGenerating proxy.txt with IPv4 proxies...\n"
    # Generate proxies based on available IP addresses
    echo "$KULLANICI:$SIFRE@$IP4:$IPV4_PORT" > proxy.txt
}

# Install necessary packages and configure Squid
echo -e "\n\n\t$yesil Gerekli Paketler Yükleniyor..$renkreset\n"
apt-get update && apt-get install -y gcc net-tools bsdtar zip

# Check IPv4 address
IP4=$(curl -4 -s icanhazip.com)
if [ -z "$IP4" ]; then
    echo -e "\n$kirmizi IPv4 adresi alınamadı. Script sonlandırılıyor.$renkreset\n"
    exit 1
fi

# Run Squid installation and proxy generation
squid_yukle
proxy_txt

# Display generated proxies
echo -e "\n$sari IPv4 Proxy Bilgisi »$yesil ${IP4}:${IPV4_PORT}:${KULLANICI}:${SIFRE}$renkreset\n"

# Clean up
rm -rf /dev/null
