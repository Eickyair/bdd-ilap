#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 00-teardown-infra.sh
# Autor       : erick
# Fecha        : 2026-06-07
# Descripción  : Elimina los contenedores y la red Docker del proyecto iLap.
#                Solicita confirmación explícita antes de cada borrado.
#                PROHIBIDO tocar la imagen base bdd-eam:1.0 ni el
#                contenedor base c1-bdd-eam.
#
# Recursos que se eliminan:
#   Contenedores : c1-bdd-proy-eam  /  c2-bdd-proy-eam
#   Red          : bdd-proy-net (172.20.0.0/16)
#
# Recursos que NUNCA se tocan:
#   Imagen base  : bdd-eam:1.0
#   Contenedor   : c1-bdd-eam
#
# Casos de estado de contenedor manejados:
#   running     → docker stop -t 30 (timeout Oracle) + docker rm
#   exited      → docker rm directo
#   created     → docker rm directo (nunca arrancó)
#   paused      → docker unpause + docker stop -t 30 + docker rm
#   restarting  → docker update --restart=no + docker stop -t 10 + docker rm
#   dead        → docker rm -f
#   removing    → skip (ya en proceso de borrado)
#
# Caso de red con contenedores aún conectados:
#   Si algún contenedor sigue adjunto a bdd-proy-net, se desconecta
#   forzosamente antes de intentar docker network rm.
#
# Uso: bash 00-teardown-infra.sh
# ---------------------------------------------------------------------------

# No usar set -e globalmente: las operaciones de limpieza no deben abortar
# ante el primer fallo. Se controla el error en cada sección crítica.
set -uo pipefail

# ---------------------------------------------------------------- constantes
C1="c1-bdd-proy-eam"
C2="c2-bdd-proy-eam"
NETWORK="bdd-proy-net"
STOP_TIMEOUT=30        # segundos — Oracle necesita tiempo para cerrar limpio

PROTECTED_IMAGE="bdd-eam:1.0"
PROTECTED_CONTAINER="c1-bdd-eam"

# ------------------------------------------------------------------ colores
RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYA='\033[0;36m'
RST='\033[0m'

log()  { echo -e "${CYA}[INFO]${RST}  $*"; }
ok()   { echo -e "${GRN}[OK]${RST}    $*"; }
warn() { echo -e "${YEL}[WARN]${RST}  $*"; }
err()  { echo -e "${RED}[ERROR]${RST} $*" >&2; }

# -------------------------------------------- función: pedir confirmación
_confirm() {
    local prompt="$1"
    local answer
    echo ""
    echo -e "${YEL}${prompt}${RST}"
    read -rp "  Escribir 'si' para confirmar: " answer
    [ "${answer}" = "si" ]
}

# -------------------------------------------- funciones de estado Docker
_container_exists() {
    docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${1}$"
}

_network_exists() {
    docker network inspect "$1" &>/dev/null
}

_container_state() {
    docker inspect "$1" --format '{{.State.Status}}' 2>/dev/null || echo "unknown"
}

_restart_policy() {
    docker inspect "$1" --format '{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null || echo "no"
}

_network_containers() {
    # Devuelve los nombres de contenedores adjuntos a la red
    docker network inspect "$1" \
        --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | tr ' ' '\n' | grep -v '^$' || true
}

# --------------------------------- función principal: eliminar contenedor
_remove_container() {
    local name="$1"
    local state
    state=$(_container_state "${name}")

    log "Estado de ${name}: ${state}"

    case "${state}" in

        removing)
            warn "${name} ya está en proceso de borrado — se omite."
            return 0
            ;;

        dead)
            log "Forzando rm de contenedor muerto ${name}..."
            docker rm -f "${name}" && ok "${name} eliminado (force)." \
                || err "No se pudo eliminar ${name}."
            ;;

        paused)
            log "Reanudando contenedor pausado ${name}..."
            docker unpause "${name}" || true
            log "Deteniendo ${name} (timeout ${STOP_TIMEOUT}s)..."
            docker stop -t "${STOP_TIMEOUT}" "${name}" || true
            docker rm "${name}" && ok "${name} eliminado." \
                || { err "Fallo con rm; intentando rm -f..."; docker rm -f "${name}" && ok "${name} eliminado (force)."; }
            ;;

        restarting)
            # El daemon lo reinicia automáticamente; actualizar política antes de stop
            log "Actualizando restart policy de ${name} a 'no'..."
            docker update --restart=no "${name}" || true
            log "Deteniendo ${name}..."
            docker stop -t 10 "${name}" || true
            docker rm "${name}" && ok "${name} eliminado." \
                || { err "Fallo con rm; intentando rm -f..."; docker rm -f "${name}" && ok "${name} eliminado (force)."; }
            ;;

        running)
            log "Deteniendo ${name} (timeout ${STOP_TIMEOUT}s — Oracle necesita tiempo)..."
            docker stop -t "${STOP_TIMEOUT}" "${name}" || true
            docker rm "${name}" && ok "${name} eliminado." \
                || { err "Fallo con rm; intentando rm -f..."; docker rm -f "${name}" && ok "${name} eliminado (force)."; }
            ;;

        exited|created)
            log "Eliminando ${name} (ya detenido)..."
            docker rm "${name}" && ok "${name} eliminado." \
                || err "No se pudo eliminar ${name}."
            ;;

        unknown|*)
            warn "Estado desconocido para ${name}: '${state}'. Intentando rm -f..."
            docker rm -f "${name}" && ok "${name} eliminado (force)." \
                || err "No se pudo eliminar ${name}. Revisar manualmente."
            ;;
    esac
}

