#!/bin/bash

sed -i "s/\$VPN_DOMAIN/$VPN_DOMAIN/g" /etc/ipsec.conf

# Проверка наличия сертификатов
if [ ! -f /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem ]; then
  certbot certonly --standalone --non-interactive --agree-tos --email "$CERTBOT_EMAIL" -d "$VPN_DOMAIN"
fi

# Настройка автоматического обновления сертификата с помощью cron
echo "0 0 * * * certbot renew --quiet --deploy-hook '/update_certs_and_restart.sh'" | crontab -

# Запуск cron в фоновом режиме
cron

# Копируем сертификаты в нужную директорию для StrongSwan
cp /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem /etc/strongswan/certs/server-cert.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/privkey.pem /etc/strongswan/certs/server-key.pem

# Проверка прав доступа на сертификаты
chmod 600 /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem
chown root:root /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem

# Настраиваем учетные данные в ipsec.secrets
echo ": RSA \"/etc/strongswan/certs/server-key.pem\"" > /etc/ipsec.secrets
echo "$VPN_USERNAME : EAP \"$VPN_PASSWORD\"" >> /etc/ipsec.secrets

# TODO
# Запуск StrongSwan в отладочном режиме для тестирования
exec ipsec start --nofork