FROM alpine:3

# Установка необходимых пакетов
RUN apk add --no-cache strongswan strongswan-libcharon strongswan-libs strongswan-extra-plugins \
  certbot bash sed curl cronie

# Копирование конфигурации StrongSwan
COPY ipsec.conf /etc/ipsec.conf

# Создание директории для сертификатов
RUN mkdir -p /etc/strongswan/certs

# Копирование пользовательских скриптов
COPY update_certs_and_restart.sh /update_certs_and_restart.sh
RUN chmod +x /update_certs_and_restart.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Настройка точки входа
ENTRYPOINT ["/entrypoint.sh"]
