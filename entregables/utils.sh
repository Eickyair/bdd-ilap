#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# utils.sh
# Autor       : erick
# Fecha        : 2026-06-09
# Descripción  : Variables de entorno Oracle y función docker_sqlplus para
#                  ejecutar SQL*Plus dentro de contenedores sin su - oracle.
#
# Uso: source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
#      docker_sqlplus <contenedor> [argumentos_sqlplus] <<HEREDOC
# ---------------------------------------------------------------------------

# Directorio donde están los scripts wrapper (docker_sqlplus.sh, etc.)
UTILS_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin"

# Ruta al wrapper ejecutable. Usar esta variable para llamadas dentro de
# timeout(1), ya que timeout no puede ejecutar funciones bash.
DOCKER_SQLPLUS="${UTILS_BIN}/docker_sqlplus.sh"

# docker_sqlplus: atajo para llamar al wrapper sin ruta completa.
# Uso: docker_sqlplus <contenedor> <flags> <<HEREDOC
# NOTA: No funciona dentro de timeout(1). Usa "${DOCKER_SQLPLUS}" en su lugar.
docker_sqlplus() {
  "${DOCKER_SQLPLUS}" "$@"
}
