#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run-parte-3.sh  - ORQUESTADOR MAESTRO - IDEMPOTENTE
# Autor       : erick
# Fecha        : 2026-06-07
# Descripción  : Ejecuta todas las fases de la Parte 3 del Proyecto Final
#                  iLap: sinónimos, vistas, triggers y validación estructural.
#
# Uso:
#   bash run-parte-3.sh
#   bash run-parte-3.sh <sys_password>
#   SYS_PASS=<password> bash run-parte-3.sh
#   bash run-parte-3.sh --only-validate
#   bash run-parte-3.sh --skip-validate
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${PARTE3_LOG_FILE:-${LOG_DIR}/run-parte-3-$(date +%Y%m%d-%H%M%S).log}"
SHOW_HELP=false
ONLY_VALIDATE=false
SKIP_VALIDATE=false
SYS_PASS_ARG="${SYS_PASS:-}"
_GLOBAL_T0=$(date +%s)

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYA='\033[0;36m'
BLU='\033[0;34m'
MAG='\033[1;35m'
BOLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'

ok()    { echo -e "  ${GRN}[OK]${RST}    $*"; }
skip()  { echo -e "  ${YEL}[SKIP]${RST}  $*"; }
die()   { echo -e "  ${RED}[ERROR]${RST} $*" >&2; exit 1; }
phase() {
    echo ""
    echo -e "${BOLD}${MAG}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
    echo -e "${BOLD}${MAG}  $*${RST}"
    echo -e "${BOLD}${MAG}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
}

for arg in "$@"; do
    case "${arg}" in
        --only-validate) ONLY_VALIDATE=true ;;
        --skip-validate) SKIP_VALIDATE=true ;;
        --help|-h) SHOW_HELP=true ;;
        *)
            if [ -z "${SYS_PASS_ARG}" ]; then
                SYS_PASS_ARG="${arg}"
            else
                die "Argumento no reconocido o password duplicado: ${arg}"
            fi
            ;;
    esac
done

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo ""
echo "Log de ejecución: ${LOG_FILE}"

if ${SHOW_HELP}; then
    echo "Uso: bash run-parte-3.sh [sys_password] [--only-validate] [--skip-validate]"
    exit 0
fi

echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   ORQUESTADOR · Proyecto Final Parte 3 — BDD iLap    ║${RST}"
echo -e "${BOLD}${BLU}║   Semestre 2026-2 · Operador: erick                  ║${RST}"
echo -e "${BOLD}${BLU}╠══════════════════════════════════════════════════════╣${RST}"
echo -e "${BOLD}${BLU}║  Fases: 1-Sinónimos  2-Vistas  3-Triggers            ║${RST}"
echo -e "${BOLD}${BLU}║         Validación estructural                      ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

if ! ${ONLY_VALIDATE}; then
    phase "FASE 1 — Sinónimos lógicos de transparencia"
    echo -e "  ${DIM}Crea alias *_f<n> y *_r<n> sobre los 4 nodos${RST}"
    bash "${SCRIPT_DIR}/fase-1-sinonimos/06-run-sinonimos.sh"
    ok "Fase 1 completada."

    phase "FASE 2 — Vistas globales y soporte BLOB"
    echo -e "  ${DIM}Reconstruye vistas distribuidas, tablas temporales y funciones BLOB${RST}"
    bash "${SCRIPT_DIR}/fase-2-vistas/07-run-vistas.sh"
    ok "Fase 2 completada."

    phase "FASE 3 — Triggers INSTEAD OF"
    echo -e "  ${DIM}Otorga CREATE TRIGGER y compila los triggers de transparencia${RST}"
    if [ -n "${SYS_PASS_ARG}" ]; then
        SYS_PASS="${SYS_PASS_ARG}" bash "${SCRIPT_DIR}/fase-3-triggers/08-run-triggers.sh" "${SYS_PASS_ARG}"
    else
        bash "${SCRIPT_DIR}/fase-3-triggers/08-run-triggers.sh"
    fi
    ok "Fase 3 completada."
fi

if ${ONLY_VALIDATE}; then
    phase "VALIDACIÓN — Estructura completa de la Parte 3"
    echo -e "  ${DIM}Revisa sinónimos, vistas, tablas temporales, funciones y triggers${RST}"
    bash "${SCRIPT_DIR}/09-validate-parte-3.sh"
    ok "Validación completada."
elif ${SKIP_VALIDATE}; then
    skip "Validación omitida por --skip-validate."
else
    phase "VALIDACIÓN — Estructura completa de la Parte 3"
    echo -e "  ${DIM}Revisa sinónimos, vistas, tablas temporales, funciones y triggers${RST}"
    bash "${SCRIPT_DIR}/09-validate-parte-3.sh"
    ok "Validación completada."
fi

_total=$(( $(date +%s) - _GLOBAL_T0 ))

echo ""
echo -e "${GRN}${BOLD}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${GRN}${BOLD}║  Proyecto Final Parte 3 — COMPLETADO                 ║${RST}"
echo -e "${GRN}${BOLD}╠══════════════════════════════════════════════════════╣${RST}"
echo -e "${GRN}${BOLD}║${RST}  Tiempo total de ejecución: ${_total}s"
echo -e "${GRN}${BOLD}║${RST}  Log guardado en: ${LOG_FILE}"
echo -e "${GRN}${BOLD}╚══════════════════════════════════════════════════════╝${RST}"
echo ""