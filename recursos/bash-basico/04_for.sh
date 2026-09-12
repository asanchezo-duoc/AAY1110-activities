#!/bin/bash
# for: recorrer una lista de valores, un rango numérico, o la salida de un comando.

echo "-- for sobre una lista de palabras --"
for color in rojo verde azul; do
    echo "Color: $color"
done

echo "-- for estilo C, con rango numérico --"
for ((i = 1; i <= 5; i++)); do
    echo "Iteración $i"
done

echo "-- for sobre archivos que calzan un patrón --"
for archivo in *.sh; do
    echo "Script encontrado: $archivo"
done
