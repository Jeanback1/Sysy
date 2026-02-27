#!/bin/bash

# Comprobar que se pasaron los argumentos necesarios
if [ "$#" -ne 2 ]; then
  echo -e "Uso: $0 <lista_de_comandos.txt> <archivo_salida.txt>"
  echo -e "Ejemplo: $0 comandos.txt resultados.txt"
  exit 1
fi

INPUT_FILE=$1
OUTPUT_FILE=$2

# Limpiar o crear el archivo de salida
>"$OUTPUT_FILE"

echo -e "\e[1;34m[*] Iniciando ejecución secuencial de ffuf...\e[0m"
echo "==================================================" >>"$OUTPUT_FILE"
echo "INICIO DE ESCANEO: $(date)" >>"$OUTPUT_FILE"
echo "==================================================" >>"$OUTPUT_FILE"

# Leer el archivo línea por línea
while IFS= read -r cmd || [ -n "$cmd" ]; do
  # Omitir líneas vacías o que empiecen con # (comentarios)
  if [[ -z "$cmd" || "$cmd" == \#* ]]; then
    continue
  fi

  echo -e "\e[1;33m[+] Ejecutando:\e[0m $cmd"

  # Formatear la separación en el archivo de texto
  echo -e "\n--------------------------------------------------" >>"$OUTPUT_FILE"
  echo "COMANDO: $cmd" >>"$OUTPUT_FILE"
  echo "--------------------------------------------------" >>"$OUTPUT_FILE"

  # Ejecutar el comando.
  # Usamos eval para interpretar correctamente la sintaxis del comando guardado.
  # 2>&1 redirige los errores al mismo archivo para que no te pierdas nada.
  eval "$cmd" >>"$OUTPUT_FILE" 2>&1

  echo -e "\e[1;32m[*] Terminado.\e[0m"
  echo "ESTADO: Finalizado" >>"$OUTPUT_FILE"

done <"$INPUT_FILE"

echo -e "\n\e[1;32m[✓] Todos los comandos han sido ejecutados. Revisa '$OUTPUT_FILE'\e[0m"
