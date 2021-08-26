#!/bin/bash

# Explicación de los argumentos
# $1 = comando
# $2 = directorio de trabajo del script para los diferentes comandos

# Se concatenaran identificadores [nivel_concurrencia][id_proceso]
fitxers_copia="$2archivo_copia";
control_procesos="control_procesos.log"
cpu_vsz_file="aux_cpu_vsz"   #"$2aux_cpu_vsz"

cpu_file="$2cpu"
vsz_file="$2vsz"
hdd_file="$2hdd"
net_file="$2net"
time_file="$2time"



intervalo_muestreo=5; #segundos

# Ejecutamos el comando en segundo plano

# Vamos a monitorizar 4 experimentos:
    # 1 nivel de conc, 2 nvl de cnc, etc...

for (( i = 0; i < 4; i++ )); do
    # Lanzamos el número de procesos correspondientes
    pids=""
    for (( j = $i; j >= 0; j-- )); do
        # Lanzamos el proceso.
        # El output del time se envia por el stderr.
        #eval "time { $1$fitxers_copia$i$j & } 2>> $time_file$i$j"
        bytes_red_first=$(ifconfig | tail -n 2 | head -n 1 | awk '{print $2}' | cut -c 4-)
        #eval "time { $1$fitxers_copia$i$j & } 2>> $time_file$i$j"
        eval "{ TIMEFORMAT='%E %U %S';time $1$fitxers_copia$i$j & } 2>> $time_file$i"

        # REAL USER SYSTEM. TIME

        # La concatenación al proceso pasado por parametro $1 nos provocarà
        # Tendrà los siguientes efectos:
        #                   $1 = cp archivo.iso path/
        #     $1$fitxers_copia = cp archivo.iso path/archivo_copia
        # $1$fitxers_copia$i$j =
        # cp archivo.iso path/archivo_copia[nivel_concurrencia][nº_proceso]
        #                   $1  $fitx_copia                  $i          $j
        # nº proceso corresponde al orden en el cual se ha lanzado el proceso

        # Cojemos el PID del comando a ejecutar que será el hijo del "time"
        pid_actual=$(pgrep -P $!)
        if [[ $pids = "" ]]; then
            pids=$pid_actual
        else
            pids="$pids $pid_actual"
        fi

    done
    # Monitorizamos los procesos mientras no hayan acabado
    n_procesos=$(($i+1));
    linies="0";
    echo "INICIANDO MONITORIZACION"
    while [[ $linies -ne $n_procesos  ]]; do

        # MUESTREO DE EL CPU Y VSZ
        #echo $pids
        #echo $cpu_vsz_file
        eval "ps -p  \"$pids\" -o %cpu,vsz > $cpu_vsz_file"
        linies_fitxer=$(wc -l $cpu_vsz_file | awk '{print $1}')
        # Para quitarnos la cabecera (%CPU VSZ)
        linies_fitxer=$(($linies_fitxer - 1))
        # Quitamos la cabecera

        #eval "cat $cpu_vsz_file | tail -n $linies_fitxer > $cpu_vsz_file"
        AUXILIAR=$(cat $cpu_vsz_file | tail -n $linies_fitxer)
        printf "$AUXILIAR\n" > $cpu_vsz_file
        cat $cpu_vsz_file
        # Sumamos las linias del %CPU         marcamos el nivel de concurrencia
        cat $cpu_vsz_file | awk '{s+=$1} END {print s}'  >> $cpu_file$i
        # Sumamos las linias del VSZ          marcamos el nivel de concurrencia
        cat $cpu_vsz_file | awk '{s+=$2} END {print s}' >> $vsz_file$i

        # Aqui van los rendimientos de HDD
        # col 1 = read KB/s # col 2 = read KB/s
        iostat -dx sda | tail -n 2 | head -n 1 | awk '{print $6" "$7}' >> $hdd_file$i

        # Esperamos para tomar la siguiente muestra
        sleep $intervalo_muestreo

        # Rendimiento de red
        bytes_red_second=$(ifconfig | tail -n 2 | head -n 1 | awk '{print $2}' | cut -c 4-)
        bytes_descargados=$(($bytes_red_second-$bytes_red_first));
        bytes_seconds=$(bc -l <<< "scale=3; $bytes_descargados/$intervalo_muestreo")
        kbytes_seconds=$(bc -l <<< "scale=2; $bytes_descargados/1024")
        echo "$kbytes_seconds" >> $net_file$i
        bytes_red_first=$bytes_red_second;

        # Los tiempos de CPU seran adquiridos posteriormente con el uso del time

        # Verificamos la conticion de salida del bucle
        kill -0 $pids 2> $control_procesos
        linies=$(wc -l $control_procesos | awk '{print $1}')
    done

    # Borramos los restos.
    rm $control_procesos
    rm $cpu_vsz_file
    # Borrar los .iso copiados
    eval "rm $fitxers_copia*"
done
# CORREGIR OUTPUT DEL TIME. NO EL DONA BE!
# REVISAR LA ELIMINACIÓ DELS FITXERS!!!
