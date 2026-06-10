#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 05-run-ddl.sh  — IDEMPOTENTE
# Autor       : erick
# Fecha        : 2026-06-04
# Descripción  : Crea los fragmentos locales en los 4 nodos ejecutando
#                  s-03-ilap-main-ddl.sql. Cada DDL individual inicia con
#                  DROP TABLE IF EXISTS en orden inverso, lo que garantiza
#                  idempotencia total.
#
# Prerequisito: bash ../fase-3-ligas/04-run-ligas.sh
# Uso: bash 05-run-ddl.sh
# ---------------------------------------------------------------------------
set -euo pipefail

C1="c1-bdd-proy-eam"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL="${SCRIPT_DIR}/s-03-ilap-main-ddl.sql"
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
echo -e "${BOLD}${BLU}║   FASE 4 · Creación de fragmentos DDL — BDD iLap     ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

[ "$(docker inspect "${C1}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
    || die "Contenedor ${C1} no está corriendo. Ejecuta las fases anteriores primero."

step "Creando esquema distribuido iLap en los 4 nodos"
log "Script SQL : s-03-ilap-main-ddl.sql (orquestador)"
log "Conecta como ilap_bdd a cada nodo y ejecuta el DDL local:"
log "  s-03-ilap-eam-s1-ddl.sql → eambdd_s1: 12 tablas (fragmentos Norte)"
log "  s-03-ilap-eam-s2-ddl.sql → eambdd_s2: 11 tablas (fragmentos Este)"
log "  s-03-ilap-eam-s3-ddl.sql → eambdd_s3: 11 tablas (fragmentos Oeste)"
log "  s-03-ilap-eam-s4-ddl.sql → eambdd_s4: 11 tablas (fragmentos Sur)"
log "Idempotente: cada DDL inicia con DROP TABLE IF EXISTS en orden inverso."
wait_msg "Ejecutando SQL*Plus vía ${C1} (timeout: 300s — 4 nodos, ~45 tablas en total)..."

_t0=$(date +%s)
set +e
timeout 300 "${DOCKER_SQLPLUS}" "${C1}" /nolog <<EOF
whenever sqlerror exit failure
@${SQL}
exit;
EOF
_rc=$?
set -e
_elapsed=$(( $(date +%s) - _t0 ))

[ $_rc -eq 124 ] && die "Timeout (300s): s-03-ilap-main-ddl.sql no completó. Puede haber un lock en algún fragmento o un fallo de conexión vía database link."
[ $_rc -ne 0 ]   && die "Error en la creación del esquema distribuido (código: ${_rc}). Revisa la salida anterior para identificar qué tabla o nodo falló."

ok "Esquema distribuido creado exitosamente en los 4 nodos (${_elapsed}s)."

echo ""
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "${GRN}${BOLD}  FASE 4 completada — esquema distribuido listo${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "  Tablas de datos    : SUCURSAL, LAPTOP, LAPTOP_INVENTARIO,"
echo -e "                       HISTORICO_STATUS_LAPTOP, SERVICIO_LAPTOP"
echo -e "  Catálogos replicados: TIPO_PROCESADOR, TIPO_TARJETA_VIDEO,"
echo -e "                        TIPO_ALMACENAMIENTO, TIPO_MONITOR"
echo -e "  ${DIM}Próximo paso: bash validate-parte-2.sh${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo ""
