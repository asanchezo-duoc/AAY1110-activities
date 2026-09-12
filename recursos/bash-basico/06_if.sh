#!/bin/bash
# if / elif / else: decisiones según condiciones numéricas, de texto o de archivos.

read -p "Ingresa un número: " numero

if [ "$numero" -gt 0 ] 2>/dev/null; then
    echo "Es positivo"
elif [ "$numero" -lt 0 ] 2>/dev/null; then
    echo "Es negativo"
elif [ "$numero" -eq 0 ] 2>/dev/null; then
    echo "Es cero"
else
    echo "Eso no parece un número entero"
fi

echo "-- comparación de strings --"
if [ "$USER" = "root" ]; then
    echo "Estás como root"
else
    echo "Estás como $USER (no root)"
fi

echo "-- comprobación de archivos --"
if [ -f "/etc/hostname" ]; then
    echo "/etc/hostname existe y es un archivo regular"
else
    echo "/etc/hostname no existe en este sistema"
fi
