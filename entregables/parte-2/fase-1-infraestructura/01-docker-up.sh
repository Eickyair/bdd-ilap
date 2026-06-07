#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 01-docker-up.sh  — IDEMPOTENTE
# Autor       : erick
# Fecha        : 2026-06-04
# Descripción  : Crea y levanta la infraestructura Docker para la BDD
#                  distribuida iLap (equipo individual, iniciales: eam).
#                  Puede ejecutarse múltiples veces sin efectos secundarios.
#
#   Contenedor 1: c1-bdd-proy-eam  172.20.0.21  PDBs: eambdd_s1, eambdd_s2
#   Contenedor 2: c2-bdd-proy-eam  172.20.0.22  PDBs: eambdd_s3, eambdd_s4
#
# Uso:  bash 01-docker-up.sh
# ---------------------------------------------------------------------------
set -euo pipefail

BASE_IMAGE="bdd-eam:1.0"
SOURCE_CONTAINER="c1-bdd-eam"
NETWORK="bdd-proy-net"
SUBNET="172.20.0.0/16"

C1_NAME="c1-bdd-proy-eam"
C1_HOST="h1-bdd-proy-eam.fi.unam"
C1_IP="172.20.0.21"

C2_NAME="c2-bdd-proy-eam"
C2_HOST="h2-bdd-proy-eam.fi.unam"
C2_IP="172.20.0.22"

UNAM_HOME="${UNAM_HOME:-/unam}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
warn()     { echo -e "  ${YEL}[WARN]${RST}  $*"; }
die()      { echo -e "  ${RED}[ERROR]${RST} $*" >&2; exit 1; }
step()     { echo ""; echo -e "${BOLD}${BLU}▶ $*${RST}"; }
wait_msg() { echo -e "  ${MAG}[WAIT]${RST}  $*"; }

# ------------------------------------------------------------------ banner
echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   FASE 1 · Infraestructura Docker — BDD iLap         ║${RST}"
echo -e "${BOLD}${BLU}║   Proyecto iLap · Semestre 2026-2 · Operador: erick  ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

# ------------------------------------------------------------------ imagen
step "Imagen base: ${BASE_IMAGE}"
log "Verificando si la imagen ${BASE_IMAGE} ya existe en el registro Docker local..."
if ! docker image inspect "${BASE_IMAGE}" &>/dev/null; then
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${SOURCE_CONTAINER}$"; then
        die "No existe la imagen '${BASE_IMAGE}' ni el contenedor fuente '${SOURCE_CONTAINER}'. Verifica el entorno base antes de continuar."
    fi
    wait_msg "Creando imagen ${BASE_IMAGE} desde '${SOURCE_CONTAINER}' — snapshot de ~3 GB, puede tardar 2-5 min (timeout: 300s)..."
    _t0=$(date +%s)
    set +e
    timeout 300 docker commit "${SOURCE_CONTAINER}" "${BASE_IMAGE}"
    _rc=$?
    set -e
    _elapsed=$(( $(date +%s) - _t0 ))
    [ $_rc -eq 124 ] && die "Timeout (300s): docker commit tardó demasiado. Verifica que '${SOURCE_CONTAINER}' no tenga I/O bloqueado."
    [ $_rc -ne 0 ]   && die "docker commit falló (código: ${_rc}). Revisa el estado del contenedor '${SOURCE_CONTAINER}'."
    ok "Imagen ${BASE_IMAGE} creada en ${_elapsed}s."
else
    ok "Imagen ${BASE_IMAGE} ya existe en Docker local — se reutiliza sin recrear."
fi

# ------------------------------------------------------------------- red
step "Red Docker: ${NETWORK} (${SUBNET})"
log "Verificando existencia de la red ${NETWORK}..."
if ! docker network inspect "${NETWORK}" &>/dev/null; then
    log "Red no encontrada — creando ${NETWORK} con subnet ${SUBNET}..."
    docker network create --subnet="${SUBNET}" "${NETWORK}"
    ok "Red ${NETWORK} creada (subnet ${SUBNET})."
else
    ok "Red ${NETWORK} ya existe — nada que hacer."
fi

# --------------------------------------------------------- contenedores
_ensure_container() {
    local name="$1" hostname="$2" ip="$3" peer_host="$4" peer_ip="$5"

    step "Contenedor: ${name}"
    log "IP asignada : ${ip}  |  Hostname: ${hostname}"
    log "Peer        : ${peer_host} → ${peer_ip}"

    if docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; then
        if [ "$(docker inspect "${name}" --format '{{.State.Running}}')" = "true" ]; then
            ok "Contenedor ${name} ya está corriendo — se mantiene sin cambios."
        else
            log "Contenedor ${name} existe pero está detenido — iniciando..."
            docker start "${name}"
            ok "Contenedor ${name} iniciado correctamente."
        fi
        return
    fi

    log "Contenedor ${name} no existe — creando desde imagen ${BASE_IMAGE}..."
    docker run -dit \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v "${UNAM_HOME}:${UNAM_HOME}" \
        --name "${name}" \
        --hostname "${hostname}" \
        --expose 1521 \
        --shm-size=2gb \
        --net="${NETWORK}" \
        --ip "${ip}" \
        --add-host "${peer_host}:${peer_ip}" \
        -e DISPLAY="${DISPLAY:-:0}" \
        "${BASE_IMAGE}" bash
    ok "Contenedor ${name} creado y corriendo."
}

_ensure_container "${C1_NAME}" "${C1_HOST}" "${C1_IP}" "${C2_HOST}" "${C2_IP}"
_ensure_container "${C2_NAME}" "${C2_HOST}" "${C2_IP}" "${C1_HOST}" "${C1_IP}"

