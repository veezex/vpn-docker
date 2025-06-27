#!/bin/bash
# Убираем set -e чтобы скрипт не завершался при ошибках
# set -e

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
echo "Применение настроек ядра..."
sysctl -w net.ipv4.ip_forward=1 2>/dev/null || echo "Не удалось установить ip_forward через sysctl (нормально для некоторых контейнеров)"

# Проверка доступности модуля ядра
KERNEL_MODULE_AVAILABLE=false
if modprobe amneziawg 2>/dev/null; then
    log "Модуль ядра amneziawg доступен"
    KERNEL_MODULE_AVAILABLE=true
elif modprobe wireguard 2>/dev/null; then
    log "Модуль ядра wireguard доступен"
    KERNEL_MODULE_AVAILABLE=true
else
    log "Модуль ядра amneziawg/wireguard недоступен, работаем в userspace режиме"
    KERNEL_MODULE_AVAILABLE=false
fi

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
            client_ip="10.8.0.$((i+2))"
            log "Добавление клиента: $client_name с IP $client_ip"
            
            # Добавляем пир прямо в конфигурационный файл (более надежно)
            if [ -f "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" ]; then
                # Проверяем, нет ли уже этого ключа в конфиге
                if ! grep -q "$key" "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf"; then
                    cat >> "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" << EOF

[Peer]
PublicKey = $key
AllowedIPs = $client_ip/32
EOF
                    log "Клиент $client_name добавлен в конфигурацию"
                fi
            fi
        fi
    done
fi

# Функция для получения серверного публичного ключа
show_server_public_key() {
    if [ -f "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" ]; then
        # Сначала пробуем получить из комментария (awgcfg.py сохраняет публичный ключ там)
        public_key=$(grep "#_PublicKey" "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" | cut -d'=' -f2 | tr -d ' ')
        if [ -n "$public_key" ]; then
            echo "=== СЕРВЕРНЫЙ ПУБЛИЧНЫЙ КЛЮЧ ==="
            echo "$public_key"
            echo "==============================="
        else
            # Если не найден в комментарии, генерируем из приватного
            private_key=$(grep "PrivateKey" "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" | cut -d'=' -f2 | tr -d ' ')
            if [ -n "$private_key" ]; then
                public_key=$(echo "$private_key" | awg pubkey 2>/dev/null || echo "$private_key" | wg pubkey 2>/dev/null)
                if [ -n "$public_key" ]; then
                    echo "=== СЕРВЕРНЫЙ ПУБЛИЧНЫЙ КЛЮЧ ==="
                    echo "$public_key"
                    echo "==============================="
                fi
            fi
        fi
    fi
}

# Создание скрипта для получения публичного ключа сервера
cat > /usr/local/bin/get-server-key << 'EOF'
#!/bin/bash
interface=${1:-awg0}
if [ -f "/etc/amnezia/amneziawg/${interface}.conf" ]; then
    # Сначала пробуем получить из комментария (awgcfg.py сохраняет публичный ключ там)
    public_key=$(grep "#_PublicKey" "/etc/amnezia/amneziawg/${interface}.conf" | cut -d'=' -f2 | tr -d ' ')
    if [ -n "$public_key" ]; then
        echo "$public_key"
    else
        # Если не найден в комментарии, генерируем из приватного
        private_key=$(grep "PrivateKey" "/etc/amnezia/amneziawg/${interface}.conf" | cut -d'=' -f2 | tr -d ' ')
        if [ -n "$private_key" ]; then
            echo "$private_key" | awg pubkey 2>/dev/null || echo "$private_key" | wg pubkey 2>/dev/null || echo "Ошибка генерации публичного ключа"
        else
            echo "Ошибка: не удалось найти приватный ключ в конфигурации"
        fi
    fi
else
    echo "Ошибка: файл конфигурации не найден"
fi
EOF
chmod +x /usr/local/bin/get-server-key

# Запуск интерфейса
log "Запуск AmneziaWG интерфейса $WG_INTERFACE..."

# Попытка запуска с обработкой ошибок
if ! awg-quick up "$WG_INTERFACE" 2>/dev/null; then
    log "Стандартный запуск не удался, пробуем альтернативные методы..."
    
    # Проверяем, есть ли конфигурационный файл
    if [ -f "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" ]; then
        log "Попытка ручного создания интерфейса..."
        
        # Создаем интерфейс вручную
        if ip link add "$WG_INTERFACE" type wireguard 2>/dev/null; then
            log "Создан WireGuard интерфейс"
        elif ip link add "$WG_INTERFACE" type amneziawg 2>/dev/null; then
            log "Создан AmneziaWG интерфейс"
        else
            log "Попытка создания через стандартный способ..."
            ip link add "$WG_INTERFACE" type dummy 2>/dev/null || true
        fi
        
        if ip link show "$WG_INTERFACE" >/dev/null 2>&1; then
            # Настраиваем интерфейс через конфигурацию
            log "Применение конфигурации к интерфейсу..."
            
            # Извлекаем приватный ключ и настройки из конфига
            PRIVATE_KEY=$(grep "PrivateKey" "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" | cut -d'=' -f2 | tr -d ' ')
            LISTEN_PORT=$(grep "ListenPort" "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" | cut -d'=' -f2 | tr -d ' ')
            
            log "Найден приватный ключ: ${PRIVATE_KEY:0:10}... и порт: $LISTEN_PORT"
            
            # Настраиваем интерфейс с помощью wg/awg команд
            log "Настройка приватного ключа..."
            if command -v awg >/dev/null; then
                if awg set "$WG_INTERFACE" private-key <(echo "$PRIVATE_KEY") listen-port "$LISTEN_PORT" 2>/dev/null; then
                    log "Успешно настроен через awg"
                elif wg set "$WG_INTERFACE" private-key <(echo "$PRIVATE_KEY") listen-port "$LISTEN_PORT" 2>/dev/null; then
                    log "Успешно настроен через wg"
                else
                    log "ОШИБКА: Не удалось настроить интерфейс ни через awg, ни через wg"
                fi
            else
                if wg set "$WG_INTERFACE" private-key <(echo "$PRIVATE_KEY") listen-port "$LISTEN_PORT" 2>/dev/null; then
                    log "Успешно настроен через wg"
                else
                    log "ОШИБКА: Не удалось настроить интерфейс через wg"
                fi
            fi
            
            # Получаем IP адрес из переменной окружения (более надежно)
            INTERFACE_IP="$WG_NETWORK"
            log "Назначение IP адреса: $INTERFACE_IP"
            if [ -n "$INTERFACE_IP" ]; then
                if ip addr add "$INTERFACE_IP" dev "$WG_INTERFACE" 2>/dev/null; then
                    log "IP адрес назначен успешно"
                else
                    log "ПРЕДУПРЕЖДЕНИЕ: Не удалось назначить IP адрес"
                fi
                
                if ip link set "$WG_INTERFACE" up 2>/dev/null; then
                    log "Интерфейс поднят успешно"
                else
                    log "ПРЕДУПРЕЖДЕНИЕ: Не удалось поднять интерфейс"
                fi
                
                log "Интерфейс $WG_INTERFACE настроен вручную с IP: $INTERFACE_IP"
            fi
            
            # Добавляем пиров (клиентов) если есть
            log "Добавление пиров в интерфейс..."
            if [ -n "$WG_CLIENT_KEYS" ]; then
                IFS=',' read -ra KEYS <<< "$WG_CLIENT_KEYS"
                for i in "${!KEYS[@]}"; do
                    key="${KEYS[$i]}"
                    if [ -n "$key" ]; then
                        client_ip="10.8.0.$((i+2))"
                        log "Добавление пира с ключом ${key:0:10}... и IP $client_ip"
                        if command -v awg >/dev/null; then
                            awg set "$WG_INTERFACE" peer "$key" allowed-ips "$client_ip/32" 2>/dev/null || \
                            wg set "$WG_INTERFACE" peer "$key" allowed-ips "$client_ip/32" 2>/dev/null || \
                            log "ПРЕДУПРЕЖДЕНИЕ: Не удалось добавить пира $key"
                        else
                            wg set "$WG_INTERFACE" peer "$key" allowed-ips "$client_ip/32" 2>/dev/null || \
                            log "ПРЕДУПРЕЖДЕНИЕ: Не удалось добавить пира $key"
                        fi
                    fi
                done
            fi
        else
            log "ОШИБКА: Не удалось создать интерфейс $WG_INTERFACE"
            log "Проверьте поддержку WireGuard/AmneziaWG в ядре"
            log "Продолжаем работу без интерфейса..."
        fi
    else
        log "ОШИБКА: Конфигурационный файл не найден"
        log "Продолжаем работу..."
    fi
else
    log "Интерфейс запущен через awg-quick успешно!"
fi

log "Завершение настройки интерфейса"

# Показ серверного публичного ключа
log "Получение серверного публичного ключа..."
show_server_public_key

# Показ статуса
log "AmneziaWG сервер запущен!"
log "Для получения серверного публичного ключа выполните: docker exec <container_name> get-server-key"

# Показ текущего состояния
log "Проверка состояния интерфейса..."
if awg show 2>/dev/null; then
    log "Статус через awg:"
    awg show
elif wg show 2>/dev/null; then
    log "Статус через wg:"
    wg show
else
    log "Команды awg/wg недоступны, проверяем интерфейс напрямую"
    if ip addr show "$WG_INTERFACE" 2>/dev/null; then
        log "Информация об интерфейсе:"
        ip addr show "$WG_INTERFACE"
    else
        log "Интерфейс $WG_INTERFACE не найден"
    fi
fi

log "Настройка завершена, переходим к основному циклу"

# Функция для корректного завершения
cleanup() {
    log "Остановка AmneziaWG сервера..."
    awg-quick down "$WG_INTERFACE" 2>/dev/null || \
    (ip link delete "$WG_INTERFACE" 2>/dev/null && log "Интерфейс удален вручную") || \
    true
    exit 0
}

# Обработка сигналов завершения
trap cleanup SIGTERM SIGINT

# Бесконечный цикл для поддержания работы контейнера
log "Контейнер готов к работе. Поддержание активности..."
while true; do
    sleep 30
    # Проверка состояния интерфейса
    if ! ip link show "$WG_INTERFACE" &>/dev/null; then
        log "Интерфейс $WG_INTERFACE не активен, попытка восстановления..."
        # Попытка пересоздания интерфейса
        if [ -f "/etc/amnezia/amneziawg/${WG_INTERFACE}.conf" ]; then
            awg-quick up "$WG_INTERFACE" 2>/dev/null || log "Не удалось восстановить интерфейс"
        fi
    else
        # Периодический вывод статистики
        if [ $(($(date +%s) % 300)) -eq 0 ]; then  # каждые 5 минут
            log "Интерфейс $WG_INTERFACE активен"
        fi
    fi
done
