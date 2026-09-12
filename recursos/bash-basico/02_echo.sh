#!/bin/bash
# echo: el comando más básico para imprimir texto en pantalla.

echo "Texto simple"

echo -n "Sin salto de línea al final... "
echo "(esta línea sigue en la misma fila gracias a -n arriba)"

echo -e "Con -e se interpretan escapes:\ttabulador\nsalto de línea"

NOMBRE="Alumno"
echo "Comillas dobles interpolan variables: hola, $NOMBRE"
echo 'Comillas simples NO interpolan: hola, $NOMBRE'
