#!/bin/bash
#
# install.sh - Instalador de Nginx Proxy Manager (Docker Compose)
# Uso: curl -sSL https://raw.githubusercontent.com/mtandazo35/npm-installer/main/install.sh | sudo bash
#
set -e

[ "$(id -u)" -eq 0 ] || { echo "Ejecuta como root (sudo)"; exit 1; }

DIR="${NPM_DIR:-/root/npm}"
TZ_NPM="${NPM_TZ:-America/Guayaquil}"
SUBNET="${NPM_SUBNET:-172.31.5.0/24}"
NPM_IP="${NPM_IP:-172.31.5.2}"

# 1. Docker + plugin compose
if ! command -v docker >/dev/null 2>&1; then
  echo "==> Instalando Docker..."
  curl -fsSL https://get.docker.com | sh
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "==> Instalando el plugin docker compose..."
  apt-get update -qq
  apt-get install -y docker-compose-plugin
fi
systemctl enable --now docker >/dev/null 2>&1 || true

# 2. Avisar si los puertos ya están ocupados (Apache/Nginx del host)
for P in 80 81 443; do
  if ss -tlnp 2>/dev/null | grep -q ":${P} "; then
    echo "AVISO: el puerto ${P} ya está en uso; NPM no podrá levantar hasta liberarlo:"
    ss -tlnp | grep ":${P} "
  fi
done

# 3. Stack
mkdir -p "$DIR"
cd "$DIR"

if [ -f docker-compose.yml ]; then
  cp -a docker-compose.yml "docker-compose.yml.bak.$(date +%Y%m%d-%H%M%S)"
fi

cat > docker-compose.yml <<YML
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    environment:
      - TZ=${TZ_NPM}
      - PUID=1000
      - PGID=1000
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    networks:
      npm-network:
        ipv4_address: ${NPM_IP}

networks:
  npm-network:
    ipam:
      driver: default
      config:
        - subnet: ${SUBNET}
YML

echo "==> Levantando Nginx Proxy Manager..."
docker compose up -d

# 4. Esperar a que responda la interfaz de administración
echo -n "==> Esperando a la interfaz (puerto 81)"
for _ in $(seq 1 60); do
  if curl -fsS -o /dev/null http://127.0.0.1:81 2>/dev/null; then break; fi
  echo -n "."
  sleep 2
done
echo ""

IP=$(hostname -I | awk '{print $1}')
echo ""
echo "=========================================="
echo " Nginx Proxy Manager instalado"
echo " Panel:    http://${IP}:81"
echo " Usuario:  admin@example.com"
echo " Password: changeme   (cámbialos en el primer login)"
echo " Stack:    ${DIR}/docker-compose.yml"
echo "=========================================="
docker compose ps
