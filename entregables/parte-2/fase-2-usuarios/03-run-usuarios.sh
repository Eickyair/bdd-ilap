#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 03-run-usuarios.sh  — IDEMPOTENTE
# Autor       : erick
# Fecha        : 2026-06-04
# Descripción  : Crea el usuario ilap_bdd en los 4 nodos ejecutando
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
source "${SCRIPT_DIR}/../../utils.sh"

# ----------------------------------------------------------------- colores
RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYA='\033[0;36m'
BLU='\033[0;34m'
MAG='\033[1;35m'
BOLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'

log()      { echo -e "  ${CYA}[INFO]${RST}  $*"; }
ok()       { echo -e "  ${GRN}[OK]${RST}    $*"; }
die()      { echo -e "  ${RED}[ERROR]${RST} $*" >&2; exit 1; }
step()     { echo ""; echo -e "${BOLD}${BLU}▶ $*${RST}"; }
wait_msg() { echo -e "  ${MAG}[WAIT]${RST}  $*"; }

# ------------------------------------------------------------------ banner
echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   FASE 2 · Creación de usuario ilap_bdd — BDD iLap   ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

# Obtener password de sys
if [ $# -ge 1 ]; then
    SYS_PASS="$1"
    log "Password de sys recibido como argumento de línea de comandos."
else
    echo -e "  ${YEL}[INPUT]${RST}  Se requiere el password de SYS para conectarse a los 4 nodos como SYSDBA."
    read -rsp "           Password de sys: " SYS_PASS
    echo ""
fi

[ -z "${SYS_PASS}" ] && die "El password de sys no puede estar vacío."

[ "$(docker inspect "${C1}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
    || die "Contenedor ${C1} no está corriendo. Ejecuta 01-docker-up.sh y 02-oracle-config.sh primero."

step "Creando usuario ilap_bdd en los 4 nodos"
log "Script SQL: s-01-ilap-usuario.sql (DROP USER IF EXISTS + CREATE USER + 7 privilegios mínimos)"
log "Secuencia : eambdd_s1 (Norte) → eambdd_s2 (Este) → eambdd_s3 (Oeste) → eambdd_s4 (Sur)"
wait_msg "Ejecutando SQL*Plus vía ${C1} (timeout: 180s)..."

_t0=$(date +%s)
set +e
timeout 180 "${DOCKER_SQLPLUS}" "${C1}" /nolog <<EOF
whenever sqlerror exit failure
set serveroutput on

prompt === [1/4] Conectando a eambdd_s1 (Norte · Procesamiento) ===
connect sys/${SYS_PASS}@eambdd_s1 as sysdba
@${SCRIPT_DIR}/s-01-ilap-usuario.sql

prompt === [2/4] Conectando a eambdd_s2 (Este · Almacenamiento) ===
connect sys/${SYS_PASS}@eambdd_s2 as sysdba
@${SCRIPT_DIR}/s-01-ilap-usuario.sql

prompt === [3/4] Conectando a eambdd_s3 (Oeste · Seguridad) ===
connect sys/${SYS_PASS}@eambdd_s3 as sysdba
@${SCRIPT_DIR}/s-01-ilap-usuario.sql

prompt === [4/4] Conectando a eambdd_s4 (Sur · Imagenes) ===
connect sys/${SYS_PASS}@eambdd_s4 as sysdba
@${SCRIPT_DIR}/s-01-ilap-usuario.sql

prompt Listo!
disconnect
exit;
EOF
_rc=$?
set -e
_elapsed=$(( $(date +%s) - _t0 ))

[ $_rc -eq 124 ] && die "Timeout (180s): SQL*Plus no completó en los 4 nodos. Verifica que Oracle esté disponible (02-oracle-config.sh)."
[ $_rc -ne 0 ]   && die "Error en SQL*Plus al crear el usuario ilap_bdd (código: ${_rc}). Revisa la salida anterior."

ok "Usuario ilap_bdd creado exitosamente en los 4 nodos (${_elapsed}s)."

echo ""
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "${GRN}${BOLD}  FASE 2 completada — usuario ilap_bdd disponible${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "  Nodos actualizados: eambdd_s1  eambdd_s2  eambdd_s3  eambdd_s4"
echo -e "  ${DIM}Próximo paso: bash ../fase-3-ligas/04-run-ligas.sh${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo ""
