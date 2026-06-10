#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 08-run-triggers.sh
# Autor       : erick
# Fecha        : 2026-06-07
# Descripción  : Otorga el privilegio CREATE TRIGGER y compila los triggers
#                  INSTEAD OF de la Parte 3 en las 4 PDBs.
# ---------------------------------------------------------------------------
set -euo pipefail

C1="c1-bdd-proy-eam"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_GRANT="${SCRIPT_DIR}/s-06-ilap-grant-create-trigger.sql"
SQL_MAIN="${SCRIPT_DIR}/s-06-ilap-main-triggers.sql"
source "${SCRIPT_DIR}/../../utils.sh"

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

echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   PARTE 3 · Fase 3 · Triggers INSTEAD OF iLap        ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

if [ $# -ge 1 ]; then
    SYS_PASS_VALUE="$1"
    log "Password de SYS recibido como argumento de línea de comandos."
elif [ -n "${SYS_PASS:-}" ]; then
    SYS_PASS_VALUE="${SYS_PASS}"
    log "Password de SYS recibido mediante la variable de entorno SYS_PASS."
else
    echo -e "  ${YEL}[INPUT]${RST}  Se requiere el password de SYS para otorgar CREATE TRIGGER en los 4 nodos."
    read -rsp "           Password de SYS: " SYS_PASS_VALUE
    echo ""
fi

[ -z "${SYS_PASS_VALUE}" ] && die "El password de SYS no puede estar vacío."

[ "$(docker inspect "${C1}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
    || die "Contenedor ${C1} no está corriendo. Ejecuta las fases anteriores primero."

step "Otorgando CREATE TRIGGER al usuario ilap_bdd"
log "Referencia documental del grant: ${SQL_GRANT}"
log "Ejecutando grants en eambdd_s1, eambdd_s2, eambdd_s3 y eambdd_s4."
echo -e "  ${DIM}Timeout del grant: 180s${RST}"

set +e
timeout 180 "${DOCKER_SQLPLUS}" "${C1}" /nolog <<EOF
whenever sqlerror exit failure

prompt ============================================
prompt Otorgando CREATE TRIGGER en eambdd_s1
prompt ============================================
connect sys/${SYS_PASS_VALUE}@eambdd_s1 as sysdba
grant create trigger to ilap_bdd;

prompt ============================================
prompt Otorgando CREATE TRIGGER en eambdd_s2
prompt ============================================
connect sys/${SYS_PASS_VALUE}@eambdd_s2 as sysdba
grant create trigger to ilap_bdd;

prompt ============================================
prompt Otorgando CREATE TRIGGER en eambdd_s3
prompt ============================================
connect sys/${SYS_PASS_VALUE}@eambdd_s3 as sysdba
grant create trigger to ilap_bdd;

prompt ============================================
prompt Otorgando CREATE TRIGGER en eambdd_s4
prompt ============================================
connect sys/${SYS_PASS_VALUE}@eambdd_s4 as sysdba
grant create trigger to ilap_bdd;

prompt Listo!
disconnect
exit;
EOF
rc=$?
set -e

[ ${rc} -eq 124 ] && die "Timeout (180s): el grant CREATE TRIGGER no terminó."
[ ${rc} -ne 0 ] && die "Fallo al otorgar CREATE TRIGGER (código: ${rc}). Revisa la salida anterior."

step "Compilando triggers INSTEAD OF en las 4 PDBs"
log "Script SQL: s-06-ilap-main-triggers.sql"
set +e
timeout 240 "${DOCKER_SQLPLUS}" "${C1}" /nolog <<EOF
whenever sqlerror exit failure
@${SQL_MAIN}
exit;
EOF
rc=$?
set -e

[ ${rc} -eq 124 ] && die "Timeout (240s): la compilación de triggers no terminó."
[ ${rc} -ne 0 ] && die "Fallo al compilar triggers (código: ${rc}). Revisa la salida anterior."

ok "Triggers creados correctamente en las 4 PDBs."

echo ""
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "${GRN}${BOLD}  Fase 3 completada — triggers listos${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "  ${DIM}Siguiente paso natural: ejecutar 09-validate-parte-3.sh${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo ""
