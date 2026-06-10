#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 07-run-vistas.sh
# Autor       : erick
# Fecha        : 2026-06-07
# Descripción  : Crea las vistas globales de la Parte 3, incluyendo soporte
#                  temporal y funciones para columnas BLOB.
# ---------------------------------------------------------------------------
set -euo pipefail

C1="c1-bdd-proy-eam"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL="${SCRIPT_DIR}/s-05-ilap-main-vistas.sql"
source "${SCRIPT_DIR}/../../utils.sh"

RED='\033[0;31m'
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
echo -e "${BOLD}${BLU}║   PARTE 3 · Fase 2 · Vistas globales iLap            ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

[ "$(docker inspect "${C1}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
    || die "Contenedor ${C1} no está corriendo. Ejecuta las fases anteriores primero."

step "Creando vistas globales y soporte BLOB en los 4 nodos"
log "Script SQL: s-05-ilap-main-vistas.sql"
log "Compila vistas comunes, tablas temporales, funciones de acceso remoto y vistas BLOB por PDB."

set +e
timeout 300 "${DOCKER_SQLPLUS}" "${C1}" /nolog <<EOF
whenever sqlerror exit failure
@${SQL}
exit;
EOF
rc=$?
set -e

[ ${rc} -eq 124 ] && die "Timeout (300s): la creación de vistas no terminó."
[ ${rc} -ne 0 ] && die "Fallo al crear las vistas (código: ${rc}). Revisa la salida anterior."

ok "Vistas globales creadas correctamente en los 4 nodos."

echo ""
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "${GRN}${BOLD}  Fase 2 completada — vistas globales listas${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "  ${DIM}Siguiente paso natural: construir triggers INSTEAD OF${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo ""