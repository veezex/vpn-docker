#!/bin/bash
# check_compatibility.sh - Проверка совместимости системы с AmneziaWG

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=== ПРОВЕРКА СОВМЕСТИМОСТИ AMNEZIAWG ==="
echo ""

# Проверка архитектуры
ARCH=$(uname -m)
log "Архитектура системы: $ARCH"

# Проверка ядра
KERNEL=$(uname -r)
log "Версия ядра: $KERNEL"

# Проверка Docker
if command -v docker >/dev/null; then
    DOCKER_VERSION=$(docker --version)
    log "Docker: $DOCKER_VERSION"
else
    error "Docker не установлен"
    exit 1
fi

# Проверка поддержки WireGuard в ядре
echo ""
log "Проверка поддержки WireGuard/AmneziaWG..."

if lsmod | grep -q wireguard; then
    log "✅ Модуль WireGuard загружен"
elif lsmod | grep -q amneziawg; then
    log "✅ Модуль AmneziaWG загружен"
elif modprobe wireguard 2>/dev/null; then
    log "✅ Модуль WireGuard доступен"
    modprobe -r wireguard
elif modprobe amneziawg 2>/dev/null; then
    log "✅ Модуль AmneziaWG доступен"
    modprobe -r amneziawg
else
    warn "⚠️  Модули ядра WireGuard/AmneziaWG недоступны"
    warn "   Контейнер будет работать в userspace режиме"
fi

# Проверка NET_ADMIN capability
echo ""
log "Проверка прав доступа..."
if [ "$EUID" -eq 0 ]; then
    log "✅ Скрипт запущен с правами root"
else
    warn "⚠️  Скрипт не запущен с правами root"
    warn "   Для Docker контейнера потребуются флаги --cap-add=NET_ADMIN"
fi

# Проверка IP forwarding
echo ""
log "Проверка настроек сети..."
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" = "1" ]; then
    log "✅ IP forwarding включен"
else
    warn "⚠️  IP forwarding отключен"
    warn "   Выполните: sudo make setup-host"
fi

# Проверка iptables
if command -v iptables >/dev/null; then
    log "✅ iptables доступен"
    
    # Проверка правил для AmneziaWG
    if iptables -t nat -L | grep -q "10.8.0.0/24"; then
        log "✅ Правила iptables для AmneziaWG настроены"
    else
        warn "⚠️  Правила iptables не настроены"
        warn "   Выполните: sudo make setup-host"
    fi
else
    error "❌ iptables недоступен"
fi

# Проверка открытых портов
echo ""
log "Проверка портов..."
if ss -ulnp | grep -q ":41822"; then
    warn "⚠️  Порт 41822 уже используется"
    ss -ulnp | grep ":41822"
else
    log "✅ Порт 41822 свободен"
fi

# Рекомендации
echo ""
echo "=== РЕКОМЕНДАЦИИ ==="

if ! grep -q "10.8.0.0/24" <(iptables -t nat -L 2>/dev/null) 2>/dev/null; then
    echo "1. Настройте хост-систему:"
    echo "   sudo make setup-host"
    echo ""
fi

echo "2. Запустите контейнер с необходимыми правами:"
echo "   make run-with-clients WG_CLIENT_KEYS='your_client_key'"
echo ""

echo "3. Проверьте работу:"
echo "   make server-key"
echo "   make status"
echo ""

if ! lsmod | grep -E "(wireguard|amneziawg)" >/dev/null; then
    echo "4. При проблемах с модулем ядра контейнер будет работать"
    echo "   в userspace режиме (может быть медленнее)"
    echo ""
fi

echo "=== ПРОВЕРКА ЗАВЕРШЕНА ==="
