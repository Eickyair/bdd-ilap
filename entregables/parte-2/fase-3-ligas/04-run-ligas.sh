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

log()  { echo "[INFO]  $*"; }
ok()   { echo "[OK]    $*"; }
die()  { echo "[ERROR] $*" >&2; exit 1; }

[ "$(docker inspect "${C1}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
    || die "Contenedor ${C1} no está corriendo."

log "Ejecutando s-02-ilap-ligas.sql..."
docker exec -i "${C1}" su - oracle -c "sqlplus /nolog" <<EOF
whenever sqlerror exit failure
@${SQL}
exit;
EOF

ok "12 database links creados (3 por nodo × 4 nodos)."

echo ""
echo "=================================================="
echo " Fase 3 completada: database links disponibles."
echo " Próximo paso: bash ../fase-4-fragmentos/05-run-ddl.sh"
echo "=================================================="
