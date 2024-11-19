FROM alpine:3

RUN apk add --no-cache squid apache2-utils certbot openssl cronie

# Создание директории для сертификатов
RUN mkdir -p /etc/squid/ssl_cert && \
  chown -R squid:squid /etc/squid/ssl_cert

# Копирование пользовательских скриптов
COPY update_certs_and_restart.sh /update_certs_and_restart.sh
RUN chmod +x /update_certs_and_restart.sh

# Добавление скрипта запуска
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Добавление конфигурации Squid
COPY squid.conf /etc/squid/squid.conf

ENTRYPOINT ["/entrypoint.sh"]
