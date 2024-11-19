#!/bin/sh

sed -i "s/\$NET_INTERFACE/$NET_INTERFACE/g" /etc/sockd.conf

# Подготовка конфигурации для пользователей
echo "${PROXY_USER}:${PROXY_PASSWORD}" > /etc/sockd.passwd

# Запуск dante-server
exec sockd -f /etc/sockd.conf