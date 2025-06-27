#!/bin/bash
set -e

# Функция для логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Функция для генерации ключей
generate_keys() {
    local private_key=$(awg genkey)
    local public_key=$(echo "$private_key" | awg pubkey)
    echo "$private_key,$public_key"
}

# Применение настроек ядра
sysctl -p /etc/sysctl.d/00-amnezia.conf

# Создание директории для конфигов
mkdir -p /etc/amnezia/amneziawg

log "Запуск AmneziaWG сервера..."
log "Интерфейс: $WG_INTERFACE"
log "Порт: $WG_PORT"
log "Сеть: $WG_NETWORK"

# Получение IP адреса контейнера (внешний IP)
EXTERNAL_IP=$(curl -s ifconfig.me || echo "127.0.0.1")
log "Внешний IP: $EXTERNAL_IP"

# Проверка существования конфигурации
if [ ! -f "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" ]; then
    log "Создание серверной конфигурации..."
    
    # Генерация серверного конфига с помощью awgcfg.py
    python3 awgcfg.py --make "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" -i "$WG_NETWORK" -p "$WG_PORT"
    
    # Создание шаблона клиентского конфига
    python3 awgcfg.py --create
    
    log "Серверная конфигурация создана"
else
    log "Использование существующей конфигурации"
fi

# Добавление клиентов из переменной окружения WG_CLIENT_KEYS
if [ -n "$WG_CLIENT_KEYS" ]; then
    log "Добавление клиентских ключей..."
    IFS=',' read -ra KEYS <<< "$WG_CLIENT_KEYS"
    for i in "${!KEYS[@]}"; do
        key="${KEYS[$i]}"
        if [ -n "$key" ]; then
            client_name="client_$((i+1))"
            log "Добавление клиента: $client_name"
            
            # Временный файл для клиентского конфига
            temp_client_conf="/tmp/${client_name}.conf"
            
            # Создаем временный клиентский конфиг с публичным ключом
            cat > "$temp_client_conf" << EOF
[Interface]
PrivateKey = dummy_private_key
Address = 10.8.0.$((i+2))/32

[Peer]
PublicKey = $key
AllowedIPs = 10.8.0.$((i+2))/32
EOF
            
            # Добавляем пир к серверному конфигу
            awg set "$WG_INTERFACE" peer "$key" allowed-ips "10.8.0.$((i+2))/32" 2>/dev/null || true
            
            # Добавляем пир в конфигурационный файл
            if ! grep -q "$key" "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf"; then
                cat >> "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" << EOF

[Peer]
PublicKey = $key
AllowedIPs = 10.8.0.$((i+2))/32
EOF
            fi
        fi
    done
fi

# Функция для получения серверного публичного ключа
show_server_public_key() {
    if [ -f "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" ]; then
        # Извлекаем приватный ключ из конфига и генерируем публичный
        private_key=$(grep "PrivateKey" "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" | cut -d'=' -f2 | tr -d ' ')
        if [ -n "$private_key" ]; then
            public_key=$(echo "$private_key" | awg pubkey)
            echo "=== СЕРВЕРНЫЙ ПУБЛИЧНЫЙ КЛЮЧ ==="
            echo "$public_key"
            echo "==============================="
        fi
    fi
}

# Создание скрипта для получения публичного ключа сервера
cat > /usr/local/bin/get-server-key << 'EOF'
#!/bin/bash
interface=${1:-awg0}
if [ -f "/etc/amnezia/amneziawg/${interface}.conf" ]; then
    private_key=$(grep "PrivateKey" "/etc/amnezia/amneziawg/${interface}.conf" | cut -d'=' -f2 | tr -d ' ')
    if [ -n "$private_key" ]; then
        echo "$private_key" | awg pubkey
    else
        echo "Ошибка: не удалось найти приватный ключ в конфигурации"
    fi
else
    echo "Ошибка: файл конфигурации не найден"
fi
EOF
chmod +x /usr/local/bin/get-server-key

# Запуск интерфейса
log "Запуск AmneziaWG интерфейса $WG_INTERFACE..."
awg-quick up "$WG_INTERFACE"

# Показ серверного публичного ключа
show_server_public_key

# Показ статуса
log "AmneziaWG сервер запущен!"
log "Для получения серверного публичного ключа выполните: docker exec <container_name> get-server-key"

# Показ текущего состояния
awg show

# Функция для корректного завершения
cleanup() {
    log "Остановка AmneziaWG сервера..."
    awg-quick down "$WG_INTERFACE" 2>/dev/null || true
    exit 0
}

# Обработка сигналов завершения
trap cleanup SIGTERM SIGINT

# Бесконечный цикл для поддержания работы контейнера
while true; do
    sleep 30
    # Проверка состояния интерфейса
    if ! ip link show "$WG_INTERFACE" &>/dev/null; then
        log "Интерфейс $WG_INTERFACE не активен, перезапуск..."
        awg-quick up "$WG_INTERFACE"
    fi
done
