#!/bin/bash
# setup_host_for_awg.sh - Скрипт настройки хост-системы для AmneziaWG в Docker

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Логирование
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   error "Этот скрипт должен быть запущен с правами root (sudo)"
   exit 1
fi

# Функция для определения основного сетевого интерфейса
get_main_interface() {
    # Получаем интерфейс с маршрутом по умолчанию
    ip route show default | awk '/default/ { print $5 }' | head -n1
}

# Функция для получения внешнего IP
get_external_ip() {
    local main_iface=$(get_main_interface)
    ip addr show "$main_iface" | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1
}

log "Настройка хост-системы для AmneziaWG Docker контейнера"

# Получение информации о сети
MAIN_INTERFACE=$(get_main_interface)
EXTERNAL_IP=$(get_external_ip)

log "Основной сетевой интерфейс: $MAIN_INTERFACE"
log "Внешний IP-адрес: $EXTERNAL_IP"

# 1. Включение IP forwarding
log "Включение IP forwarding..."
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-awg-forwarding.conf
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.d/99-awg-forwarding.conf
sysctl -p /etc/sysctl.d/99-awg-forwarding.conf

# 2. Настройка iptables для NAT
log "Настройка iptables правил..."

# Очистка существующих правил для AWG (если есть)
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o "$MAIN_INTERFACE" -j MASQUERADE 2>/dev/null || true
iptables -D FORWARD -s 10.8.0.0/24 -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -d 10.8.0.0/24 -j ACCEPT 2>/dev/null || true

# Добавление новых правил
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$MAIN_INTERFACE" -j MASQUERADE
iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -d 10.8.0.0/24 -j ACCEPT

# Разрешаем трафик на порту AmneziaWG
iptables -A INPUT -p udp --dport 41822 -j ACCEPT

log "Правила iptables добавлены"

# 3. Сохранение правил iptables
log "Сохранение правил iptables..."

# Установка iptables-persistent если его нет
if ! dpkg -l | grep -q iptables-persistent; then
    log "Установка iptables-persistent..."
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
fi

# Сохранение правил
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# 4. Создание скрипта для очистки правил
cat > /usr/local/bin/cleanup-awg-rules.sh << 'EOF'
#!/bin/bash
# Скрипт для очистки правил AmneziaWG

# Получение основного интерфейса
MAIN_INTERFACE=$(ip route show default | awk '/default/ { print $5 }' | head -n1)

echo "Очистка iptables правил для AmneziaWG..."

# Удаление правил
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o "$MAIN_INTERFACE" -j MASQUERADE 2>/dev/null || true
iptables -D FORWARD -s 10.8.0.0/24 -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -d 10.8.0.0/24 -j ACCEPT 2>/dev/null || true
iptables -D INPUT -p udp --dport 41822 -j ACCEPT 2>/dev/null || true

echo "Правила очищены"

# Сохранение изменений
if command -v iptables-save >/dev/null; then
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    echo "Правила сохранены"
fi
EOF

chmod +x /usr/local/bin/cleanup-awg-rules.sh

# 5. Проверка Docker
log "Проверка Docker..."
if ! command -v docker >/dev/null; then
    error "Docker не установлен. Установите Docker перед продолжением."
    exit 1
fi

if ! systemctl is-active --quiet docker; then
    log "Запуск Docker..."
    systemctl start docker
    systemctl enable docker
fi

# 6. Создание Docker network для AWG (если нужно)
log "Настройка Docker сети..."
if ! docker network ls | grep -q awg-network; then
    docker network create \
        --driver bridge \
        --subnet=172.20.0.0/16 \
        --gateway=172.20.0.1 \
        awg-network
    log "Docker сеть awg-network создана"
else
    log "Docker сеть awg-network уже существует"
fi

# 7. Вывод информации
log "Настройка завершена успешно!"
echo ""
echo -e "${GREEN}=== ИНФОРМАЦИЯ ДЛЯ ЗАПУСКА КОНТЕЙНЕРА ===${NC}"
echo -e "${YELLOW}Основной интерфейс:${NC} $MAIN_INTERFACE"
echo -e "${YELLOW}Внешний IP:${NC} $EXTERNAL_IP"
echo -e "${YELLOW}AWG сеть:${NC} 10.8.0.0/24"
echo ""
echo -e "${GREEN}=== КОМАНДЫ ДЛЯ ЗАПУСКА ===${NC}"
echo "# Переход в директорию с проектом:"
echo "cd /path/to/amnezia-wg"
echo ""
echo "# Запуск с клиентскими ключами:"
echo "make run-with-clients WG_CLIENT_KEYS='your_client_public_key'"
echo ""
echo "# Или через Docker напрямую:"
echo "docker run -d \\"
echo "  --name awg-server \\"
echo "  --cap-add=NET_ADMIN \\"
echo "  --cap-add=SYS_MODULE \\"
echo "  --sysctl net.ipv4.ip_forward=1 \\"
echo "  --network=awg-network \\"
echo "  -p 41822:41822/udp \\"
echo "  -e WG_CLIENT_KEYS='your_client_public_key' \\"
echo "  amnezia-wg-server"
echo ""
echo -e "${GREEN}=== ПОЛЕЗНЫЕ КОМАНДЫ ===${NC}"
echo "# Просмотр правил iptables:"
echo "iptables -t nat -L -n -v | grep 10.8.0"
echo ""
echo "# Очистка правил AWG:"
echo "sudo /usr/local/bin/cleanup-awg-rules.sh"
echo ""
echo "# Просмотр логов контейнера:"
echo "docker logs awg-server"
echo ""
echo -e "${YELLOW}ВАЖНО:${NC} Убедитесь, что порт 41822/UDP открыт в файрволе!"

# 8. Проверка файрвола
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
    warn "UFW активен. Не забудьте открыть порт 41822:"
    echo "sudo ufw allow 41822/udp"
elif command -v firewall-cmd >/dev/null && systemctl is-active --quiet firewalld; then
    warn "firewalld активен. Не забудьте открыть порт 41822:"
    echo "sudo firewall-cmd --permanent --add-port=41822/udp"
    echo "sudo firewall-cmd --reload"
fi
