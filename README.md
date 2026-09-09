# npm-installer

Instalador de [Nginx Proxy Manager](https://nginxproxymanager.com/) con Docker Compose. Instala Docker si falta, escribe el stack en `/root/npm` y levanta el contenedor con red propia `172.31.5.0/24`.

## ⚡ Quick install (one-liner)

```bash
curl -sSL https://raw.githubusercontent.com/mtandazo35/npm-installer/main/install.sh | sudo bash
```

Al terminar, abre el panel en:

```
http://<IP_DEL_SERVIDOR>:81
```

Credenciales por defecto (cámbialas en el primer login):

- **Email:** `admin@example.com`
- **Password:** `changeme`

## Qué hace el instalador

1. Exige root.
2. Instala Docker (`get.docker.com`) y el plugin `docker compose` si no están.
3. Avisa si los puertos 80, 81 o 443 ya están ocupados en el host (Apache/Nginx), mostrando quién los tiene.
4. Crea `/root/npm/docker-compose.yml` (respaldando el anterior si existía).
5. `docker compose up -d` y espera a que responda el puerto 81.
6. Muestra la URL del panel y las credenciales por defecto.

## Variables opcionales

| Variable | Por defecto | Uso |
|---|---|---|
| `NPM_DIR` | `/root/npm` | Carpeta del stack |
| `NPM_TZ` | `America/Guayaquil` | Zona horaria del contenedor |
| `NPM_SUBNET` | `172.31.5.0/24` | Subred de la red `npm-network` |
| `NPM_IP` | `172.31.5.2` | IP fija del contenedor |

```bash
curl -sSL https://raw.githubusercontent.com/mtandazo35/npm-installer/main/install.sh \
  | sudo NPM_DIR=/root/proxy NPM_SUBNET=172.31.9.0/24 NPM_IP=172.31.9.2 bash
```

## Instalación manual (paso a paso)

```bash
mkdir -p npm && cd npm
nano docker-compose.yml
```

```yaml
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
      - TZ=America/Guayaquil
      - PUID=1000
      - PGID=1000
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    networks:
      npm-network:
        ipv4_address: 172.31.5.2

networks:
  npm-network:
    ipam:
      driver: default
      config:
        - subnet: 172.31.5.0/24
```

```bash
docker compose up -d
```

## Operación

```bash
cd /root/npm
docker compose ps
docker compose logs -f
docker compose pull && docker compose up -d   # actualizar
docker compose down                            # parar
```

Los datos viven en `/root/npm/data` y los certificados en `/root/npm/letsencrypt`: respalda esas dos carpetas.

## Notas

- Los puertos 80 y 443 deben estar libres en el host y abiertos en el firewall para que funcione Let's Encrypt.
- Docker publica puertos saltándose UFW; si el host debe filtrar, usa la cadena `DOCKER-USER`.
