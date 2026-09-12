#!/bin/bash
# printf: impresión con formato controlado, similar a C.
# Más predecible que echo cuando necesitas alinear columnas o tipos de dato específicos.

printf "Hola, %s. Tienes %d años.\n" "Alumno" 20

# %-10s = string alineado a la izquierda, ancho mínimo 10
# %5d   = entero alineado a la derecha, ancho mínimo 5
printf "%-10s|%5d\n" "Ana" 7
printf "%-10s|%5d\n" "Luis" 123

# A diferencia de echo, printf no agrega salto de línea automático: hay que incluir \n
printf "Sin salto automático"
printf " -> por eso esta línea continúa aquí.\n"
