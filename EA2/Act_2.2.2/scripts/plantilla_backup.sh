#!/bin/bash
#
# Plantilla de referencia para el script de respaldo de Act_2.2.2.
# NO es la solución a entregar: faltan piezas a propósito (marcadas con TODO)
# y usa rutas de ejemplo distintas a las que pide tu caso real.
# Adapta las rutas, agrega manejo de errores y ajusta el log según tu contexto.

ORIGEN="/ruta/ejemplo/datos"        # TODO: reemplaza por el directorio real a respaldar
DESTINO="/ruta/ejemplo/backups"     # TODO: reemplaza por el directorio real de respaldos
LOG="$DESTINO/backup.log"

FECHA=$(date +"%Y%m%d_%H%M%S")
ARCHIVO="backup_${FECHA}.tar.gz"

INICIO=$(date +"%Y-%m-%d %H:%M:%S")
echo "[$INICIO] Inicio de respaldo" >> "$LOG"

# TODO: verifica que $DESTINO exista antes de escribir en él (mkdir -p, o valida y aborta)

tar -czf "$DESTINO/$ARCHIVO" -C "$ORIGEN" .
RESULTADO=$?

FIN=$(date +"%Y-%m-%d %H:%M:%S")

if [ $RESULTADO -eq 0 ]; then
    TAMANO=$(du -h "$DESTINO/$ARCHIVO" | cut -f1)
    echo "[$FIN] Respaldo OK: $ARCHIVO ($TAMANO)" >> "$LOG"
else
    echo "[$FIN] ERROR: tar terminó con código $RESULTADO" >> "$LOG"
    # TODO: decide qué más hacer ante un error (¿notificar?, ¿reintentar?, ¿limpiar archivo parcial?)
fi

# TODO: política de retención — ¿cuántos respaldos antiguos conservas? ¿los borras o los mueves?
