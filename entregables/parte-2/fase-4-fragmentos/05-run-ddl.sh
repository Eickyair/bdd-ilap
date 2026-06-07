#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 05-run-ddl.sh  — IDEMPOTENTE
# @Autor:          Erick Yair Aguilar Martínez
# @Fecha creación: 04/06/2026
# @Descripción:    Crea los fragmentos locales en los 4 nodos ejecutando
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

log()  { echo "[INFO]  $*"; }
ok()   { echo "[OK]    $*"; }
die()  { echo "[ERROR] $*" >&2; exit 1; }

[ "$(docker inspect "${C1}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
    || die "Contenedor ${C1} no está corriendo."

log "Ejecutando s-03-ilap-main-ddl.sql en los 4 nodos..."
docker exec -i "${C1}" su - oracle -c "sqlplus /nolog" <<EOF
whenever sqlerror exit failure
@${SQL}
exit;
EOF

ok "Fragmentos DDL creados en los 4 nodos."

echo ""
echo "=================================================="
echo " Fase 4 completada: esquema distribuido listo."
echo " Ejecuta la validación: bash ../v-01-run-validations.sh"
echo "=================================================="
