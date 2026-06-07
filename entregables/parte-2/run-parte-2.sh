#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run-parte-2.sh  — ORQUESTADOR MAESTRO — IDEMPOTENTE
# @Autor:          Erick Yair Aguilar Martínez
# @Fecha creación: 04/06/2026
# @Descripción:    Ejecuta todas las fases del Proyecto Final Parte 2 en orden.
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

for arg in "$@"; do
    case "${arg}" in
        --skip-fase1)    SKIP_FASE1=true ;;
        --only-validate) ONLY_VALIDATE=true ;;
    esac
done

log()     { echo ""; echo "══════════════════════════════════════════════"; echo "  $*"; echo "══════════════════════════════════════════════"; }
ok()      { echo "[OK]    $*"; }
section() { echo ""; echo "▶ $*"; }

if ! ${ONLY_VALIDATE}; then

    # ------------------------------------------------------------------
    if ! ${SKIP_FASE1}; then
        log "FASE 1 — Infraestructura Docker"
        bash "${SCRIPT_DIR}/fase-1-infraestructura/01-docker-up.sh"
        bash "${SCRIPT_DIR}/fase-1-infraestructura/02-oracle-config.sh"
        ok "Fase 1 completada."
    else
        echo "[SKIP]  Fase 1 omitida por --skip-fase1."
    fi

    # ------------------------------------------------------------------
    log "FASE 2 — Creación de usuario ilap_bdd"
    if [ -n "${SYS_PASS:-}" ]; then
        bash "${SCRIPT_DIR}/fase-2-usuarios/03-run-usuarios.sh" "${SYS_PASS}"
    else
        bash "${SCRIPT_DIR}/fase-2-usuarios/03-run-usuarios.sh"
    fi
    ok "Fase 2 completada."

    # ------------------------------------------------------------------
    log "FASE 3 — Creación de database links"
    bash "${SCRIPT_DIR}/fase-3-ligas/04-run-ligas.sh"
    ok "Fase 3 completada."

    # ------------------------------------------------------------------
    log "FASE 4 — Creación de fragmentos DDL"
    bash "${SCRIPT_DIR}/fase-4-fragmentos/05-run-ddl.sh"
    ok "Fase 4 completada."

fi

# ------------------------------------------------------------------
log "VALIDACIÓN — Consistencia de la BDD distribuida"
bash "${SCRIPT_DIR}/v-01-run-validations.sh"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Proyecto Final Parte 2 — COMPLETADO         ║"
echo "╚══════════════════════════════════════════════╝"
