#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 07-run-soporte-blobs.sh
# Autor       : erick
# Fecha        : 2026-06-07
# Descripcion  : Otorga CREATE ANY DIRECTORY a ilap_bdd y compila el soporte
#                 BLOB en los 4 nodos de la Parte 4.
# ---------------------------------------------------------------------------
set -euo pipefail

C1="c1-bdd-proy-eam"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_MAIN="${SCRIPT_DIR}/s-07-ilap-main-soporte-blobs.sql"
LOG_DIR="${PARTE4_LOG_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)/logs}"
LOG_STAMP="${PARTE4_LOG_STAMP:-$(date +%Y%m%d-%H%M%S)}"
LOG_FILE="${LOG_DIR}/07-run-soporte-blobs-${LOG_STAMP}.log"

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYA='\033[0;36m'
BLU='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'

log()  { echo -e "  ${CYA}[INFO]${RST}  $*"; }
ok()   { echo -e "  ${GRN}[OK]${RST}    $*"; }
die()  { echo -e "  ${RED}[ERROR]${RST} $*" >&2; exit 1; }
step() { echo ""; echo -e "${BOLD}${BLU}▶ $*${RST}"; }

mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   PARTE 4 · Fase 1 · Soporte BLOB iLap               ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""
log "Log de soporte BLOB: ${LOG_FILE}"

if [ $# -ge 1 ]; then
    SYS_PASS_VALUE="$1"
    log "Password de SYS recibido como argumento de linea de comandos."
elif [ -n "${SYS_PASS:-}" ]; then
    SYS_PASS_VALUE="${SYS_PASS}"
    log "Password de SYS recibido mediante la variable de entorno SYS_PASS."
else
    echo -e "  ${YEL}[INPUT]${RST}  Se requiere el password de SYS para otorgar CREATE ANY DIRECTORY."
    read -rsp "           Password de SYS: " SYS_PASS_VALUE
    echo ""
fi

[ -z "${SYS_PASS_VALUE}" ] && die "El password de SYS no puede estar vacio."

[ "$(docker inspect "${C1}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
    || die "Contenedor ${C1} no esta corriendo. Ejecuta la infraestructura primero."

step "Otorgando CREATE ANY DIRECTORY al usuario ilap_bdd"
set +e
timeout 180 docker exec -i "${C1}" su - oracle -c "sqlplus /nolog" <<EOF
whenever sqlerror exit failure

prompt ============================================
prompt Grant CREATE ANY DIRECTORY en eambdd_s1
prompt ============================================
connect sys/${SYS_PASS_VALUE}@eambdd_s1 as sysdba
grant create any directory to ilap_bdd;

prompt ============================================
prompt Grant CREATE ANY DIRECTORY en eambdd_s2
prompt ============================================
connect sys/${SYS_PASS_VALUE}@eambdd_s2 as sysdba
grant create any directory to ilap_bdd;

prompt ============================================
prompt Grant CREATE ANY DIRECTORY en eambdd_s3
prompt ============================================
connect sys/${SYS_PASS_VALUE}@eambdd_s3 as sysdba
grant create any directory to ilap_bdd;

prompt ============================================
prompt Grant CREATE ANY DIRECTORY en eambdd_s4
prompt ============================================
connect sys/${SYS_PASS_VALUE}@eambdd_s4 as sysdba
grant create any directory to ilap_bdd;

disconnect
exit;
EOF
rc=$?
set -e

[ ${rc} -eq 124 ] && die "Timeout (180s): el grant CREATE ANY DIRECTORY no termino."
[ ${rc} -ne 0 ] && die "Fallo al otorgar CREATE ANY DIRECTORY (codigo: ${rc})."

step "Compilando directorios y funcion fx_carga_blob"
set +e
timeout 240 docker exec -i "${C1}" su - oracle -c "sqlplus /nolog" <<EOF
whenever sqlerror exit failure
@${SQL_MAIN}
exit;
EOF
rc=$?
set -e

[ ${rc} -eq 124 ] && die "Timeout (240s): la configuracion BLOB no termino."
[ ${rc} -ne 0 ] && die "Fallo al crear el soporte BLOB (codigo: ${rc})."

ok "Soporte BLOB configurado correctamente en las 4 PDBs."