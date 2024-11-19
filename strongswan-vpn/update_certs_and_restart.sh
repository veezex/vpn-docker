#!/bin/bash

# Копирование сертификатов для StrongSwan
cp /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem /etc/strongswan/certs/server-cert.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/privkey.pem /etc/strongswan/certs/server-key.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/chain.pem /etc/ipsec.d/cacerts/ca-cert.pem

# Проверка прав доступа к сертификатам
chmod 640 /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem ipsec:ipsec /etc/ipsec.d/cacerts/ca-cert.pem
chown -R ipsec:ipsec /etc/strongswan
chown ipsec:ipsec /etc/ipsec.d/cacerts/ca-cert.pem