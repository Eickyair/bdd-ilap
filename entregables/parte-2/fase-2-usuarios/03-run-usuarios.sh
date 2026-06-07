#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 03-run-usuarios.sh  — IDEMPOTENTE
# @Autor:          Erick Yair Aguilar Martínez
# @Fecha creación: 04/06/2026
# @Descripción:    Crea el usuario ilap_bdd en los 4 nodos ejecutando
#                  s-01-ilap-main-usuario.sql dentro del contenedor c1.
#                  El script SQL usa DROP USER IF EXISTS, por lo que es
#                  seguro ejecutarlo múltiples veces.
#
# Prerequisito: bash ../fase-1-infraestructura/02-oracle-config.sh
# Uso: bash 03-run-usuarios.sh [sys_password]
#      Si no se proporciona el password, se solicitará de forma interactiva.
# ---------------------------------------------------------------------------
set -euo pipefail

C1="c1-bdd-proy-eam"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SQL="${SCRIPT_DIR}/s-01-ilap-main-usuario.sql"

log()  { echo "[INFO]  $*"; }
ok()   { echo "[OK]    $*"; }
die()  { echo "[ERROR] $*" >&2; exit 1; }

# Obtener password de sys
if [ $# -ge 1 ]; then
    SYS_PASS="$1"
else
    read -rsp "Proporcione el password de sys: " SYS_PASS
    echo ""
fi

[ -z "${SYS_PASS}" ] && die "Password de sys no puede estar vacío."

[ "$(docker inspect "${C1}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
    || die "Contenedor ${C1} no está corriendo."

log "Ejecutando s-01-ilap-main-usuario.sql en los 4 nodos..."

# Construir el script con el password embebido para ejecución no interactiva
docker exec -i "${C1}" su - oracle -c "sqlplus /nolog" <<EOF
whenever sqlerror exit failure
set serveroutput on

prompt === Creando usuario en eambdd_s1 ===
connect sys/${SYS_PASS}@eambdd_s1 as sysdba
@${SCRIPT_DIR}/s-01-ilap-usuario.sql

prompt === Creando usuario en eambdd_s2 ===
connect sys/${SYS_PASS}@eambdd_s2 as sysdba
@${SCRIPT_DIR}/s-01-ilap-usuario.sql

prompt === Creando usuario en eambdd_s3 ===
connect sys/${SYS_PASS}@eambdd_s3 as sysdba
@${SCRIPT_DIR}/s-01-ilap-usuario.sql

prompt === Creando usuario en eambdd_s4 ===
connect sys/${SYS_PASS}@eambdd_s4 as sysdba
@${SCRIPT_DIR}/s-01-ilap-usuario.sql

prompt Listo!
disconnect
exit;
EOF

ok "Usuario ilap_bdd creado en los 4 nodos."

echo ""
echo "=================================================="
echo " Fase 2 completada: usuario ilap_bdd disponible."
echo " Próximo paso: bash ../fase-3-ligas/04-run-ligas.sh"
echo "=================================================="
