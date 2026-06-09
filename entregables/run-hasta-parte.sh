#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run-hasta-parte.sh
# Autor       : erick
# Fecha        : 2026-06-07
# Descripcion  : Ejecuta acumulativamente las Partes 2 a N del proyecto iLap.
#                Si N=3, ejecuta Parte 2 y Parte 3. Si N=4, ejecuta 2, 3 y 4.
#
# Uso:
#   bash run-hasta-parte.sh 2
#   bash run-hasta-parte.sh 3
#   bash run-hasta-parte.sh 4
#   bash run-hasta-parte.sh 4 <sys_password>
#   SYS_PASS=<password> bash run-hasta-parte.sh 3
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PART="${1:-}"
SYS_PASS_VALUE="${2:-${SYS_PASS:-}}"
_GLOBAL_T0=$(date +%s)

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYA='\033[0;36m'
BLU='\033[0;34m'
MAG='\033[1;35m'
BOLD='\033[1m'
RST='\033[0m'

log()   { echo -e "  ${CYA}[INFO]${RST}  $*"; }
ok()    { echo -e "  ${GRN}[OK]${RST}    $*"; }
die()   { echo -e "  ${RED}[ERROR]${RST} $*" >&2; exit 1; }
phase() {
    echo ""
    echo -e "${BOLD}${MAG}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
    echo -e "${BOLD}${MAG}  $*${RST}"
    echo -e "${BOLD}${MAG}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
}

usage() {
    cat <<'EOF'
Uso:
  bash entregables/run-hasta-parte.sh 2
  bash entregables/run-hasta-parte.sh 3
  bash entregables/run-hasta-parte.sh 4
  bash entregables/run-hasta-parte.sh 4 <sys_password>
  SYS_PASS=<password> bash entregables/run-hasta-parte.sh 3

Comportamiento:
  2 -> ejecuta Parte 2
  3 -> ejecuta Parte 2 y Parte 3
  4 -> ejecuta Parte 2, Parte 3 y Parte 4
EOF
}

case "${TARGET_PART}" in
    2|3|4) ;;
    --help|-h|'')
        usage
        exit 0
        ;;
    *)
        die "La parte objetivo debe ser 2, 3 o 4. Usa --help para ver el uso."
        ;;
esac

echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   ORQUESTADOR ACUMULATIVO · Proyecto Final iLap      ║${RST}"
echo -e "${BOLD}${BLU}╠══════════════════════════════════════════════════════╣${RST}"
echo -e "${BOLD}${BLU}║   Ejecutando hasta la Parte ${TARGET_PART}                         ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

if [ -n "${SYS_PASS_VALUE}" ]; then
    export SYS_PASS="${SYS_PASS_VALUE}"
    log "SYS_PASS disponible para las partes que requieren operaciones SYSDBA."
else
    log "SYS_PASS no fue proporcionado; los runners pueden solicitarlo de forma interactiva."
fi

phase "PARTE 2"
bash "${SCRIPT_DIR}/parte-2/run-parte-2.sh"
ok "Parte 2 completada."

if [ "${TARGET_PART}" -ge 3 ]; then
    phase "PARTE 3"
    bash "${SCRIPT_DIR}/parte-3/run-parte-3.sh"
    ok "Parte 3 completada."
fi

if [ "${TARGET_PART}" -ge 4 ]; then
    phase "PARTE 4"
    bash "${SCRIPT_DIR}/parte-4/run-parte-4.sh"
    ok "Parte 4 completada."
fi

_total=$(( $(date +%s) - _GLOBAL_T0 ))

echo ""
echo -e "${GRN}${BOLD}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${GRN}${BOLD}║  Ejecución acumulativa completada                    ║${RST}"
echo -e "${GRN}${BOLD}╠══════════════════════════════════════════════════════╣${RST}"
echo -e "${GRN}${BOLD}║${RST}  Última parte ejecutada: ${TARGET_PART}"
echo -e "${GRN}${BOLD}║${RST}  Tiempo total de ejecución: ${_total}s"
echo -e "${GRN}${BOLD}╚══════════════════════════════════════════════════════╝${RST}"
echo ""