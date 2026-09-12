#!/bin/bash
# Ejemplos de uso del comando `at`: tareas de UNA sola ejecución futura
# (a diferencia de cron, que repite según un horario).
#
# Requiere el paquete `at` instalado y el servicio corriendo:
#   sudo apt install -y at
#   sudo systemctl enable --now atd

echo "-- Programar para dentro de 5 minutos --"
echo "/home/usuario/notificar.sh" | at now + 5 minutes

echo "-- Programar para una hora específica de hoy (o mañana si ya pasó) --"
echo "/home/usuario/reporte.sh" | at 14:30

echo "-- Programar para una fecha y hora específica --"
echo "/home/usuario/respaldo_especial.sh" | at 22:00 2026-12-31

echo "-- Ver los jobs pendientes --"
atq

echo "-- Ver el contenido de un job pendiente (reemplaza N por el número que entrega atq) --"
at -c N

echo "-- Eliminar un job pendiente (reemplaza N por el número que entrega atq) --"
atrm N
