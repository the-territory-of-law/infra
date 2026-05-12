#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-all}"
IMAGE_TAG="${2:-latest}"

set_env_var() {
  local key="$1"
  local value="$2"

  touch .env

  if grep -q "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${value}|" .env
  else
    echo "${key}=${value}" >> .env
  fi
}

case "$SERVICE" in
  frontend)
    set_env_var "FRONTEND_IMAGE_TAG" "$IMAGE_TAG"

    docker compose pull frontend
    docker compose up -d frontend
    ;;

  backend)
    set_env_var "BACKEND_IMAGE_TAG" "$IMAGE_TAG"

    docker compose pull backend
    docker compose up -d backend
    ;;

  all)
    set_env_var "FRONTEND_IMAGE_TAG" "$IMAGE_TAG"
    set_env_var "BACKEND_IMAGE_TAG" "$IMAGE_TAG"

    docker compose --profile monitoring pull
    docker compose --profile monitoring up -d --remove-orphans
    ;;

  *)
    echo "Unknown service: $SERVICE"
    echo "Allowed values: all, frontend, backend"
    exit 1
    ;;
esac

./scripts/deploy-nginx.sh

docker compose --profile monitoring ps
sudo nginx -t
