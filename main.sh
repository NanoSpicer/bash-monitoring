#!/bin/bash
clear
# Constantes de paths
work_load="ubuntu-16.04.2-desktop-amd64.iso"
fichero_resultados="resultados.res"
# Array que almacena el nombre de todos los subdirectorios
array_dirs=("HDD-HDD/" "PEN-HDD/" "LAN-HDD/" "RED-HDD/" "GDRIVE-HDD/");

# Comandos correspondientes a lo que especifica el enunciado.

# 1º De un directorio a otro
hdd="cp $work_load ${array_dirs[0]}"

# 2º De un pendrive al subdirectorio actual
dir_pen="/media/mich/MICH/$work_load"
pen="cp $dir_pen ${array_dirs[1]}"

# 3º Desde un ordenador conectado a la LAN
ip_server_lan="192.168.1.X"
dir_lan="$ip_server_lan:/$work_load"
lan="wget -O $work_load $dir_lan ${array_dirs[2]}"

# 4º Desde el servidor de la assignatura de la UIB
user="43235792R"
ip_server_uib="130.206.30.21"
pass="mroman"
permisos="sshpass -p '$pass'"

dir_red="$user@$ip_server_uib:/home/public/$work_load"
red="$permisos scp $dir_red ${array_dirs[3]}"

# 5º Desde dropbox | aka drive
dir_drive="https://drive.google.com/uc?export=download&id=0By8wY1CaIKwFUDltdDJRRW4wSTg"
g_drive="wget -O $work_load $dir_drive ${array_dirs[4]}"

# Array que almacena los comandos corresponientes a cada uno de los subdirectorios.
array_comandos=("$hdd" "$pen" "$lan" "$red" "$g_drive");


for (( i = 0; i < 5; i++ )); do

    # Si hay restos de una monitorizacion previa, los eliminamos
    if [[ -d "${array_dirs[$i]}" ]]; then
        rm -rf ${array_dirs[$i]}
    fi
    # Crear los subdirectorios
    $(mkdir ${array_dirs[$i]})
    # Lanzar la monitorizacion
    ./monitorizar.sh "${array_comandos[$i]}" ${array_dirs[$i]}

done

clear

for path in ${array_dirs[@]}; do
	./resultados.sh $path $fichero_resultados
done


clear

echo "Resultados del proceso de monitorizacion:"
echo
for path in ${array_dirs[@]}; do
	cat $path$fichero_resultados
done

echo "Final del programa!!"
