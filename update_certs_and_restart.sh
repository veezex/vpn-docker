#!/bin/bash

# Копируем сертификаты в нужную директорию
cp /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem /etc/strongswan/certs/server-cert.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/privkey.pem /etc/strongswan/certs/server-key.pem

# Перезапускаем StrongSwan для применения новых сертификатов
ipsec restart