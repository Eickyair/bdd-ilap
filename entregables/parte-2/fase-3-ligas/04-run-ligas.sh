#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 04-run-ligas.sh  — IDEMPOTENTE
# Autor       : erick
# Fecha        : 2026-06-04
# Descripción  : Crea los 12 database links (3 por nodo) ejecutando
#                  s-02-ilap-ligas.sql. El script usa DROP DATABASE LINK IF
#                  EXISTS antes de cada CREATE, por lo que es idempotente.
#
# Prerequisito: bash ../fase-2-usuarios/03-run-usuarios.sh
# Uso: bash 04-run-ligas.sh
# ---------------------------------------------------------------------------
set -euo pipefail

C1="c1-bdd-proy-eam"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL="${SCRIPT_DIR}/s-02-ilap-ligas.sql"

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
echo -e "${BOLD}${BLU}║   FASE 3 · Creación de database links — BDD iLap     ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

[ "$(docker inspect "${C1}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
    || die "Contenedor ${C1} no está corriendo. Ejecuta las fases 1 y 2 primero."

step "Creando 12 database links en malla completa (3 por nodo)"
log "Script SQL : s-02-ilap-ligas.sql"
log "Topología  : malla completa bidireccional — 4 nodos × 3 links salientes = 12 links"
log "  eambdd_s1 → s2, s3, s4  |  eambdd_s2 → s1, s3, s4"
log "  eambdd_s3 → s1, s2, s4  |  eambdd_s4 → s1, s2, s3"
log "Nombre de link = nombre global de la PDB destino (ej: eambdd_s2.fi.unam)"
wait_msg "Ejecutando SQL*Plus vía ${C1} (timeout: 90s)..."

_t0=$(date +%s)
set +e
timeout 90 docker exec -i "${C1}" su - oracle -c "sqlplus /nolog" <<EOF
whenever sqlerror exit failure
@${SQL}
exit;
EOF
_rc=$?
set -e
_elapsed=$(( $(date +%s) - _t0 ))

[ $_rc -eq 124 ] && die "Timeout (90s): s-02-ilap-ligas.sql no completó. Verifica conectividad TNS entre los 4 nodos Oracle."
[ $_rc -ne 0 ]   && die "Error al crear database links (código: ${_rc}). Revisa la salida anterior."

ok "12 database links creados exitosamente en ${_elapsed}s."

echo ""
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "${GRN}${BOLD}  FASE 3 completada — 12 DB links disponibles${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "  Prueba: ${DIM}SELECT * FROM dual@eambdd_s2.fi.unam;${RST}  (desde eambdd_s1)"
echo -e "  ${DIM}Próximo paso: bash ../fase-4-fragmentos/05-run-ddl.sh${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo ""
