#!/bin/bash
# =============================================================
# OSMECH — Script de deploy na Hostinger VPS
# Uso: ./deploy.sh
# Pré-requisitos no VPS: docker, docker compose, flutter, git
# =============================================================
set -e

echo "=== OSMECH Deploy ==="

# 1. Build do frontend Flutter
echo "[1/4] Build do frontend..."
cd frontend
flutter pub get
flutter build web --release --dart-define=API_URL=https://seudominio.com.br
cd ..

# 2. Sobe os containers
echo "[2/4] Subindo containers..."
docker compose -f docker-compose.prod.yml --env-file .env.prod pull
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build

# 3. Aguarda o backend ficar saudável
echo "[3/4] Aguardando backend..."
for i in $(seq 1 12); do
  if docker exec osmech-backend wget -qO- http://localhost:8080/api/actuator/health 2>/dev/null | grep -q '"UP"'; then
    echo "Backend UP!"
    break
  fi
  echo "  Aguardando... ($i/12)"
  sleep 10
done

# 4. Verifica status
echo "[4/4] Status dos containers:"
docker compose -f docker-compose.prod.yml ps

echo ""
echo "=== Deploy concluído ==="
echo "Acesse: https://seudominio.com.br"
