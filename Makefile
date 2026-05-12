SHELL := /usr/bin/env bash

.DEFAULT_GOAL := help

COMPOSE_FILE ?= docker-compose.yml
COMPOSE := docker compose -f $(COMPOSE_FILE)

SERVICE ?= all
IMAGE_TAG ?= latest

FRONTEND_SERVICE ?= frontend
BACKEND_SERVICE ?= backend
MONITORING_PROFILE ?= monitoring

.PHONY: help
help:
	@echo "Available commands:"
	@echo ""
	@echo "Deploy:"
	@echo "  make deploy SERVICE=frontend IMAGE_TAG=sha  Deploy selected service"
	@echo "  make deploy-frontend IMAGE_TAG=sha          Deploy frontend"
	@echo "  make deploy-backend IMAGE_TAG=sha           Deploy backend"
	@echo "  make deploy-all                             Deploy full stack"
	@echo ""
	@echo "Nginx:"
	@echo "  make nginx-deploy                           Copy nginx config, test it and reload nginx"
	@echo "  make nginx-test                             Test current nginx config"
	@echo "  make nginx-reload                           Reload nginx"
	@echo "  make nginx-status                           Show nginx status"
	@echo "  make nginx-logs                             Show nginx logs"
	@echo ""
	@echo "Docker Compose:"
	@echo "  make up                                     Start docker compose services"
	@echo "  make up-monitoring                          Start docker compose services with monitoring profile"
	@echo "  make down                                   Stop docker compose services"
	@echo "  make down-volumes                           Stop services and remove volumes"
	@echo "  make restart                                Restart docker compose services"
	@echo "  make ps                                     Show docker compose services"
	@echo "  make logs                                   Show docker compose logs"
	@echo "  make pull                                   Pull docker compose images"
	@echo "  make compose-check                          Validate docker compose config"
	@echo "  make compose-check-monitoring               Validate docker compose config with monitoring profile"
	@echo ""
	@echo "Frontend:"
	@echo "  make frontend-up                            Start frontend service"
	@echo "  make frontend-restart                       Restart frontend service"
	@echo "  make frontend-pull                          Pull frontend image"
	@echo "  make frontend-logs                          Show frontend logs"
	@echo "  make frontend-shell                         Open shell in frontend container"
	@echo "  make frontend-health                        Check frontend health"
	@echo ""
	@echo "Backend:"
	@echo "  make backend-up                             Start backend service"
	@echo "  make backend-restart                        Restart backend service"
	@echo "  make backend-pull                           Pull backend image"
	@echo "  make backend-logs                           Show backend logs"
	@echo "  make backend-shell                          Open shell in backend container"
	@echo "  make backend-health                         Check backend health"
	@echo "  make backend-migrate                        Run backend migrations"
	@echo ""
	@echo "Monitoring:"
	@echo "  make monitoring-up                          Start monitoring stack"
	@echo "  make monitoring-down                        Stop monitoring stack"
	@echo "  make monitoring-logs                        Show monitoring logs"
	@echo "  make monitoring-ps                          Show monitoring services"
	@echo ""
	@echo "Server:"
	@echo "  make ufw-status                             Show firewall status"
	@echo "  make fail2ban-status                        Show fail2ban sshd jail status"
	@echo "  make ssh-status                             Show ssh service status"
	@echo "  make status                                 Show common infra status"

.PHONY: deploy
deploy:
	./scripts/deploy-service.sh "$(SERVICE)" "$(IMAGE_TAG)"

.PHONY: deploy-frontend
deploy-frontend:
	./scripts/deploy-service.sh frontend "$(IMAGE_TAG)"

.PHONY: deploy-backend
deploy-backend:
	./scripts/deploy-service.sh backend "$(IMAGE_TAG)"

.PHONY: deploy-all
deploy-all:
	./scripts/deploy-service.sh all "$(IMAGE_TAG)"

.PHONY: nginx-deploy
nginx-deploy:
	./scripts/deploy-nginx.sh

.PHONY: nginx-test
nginx-test:
	sudo nginx -t

.PHONY: nginx-reload
nginx-reload:
	sudo nginx -t
	sudo systemctl reload nginx

.PHONY: nginx-status
nginx-status:
	sudo systemctl status nginx --no-pager

.PHONY: nginx-logs
nginx-logs:
	sudo journalctl -u nginx -n 100 --no-pager

.PHONY: up
up:
	$(COMPOSE) up -d

