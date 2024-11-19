#!/bin/bash

# Копируем сертификаты в нужную директорию для StrongSwan
cp /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem /etc/strongswan/certs/server-cert.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/privkey.pem /etc/strongswan/certs/server-key.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/chain.pem /etc/ipsec.d/cacerts/ca-cert.pem

# Проверка прав доступа на сертификаты
chmod 600 /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem
chown root:root /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem

# Перезапускаем StrongSwan для применения новых сертификатов
ipsec restart