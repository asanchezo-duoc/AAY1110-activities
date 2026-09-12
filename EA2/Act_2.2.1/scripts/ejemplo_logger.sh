#!/bin/bash
# Ejemplo didáctico: crea un pseudo-respaldo y registra el resultado en DOS lugares:
#   1. Un archivo de log propio (como en Act_2.2.2).
#   2. El log del sistema, vía `logger` (syslog/journald) — para poder revisarlo
#      con las herramientas estándar de administración de Linux (journalctl, /var/log/syslog).
#
# Usa rutas y nombres de ejemplo: adapta todo antes de reutilizarlo en un caso real.

ORIGEN="/tmp/act221-ejemplo/origen"
DESTINO="/tmp/act221-ejemplo/destino"
LOG_LOCAL="$DESTINO/respaldo.log"
TAG="respaldo_ejemplo"   # identificador para filtrar este script en el log del sistema

mkdir -p "$ORIGEN" "$DESTINO"

FECHA=$(date +"%Y%m%d_%H%M%S")
ARCHIVO="respaldo_${FECHA}.tar.gz"

INICIO=$(date +"%Y-%m-%d %H:%M:%S")
echo "[$INICIO] Inicio de respaldo" >> "$LOG_LOCAL"
logger -t "$TAG" "Inicio de respaldo: $ARCHIVO"

tar -czf "$DESTINO/$ARCHIVO" -C "$ORIGEN" .
RESULTADO=$?

FIN=$(date +"%Y-%m-%d %H:%M:%S")

if [ $RESULTADO -eq 0 ]; then
    TAMANO=$(du -h "$DESTINO/$ARCHIVO" | cut -f1)
    echo "[$FIN] Respaldo OK: $ARCHIVO ($TAMANO)" >> "$LOG_LOCAL"
    logger -t "$TAG" -p user.info "Respaldo OK: $ARCHIVO ($TAMANO)"
else
    echo "[$FIN] ERROR: tar terminó con código $RESULTADO" >> "$LOG_LOCAL"
    logger -t "$TAG" -p user.err "ERROR al generar respaldo (código $RESULTADO)"
fi
