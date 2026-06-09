#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# validate-hasta-parte.sh
# Autor       : erick
# Fecha        : 2026-06-07
# Descripcion  : Ejecuta la validacion acumulativa de las Partes 2, 3 y 4 del
#                proyecto iLap reutilizando los validadores existentes y los
#                scripts oficiales del profesor para la presentacion final.
#                Muestra toda la salida en pantalla y en logs, y pausa en
#                puntos clave para inspeccion manual.
#
# Uso:
#   bash entregables/validate-hasta-parte.sh
#   bash entregables/validate-hasta-parte.sh 2
#   bash entregables/validate-hasta-parte.sh 3
#   bash entregables/validate-hasta-parte.sh 4
#   bash entregables/validate-hasta-parte.sh 4 <sys_password>
#   SYS_PASS=<password> bash entregables/validate-hasta-parte.sh 4
#
# Comportamiento:
#   2 -> valida Parte 2
#   3 -> valida Parte 2 y Parte 3
#   4 -> valida Parte 2, Parte 3 y Parte 4
#
# Notas de idempotencia:
#   - Las validaciones de Parte 2 y Parte 3 son de solo lectura.
#   - Antes de cada validador oficial de Parte 4 se recompone la carga con
#     run-parte-4.sh para asegurar una reejecucion consistente.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PART="${1:-4}"
SYS_PASS_VALUE="${2:-${SYS_PASS:-}}"
PDB_DEMO="${PDB_DEMO:-eambdd_s1}"
FRAGMENTACION_SERVICIO="${FRAGMENTACION_SERVICIO:-S}"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_STAMP="${VALIDATE_LOG_STAMP:-$(date +%Y%m%d-%H%M%S)}"
RUN_LOG="${LOG_DIR}/validate-hasta-parte-${LOG_STAMP}.log"
PARTE4_STAGE_DIR="/tmp/bdd/proyecto-final/workdir/entregables/parte-4/fase-2-presentacion"
GLOBAL_T0=$(date +%s)

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYA='\033[0;36m'
BLU='\033[0;34m'
MAG='\033[1;35m'
BOLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'

log()   { echo -e "  ${CYA}[INFO]${RST}  $*"; }
ok()    { echo -e "  ${GRN}[OK]${RST}    $*"; }
warn()  { echo -e "  ${YEL}[WARN]${RST}  $*"; }
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
  bash entregables/validate-hasta-parte.sh
  bash entregables/validate-hasta-parte.sh 2
  bash entregables/validate-hasta-parte.sh 3
  bash entregables/validate-hasta-parte.sh 4
  bash entregables/validate-hasta-parte.sh 4 <sys_password>
  SYS_PASS=<password> bash entregables/validate-hasta-parte.sh 4

Variables de entorno opcionales:
  PDB_DEMO=eambdd_s1
  FRAGMENTACION_SERVICIO=S
EOF
}

pause_step() {
    local message="$1"
    echo ""
    echo -e "  ${YEL}[PAUSA]${RST}  ${message}"
    if [ -t 0 ]; then
        read -r -p "           Presiona Enter para continuar... " _unused
    else
        log "No hay TTY interactiva; la pausa se omite automaticamente."
    fi
}

run_step() {
    local label="$1"
    local step_log="${LOG_DIR}/${label}-${LOG_STAMP}.log"
    shift

    log "Mostrando salida completa de ${label}"
    log "Log persistente: ${step_log}"
    set +e
    "$@" 2>&1 | tee "${step_log}"
    local rc=${PIPESTATUS[0]}
    set -e

    [ ${rc} -eq 0 ] || die "Fallo ${label} (codigo ${rc}). Revisa ${step_log}."
    ok "${label} completado."
}

run_sqlplus_profesor_insert() {
    local label="$1"
    local step_log="${LOG_DIR}/${label}-${LOG_STAMP}.log"

    log "Ejecutando s-08-ilap-presentacion-4.plb en ${PDB_DEMO}"
    log "Tecnica de servicio_laptop enviada al prompt: ${FRAGMENTACION_SERVICIO}"
    log "Log persistente: ${step_log}"
    set +e
    docker exec -i c1-bdd-proy-eam su - oracle -c "cd '${PARTE4_STAGE_DIR}' && sqlplus /nolog @s-08-ilap-presentacion-4.plb" <<EOF | tee "${step_log}"
${PDB_DEMO}
${FRAGMENTACION_SERVICIO}
EOF
    local rc=${PIPESTATUS[0]}
    set -e

    [ ${rc} -eq 0 ] || die "Fallo ${label} (codigo ${rc}). Revisa ${step_log}."
    ok "${label} completado."
}

