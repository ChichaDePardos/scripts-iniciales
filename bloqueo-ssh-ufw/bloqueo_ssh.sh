#!/bin/bash
# Bloqueo y limpieza automática de IPs que realizan ataques SSH
# Autor: Steeng Braithwaite
# Licencia: MIT
# Repositorio: https://github.com/<TU_USUARIO>/bloqueo-ssh-ufw
#
# Funciones:
#   1. Detecta IPs con más de $THRESHOLD intentos fallidos y las bloquea con UFW
#   2. Limpia bloqueos con más de $DIAS_LIMPIEZA días de antigüedad
#
# Requisitos:
#   - UFW activo
#   - Acceso root
#   - Ubuntu/Debian con /var/log/auth.log disponible
#
# Uso:
#   Ejecutar manualmente o programar en cron:
#     sudo crontab -e
#     0 * * * * /usr/local/bin/bloqueo_ssh.sh
#
# Log:
#   Guarda registro en /var/log/ufw_bloqueos.log

set -euo pipefail

LOGFILE="/var/log/ufw_bloqueos.log"
THRESHOLD=5       # Intentos mínimos para bloquear
DIAS_LIMPIEZA=30  # Días para borrar bloqueos viejos

# Asegurar archivo de log
touch "$LOGFILE"
chmod 644 "$LOGFILE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando análisis..." >> "$LOGFILE"

# 1️⃣ Bloquear IPs con más intentos que el límite
grep -E "Failed password|Invalid user" /var/log/auth.log \
| awk '{print $(NF-3)}' \
| grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' \
| sort | uniq -c \
| awk -v limit="$THRESHOLD" '$1 > limit {print $1, $2}' \
| while read count ip; do
    if ! ufw status | grep -qw "$ip"; then
        ufw deny from "$ip" > /dev/null
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $count intentos - $ip BLOQUEADA" >> "$LOGFILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $count intentos - $ip YA BLOQUEADA" >> "$LOGFILE"
    fi
done

# 2️⃣ Limpieza de IPs bloqueadas hace más de DIAS_LIMPIEZA días
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando limpieza de IPs bloqueadas hace más de $DIAS_LIMPIEZA días..." >> "$LOGFILE"

OLD_IPS=$(grep "BLOQUEADA" "$LOGFILE" \
    | awk -v d="$DIAS_LIMPIEZA" -v now=$(date +%s) \
    '{ 
        cmd = "date -d \"" $1 " " $2 "\" +%s";
        cmd | getline ts;
        close(cmd);
        if ((now - ts) > (d*86400)) print $6;
    }' | sort -u)

for ip in $OLD_IPS; do
    if ufw status | grep -qw "$ip"; then
        ufw delete deny from "$ip" > /dev/null
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] IP $ip ELIMINADA por antigüedad" >> "$LOGFILE"
    fi
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Análisis y limpieza finalizados." >> "$LOGFILE"
echo "----------------------------------------" >> "$LOGFILE"
