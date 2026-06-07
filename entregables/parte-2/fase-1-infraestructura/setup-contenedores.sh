#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# setup-contenedores.sh
# Autor       : erick
# Fecha        : 2026-06-04
# Descripción  : Configuración de infraestructura Docker para BDD distribuida
#                  (equipo individual, iniciales: eam).
#
# Topología:
#   Contenedor 1 (c1-bdd-proy-eam) — h1-bdd-proy-eam.fi.unam  172.20.0.21
#     PDBs: eambdd_s1 (Nodo 1/Norte), eambdd_s2 (Nodo 2/Este)
#   Contenedor 2 (c2-bdd-proy-eam) — h2-bdd-proy-eam.fi.unam  172.20.0.22
#     PDBs: eambdd_s3 (Nodo 3/Oeste), eambdd_s4 (Nodo 4/Sur)
#
# EJECUCIÓN:  Ejecutar cada bloque manualmente desde la máquina host.
# ---------------------------------------------------------------------------

# =============================================================================
# PASO A — Cerrar el contenedor de prácticas si está corriendo
# =============================================================================
# docker stop c1-bdd-eam

# =============================================================================
# PASO B — Crear imagen a partir del contenedor de prácticas
# =============================================================================
docker commit c1-bdd-eam bdd-eam:1.0

# =============================================================================
# PASO C — Crear la red Docker compartida para los dos contenedores
# =============================================================================
docker network create --subnet=172.20.0.0/16 bdd-proy-net

# =============================================================================
# PASO D — Crear los dos contenedores a partir de la imagen
# =============================================================================

# Contenedor 1 — aloja eambdd_s1 y eambdd_s2
docker run -i -t \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ${UNAM_HOME}:${UNAM_HOME} \
  --name c1-bdd-proy-eam \
  --hostname h1-bdd-proy-eam.fi.unam \
  --expose 1521 \
  --shm-size=2gb \
  --net=bdd-proy-net \
  --ip 172.20.0.21 \
  --add-host h2-bdd-proy-eam.fi.unam:172.20.0.22 \
  -e DISPLAY=$DISPLAY \
  bdd-eam:1.0 bash

# Contenedor 2 — alojará eambdd_s3 y eambdd_s4
docker run -i -t \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ${UNAM_HOME}:${UNAM_HOME} \
  --name c2-bdd-proy-eam \
  --hostname h2-bdd-proy-eam.fi.unam \
  --expose 1521 \
  --shm-size=2gb \
  --net=bdd-proy-net \
  --ip 172.20.0.22 \
  --add-host h1-bdd-proy-eam.fi.unam:172.20.0.21 \
  -e DISPLAY=$DISPLAY \
  bdd-eam:1.0 bash

# =============================================================================
# PASO E — Aliases en la máquina host para acceso rápido
# =============================================================================
# Agregar al archivo ~/.bashrc o ~/.zshrc:
#
# alias dockerBddProy1='docker start c1-bdd-proy-eam && docker attach c1-bdd-proy-eam'
# alias dockerBddProy1T='docker exec -it c1-bdd-proy-eam bash'
# alias dockerBddProy2='docker start c2-bdd-proy-eam && docker attach c2-bdd-proy-eam'
# alias dockerBddProy2T='docker exec -it c2-bdd-proy-eam bash'

# =============================================================================
# PASO F — Configuración /etc/profile.d/99-custom-env.sh dentro de cada
#           contenedor (ejecutar manualmente dentro de cada contenedor)
# =============================================================================
# --- En contenedor 1 (c1-bdd-proy-eam): ---
# export ORACLE_HOSTNAME=h1-bdd-proy-eam
#
# --- En contenedor 2 (c2-bdd-proy-eam): ---
# export ORACLE_HOSTNAME=h2-bdd-proy-eam

# =============================================================================
# PASO G — listener.ora  ($ORACLE_HOME/network/admin/listener.ora)
# =============================================================================
# --- Contenedor 1: ---
# LISTENER =
#   (DESCRIPTION_LIST =
#     (DESCRIPTION =
#       (ADDRESS = (PROTOCOL = TCP)(HOST = h1-bdd-proy-eam.fi.unam)(PORT = 1521))
#       (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
#     )
#   )
#
# --- Contenedor 2: ---
# LISTENER =
#   (DESCRIPTION_LIST =
#     (DESCRIPTION =
#       (ADDRESS = (PROTOCOL = TCP)(HOST = h2-bdd-proy-eam.fi.unam)(PORT = 1521))
#       (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
#     )
#   )

# =============================================================================
# PASO H — tnsnames.ora ($ORACLE_HOME/network/admin/tnsnames.ora)
#           Copiar el mismo archivo en AMBOS contenedores.
#           Ver archivo: tnsnames.ora (en este mismo directorio)
# =============================================================================

# =============================================================================
# PASO I — Crear PDBs eambdd_s3 y eambdd_s4 en el contenedor 2
#          (el contenedor 2 es réplica del 1 y trae eambdd_s1/s2 copiadas)
# =============================================================================
# Dentro del contenedor 2, conectar como sys en cdb$root y eliminar las PDBs
# copiadas, luego crear las nuevas.
#
# -- en el contenedor 2, como sys / sysdba:
# alter pluggable database eambdd_s1 close;
# drop pluggable database eambdd_s1 including datafiles;
# alter pluggable database eambdd_s2 close;
# drop pluggable database eambdd_s2 including datafiles;
#
# -- eliminar directorios (como usuario oracle del SO):
# rm -rf /opt/oracle/oradata/FREE/eambdd_s1 /opt/oracle/oradata/FREE/eambdd_s2
#
# -- crear las nuevas PDBs desde pdb$seed:
# create pluggable database eambdd_s3
#   admin user admin identified by admin
#   file_name_convert = (
#     '/opt/oracle/oradata/FREE/pdbseed',
#     '/opt/oracle/oradata/FREE/eambdd_s3'
#   );
# create pluggable database eambdd_s4
#   admin user admin identified by admin
#   file_name_convert = (
#     '/opt/oracle/oradata/FREE/pdbseed',
#     '/opt/oracle/oradata/FREE/eambdd_s4'
#   );
#
# -- abrir permanentemente:
# alter pluggable database all open;
# alter pluggable database all save state;
#
# -- crear tablespace users en cada nueva PDB:
# connect sys@eambdd_s3 as sysdba
# create tablespace users
#   datafile '/opt/oracle/oradata/FREE/eambdd_s3/users01.dbf' size 100m
#   autoextend on next 10m maxsize 11g
#   extent management local
#   segment space management auto;
# alter database default tablespace users;
#
# connect sys@eambdd_s4 as sysdba
# create tablespace users
#   datafile '/opt/oracle/oradata/FREE/eambdd_s4/users01.dbf' size 100m
#   autoextend on next 10m maxsize 11g
#   extent management local
#   segment space management auto;
# alter database default tablespace users;

# =============================================================================
# PASO J — Verificación de conectividad entre contenedores
# =============================================================================
# Desde contenedor 1:
#   ping h2-bdd-proy-eam.fi.unam
# Desde contenedor 2:
#   ping h1-bdd-proy-eam.fi.unam
