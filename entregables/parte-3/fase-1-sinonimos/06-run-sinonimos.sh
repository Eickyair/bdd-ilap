#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 06-run-sinonimos.sh
# Autor       : erick
# Fecha        : 2026-06-07
# Descripción  : Crea y valida los sinónimos lógicos de transparencia de la
#                  Parte 3 para los 4 nodos de iLap.
#
# Prerequisito: bash ../../parte-2/fase-4-fragmentos/05-run-ddl.sh
# Uso: bash 06-run-sinonimos.sh
# ---------------------------------------------------------------------------
set -euo pipefail

C1="c1-bdd-proy-eam"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL="${SCRIPT_DIR}/s-04-ilap-main-sinonimos.sql"
source "${SCRIPT_DIR}/../../utils.sh"

RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
CYA='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'

log()  { echo -e "  ${CYA}[INFO]${RST}  $*"; }
ok()   { echo -e "  ${GRN}[OK]${RST}    $*"; }
die()  { echo -e "  ${RED}[ERROR]${RST} $*" >&2; exit 1; }
step() { echo ""; echo -e "${BOLD}${BLU}▶ $*${RST}"; }

echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   PARTE 3 · Fase 1 · Sinónimos de transparencia      ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

[ "$(docker inspect "${C1}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
    || die "Contenedor ${C1} no está corriendo. Ejecuta la Parte 2 primero."

step "Creando sinónimos de transparencia en los 4 nodos"
log "Script SQL: s-04-ilap-main-sinonimos.sql"
log "Cada nodo recibe alias lógicos *_f<n> y *_r<n> para ocultar ubicación física."
log "El main también ejecuta un validador básico por conteos en cada PDB."

set +e
timeout 120 "${DOCKER_SQLPLUS}" "${C1}" /nolog <<EOF
whenever sqlerror exit failure
@${SQL}
exit;
EOF
rc=$?
set -e

[ ${rc} -eq 124 ] && die "Timeout (120s): la creación de sinónimos no terminó." 
[ ${rc} -ne 0 ] && die "Fallo al crear sinónimos (código: ${rc}). Revisa la salida anterior."

ok "Sinónimos creados correctamente en los 4 nodos."

echo ""
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "${GRN}${BOLD}  Fase 1 completada — sinónimos listos${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "  ${DIM}Siguiente paso natural: construir s-05-ilap-vistas.sql${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo ""