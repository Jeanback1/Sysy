#!/bin/bash

# Comprobamos que se hayan pasado suficientes argumentos
if [ "$#" -lt 3 ]; then
  echo "[-] Error de sintaxis."
  echo "    Uso: encolar -f <archivo.txt> <comando a guardar>"
  exit 1
fi

# Buscamos el flag -f para identificar el archivo
if [ "$1" == "-f" ]; then
  archivo="$2"

  # Usamos 'shift 2' para borrar '-f' y 'archivo.txt' de la lista de argumentos
  shift 2

  # Todo lo que queda en la lista de argumentos ($@) es tu comando de recon
  comando="$@"

  # Guardamos el comando en el archivo
  echo "$comando" >>"$archivo"

  echo "[+] Encolado en $archivo: $comando"
else
  echo "[-] Debes especificar un archivo de salida con -f"
fi
