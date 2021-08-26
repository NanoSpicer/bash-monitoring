#!/bin/bash

echo "Inicio Prueba"
#NOMBRE DEL DIRECTORIO ACTUAL
directorio=$1
#DIRECCIONES DE LOS FICHEROS
file_cpu="$1cpu"
file_vsz="$1vsz"
file_time="$1time"
file_net="$1net"
file_hdd="$1hdd"
#NOMBRE DEL FICHERO DONDE SE GUARDAN LOS RESULTADOS
resultados=$2
#Dado un fichero y un numero indicando la columna te calcula la media
#aritmetica de los valores de esa columna
function media_aritmetica (){
	suma_dividendo=0
	media=0
	numero_elementos=$(wc -l $1 | awk '{ print $1 }')
	while IFS='' read -r line || [[ -n "$line" ]]; do
			comando="echo \"$line\" | awk '{ print \$$2 }'"
			#echo "Comando: "$comando
   		eval elemento=\$\($comando\)
   		#echo "Elemento: "$elemento
   		suma_dividendo=$( bc -l <<< "scale=3;$suma_dividendo + $elemento" )
	done < "$1"
	media=$( bc -l <<< "scale=3;$suma_dividendo / $numero_elementos" )
}
#Dado un fichero y un numero indicando la columna te calcula la media
#armonica de los valores de esa columna
function media_armonica (){
	suma_divisor=0
	media=0
	numero_elementos=$(wc -l $1 | awk '{ print $1 }')
	while IFS='' read -r line || [[ -n "$line" ]]; do
			comando="echo \"$line\" | awk '{ print \$$2 }'"
			#echo "Comando: "$comando
   		eval elemento=\$\($comando\)
   		#echo "Elemento: "$elemento
   		suma_divisor=$( bc -l <<< "scale=3;$suma_divisor + 1/$elemento" )
	done < "$1"
	media=$( bc -l <<< "scale=3; $numero_elementos/$suma_divisor" )
}
clear

	echo "------------------------------------------  $directorio  ----------------------------------------------" >> $resultados
	echo "CONC |  CPU      RAM      Escritura kB/s   Lectur kB/s   Descarga kB/s   T_Total   T_Usuario   T_CPU" >> $resultados
	echo "-------------------------------------------------------------------------------------------------------" >> $resultados
concurrencia=1
medias=("0" "0" "0" "0" "0" "0" "0" "0")
#POR CADA FICHERO CON DIFERENTE CONCURRENCIA
for i in $file_cpu*; do
	echo "$concurrencia -------------------------------------------------------------------------------------------------" >> $resultados
	#MEDIA CPU
	media_aritmetica $file_cpu$((concurrencia - 1)) 1
	medias[0]=$media
	#MEDIA RAM
	media_aritmetica $file_vsz$((concurrencia - 1)) 1
	medias[1]=$media
	#MEDIA ESCRITURAS
	media_armonica $file_hdd$((concurrencia - 1)) 1
	media[2]=$media
	#MEDIA LECTURAS
	media_armonica$file_hdd$((concurrencia - 1)) 2
	media[3]=$media
	#MEDIA RED
	media_armonica $file_net$((concurrencia - 1)) 1
	medias[4]=$media
	#MEDIA TIEMPO TOTAL
	media_aritmetica $file_time$((concurrencia - 1)) 1
	medias[5]=$media
	#MEDIA TIEMPO USUARIO
	media_aritmetica $file_time$((concurrencia - 1)) 2
	medias[6]=$media
	#MEDIA TIEMPO SISTEMA
	media_aritmetica $file_time$((concurrencia - 1)) 3
	medias[7]=$media
	#IMPRIMIMOS RESULTADOS
	echo "      ${medias[0]}   ${medias[1]}   ${medias[2]}   ${medias[3]}   ${medias[4]}   ${medias[5]}   ${medias[6]}   ${medias[7]}">> $resultados
	#AUMENTAMOS EL NUMERO DE CONCURRENCIA ACTUAL
	concurrencia=$(($concurrencia + 1))
done
echo "Final de la prueba"