run_sqlplus_profesor_delete() {
    local label="$1"
    local step_log="${LOG_DIR}/${label}-${LOG_STAMP}.log"

    log "Ejecutando s-08-ilap-presentacion-6.plb en ${PDB_DEMO}"
    log "Log persistente: ${step_log}"
    set +e
    docker exec -i c1-bdd-proy-eam su - oracle -c "cd '${PARTE4_STAGE_DIR}' && sqlplus /nolog @s-08-ilap-presentacion-6.plb" <<EOF | tee "${step_log}"
${PDB_DEMO}
EOF
    local rc=${PIPESTATUS[0]}
    set -e

    [ ${rc} -eq 0 ] || die "Fallo ${label} (codigo ${rc}). Revisa ${step_log}."
    ok "${label} completado."
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

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${RUN_LOG}") 2>&1

echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   ORQUESTADOR DE VALIDACION · Proyecto Final iLap    ║${RST}"
echo -e "${BOLD}${BLU}╠══════════════════════════════════════════════════════╣${RST}"
echo -e "${BOLD}${BLU}║   Validando hasta la Parte ${TARGET_PART}                         ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

log "Log general de la validacion: ${RUN_LOG}"
log "PDB_DEMO=${PDB_DEMO}"
log "FRAGMENTACION_SERVICIO=${FRAGMENTACION_SERVICIO}"

phase "VALIDACION — Parte 2"
echo -e "  ${DIM}Verifica conectividad, DB links y fragmentos fisicos${RST}"
pause_step "Se ejecutara validate-parte-2.sh y se mostrara toda su salida."
run_step "validate-parte-2" bash "${SCRIPT_DIR}/parte-2/validate-parte-2.sh"

if [ "${TARGET_PART}" -ge 3 ]; then
    phase "VALIDACION — Parte 3"
    echo -e "  ${DIM}Verifica sinonimos, vistas, tablas temporales, funciones y triggers${RST}"
    pause_step "Se ejecutara 09-validate-parte-3.sh con salida completa en pantalla."
    run_step "validate-parte-3" bash "${SCRIPT_DIR}/parte-3/09-validate-parte-3.sh"
fi

if [ "${TARGET_PART}" -ge 4 ]; then
    phase "PREPARACION — Parte 4 antes de INSERT"
    echo -e "  ${DIM}Recompone la carga oficial para validar inserciones sobre un estado consistente${RST}"
    if [ -z "${SYS_PASS_VALUE}" ]; then
        warn "run-parte-4.sh puede pedir el password de SYS de forma interactiva."
    else
        log "SYS_PASS disponible para recomponer la carga oficial de Parte 4."
    fi
    pause_step "Se ejecutara run-parte-4.sh antes del validador oficial de INSERT."
    if [ -n "${SYS_PASS_VALUE}" ]; then
        run_step "run-parte-4-before-insert" bash "${SCRIPT_DIR}/parte-4/run-parte-4.sh" "${SYS_PASS_VALUE}"
    else
        run_step "run-parte-4-before-insert" bash "${SCRIPT_DIR}/parte-4/run-parte-4.sh"
    fi

    phase "VALIDACION OFICIAL — Parte 4 INSERT"
    echo -e "  ${DIM}Ejecuta s-08-ilap-presentacion-4.plb del profesor con prompts respondidos${RST}"
    pause_step "Se lanzara el validador oficial de INSERT. Revisa la salida completa antes de seguir."
    run_sqlplus_profesor_insert "s-08-ilap-presentacion-4"

    phase "PREPARACION — Parte 4 antes de DELETE"
    echo -e "  ${DIM}Recompone nuevamente la carga oficial para validar eliminacion de forma reejecutable${RST}"
    pause_step "Se ejecutara run-parte-4.sh antes del validador oficial de DELETE."
    if [ -n "${SYS_PASS_VALUE}" ]; then
        run_step "run-parte-4-before-delete" bash "${SCRIPT_DIR}/parte-4/run-parte-4.sh" "${SYS_PASS_VALUE}"
    else
        run_step "run-parte-4-before-delete" bash "${SCRIPT_DIR}/parte-4/run-parte-4.sh"
    fi

    phase "VALIDACION OFICIAL — Parte 4 DELETE"
    echo -e "  ${DIM}Ejecuta s-08-ilap-presentacion-6.plb del profesor sobre el ambiente recompuesto${RST}"
    pause_step "Se lanzara el validador oficial de DELETE. Este bloque valida la eliminacion transparente."
    run_sqlplus_profesor_delete "s-08-ilap-presentacion-6"
fi

TOTAL_TIME=$(( $(date +%s) - GLOBAL_T0 ))

echo ""
echo -e "${GRN}${BOLD}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${GRN}${BOLD}║  Validacion acumulativa completada                   ║${RST}"
echo -e "${GRN}${BOLD}╠══════════════════════════════════════════════════════╣${RST}"
echo -e "${GRN}${BOLD}║${RST}  Ultima parte validada: ${TARGET_PART}"
echo -e "${GRN}${BOLD}║${RST}  Tiempo total de ejecucion: ${TOTAL_TIME}s"
echo -e "${GRN}${BOLD}║${RST}  Log general: ${RUN_LOG}"
echo -e "${GRN}${BOLD}╚══════════════════════════════════════════════════════╝${RST}"
echo ""