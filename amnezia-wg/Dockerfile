FROM ubuntu:24.04

# Установка системных пакетов
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    software-properties-common \
    curl \
    wget \
    python3 \
    python3-pip \
    iptables \
    iproute2 \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Включение маршрутизации IPv4
RUN echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/00-amnezia.conf

# Установка пакетов AmneziaWG
RUN add-apt-repository -y ppa:amnezia/ppa && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y amneziawg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Установка Python модулей
RUN pip3 install qrcode[pil] --break-system-packages

# Создание рабочей директории
WORKDIR /awg

# Скачивание утилиты для работы с конфигами AWG
RUN wget -O awgcfg.py https://gist.githubusercontent.com/remittor/8c3d9ff293b2ba4b13c367cc1a69f9eb/raw/awgcfg.py

# Создание entrypoint скрипта
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Открытие порта AmneziaWG
EXPOSE 41822/udp

# Переменные окружения со значениями по умолчанию
ENV WG_INTERFACE=awg0
ENV WG_PORT=41822
ENV WG_NETWORK=10.8.0.1/24
ENV WG_CLIENT_KEYS=""

ENTRYPOINT ["/entrypoint.sh"]
