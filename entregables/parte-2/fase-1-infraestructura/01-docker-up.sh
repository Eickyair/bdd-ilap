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

log()  { echo "[INFO]  $*"; }
ok()   { echo "[OK]    $*"; }
warn() { echo "[WARN]  $*"; }

# ------------------------------------------------------------------ imagen --
log "Verificando imagen base ${BASE_IMAGE}..."
if ! docker image inspect "${BASE_IMAGE}" &>/dev/null; then
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${SOURCE_CONTAINER}$"; then
        echo "[ERROR] No existe el contenedor '${SOURCE_CONTAINER}' para crear la imagen."
        exit 1
    fi
    log "Creando imagen ${BASE_IMAGE} desde ${SOURCE_CONTAINER}..."
    docker commit "${SOURCE_CONTAINER}" "${BASE_IMAGE}"
    ok "Imagen ${BASE_IMAGE} creada."
else
    ok "Imagen ${BASE_IMAGE} ya existe."
fi

# ------------------------------------------------------------------- red ---
log "Verificando red ${NETWORK}..."
if ! docker network inspect "${NETWORK}" &>/dev/null; then
    log "Creando red ${NETWORK} (${SUBNET})..."
    docker network create --subnet="${SUBNET}" "${NETWORK}"
    ok "Red ${NETWORK} creada."
else
    ok "Red ${NETWORK} ya existe."
fi

# --------------------------------------------------------- contenedor 1 ---
_ensure_container() {
    local name="$1" hostname="$2" ip="$3" peer_host="$4" peer_ip="$5"

    if docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; then
        if [ "$(docker inspect "${name}" --format '{{.State.Running}}')" = "true" ]; then
            ok "Contenedor ${name} ya está corriendo."
        else
            log "Iniciando contenedor detenido ${name}..."
            docker start "${name}"
            ok "Contenedor ${name} iniciado."
        fi
        return
    fi

    log "Creando y levantando contenedor ${name}..."
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

# ------------------------------------------------- copiar tnsnames.ora ---
TNSNAMES_SRC="${SCRIPT_DIR}/tnsnames.ora"
TNSNAMES_DST="\$ORACLE_HOME/network/admin/tnsnames.ora"

for container in "${C1_NAME}" "${C2_NAME}"; do
    log "Copiando tnsnames.ora en ${container}..."
    ORACLE_HOME=$(docker exec "${container}" bash -c \
        'source /etc/profile.d/99-custom-env.sh 2>/dev/null; echo "${ORACLE_HOME}"' 2>/dev/null || true)

    if [ -z "${ORACLE_HOME}" ]; then
        # fallback: buscar oracle home directamente
        ORACLE_HOME=$(docker exec "${container}" bash -c \
            'find /opt/oracle/product -maxdepth 3 -name "sqlplus" 2>/dev/null | head -1 | sed "s|/bin/sqlplus||"' 2>/dev/null || true)
    fi

    if [ -n "${ORACLE_HOME}" ]; then
        docker exec "${container}" bash -c \
            "mkdir -p ${ORACLE_HOME}/network/admin"
        docker cp "${TNSNAMES_SRC}" "${container}:${ORACLE_HOME}/network/admin/tnsnames.ora"
        ok "tnsnames.ora copiado en ${container} → ${ORACLE_HOME}/network/admin/"
    else
        warn "No se encontró ORACLE_HOME en ${container}; tnsnames.ora no copiado automáticamente."
    fi
done

# ---------------------------------------------- ORACLE_HOSTNAME en c1 ---
log "Configurando ORACLE_HOSTNAME en ${C1_NAME}..."
docker exec "${C1_NAME}" bash -c \
    "grep -q 'ORACLE_HOSTNAME=h1-bdd-proy-eam' /etc/profile.d/99-custom-env.sh 2>/dev/null || \
     echo 'export ORACLE_HOSTNAME=h1-bdd-proy-eam' >> /etc/profile.d/99-custom-env.sh"
ok "ORACLE_HOSTNAME=h1-bdd-proy-eam en ${C1_NAME}."

log "Configurando ORACLE_HOSTNAME en ${C2_NAME}..."
docker exec "${C2_NAME}" bash -c \
    "grep -q 'ORACLE_HOSTNAME=h2-bdd-proy-eam' /etc/profile.d/99-custom-env.sh 2>/dev/null || \
     echo 'export ORACLE_HOSTNAME=h2-bdd-proy-eam' >> /etc/profile.d/99-custom-env.sh"
ok "ORACLE_HOSTNAME=h2-bdd-proy-eam en ${C2_NAME}."

# ------------------------------------------- listener.ora en cada contenedor ---
_write_listener() {
    local container="$1" oracle_host="$2"
    log "Escribiendo listener.ora en ${container}..."
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
    ok "listener.ora configurado en ${container}."
}

_write_listener "${C1_NAME}" "${C1_HOST}"
_write_listener "${C2_NAME}" "${C2_HOST}"

# ------------------------------------------- validar ping entre nodos ---
log "Validando ping ${C1_NAME} → ${C2_NAME}..."
if docker exec "${C1_NAME}" ping -c 2 -W 2 "${C2_HOST}" &>/dev/null; then
    ok "Ping ${C1_HOST} → ${C2_HOST}: OK"
else
    warn "Ping ${C1_HOST} → ${C2_HOST}: FALLO (verificar /etc/hosts)"
fi

log "Validando ping ${C2_NAME} → ${C1_NAME}..."
if docker exec "${C2_NAME}" ping -c 2 -W 2 "${C1_HOST}" &>/dev/null; then
    ok "Ping ${C2_HOST} → ${C1_HOST}: OK"
else
    warn "Ping ${C2_HOST} → ${C1_HOST}: FALLO (verificar /etc/hosts)"
fi

echo ""
echo "=================================================="
echo " Infraestructura Docker lista."
echo " Próximo paso: bash 02-oracle-config.sh"
echo "=================================================="