# ------------------------------------------------- copiar tnsnames.ora
step "tnsnames.ora — distribuir archivo de aliases TNS a ambos contenedores"
TNSNAMES_SRC="${SCRIPT_DIR}/tnsnames.ora"

for container in "${C1_NAME}" "${C2_NAME}"; do
    log "Detectando ORACLE_HOME en ${container}..."
    ORACLE_HOME=$(docker exec "${container}" bash -c \
        'source /etc/profile.d/99-custom-env.sh 2>/dev/null; echo "${ORACLE_HOME}"' 2>/dev/null || true)

    if [ -z "${ORACLE_HOME}" ]; then
        log "Variable ORACLE_HOME no definida en /etc/profile.d — buscando sqlplus en /opt/oracle/product..."
        ORACLE_HOME=$(docker exec "${container}" bash -c \
            'find /opt/oracle/product -maxdepth 3 -name "sqlplus" 2>/dev/null | head -1 | sed "s|/bin/sqlplus||"' 2>/dev/null || true)
    fi

    if [ -n "${ORACLE_HOME}" ]; then
        docker exec "${container}" bash -c "mkdir -p ${ORACLE_HOME}/network/admin"
        docker cp "${TNSNAMES_SRC}" "${container}:${ORACLE_HOME}/network/admin/tnsnames.ora"
        ok "tnsnames.ora → ${container}:${ORACLE_HOME}/network/admin/ (4 alias: eambdd_s1..s4)"
    else
        warn "No se encontró ORACLE_HOME en ${container} — tnsnames.ora NO copiado. Copia manual requerida."
    fi
done

# ---------------------------------------------- ORACLE_HOSTNAME
step "ORACLE_HOSTNAME — configurar identidad del listener en cada contenedor"
log "Registrando ORACLE_HOSTNAME=h1-bdd-proy-eam en ${C1_NAME}..."
docker exec "${C1_NAME}" bash -c \
    "grep -q 'ORACLE_HOSTNAME=h1-bdd-proy-eam' /etc/profile.d/99-custom-env.sh 2>/dev/null || \
     echo 'export ORACLE_HOSTNAME=h1-bdd-proy-eam' >> /etc/profile.d/99-custom-env.sh"
ok "ORACLE_HOSTNAME=h1-bdd-proy-eam persistido en /etc/profile.d/99-custom-env.sh (${C1_NAME})."

log "Registrando ORACLE_HOSTNAME=h2-bdd-proy-eam en ${C2_NAME}..."
docker exec "${C2_NAME}" bash -c \
    "grep -q 'ORACLE_HOSTNAME=h2-bdd-proy-eam' /etc/profile.d/99-custom-env.sh 2>/dev/null || \
     echo 'export ORACLE_HOSTNAME=h2-bdd-proy-eam' >> /etc/profile.d/99-custom-env.sh"
ok "ORACLE_HOSTNAME=h2-bdd-proy-eam persistido en /etc/profile.d/99-custom-env.sh (${C2_NAME})."

# ------------------------------------------- listener.ora
step "listener.ora — configurar dirección TCP/IPC del listener Oracle en cada contenedor"
_write_listener() {
    local container="$1" oracle_host="$2"
    log "Escribiendo listener.ora en ${container} (HOST=${oracle_host}, PORT=1521)..."
    docker exec "${container}" bash -c "
        OHOME=\$(find /opt/oracle/product -maxdepth 3 -name sqlplus 2>/dev/null | head -1 | sed 's|/bin/sqlplus||')
        [ -z \"\$OHOME\" ] && exit 0
        mkdir -p \"\$OHOME/network/admin\"
        cat > \"\$OHOME/network/admin/listener.ora\" <<'LISTENER_EOF'
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${oracle_host})(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
LISTENER_EOF
        echo 'listener.ora escrito en '\"\$OHOME/network/admin/\"
    "
    ok "listener.ora en ${container} → TCP:${oracle_host}:1521 + IPC:EXTPROC1521."
}

_write_listener "${C1_NAME}" "${C1_HOST}"
_write_listener "${C2_NAME}" "${C2_HOST}"

# ------------------------------------------- validar ping entre nodos
step "Validación de red — ping bidireccional entre contenedores"
log "Probando conectividad ${C1_HOST} → ${C2_HOST} (2 pings, timeout 2s c/u)..."
if docker exec "${C1_NAME}" ping -c 2 -W 2 "${C2_HOST}" &>/dev/null; then
    ok "Ping ${C1_HOST} → ${C2_HOST}: EXITOSO — ruta Docker entre contenedores OK."
else
    warn "Ping ${C1_HOST} → ${C2_HOST}: FALLÓ — verificar --add-host en ${C1_NAME} (/etc/hosts)."
fi

log "Probando conectividad ${C2_HOST} → ${C1_HOST} (2 pings, timeout 2s c/u)..."
if docker exec "${C2_NAME}" ping -c 2 -W 2 "${C1_HOST}" &>/dev/null; then
    ok "Ping ${C2_HOST} → ${C1_HOST}: EXITOSO — ruta Docker entre contenedores OK."
else
    warn "Ping ${C2_HOST} → ${C1_HOST}: FALLÓ — verificar --add-host en ${C2_NAME} (/etc/hosts)."
fi

# ---------------------------------------------------------------- resumen
echo ""
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "${GRN}${BOLD}  FASE 1 completada — Infraestructura Docker lista${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "  ${CYA}${C1_NAME}${RST}  ${C1_IP}  PDBs: eambdd_s1, eambdd_s2"
echo -e "  ${CYA}${C2_NAME}${RST}  ${C2_IP}  PDBs: eambdd_s3, eambdd_s4"
echo -e "  ${DIM}Próximo paso: bash 02-oracle-config.sh${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo ""
