#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run-parte-4.sh
# Autor       : erick
# Fecha        : 2026-06-08
# Descripcion  : Descomprime el paquete oficial carga-inicial, configura
#                 soporte BLOB y ejecuta la carga base de la Parte 4 para iLap.
# Uso          : run-parte-4.sh [-v|--validate] [SYS_PASS]
#                  -v / --validate  Ejecuta las validaciones del PDF en su punto
#                                   exacto: Presentacion 4 (INSERT+replicacion)
#                                   tras la carga, luego Presentacion 5 (DELETE)
#                                   y Presentacion 6 (validacion DELETE) en las 4
#                                   PDBs. ATENCION: la validacion de DELETE deja
#                                   la BDD vacia.
# ---------------------------------------------------------------------------
set -euo pipefail

C1="c1-bdd-proy-eam"
C2="c2-bdd-proy-eam"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../../carga-inicial"
PHASE1_DIR="${SCRIPT_DIR}/fase-1-soporte-blob"
PHASE2_DIR="${SCRIPT_DIR}/fase-2-presentacion"
PART3_TRIGGER_DIR="${SCRIPT_DIR}/../parte-3/fase-3-triggers"
STAGE_ROOT="/tmp/bdd/proyecto-final/workdir"
STAGE_PHASE2_DIR="${STAGE_ROOT}/entregables/parte-4/fase-2-presentacion"
PDB_DEMO="${PDB_DEMO:-eambdd_s1}"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_STAMP="${PARTE4_LOG_STAMP:-$(date +%Y%m%d-%H%M%S)}"
RUN_LOG="${LOG_DIR}/run-parte-4-${LOG_STAMP}.log"
_GLOBAL_T0=$(date +%s)

# Tecnica vigente del proyecto para fragmentar servicio_laptop (Presentacion 4).
SERVICIO_LAPTOP_TECNICA="S"
PDB_LIST=(eambdd_s1 eambdd_s2 eambdd_s3 eambdd_s4)

