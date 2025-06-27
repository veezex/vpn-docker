# AmneziaWG Docker Server

Docker контейнер для запуска сервера AmneziaWG (обфусцированная версия WireGuard) на базе Ubuntu 24.04.

## Особенности

- ✅ Основан на Ubuntu 24.04 LTS
- ✅ Автоматическая настройка сервера AmneziaWG
- ✅ Поддержка переменной окружения `WG_CLIENT_KEYS` для добавления клиентов
- ✅ Простое получение серверного публичного ключа
- ✅ Автоматическое управление iptables правилами
- ✅ Готовые Makefile команды для удобства

## Быстрый старт

### 1. Сборка и запуск без клиентов

```bash
make build
make run
```

### 2. Получение серверного публичного ключа

```bash
make server-key
```

### 3. Запуск с клиентскими ключами

```bash
# Один клиент
make run-with-clients WG_CLIENT_KEYS='AbCdEfGhIjKlMnOpQrStUvWxYz123456789='

# Несколько клиентов (разделённые запятой)
make run-with-clients WG_CLIENT_KEYS='client1_key,client2_key,client3_key'
```

## Доступные команды

```bash
make help           # Показать справку
make build          # Собрать Docker образ
make run            # Запустить без клиентов
make run-with-clients WG_CLIENT_KEYS='key1,key2' # Запустить с клиентами
make stop           # Остановить контейнер
make logs           # Показать логи
make shell          # Войти в контейнер
make server-key     # Получить серверный публичный ключ
make status         # Показать статус AmneziaWG
make clean          # Удалить контейнер и образ
make generate-client-key # Сгенерировать новый клиентский ключ
make show-config    # Показать конфигурацию сервера
```

## Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `WG_INTERFACE` | Имя интерфейса | `awg0` |
| `WG_PORT` | UDP порт | `51820` |
| `WG_NETWORK` | Сеть сервера | `10.8.0.1/24` |
| `WG_CLIENT_KEYS` | Публичные ключи клиентов (через запятую) | пусто |

## Ручной запуск через Docker

```bash
# Сборка
docker build -t amnezia-wg-server .

# Запуск с клиентами
docker run -d \
  --name awg-server \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl net.ipv4.ip_forward=1 \
  -p 51820:51820/udp \
  -e WG_CLIENT_KEYS="client1_public_key,client2_public_key" \
  amnezia-wg-server

# Получение серверного ключа
docker exec awg-server get-server-key

# Просмотр статуса
docker exec awg-server awg show
```

## Работа с клиентскими ключами

### Генерация нового клиентского ключа

```bash
# Через Makefile
make generate-client-key

# Через Docker напрямую
docker run --rm amnezia-wg-server awg genkey | tee private.key
docker run --rm amnezia-wg-server awg pubkey < private.key
```

### Добавление клиентов во время работы

1. Остановите контейнер: `make stop`
2. Запустите с новыми ключами: `make run-with-clients WG_CLIENT_KEYS='old_key,new_key'`

## Конфигурация клиента

После запуска сервера клиентам понадобится:

1. **Серверный публичный ключ** - получите командой `make server-key`
2. **Endpoint** - IP-адрес сервера и порт (по умолчанию 51820)
3. **Allowed IPs** - обычно `0.0.0.0/0` для полного туннелирования

Пример клиентской конфигурации:

```ini
[Interface]
PrivateKey = <клиентский_приватный_ключ>
Address = 10.8.0.2/32

[Peer]
PublicKey = <серверный_публичный_ключ>
AllowedIPs = 0.0.0.0/0
Endpoint = <IP_сервера>:51820
PersistentKeepalive = 25

# AmneziaWG специфичные параметры (получите из полной конфигурации)
Jc = <значение>
Jmin = <значение>
Jmax = <значение>
S1 = <значение>
S2 = <значение>
H1 = <значение>
H2 = <значение>
H3 = <значение>
H4 = <значение>
```

## Отладка

```bash
# Просмотр логов
make logs

# Вход в контейнер
make shell

# Проверка состояния
make status

# Просмотр конфигурации
make show-config
```

## Безопасность

- Контейнер требует привилегированные права (`NET_ADMIN`, `SYS_MODULE`)
- Убедитесь, что порт 51820/UDP доступен извне
- Храните приватные ключи в безопасности
- Регулярно обновляйте образ для получения security-обновлений

## Технические детали

- Базовый образ: Ubuntu 24.04
- AmneziaWG устанавливается из официального PPA
- Автоматическое управление iptables
- Использует `awgcfg.py` для генерации конфигураций
- Поддерживает IPv4 forwarding
- Graceful shutdown при получении SIGTERM

## Лицензия

Этот проект использует AmneziaWG, который является форком WireGuard. Убедитесь в соблюдении соответствующих лицензий при использовании в коммерческих целях.
