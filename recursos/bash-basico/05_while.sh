#!/bin/bash
# while: repite un bloque mientras la condición sea verdadera.

echo "-- while con contador --"
contador=1
while [ $contador -le 5 ]; do
    echo "Contador: $contador"
    contador=$((contador + 1))
done

echo "-- while leyendo línea por línea (patrón muy usado con archivos) --"
echo -e "linea1\nlinea2\nlinea3" > /tmp/ejemplo_while.txt
while read -r linea; do
    echo "Leí: $linea"
done < /tmp/ejemplo_while.txt
rm -f /tmp/ejemplo_while.txt
