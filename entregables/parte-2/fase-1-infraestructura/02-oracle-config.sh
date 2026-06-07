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

log()  { echo "[INFO]  $*"; }
ok()   { echo "[OK]    $*"; }
warn() { echo "[WARN]  $*"; }
die()  { echo "[ERROR] $*" >&2; exit 1; }

# -------------------------------------------------------- helpers --------
_container_running() {
    [ "$(docker inspect "$1" --format '{{.State.Running}}' 2>/dev/null)" = "true" ]
}

_oracle_exec() {
    # Ejecuta SQL*Plus como oracle dentro del contenedor indicado
    local container="$1"; shift
    docker exec "${container}" su - oracle -c "sqlplus -s /nolog <<'SQLEOF'
$*
SQLEOF"
}

_oracle_exec_file() {
    local container="$1" sqlfile="$2"
    docker exec -i "${container}" su - oracle -c "sqlplus -s /nolog" < "${sqlfile}"
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

_wait_oracle() {
    local container="$1"
    local max=30 i=0
    log "Esperando que Oracle CDB esté disponible en ${container}..."
    while [ $i -lt $max ]; do
        if docker exec "${container}" su - oracle -c \
            "sqlplus -s / as sysdba <<'EOF'
set heading off feedback off
select 'UP' from dual;
exit;
EOF" 2>/dev/null | grep -q "UP"; then
            ok "Oracle CDB listo en ${container}."
            return 0
        fi
        sleep 5; i=$((i+1))
        echo -n "."
    done
    echo ""
    die "Oracle no respondió en ${container} después de $((max*5)) segundos."
}

# ================================================== CONTENEDOR 1 =========
log "=== Configurando Oracle en ${C1} ==="
_container_running "${C1}" || die "Contenedor ${C1} no está corriendo. Ejecuta 01-docker-up.sh primero."

log "Iniciando Oracle CDB en ${C1}..."
docker exec "${C1}" su - oracle -c \
    "lsnrctl status > /dev/null 2>&1 || lsnrctl start" 2>/dev/null || true
docker exec "${C1}" su - oracle -c \
    "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror continue
startup;
alter pluggable database all open;
alter pluggable database all save state;
exit;
EOF" 2>/dev/null || true

_wait_oracle "${C1}"

# Verificar eambdd_s1 y eambdd_s2
for pdb in eambdd_s1 eambdd_s2; do
    if _check_pdb_exists "${C1}" "${pdb}"; then
        ok "PDB ${pdb} existe en ${C1}."
    else
        warn "PDB ${pdb} NO encontrada en ${C1}. Puede requerir creación manual."
    fi
done

# ================================================== CONTENEDOR 2 =========
log "=== Configurando Oracle en ${C2} ==="
_container_running "${C2}" || die "Contenedor ${C2} no está corriendo. Ejecuta 01-docker-up.sh primero."

log "Iniciando Oracle CDB en ${C2}..."
docker exec "${C2}" su - oracle -c \
    "lsnrctl status > /dev/null 2>&1 || lsnrctl start" 2>/dev/null || true
docker exec "${C2}" su - oracle -c \
    "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror continue
startup;
exit;
EOF" 2>/dev/null || true

_wait_oracle "${C2}"

# ----- Determinar si necesitamos crear s3/s4 en c2 ----------------------
S3_EXISTS=false; S4_EXISTS=false
_check_pdb_exists "${C2}" "eambdd_s3" && S3_EXISTS=true
_check_pdb_exists "${C2}" "eambdd_s4" && S4_EXISTS=true

if ${S3_EXISTS} && ${S4_EXISTS}; then
    ok "PDBs eambdd_s3 y eambdd_s4 ya existen en ${C2}."
else
    log "Creando PDBs eambdd_s3 y/o eambdd_s4 en ${C2}..."

    # Eliminar PDBs copiadas del c1 si aún existen
    docker exec "${C2}" su - oracle -c "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror continue
alter pluggable database eambdd_s1 close immediate;
drop pluggable database eambdd_s1 including datafiles;
alter pluggable database eambdd_s2 close immediate;
drop pluggable database eambdd_s2 including datafiles;
exit;
EOF" 2>/dev/null || true

    # Limpiar directorios residuales
    docker exec "${C2}" su - oracle -c \
        "rm -rf /opt/oracle/oradata/FREE/eambdd_s1 \
                /opt/oracle/oradata/FREE/eambdd_s2 2>/dev/null || true"

    # Crear eambdd_s3
    if ! ${S3_EXISTS}; then
        log "Creando eambdd_s3..."
        docker exec "${C2}" su - oracle -c "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror exit failure
create pluggable database eambdd_s3
  admin user admin identified by admin
  file_name_convert = (
    '/opt/oracle/oradata/FREE/pdbseed',
    '/opt/oracle/oradata/FREE/eambdd_s3'
  );
exit;
EOF"
        ok "PDB eambdd_s3 creada."
    fi

    # Crear eambdd_s4
    if ! ${S4_EXISTS}; then
        log "Creando eambdd_s4..."
        docker exec "${C2}" su - oracle -c "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror exit failure
create pluggable database eambdd_s4
  admin user admin identified by admin
  file_name_convert = (
    '/opt/oracle/oradata/FREE/pdbseed',
    '/opt/oracle/oradata/FREE/eambdd_s4'
  );
exit;
EOF"
        ok "PDB eambdd_s4 creada."
    fi

    # Abrir todas y guardar estado
    log "Abriendo PDBs y guardando estado..."
    docker exec "${C2}" su - oracle -c "sqlplus -s / as sysdba <<'EOF'
whenever sqlerror continue
alter pluggable database all open;
alter pluggable database all save state;
exit;
EOF"

    # Crear tablespace USERS en cada nueva PDB
    for pdb in eambdd_s3 eambdd_s4; do
        log "Creando tablespace USERS en ${pdb}..."
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
        ok "Tablespace USERS creado en ${pdb}."
    done
fi

# Arrancar listener en c2 con la config actualizada
docker exec "${C2}" su - oracle -c \
    "lsnrctl stop 2>/dev/null; lsnrctl start" 2>/dev/null || true
ok "Listener reiniciado en ${C2}."

echo ""
echo "=================================================="
echo " Oracle configurado en ambos contenedores."
echo " Nodos disponibles:"
echo "   eambdd_s1, eambdd_s2  → ${C1}"
echo "   eambdd_s3, eambdd_s4  → ${C2}"
echo " Próximo paso: bash ../fase-2-usuarios/03-run-usuarios.sh"
echo "=================================================="
