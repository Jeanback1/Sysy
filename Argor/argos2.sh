#!/bin/bash

# --- CONFIGURACIÓN ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RESET='\033[0m'

# --- CONFIGURACIÓN DE ALERTAS (EDITA ESTO) ---
# Si usas Discord, pon tu Webhook URL aquí:
DISCORD_WEBHOOK_URL=""

# 1. Verificar Argumentos
if [ -z "$1" ]; then
  echo -e "${RED}[!] Uso: ./argos.sh <scope.txt>${RESET}"
  exit 1
fi

SCOPE_FILE="$1"
PROGRAM_NAME=$(basename "$SCOPE_FILE") # Extrae el nombre del archivo para el mensaje

# Definir archivos temporales y finales
SUBS_BRUTOS="temp_subs_raw.txt"
VIVOS_BRUTOS="temp_live_raw.txt"
LISTA_DEFINITIVA="master_live.txt"
NUEVOS_HALLAZGOS="temp_new_only.txt" # Archivo para guardar SOLO lo nuevo de hoy

# Limpiar temporales antiguos
rm -f "$SUBS_BRUTOS" "$VIVOS_BRUTOS" "$NUEVOS_HALLAZGOS"
touch "$SUBS_BRUTOS"

echo -e "${BLUE}[+] Iniciando Argos sobre: $PROGRAM_NAME${RESET}"

# --- PASO 1: RECOLECCIÓN (Subfinder + Assetfinder) ---
echo -e "${BLUE}[1] Recolectando subdominios...${RESET}"

while IFS= read -r domain || [ -n "$domain" ]; do
  if [ -z "$domain" ]; then continue; fi
  # Ejecutamos y guardamos (append >>) en el txt bruto
  subfinder -d "$domain" -silent >>"$SUBS_BRUTOS"
  assetfinder --subs-only "$domain" >>"$SUBS_BRUTOS"
done <"$SCOPE_FILE"

echo -e "${GREEN}[OK] Recolección terminada.${RESET}"

# --- PASO 2: LIMPIEZA Y HTTPX ---
echo -e "${BLUE}[2] Verificando cuáles están vivos con httpx-pd...${RESET}"

if [ -s "$SUBS_BRUTOS" ]; then
  # Tomamos el txt bruto -> sort -> httpx -> txt de vivos
  cat "$SUBS_BRUTOS" | sort -u | httpx -silent >"$VIVOS_BRUTOS"
else
  echo -e "${RED}[!] No se encontraron subdominios en la fase 1. Abortando.${RESET}"
  exit 1
fi

# --- PASO 3: UNIFICACIÓN Y DETECCIÓN DE NOVEDADES ---
echo -e "${BLUE}[3] Filtrando novedades con anew...${RESET}"

if [ -s "$VIVOS_BRUTOS" ]; then
  # AQUÍ ESTÁ LA MAGIA:
  # Usamos anew para añadir a la lista maestra, pero guardamos la salida (lo nuevo) en un archivo aparte.
  cat "$VIVOS_BRUTOS" | anew "$LISTA_DEFINITIVA" >"$NUEVOS_HALLAZGOS"
else
  echo -e "${RED}[!] Httpx no encontró dominios vivos.${RESET}"
fi

# --- PASO 4: LÓGICA DE NOTIFICACIÓN ---

if [ -s "$NUEVOS_HALLAZGOS" ]; then
  # Contamos cuántas líneas tiene el archivo de nuevos hallazgos
  NUMERO=$(wc -l <"$NUEVOS_HALLAZGOS")

  # Preparamos el mensaje
  MENSAJE="[ARGOS] Se encontraron $NUMERO nuevos subdominios en $PROGRAM_NAME"

  echo -e "${GREEN}[!] $MENSAJE${RESET}"
  echo -e "${BLUE}[i] Lista actualizada en: $LISTA_DEFINITIVA${RESET}"

  # --- ZONA DE NOTIFICACIONES ---

  # OPCIÓN A: Notificación de Escritorio (Arch Linux / Gnome / KDE / Hyprland)
  # Requiere tener 'libnotify' instalado
  if command -v notify-send &>/dev/null; then
    notify-send "Argos Alert" "$MENSAJE"
  fi

  # OPCIÓN B: Discord Webhook (Si configuraste la URL arriba)
  if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    # Creamos un JSON simple para Discord
    # Enviamos el mensaje y, si son pocos (menos de 10), enviamos los dominios también.
    if [ "$NUMERO" -lt 10 ]; then
      CONTENT="$MENSAJE:\n\`\`\`\n$(cat $NUEVOS_HALLAZGOS)\n\`\`\`"
    else
      CONTENT="$MENSAJE\n(Revisar servidor para lista completa)"
    fi

    curl -H "Content-Type: application/json" \
      -d "{\"content\": \"$CONTENT\"}" \
      "$DISCORD_WEBHOOK_URL" -s >/dev/null
  fi

else
  echo -e "${RED}[~] No hay novedades. El scope sigue igual.${RESET}"
fi

# --- LIMPIEZA FINAL ---
rm -f "$SUBS_BRUTOS" "$VIVOS_BRUTOS" "$NUEVOS_HALLAZGOS"
