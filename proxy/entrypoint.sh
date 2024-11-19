#!/bin/sh

# Получение SSL-сертификатов с помощью Let's Encrypt
if [ ! -f /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem ]; then
  certbot certonly --standalone --non-interactive --agree-tos --email "$CERTBOT_EMAIL" -d "$PROXY_DOMAIN"
fi

# Настройка автоматического обновления сертификатов через Cron
echo "0 0 * * * certbot renew --quiet --deploy-hook '/update_certs_and_restart.sh'" | crontab -

# Копирование сертификатов в директорию Squid
cp /etc/letsencrypt/live/$PROXY_DOMAIN/fullchain.pem /etc/squid/ssl_cert/
cp /etc/letsencrypt/live/$PROXY_DOMAIN/privkey.pem /etc/squid/ssl_cert/

# Установка прав доступа
chown squid:squid /etc/squid/ssl_cert/fullchain.pem /etc/squid/ssl_cert/privkey.pem

# Запуск Squid
exec squid -N