# Procesa la flag de validacion sin romper el argumento posicional SYS_PASS.
RUN_VALIDATIONS=false
POSITIONAL_ARGS=()
while [ $# -gt 0 ]; do
    case "$1" in
        -v|--validate)
            RUN_VALIDATIONS=true
            shift
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done
if [ ${#POSITIONAL_ARGS[@]} -gt 0 ]; then
    set -- "${POSITIONAL_ARGS[@]}"
else
    set --
fi

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYA='\033[0;36m'
BLU='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'

log()  { echo -e "  ${CYA}[INFO]${RST}  $*"; }
ok()   { echo -e "  ${GRN}[OK]${RST}    $*"; }
warn() { echo -e "  ${YEL}[WARN]${RST}  $*"; }
die()  { echo -e "  ${RED}[ERROR]${RST} $*" >&2; exit 1; }
step() { echo ""; echo -e "${BOLD}${BLU}▶ $*${RST}"; }

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

require_command() {
    local name="$1"
    command -v "${name}" >/dev/null 2>&1 || die "No se encontro el comando requerido: ${name}"
}

log_container_state() {
    local container="$1"
    local inspect_output

    inspect_output=$(docker inspect "${container}" \
        --format 'name={{.Name}} status={{.State.Status}} running={{.State.Running}} started={{.State.StartedAt}}' 2>/dev/null) \
        || die "No fue posible inspeccionar el contenedor ${container}"

    log "Estado de ${container}: ${inspect_output}"
}

run_logged_command() {
    local step_name="$1"
    local step_log="${LOG_DIR}/${step_name}-${LOG_STAMP}.log"
    local started_at
    local step_t0
    shift

    started_at="$(timestamp)"
    step_t0=$(date +%s)

    log "Iniciando ${step_name} a las ${started_at}"
    log "Log persistente: ${step_log}"
    log "Comando: $*"
    {
        echo "===== ${step_name} ====="
        echo "Inicio: ${started_at}"
        echo "Comando: $*"
    } >> "${step_log}"

    set +e
    "$@" 2>&1 | tee -a "${step_log}"
    local rc=${PIPESTATUS[0]}
    set -e

    local elapsed=$(( $(date +%s) - step_t0 ))
    if [ ${rc} -eq 0 ]; then
        echo "Fin: $(timestamp)" >> "${step_log}"
        echo "Resultado: OK (${elapsed}s)" >> "${step_log}"
        ok "${step_name} finalizo en ${elapsed}s."
    else
        echo "Fin: $(timestamp)" >> "${step_log}"
        echo "Resultado: ERROR rc=${rc} (${elapsed}s)" >> "${step_log}"
        warn "${step_name} fallo tras ${elapsed}s con codigo ${rc}."
        die "${step_name} fallo. Revisa ${step_log}"
    fi

    return 0
}

prepare_image_source() {
    local name="$1"
    local zip_path="${DATA_DIR}/${name}.zip"
    local dir_path="${DATA_DIR}/${name}"
    local prefix="$2"
    local match_count

    if [[ -d "${dir_path}" ]]; then
        log "Usando directorio existente ${dir_path}"
    elif [[ -f "${zip_path}" ]]; then
        require_command unzip
        log "Descomprimiendo ${name}.zip"
        unzip -oq "${zip_path}" -d "${DATA_DIR}"
    else
        die "No existe ${zip_path} ni ${dir_path}"
    fi

    [[ -f "${dir_path}/${prefix}1.png" ]] || die "No se encontro ${dir_path}/${prefix}1.png"
    match_count=$(find "${dir_path}" -maxdepth 1 -type f -name "${prefix}*.png" | wc -l | tr -d ' ')
    [ "${match_count}" -gt 0 ] || die "No se encontraron imagenes ${prefix}*.png en ${dir_path}"
    log "Fuente ${name}: ${match_count} archivos ${prefix}*.png disponibles en ${dir_path}"
}

sync_png_payload() {
    local container="$1"
    local source_dir="$2"
    local prefix="$3"
    local target_dir="$4"
    local match_count

    match_count=$(find "${source_dir}" -maxdepth 1 -type f -name "${prefix}*.png" | wc -l | tr -d ' ')
    [ "${match_count}" -gt 0 ] || die "No hay archivos ${prefix}*.png para copiar desde ${source_dir}"

    log "Sincronizando ${match_count} archivos ${prefix}*.png hacia ${container}:${target_dir}"
    docker exec "${container}" find "${target_dir}" -maxdepth 1 -type f -name "${prefix}*.png" -delete
    (cd "${source_dir}" && tar -cf - ${prefix}*.png) | docker exec -i "${container}" tar -xf - -C "${target_dir}"
}

stage_sql_assets() {
    local container="$1"

    log "Preparando arbol SQL en ${container}"
    docker exec "${container}" rm -rf "${STAGE_ROOT}"
    docker exec "${container}" mkdir -p "${STAGE_ROOT}/entregables/parte-4" "${STAGE_ROOT}/entregables/parte-3"

    log "Copiando fase-2-presentacion a ${container}"
    docker cp "${PHASE2_DIR}" "${container}:${STAGE_ROOT}/entregables/parte-4/"

    log "Copiando triggers de Parte 3 a ${container}"
    docker cp "${PART3_TRIGGER_DIR}" "${container}:${STAGE_ROOT}/entregables/parte-3/"

    log "Copiando carga-inicial a ${container}"
    docker cp "${DATA_DIR}" "${container}:${STAGE_ROOT}/"

    docker exec "${container}" chmod -R a+rX "${STAGE_ROOT}"
    log "Arbol staged en ${container}: ${STAGE_ROOT}"
}

run_validation_plb() {
    # Ejecuta un validador .plb interactivo alimentando sus prompts por stdin.
    # stdin_payload usa \n para separar las respuestas (PDB y, si aplica, tecnica).
    local plb="$1"
    local stdin_payload="$2"

    printf '%b' "${stdin_payload}" \
        | docker exec -i "${C1}" su - oracle -c "cd '${STAGE_PHASE2_DIR}' && sqlplus /nolog @${plb}"
}

mkdir -p "${LOG_DIR}"
touch "${RUN_LOG}"
exec > >(tee -a "${RUN_LOG}") 2>&1

require_command docker
require_command find
require_command tar

echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   ORQUESTADOR · Proyecto Final Parte 4 — BDD iLap    ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""
log "Log general de la ejecucion: ${RUN_LOG}"
log "Timestamp: $(timestamp)"
log "Workspace local: ${SCRIPT_DIR}"
log "Directorio carga-inicial: ${DATA_DIR}"
log "Directorio SQL fase 1: ${PHASE1_DIR}"
log "Directorio SQL fase 2: ${PHASE2_DIR}"
log "Stage root en contenedores: ${STAGE_ROOT}"
log "PDB demo objetivo: ${PDB_DEMO}"

if [ $# -ge 1 ]; then
    SYS_PASS_VALUE="$1"
    log "Password de SYS recibido como argumento de linea de comandos."
elif [ -n "${SYS_PASS:-}" ]; then
    SYS_PASS_VALUE="${SYS_PASS}"
    log "Password de SYS recibido mediante la variable de entorno SYS_PASS."
else
    echo -e "  ${YEL}[INPUT]${RST}  Se requiere el password de SYS para la fase de soporte BLOB."
    read -rsp "           Password de SYS: " SYS_PASS_VALUE
    echo ""
fi

[ -z "${SYS_PASS_VALUE}" ] && die "El password de SYS no puede estar vacio."

for container in "${C1}" "${C2}"; do
    [ "$(docker inspect "${container}" --format '{{.State.Running}}' 2>/dev/null)" = "true" ] \
        || die "Contenedor ${container} no esta corriendo."
    log_container_state "${container}"
done

step "Preparando paquete oficial carga-inicial"
prepare_image_source laptops lap
prepare_image_source facturas fa
ok "Paquete oficial descomprimido y depurado."

step "Preparando archivos oficiales para BLOB"
for container in "${C1}" "${C2}"; do
    log "Creando directorios destino en ${container}"
    docker exec "${container}" mkdir -p /tmp/bdd/proyecto-final/imagenes/laptops /tmp/bdd/proyecto-final/imagenes/facturas
    sync_png_payload "${container}" "${DATA_DIR}/laptops" lap /tmp/bdd/proyecto-final/imagenes/laptops
    sync_png_payload "${container}" "${DATA_DIR}/facturas" fa /tmp/bdd/proyecto-final/imagenes/facturas
done
ok "Archivos oficiales copiados en ambos contenedores."

step "Preparando scripts SQL dentro de los contenedores"
for container in "${C1}" "${C2}"; do
    stage_sql_assets "${container}"
done
ok "Scripts SQL y carga-inicial disponibles dentro de los contenedores."

step "Configurando soporte BLOB"
run_logged_command \
    "07-run-soporte-blobs" \
    env PARTE4_LOG_DIR="${LOG_DIR}" PARTE4_LOG_STAMP="${LOG_STAMP}" SYS_PASS="${SYS_PASS_VALUE}" \
    bash "${PHASE1_DIR}/07-run-soporte-blobs.sh" "${SYS_PASS_VALUE}"

step "Limpiando carga previa para permitir reejecucion"
run_logged_command \
    "s-08-ilap-presentacion-5" \
    docker exec -i "${C1}" su - oracle -c "cd '${STAGE_PHASE2_DIR}' && sqlplus /nolog @s-08-ilap-presentacion-5.sql ${PDB_DEMO}"

step "Cargando catalogo manual STATUS_LAPTOP"
run_logged_command \
    "s-08-ilap-presentacion-2" \
    docker exec -i "${C1}" su - oracle -c "cd '${STAGE_PHASE2_DIR}' && sqlplus /nolog @s-08-ilap-presentacion-2.sql"

step "Insertando carga inicial oficial mediante transparencia"
run_logged_command \
    "s-08-ilap-presentacion-3" \
    docker exec -i "${C1}" su - oracle -c "cd '${STAGE_PHASE2_DIR}' && sqlplus /nolog @s-08-ilap-presentacion-3.sql ${PDB_DEMO}"

ok "Parte 4 preparada con la carga inicial oficial."

if [ "${RUN_VALIDATIONS}" = "true" ]; then
    step "Validando INSERT y datos replicados (Presentacion 4) en las 4 PDBs"
    for pdb in "${PDB_LIST[@]}"; do
        run_logged_command \
            "s-08-ilap-presentacion-4-${pdb}" \
            run_validation_plb s-08-ilap-presentacion-4.plb "${pdb}\n${SERVICIO_LAPTOP_TECNICA}\n"
    done
    ok "Validacion de INSERT completada en las 4 PDBs."

    step "Eliminando datos para validar transparencia de DELETE (Presentacion 5)"
    run_logged_command \
        "s-08-ilap-presentacion-5-validacion" \
        docker exec -i "${C1}" su - oracle -c "cd '${STAGE_PHASE2_DIR}' && sqlplus /nolog @s-08-ilap-presentacion-5.sql ${PDB_DEMO}"

    step "Validando DELETE (Presentacion 6) en las 4 PDBs"
    for pdb in "${PDB_LIST[@]}"; do
        run_logged_command \
            "s-08-ilap-presentacion-6-${pdb}" \
            run_validation_plb s-08-ilap-presentacion-6.plb "${pdb}\n"
    done
    ok "Validacion de DELETE completada en las 4 PDBs."
    warn "La validacion de DELETE (Presentacion 6) dejo la BDD vacia."
    warn "Para repoblar, ejecuta de nuevo run-parte-4.sh (sin --validate)."
fi

_total=$(( $(date +%s) - _GLOBAL_T0 ))

echo ""
echo -e "${GRN}${BOLD}Resumen:${RST}"
echo -e "  ${DIM}- Tiempo total: ${_total}s${RST}"
echo -e "  ${DIM}- Log general: ${RUN_LOG}${RST}"
echo -e "  ${DIM}- PDB demo: ${PDB_DEMO}${RST}"
if [ "${RUN_VALIDATIONS}" = "true" ]; then
    echo -e "  ${DIM}- Validaciones ejecutadas: Presentacion 4 (INSERT) y 6 (DELETE) en las 4 PDBs${RST}"
    echo -e "${GRN}${BOLD}Siguiente comando recomendado:${RST}"
    echo -e "  ${DIM}- Repoblar la BDD (la validacion DELETE la dejo vacia):  bash ${SCRIPT_DIR}/run-parte-4.sh${RST}"
else
    echo -e "${GRN}${BOLD}Siguientes comandos recomendados:${RST}"
    echo -e "  ${DIM}0) Validar todo automaticamente:  bash ${SCRIPT_DIR}/run-parte-4.sh --validate${RST}"
    echo -e "  ${DIM}1) Validar inserts:  docker exec -it ${C1} su - oracle -c \"cd '${STAGE_PHASE2_DIR}' && sqlplus /nolog @s-08-ilap-presentacion-4.plb\"${RST}"
    echo -e "  ${DIM}2) Limpiar carga:    docker exec -it ${C1} su - oracle -c \"cd '${STAGE_PHASE2_DIR}' && sqlplus /nolog @s-08-ilap-presentacion-5.sql ${PDB_DEMO}\"${RST}"
    echo -e "  ${DIM}3) Validar delete:  docker exec -it ${C1} su - oracle -c \"cd '${STAGE_PHASE2_DIR}' && sqlplus /nolog @s-08-ilap-presentacion-6.plb\"${RST}"
fi
echo ""