# ==================================================================== MAIN

echo ""
echo -e "${RED}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${RED}║        TEARDOWN — BDD iLap · Infraestructura         ║${RST}"
echo -e "${RED}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

# ------------------------------------------------- pre-flight: Docker ok?
if ! docker info &>/dev/null; then
    err "El daemon Docker no está disponible. Verifica que esté corriendo."
    exit 1
fi
ok "Docker daemon disponible."

# ------------------------------------------------- inventario de recursos
echo ""
echo -e "  Recursos que serán ${RED}ELIMINADOS${RST}:"
echo ""

TARGETS=()

for c in "${C1}" "${C2}"; do
    if _container_exists "${c}"; then
        state=$(_container_state "${c}")
        policy=$(_restart_policy "${c}")
        echo -e "    ${RED}✖${RST}  Contenedor : ${c}  [estado: ${state} | restart: ${policy}]"
        TARGETS+=("container:${c}")
    else
        echo -e "    ${YEL}–${RST}  Contenedor : ${c}  [no existe, se omite]"
    fi
done

if _network_exists "${NETWORK}"; then
    attached=$(_network_containers "${NETWORK}")
    extra=""
    [ -n "${attached}" ] && extra="  ${YEL}(contenedores adjuntos: ${attached})${RST}"
    echo -e "    ${RED}✖${RST}  Red        : ${NETWORK}  (172.20.0.0/16)${extra}"
    TARGETS+=("network:${NETWORK}")
else
    echo -e "    ${YEL}–${RST}  Red        : ${NETWORK}  [no existe, se omite]"
fi

echo ""
echo -e "  Recursos ${GRN}protegidos — NO se tocan${RST}:"
echo -e "    ${GRN}✔${RST}  Imagen base     : ${PROTECTED_IMAGE}"
echo -e "    ${GRN}✔${RST}  Contenedor base : ${PROTECTED_CONTAINER}"
echo ""

if [ ${#TARGETS[@]} -eq 0 ]; then
    ok "No hay recursos del proyecto que eliminar. Nada que hacer."
    exit 0
fi

# ------------------------------------------------- confirmación global
_confirm "¿Confirmar la eliminación de ${#TARGETS[@]} recurso(s) listado(s) arriba?" \
    || { echo "  Operación cancelada."; exit 0; }

echo ""

# ------------------------------------------------- eliminar contenedores
for c in "${C1}" "${C2}"; do
    _container_exists "${c}" || continue

    _confirm "Eliminar contenedor '${c}'?" \
        || { echo "  Se omite ${c}."; continue; }

    _remove_container "${c}"
done

# ------------------------------------------------- eliminar red
if _network_exists "${NETWORK}"; then

    _confirm "Eliminar red '${NETWORK}' (172.20.0.0/16)?" \
        || { echo "  Se omite la red."; }

    if _network_exists "${NETWORK}"; then
        # Desconectar cualquier contenedor aún adjunto (evita ORA-EBUSY en Docker)
        attached=$(_network_containers "${NETWORK}")
        if [ -n "${attached}" ]; then
            warn "Hay contenedores adjuntos a ${NETWORK}: ${attached}"
            log "Desconectando forzosamente antes de eliminar la red..."
            for attached_c in ${attached}; do
                docker network disconnect -f "${NETWORK}" "${attached_c}" && \
                    ok "Desconectado: ${attached_c}" || \
                    warn "No se pudo desconectar ${attached_c}"
            done
        fi

        log "Eliminando red ${NETWORK}..."
        docker network rm "${NETWORK}" && ok "Red ${NETWORK} eliminada." \
            || err "No se pudo eliminar la red ${NETWORK}. Revisar manualmente."
    fi
fi

# ------------------------------------------------- validación final
echo ""
echo -e "${GRN}══════════════════════════════════════════════════════${RST}"
echo -e "${GRN} Teardown completado.${RST}"
echo ""

if docker image inspect "${PROTECTED_IMAGE}" &>/dev/null; then
    ok "Imagen base ${PROTECTED_IMAGE} — intacta."
else
    warn "Imagen base ${PROTECTED_IMAGE} no encontrada (no fue tocada por este script)."
fi

if _container_exists "${PROTECTED_CONTAINER}"; then
    ok "Contenedor base ${PROTECTED_CONTAINER} — intacto."
else
    warn "Contenedor base ${PROTECTED_CONTAINER} no encontrado (no fue tocado por este script)."
fi

echo ""
echo -e "  Para recrear la infra: ${CYA}bash 01-docker-up.sh${RST}"
echo -e "${GRN}══════════════════════════════════════════════════════${RST}"
echo ""
