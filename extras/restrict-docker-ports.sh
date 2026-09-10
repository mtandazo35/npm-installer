#!/bin/bash
# Restringe puertos publicados por Docker que UFW no puede filtrar (cadena DOCKER-USER).
# Ojo: --dport NO sirve tras el DNAT de Docker, y sin --ctdir ORIGINAL se descartan
# las respuestas del contenedor y el servicio se cuelga.
set -e

PORTS="${PORTS:-81}"
ALLOW="${ALLOW:-205.235.6.128/25 10.77.88.2/32 45.224.21.25/32 172.16.35.0/24 172.19.1.0/24}"

# Limpiar reglas propias previas (idempotente)
while iptables -S DOCKER-USER | grep -q "restrict-docker-ports"; do
  N=$(iptables -S DOCKER-USER | grep -n "restrict-docker-ports" | head -1 | cut -d: -f1)
  iptables -D DOCKER-USER $((N-1))
done

for P in $PORTS; do
  iptables -I DOCKER-USER 1 -p tcp -m conntrack --ctdir ORIGINAL --ctorigdstport "$P" \
    -m comment --comment "restrict-docker-ports" -j DROP
  for S in $ALLOW; do
    iptables -I DOCKER-USER 1 -s "$S" -p tcp -m conntrack --ctdir ORIGINAL --ctorigdstport "$P" \
      -m comment --comment "restrict-docker-ports" -j RETURN
  done
done

iptables -L DOCKER-USER -v -n --line-numbers | head -12
