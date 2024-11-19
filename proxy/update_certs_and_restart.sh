#!/bin/bash

# Копирование сертификатов в директорию Squid
cp /etc/letsencrypt/live/$PROXY_DOMAIN/fullchain.pem /etc/squid/ssl_cert/
cp /etc/letsencrypt/live/$PROXY_DOMAIN/privkey.pem /etc/squid/ssl_cert/

# Установка прав доступа
chown squid:squid /etc/squid/ssl_cert/fullchain.pem /etc/squid/ssl_cert/privkey.pem