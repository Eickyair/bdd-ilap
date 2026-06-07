#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 02-oracle-config.sh  — IDEMPOTENTE
# Autor       : erick
# Fecha        : 2026-06-04
# Descripción  : Inicia Oracle CDB en ambos contenedores y garantiza que
#                  los 4 nodos estén disponibles:
#                    c1-bdd-proy-eam → eambdd_s1, eambdd_s2
#                    c2-bdd-proy-eam → eambdd_s3, eambdd_s4
#
#                  En c2: elimina las PDBs copiadas (s1/s2) y crea s3/s4
#                  desde pdb$seed. Operación idempotente: si las PDBs ya
#                  existen con el nombre correcto, no las re-crea.
#
# Prerequisito: bash 01-docker-up.sh ejecutado correctamente.
# Uso: bash 02-oracle-config.sh
# ---------------------------------------------------------------------------
set -euo pipefail

C1="c1-bdd-proy-eam"
C2="c2-bdd-proy-eam"
C1_HOST="h1-bdd-proy-eam.fi.unam"
C2_HOST="h2-bdd-proy-eam.fi.unam"

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
timer()    { echo -e "  ${DIM}[TIME]${RST}  $*"; }

# ------------------------------------------------------------------ banner
echo ""
echo -e "${BOLD}${BLU}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BOLD}${BLU}║   FASE 1b · Configuración Oracle — BDD iLap          ║${RST}"
echo -e "${BOLD}${BLU}║   Proyecto iLap · Semestre 2026-2 · Operador: erick  ║${RST}"
echo -e "${BOLD}${BLU}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

# -------------------------------------------------------- helpers --------
_container_running() {
    [ "$(docker inspect "$1" --format '{{.State.Running}}' 2>/dev/null)" = "true" ]
}

