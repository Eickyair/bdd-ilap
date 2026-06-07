#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run-parte-2.sh  — ORQUESTADOR MAESTRO — IDEMPOTENTE
# Autor       : erick
# Fecha        : 2026-06-04
# Descripción  : Ejecuta todas las fases del Proyecto Final Parte 2 en orden.
#                  Puede interrumpirse y re-ejecutarse desde cualquier punto;
#                  cada fase es idempotente.
#
#   Fase 1 — Infraestructura Docker (contenedores, red, tnsnames, listener)
#   Fase 2 — Creación de usuario ilap_bdd en los 4 nodos
#   Fase 3 — Creación de 12 database links
#   Fase 4 — Creación de fragmentos DDL en los 4 nodos
#   Validación — Verificación de consistencia de la BDD distribuida
#
# Uso:
#   bash run-parte-2.sh                 # ejecuta todas las fases
#   bash run-parte-2.sh --skip-fase1    # omite Docker (ya levantado)
#   bash run-parte-2.sh --only-validate # solo ejecuta validaciones
#
# Variables de entorno opcionales:
#   SYS_PASS=<password>   evita el prompt interactivo de sys
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_FASE1=false
ONLY_VALIDATE=false
_GLOBAL_T0=$(date +%s)

for arg in "$@"; do
    case "${arg}" in
        --skip-fase1)    SKIP_FASE1=true ;;
        --only-validate) ONLY_VALIDATE=true ;;
    esac
done

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

ok()    { echo -e "  ${GRN}[OK]${RST}    $*"; }
skip()  { echo -e "  ${YEL}[SKIP]${RST}  $*"; }
phase() {
    echo ""
    echo -e "${BOLD}${MAG}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
    echo -e "${BOLD}${MAG}  $*${RST}"
    echo -e "${BOLD}${MAG}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
}

# ----------------------------------------------------------------- banner
echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   ORQUESTADOR · Proyecto Final Parte 2 — BDD iLap    ║${RST}"
echo -e "${BOLD}${BLU}║   Semestre 2026-2 · Operador: erick                  ║${RST}"
echo -e "${BOLD}${BLU}╠══════════════════════════════════════════════════════╣${RST}"
echo -e "${BOLD}${BLU}║  Fases: 1-Docker  1b-Oracle  2-Usuarios  3-Links     ║${RST}"
echo -e "${BOLD}${BLU}║         4-DDL     Validación                          ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

if ! ${ONLY_VALIDATE}; then

    if ! ${SKIP_FASE1}; then
        phase "FASE 1 — Infraestructura Docker"
        echo -e "  ${DIM}Crea red bdd-proy-net, contenedores c1/c2, tnsnames, listener.ora${RST}"
        bash "${SCRIPT_DIR}/fase-1-infraestructura/01-docker-up.sh"
        ok "Fase 1a (Docker) completada."

        phase "FASE 1b — Configuración Oracle"
        echo -e "  ${DIM}Inicia CDB, crea PDBs eambdd_s3/s4 en c2, configura tablespace USERS${RST}"
        bash "${SCRIPT_DIR}/fase-1-infraestructura/02-oracle-config.sh"
        ok "Fase 1b (Oracle) completada."
    else
        skip "Fase 1 omitida por --skip-fase1 (asumiendo contenedores ya levantados)."
    fi

    phase "FASE 2 — Creación de usuario ilap_bdd"
    echo -e "  ${DIM}Crea usuario ilap_bdd con 7 privilegios mínimos en los 4 nodos${RST}"
    if [ -n "${SYS_PASS:-}" ]; then
        bash "${SCRIPT_DIR}/fase-2-usuarios/03-run-usuarios.sh" "${SYS_PASS}"
    else
        bash "${SCRIPT_DIR}/fase-2-usuarios/03-run-usuarios.sh"
    fi
    ok "Fase 2 (usuarios) completada."

    phase "FASE 3 — Creación de database links"
    echo -e "  ${DIM}Crea 12 DB links en malla completa (3 por nodo × 4 nodos)${RST}"
    bash "${SCRIPT_DIR}/fase-3-ligas/04-run-ligas.sh"
    ok "Fase 3 (database links) completada."

    phase "FASE 4 — Creación de fragmentos DDL"
    echo -e "  ${DIM}Crea ~45 tablas distribuidas en los 4 nodos según esquema iLap${RST}"
    bash "${SCRIPT_DIR}/fase-4-fragmentos/05-run-ddl.sh"
    ok "Fase 4 (DDL) completada."

fi

phase "VALIDACIÓN — Consistencia de la BDD distribuida"
echo -e "  ${DIM}Verifica conectividad, usuarios, DB links y tablas en los 4 nodos${RST}"
bash "${SCRIPT_DIR}/validate-parte-2.sh"

_total=$(( $(date +%s) - _GLOBAL_T0 ))

echo ""
echo -e "${GRN}${BOLD}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${GRN}${BOLD}║  Proyecto Final Parte 2 — COMPLETADO                 ║${RST}"
echo -e "${GRN}${BOLD}╠══════════════════════════════════════════════════════╣${RST}"
echo -e "${GRN}${BOLD}║${RST}  Tiempo total de ejecución: ${_total}s"
echo -e "${GRN}${BOLD}╚══════════════════════════════════════════════════════╝${RST}"
echo ""