.PHONY: up-monitoring
up-monitoring:
	$(COMPOSE) --profile $(MONITORING_PROFILE) up -d

.PHONY: down
down:
	$(COMPOSE) down

.PHONY: down-volumes
down-volumes:
	$(COMPOSE) down -v

.PHONY: restart
restart:
	$(COMPOSE) restart

.PHONY: ps
ps:
	$(COMPOSE) ps

.PHONY: logs
logs:
	$(COMPOSE) logs -f --tail=100

.PHONY: pull
pull:
	$(COMPOSE) pull

.PHONY: compose-check
compose-check:
	$(COMPOSE) config

.PHONY: compose-check-monitoring
compose-check-monitoring:
	$(COMPOSE) --profile $(MONITORING_PROFILE) config

.PHONY: frontend-up
frontend-up:
	$(COMPOSE) up -d $(FRONTEND_SERVICE)

.PHONY: frontend-restart
frontend-restart:
	$(COMPOSE) restart $(FRONTEND_SERVICE)

.PHONY: frontend-pull
frontend-pull:
	$(COMPOSE) pull $(FRONTEND_SERVICE)

.PHONY: frontend-logs
frontend-logs:
	$(COMPOSE) logs -f --tail=100 $(FRONTEND_SERVICE)

.PHONY: frontend-shell
frontend-shell:
	$(COMPOSE) exec $(FRONTEND_SERVICE) sh

.PHONY: frontend-health
frontend-health:
	curl -i http://127.0.0.1:$${FRONTEND_PORT:-3000} || true

.PHONY: backend-up
backend-up:
	$(COMPOSE) up -d $(BACKEND_SERVICE)

.PHONY: backend-restart
backend-restart:
	$(COMPOSE) restart $(BACKEND_SERVICE)

.PHONY: backend-pull
backend-pull:
	$(COMPOSE) pull $(BACKEND_SERVICE)

.PHONY: backend-logs
backend-logs:
	$(COMPOSE) logs -f --tail=100 $(BACKEND_SERVICE)

.PHONY: backend-shell
backend-shell:
	$(COMPOSE) exec $(BACKEND_SERVICE) sh

.PHONY: backend-health
backend-health:
	curl -i http://127.0.0.1:$${BACKEND_PORT:-8000}/health || true
	curl -i http://127.0.0.1:$${BACKEND_PORT:-8000}/api/health || true

.PHONY: backend-migrate
backend-migrate:
	$(COMPOSE) exec $(BACKEND_SERVICE) sh -lc 'if command -v alembic >/dev/null 2>&1; then alembic upgrade head; elif command -v uv >/dev/null 2>&1; then uv run alembic upgrade head; elif [ -f manage.py ]; then python manage.py migrate; else echo "No known migration command found"; exit 1; fi'

.PHONY: monitoring-up
monitoring-up:
	$(COMPOSE) --profile $(MONITORING_PROFILE) up -d loki alloy grafana

.PHONY: monitoring-down
monitoring-down:
	$(COMPOSE) --profile $(MONITORING_PROFILE) stop loki alloy grafana

.PHONY: monitoring-logs
monitoring-logs:
	$(COMPOSE) --profile $(MONITORING_PROFILE) logs -f --tail=100 loki alloy grafana

.PHONY: monitoring-ps
monitoring-ps:
	$(COMPOSE) --profile $(MONITORING_PROFILE) ps loki alloy grafana

.PHONY: ufw-status
ufw-status:
	sudo ufw status verbose

.PHONY: fail2ban-status
fail2ban-status:
	sudo fail2ban-client status
	@echo ""
	-sudo fail2ban-client status sshd

.PHONY: ssh-status
ssh-status:
	sudo systemctl status ssh --no-pager
	@echo ""
	sudo ss -ltnp | grep -E ':(8888|22)\b' || true

.PHONY: status
status:
	@echo "=== Nginx ==="
	@sudo systemctl is-active nginx || true
	@echo ""
	@echo "=== SSH ==="
	@sudo systemctl is-active ssh || true
	@echo ""
	@echo "=== Fail2ban ==="
	@sudo systemctl is-active fail2ban || true
	@echo ""
	@echo "=== UFW ==="
	@sudo ufw status | head -n 20
	@echo ""
	@echo "=== Docker Compose ==="
	@$(COMPOSE) ps || true
	@echo ""
	@echo "=== Image tags ==="
	@test -f .env && grep -E '^(FRONTEND_IMAGE_TAG|BACKEND_IMAGE_TAG)=' .env || true