_check_pdb_exists() {
    local container="$1" pdb_name="$2"
    local result
    result=$(docker exec "${container}" su - oracle -c \
        "sqlplus -s / as sysdba <<'EOF'
set heading off feedback off pagesize 0
select count(*) from v\$pdbs where lower(name)=lower('${pdb_name}');
exit;
EOF" 2>/dev/null | tr -d ' \n')
    [ "${result}" = "1" ]
}

_set_local_listener() {
    local container="$1" host="$2"

    log "Configurando LOCAL_LISTENER en ${container} → ${host}:1521 y forzando registro..."
    docker exec "${container}" su - oracle -c "sqlplus -s / as sysdba <<EOF
whenever sqlerror exit failure
alter system set local_listener='(ADDRESS=(PROTOCOL=TCP)(HOST=${host})(PORT=1521))' scope=both;
alter system register;
exit;
EOF" >/dev/null
    ok "LOCAL_LISTENER persistido en ${container} y servicios registrados en el listener local."
}

_wait_oracle() {
    local container="$1"
    local max=60 i=0
    local t0
    t0=$(date +%s)
    wait_msg "Esperando que Oracle CDB responda en ${container} (sondeo cada 5s, máximo $((max*5))s)..."
    echo -n "      "
    while [ $i -lt $max ]; do
        if docker exec "${container}" su - oracle -c \
            "sqlplus -s / as sysdba <<'EOF'
set heading off feedback off
select 'UP' from dual;
exit;
EOF" 2>/dev/null | grep -q "UP"; then
            local elapsed=$(( $(date +%s) - t0 ))
            echo ""
            ok "Oracle CDB disponible en ${container} — respondió tras ${elapsed}s."
            return 0
        fi
        sleep 5; i=$((i+1))
        echo -n "."
    done
    echo ""
    die "Oracle CDB no respondió en ${container} después de $((max*5))s. Revisa logs con: docker logs ${container}"
}

# ================================================== CONTENEDOR 1 =========
step "Contenedor 1 — ${C1}  (aloja eambdd_s1 + eambdd_s2)"
_container_running "${C1}" || die "Contenedor ${C1} no está corriendo. Ejecuta 01-docker-up.sh primero."

log "Verificando listener Oracle en ${C1}..."
docker exec "${C1}" su - oracle -c \
    "lsnrctl status > /dev/null 2>&1 || lsnrctl start" 2>/dev/null || true

wait_msg "Iniciando CDB FREE en ${C1} — startup puede tardar 2-4 min en frío (timeout: 360s)..."
_t0=$(date +%s)
set +e
timeout 360 docker exec "${C1}" su - oracle -c \
    "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror continue
startup;
alter pluggable database all open;
alter pluggable database all save state;
exit;
EOF" 2>/dev/null
_rc=$?
set -e
_elapsed=$(( $(date +%s) - _t0 ))
[ $_rc -eq 124 ] && die "Timeout (360s): startup del CDB en ${C1} no completó. Verifica con: docker exec ${C1} su - oracle -c 'sqlplus / as sysdba'"
timer "Comando startup completado en ${_elapsed}s."

_set_local_listener "${C1}" "${C1_HOST}"

_wait_oracle "${C1}"

step "Verificando PDBs en ${C1}"
for pdb in eambdd_s1 eambdd_s2; do
    if _check_pdb_exists "${C1}" "${pdb}"; then
        ok "PDB ${pdb} — encontrada y accesible."
    else
        warn "PDB ${pdb} NO encontrada en ${C1}. Puede requerir creación manual."
    fi
done

# ================================================== CONTENEDOR 2 =========
step "Contenedor 2 — ${C2}  (alojará eambdd_s3 + eambdd_s4)"
_container_running "${C2}" || die "Contenedor ${C2} no está corriendo. Ejecuta 01-docker-up.sh primero."

log "Verificando listener Oracle en ${C2}..."
docker exec "${C2}" su - oracle -c \
    "lsnrctl status > /dev/null 2>&1 || lsnrctl start" 2>/dev/null || true

wait_msg "Iniciando CDB FREE en ${C2} — startup puede tardar 2-4 min en frío (timeout: 360s)..."
_t0=$(date +%s)
set +e
timeout 360 docker exec "${C2}" su - oracle -c \
    "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror continue
startup;
exit;
EOF" 2>/dev/null
_rc=$?
set -e
_elapsed=$(( $(date +%s) - _t0 ))
[ $_rc -eq 124 ] && die "Timeout (360s): startup del CDB en ${C2} no completó. Verifica con: docker exec ${C2} su - oracle -c 'sqlplus / as sysdba'"
timer "Comando startup completado en ${_elapsed}s."

_set_local_listener "${C2}" "${C2_HOST}"

_wait_oracle "${C2}"

# ----- Determinar si necesitamos crear s3/s4 en c2 ----------------------
step "PDBs propias en ${C2}  (eambdd_s3, eambdd_s4)"
S3_EXISTS=false; S4_EXISTS=false
_check_pdb_exists "${C2}" "eambdd_s3" && S3_EXISTS=true
_check_pdb_exists "${C2}" "eambdd_s4" && S4_EXISTS=true

if ${S3_EXISTS} && ${S4_EXISTS}; then
    ok "eambdd_s3 y eambdd_s4 ya existen en ${C2} — no se recrean."
else
    log "Una o ambas PDBs de nodos 3/4 no existen. Iniciando proceso de creación..."

    # Eliminar PDBs copiadas del c1 si aún existen (s1/s2 no deben estar en c2)
    log "Cerrando y eliminando PDBs heredadas eambdd_s1/s2 en ${C2} (si existen)..."
    docker exec "${C2}" su - oracle -c "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror continue
alter pluggable database eambdd_s1 close immediate;
drop pluggable database eambdd_s1 including datafiles;
alter pluggable database eambdd_s2 close immediate;
drop pluggable database eambdd_s2 including datafiles;
exit;
EOF" 2>/dev/null || true

    # Limpiar directorios residuales
    log "Eliminando directorios de datos residuales de eambdd_s1/s2 en ${C2}..."
    docker exec "${C2}" su - oracle -c \
        "rm -rf /opt/oracle/oradata/FREE/eambdd_s1 \
                /opt/oracle/oradata/FREE/eambdd_s2 2>/dev/null || true"
    ok "PDBs heredadas eliminadas — espacio liberado en ${C2}."

    # Crear eambdd_s3
    if ! ${S3_EXISTS}; then
        wait_msg "Creando PDB eambdd_s3 desde pdb\$seed — copia ~500 MB de datafiles (timeout: 360s)..."
        _t0=$(date +%s)
        set +e
        timeout 360 docker exec "${C2}" su - oracle -c "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror exit failure
create pluggable database eambdd_s3
  admin user admin identified by admin
  file_name_convert = (
    '/opt/oracle/oradata/FREE/pdbseed',
    '/opt/oracle/oradata/FREE/eambdd_s3'
  );
exit;
EOF"
        _rc=$?
        set -e
        _elapsed=$(( $(date +%s) - _t0 ))
        [ $_rc -eq 124 ] && die "Timeout (360s): CREATE PLUGGABLE DATABASE eambdd_s3 no completó. Verifica espacio en disco y que pdb\$seed no esté bloqueado."
        [ $_rc -ne 0 ]   && die "Error al crear eambdd_s3 (código: ${_rc}). Revisa la salida anterior."
        ok "PDB eambdd_s3 creada en ${_elapsed}s → /opt/oracle/oradata/FREE/eambdd_s3/"
    fi

    # Crear eambdd_s4
    if ! ${S4_EXISTS}; then
        wait_msg "Creando PDB eambdd_s4 desde pdb\$seed — copia ~500 MB de datafiles (timeout: 360s)..."
        _t0=$(date +%s)
        set +e
        timeout 360 docker exec "${C2}" su - oracle -c "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror exit failure
create pluggable database eambdd_s4
  admin user admin identified by admin
  file_name_convert = (
    '/opt/oracle/oradata/FREE/pdbseed',
    '/opt/oracle/oradata/FREE/eambdd_s4'
  );
exit;
EOF"
        _rc=$?
        set -e
        _elapsed=$(( $(date +%s) - _t0 ))
        [ $_rc -eq 124 ] && die "Timeout (360s): CREATE PLUGGABLE DATABASE eambdd_s4 no completó."
        [ $_rc -ne 0 ]   && die "Error al crear eambdd_s4 (código: ${_rc}). Revisa la salida anterior."
        ok "PDB eambdd_s4 creada en ${_elapsed}s → /opt/oracle/oradata/FREE/eambdd_s4/"
    fi

    # Abrir todas y guardar estado
    wait_msg "Abriendo todas las PDBs y guardando estado persistente (timeout: 120s)..."
    _t0=$(date +%s)
    set +e
    timeout 120 docker exec "${C2}" su - oracle -c "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror continue
alter pluggable database all open;
alter pluggable database all save state;
exit;
EOF"
    _rc=$?
    set -e
    _elapsed=$(( $(date +%s) - _t0 ))
    [ $_rc -eq 124 ] && die "Timeout (120s): ALTER PLUGGABLE DATABASE ALL OPEN no completó."
    ok "Todas las PDBs abiertas y estado guardado (${_elapsed}s) — se reabrirán automáticamente al reiniciar el CDB."

    # Crear tablespace USERS en cada nueva PDB
    for pdb in eambdd_s3 eambdd_s4; do
        log "Creando tablespace USERS en ${pdb}..."
        log "  Datafile: /opt/oracle/oradata/FREE/${pdb}/users01.dbf (100 MB inicial, autoextend hasta 11 GB)"
        docker exec "${C2}" su - oracle -c "sqlplus -s / as sysdba <<EOF
whenever sqlerror continue
alter session set container=${pdb};
create tablespace users
  datafile '/opt/oracle/oradata/FREE/${pdb}/users01.dbf' size 100m
  autoextend on next 10m maxsize 11g
  extent management local
  segment space management auto;
alter database default tablespace users;
exit;
EOF"
        ok "Tablespace USERS listo en ${pdb}."
    done
fi

# Reiniciar listener en c2 con configuración actualizada
step "Listener en ${C2} — reiniciar para registrar eambdd_s3/s4"
log "Deteniendo listener actual y reiniciando para que los nuevos nodos sean visibles por TNS..."
docker exec "${C2}" su - oracle -c \
    "lsnrctl stop 2>/dev/null; lsnrctl start" 2>/dev/null || true
_set_local_listener "${C2}" "${C2_HOST}"
ok "Listener reiniciado en ${C2} — eambdd_s3 y eambdd_s4 disponibles en TNS."

# ---------------------------------------------------------------- resumen
echo ""
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "${GRN}${BOLD}  FASE 1b completada — Oracle disponible en 4 nodos${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "  eambdd_s1 ${DIM}(Norte · Procesamiento)${RST}  → ${C1}"
echo -e "  eambdd_s2 ${DIM}(Este · Almacenamiento)${RST}   → ${C1}"
echo -e "  eambdd_s3 ${DIM}(Oeste · Seguridad)${RST}       → ${C2}"
echo -e "  eambdd_s4 ${DIM}(Sur · Imágenes)${RST}          → ${C2}"
echo -e "  ${DIM}Próximo paso: bash ../fase-2-usuarios/03-run-usuarios.sh${RST}"
echo -e "${GRN}${BOLD}══════════════════════════════════════════════════════${RST}"
echo ""
