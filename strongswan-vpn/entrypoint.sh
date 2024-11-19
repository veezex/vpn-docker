#!/bin/bash

# Обновление конфигурации StrongSwan
sed -i "s/\$VPN_DOMAIN/$VPN_DOMAIN/g" /etc/ipsec.conf

# Настройка учетных данных в ipsec.secrets
echo ": ECDSA \"/etc/strongswan/certs/server-key.pem\"" > /etc/ipsec.secrets
echo "$VPN_USERNAME : EAP \"$VPN_PASSWORD\"" >> /etc/ipsec.secrets

# Установка сертификатов через Certbot, если их нет
if [ ! -f /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem ]; then
  certbot certonly --standalone --non-interactive --agree-tos --email "$CERTBOT_EMAIL" -d "$VPN_DOMAIN"
fi

# Настройка автоматического обновления сертификатов через Cron
echo "0 0 * * * certbot renew --quiet --deploy-hook '/update_certs_and_restart.sh'" | crontab -

# Запуск Cron в фоновом режиме
crond

# Копирование сертификатов для StrongSwan
cp /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem /etc/strongswan/certs/server-cert.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/privkey.pem /etc/strongswan/certs/server-key.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/chain.pem /etc/ipsec.d/cacerts/ca-cert.pem

# Проверка прав доступа к сертификатам
chmod 600 /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem
chown root:root /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem

# Запуск StrongSwan
exec ipsec start --nofork
