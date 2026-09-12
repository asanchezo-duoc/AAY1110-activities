#!/bin/bash
#script tablas de multiplicar
#se pide ingresar 2 datos, el numero para obtener su tabla y la cantidad de terminos
clear
echo -e "\tTablas\n"

echo -e "ingresar numero -> \c"
read num
echo -e "cuantos terminos calculamos ? -> \c"
read terms

let contador=1
echo -e "\nTabla del $num\n"
while [ $contador -le $terms ];do
    let resultado=$num*$contador
    echo $num x $contador = $resultado
    let contador=$contador+1
done
echo -e "\nTarea realizada dignamente"
