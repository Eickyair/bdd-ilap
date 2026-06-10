#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# docker_sqlplus.sh  — wrapper ejecutable para docker_sqlplus()
# Autor       : erick
# Fecha        : 2026-06-09
# Descripción  : Ejecuta sqlplus dentro de un contenedor como usuario erick
#                con las variables de entorno Oracle. Reemplaza el patrón:
#                  docker exec ... su - oracle -c "sqlplus ..."
#
# Uso: docker_sqlplus.sh <contenedor> [flags_sqlplus] <<HEREDOC
# ---------------------------------------------------------------------------
set -euo pipefail

C="${1:?primer argumento: contenedor}"; shift

exec docker exec -i \
  --user erick \
  -e ORACLE_HOME=/opt/oracle/product/23ai/dbhomeFree \
  -e ORACLE_SID=free \
  -e PATH=/opt/oracle/product/23ai/dbhomeFree/bin:/usr/local/bin:/usr/bin \
  "$C" sqlplus "$@"
