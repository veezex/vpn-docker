# Makefile for AmneziaWG Docker container

# Переменные
IMAGE_NAME = amnezia-wg-server
CONTAINER_NAME = awg-server
WG_PORT = 51820
WG_NETWORK = 10.8.0.1/24

# Цвета для вывода
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m # No Color

.PHONY: build run stop logs shell clean server-key help

# Помощь
help:
	@echo "$(GREEN)AmneziaWG Docker команды:$(NC)"
	@echo "  $(YELLOW)make build$(NC)     - Собрать Docker образ"
	@echo "  $(YELLOW)make run$(NC)       - Запустить контейнер (без клиентов)"
	@echo "  $(YELLOW)make run-with-clients WG_CLIENT_KEYS='key1,key2'$(NC) - Запустить с клиентскими ключами"
	@echo "  $(YELLOW)make stop$(NC)      - Остановить контейнер"
	@echo "  $(YELLOW)make logs$(NC)      - Показать логи контейнера"
	@echo "  $(YELLOW)make shell$(NC)     - Войти в контейнер"
	@echo "  $(YELLOW)make server-key$(NC) - Получить серверный публичный ключ"
	@echo "  $(YELLOW)make status$(NC)    - Показать статус AmneziaWG"
	@echo "  $(YELLOW)make clean$(NC)     - Удалить контейнер и образ"
	@echo ""
	@echo "$(GREEN)Примеры:$(NC)"
	@echo "  # Запуск с одним клиентом"
	@echo "  make run-with-clients WG_CLIENT_KEYS='AbCdEf...123='"
	@echo ""
	@echo "  # Запуск с несколькими клиентами"
	@echo "  make run-with-clients WG_CLIENT_KEYS='key1,key2,key3'"

# Сборка образа
build:
	@echo "$(GREEN)Сборка AmneziaWG Docker образа...$(NC)"
	docker build -t $(IMAGE_NAME) .

# Запуск контейнера без клиентов
run: build
	@echo "$(GREEN)Запуск AmneziaWG сервера...$(NC)"
	@echo "$(YELLOW)ВНИМАНИЕ: Клиентские ключи не указаны. Используйте run-with-clients для добавления клиентов.$(NC)"
	docker run -d \
		--name $(CONTAINER_NAME) \
		--cap-add=NET_ADMIN \
		--cap-add=SYS_MODULE \
		--sysctl net.ipv4.ip_forward=1 \
		-p $(WG_PORT):$(WG_PORT)/udp \
		-e WG_PORT=$(WG_PORT) \
		-e WG_NETWORK=$(WG_NETWORK) \
		$(IMAGE_NAME)
	@echo "$(GREEN)Контейнер запущен. Используйте 'make server-key' для получения серверного ключа.$(NC)"

# Запуск контейнера с клиентскими ключами
run-with-clients: build
	@if [ -z "$(WG_CLIENT_KEYS)" ]; then \
		echo "$(YELLOW)Ошибка: Необходимо указать WG_CLIENT_KEYS$(NC)"; \
		echo "Пример: make run-with-clients WG_CLIENT_KEYS='key1,key2'"; \
		exit 1; \
	fi
	@echo "$(GREEN)Запуск AmneziaWG сервера с клиентскими ключами...$(NC)"
	docker run -d \
		--name $(CONTAINER_NAME) \
		--cap-add=NET_ADMIN \
		--cap-add=SYS_MODULE \
		--sysctl net.ipv4.ip_forward=1 \
		-p $(WG_PORT):$(WG_PORT)/udp \
		-e WG_PORT=$(WG_PORT) \
		-e WG_NETWORK=$(WG_NETWORK) \
		-e WG_CLIENT_KEYS="$(WG_CLIENT_KEYS)" \
		$(IMAGE_NAME)
	@echo "$(GREEN)Контейнер запущен с клиентскими ключами.$(NC)"
	@sleep 3
	@make server-key

# Остановка контейнера
stop:
	@echo "$(GREEN)Остановка AmneziaWG сервера...$(NC)"
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONTAINER_NAME) 2>/dev/null || true

# Просмотр логов
logs:
	docker logs -f $(CONTAINER_NAME)

# Вход в контейнер
shell:
	docker exec -it $(CONTAINER_NAME) /bin/bash

# Получение серверного публичного ключа
server-key:
	@echo "$(GREEN)Серверный публичный ключ:$(NC)"
	@docker exec $(CONTAINER_NAME) get-server-key

# Показать статус AmneziaWG
status:
	@echo "$(GREEN)Статус AmneziaWG:$(NC)"
	@docker exec $(CONTAINER_NAME) awg show

# Генерация клиентского ключа
generate-client-key:
	@echo "$(GREEN)Генерация нового клиентского ключа:$(NC)"
	@echo "$(YELLOW)Приватный ключ:$(NC)"
	@docker run --rm $(IMAGE_NAME) awg genkey
	@echo "$(YELLOW)Публичный ключ (добавьте его в WG_CLIENT_KEYS):$(NC)"
	@docker run --rm $(IMAGE_NAME) sh -c 'awg genkey | awg pubkey'

# Полная очистка
clean: stop
	@echo "$(GREEN)Удаление образа...$(NC)"
	docker rmi $(IMAGE_NAME) 2>/dev/null || true

# Перезапуск с теми же параметрами
restart: stop run-with-clients

# Показать конфигурацию сервера
show-config:
	@echo "$(GREEN)Конфигурация сервера:$(NC)"
	@docker exec $(CONTAINER_NAME) cat /etc/amnezia/amneziawg/awg0.conf
