FROM alpine:3

# Установка необходимых пакетов
RUN apk add --no-cache dante-server sed

# Копируем конфигурационные файлы
COPY sockd.conf /etc/sockd.conf

# Добавляем скрипт запуска
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Запуск прокси
ENTRYPOINT ["/entrypoint.sh"]
