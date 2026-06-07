-- Autor       : erick
-- Fecha        : 2026-06-04
-- Descripción  : Creación de database links en los 4 nodos de la BDD.
--                 3 ligas por nodo, 12 en total. La comunicación es bidireccional.
--                 El nombre de cada liga es el nombre global de la PDB destino.
--                 No se especifican credenciales porque ilap_bdd existe en los 4 nodos.
--                 Ejecutar desde SQL*Plus con: sqlplus /nolog @s-02-ilap-ligas.sql

clear screen
whenever sqlerror exit rollback;

-- ============================================================
-- Ligas desde eambdd_s1 → s2, s3, s4
-- ============================================================
prompt ============================
prompt Creando ligas en eambdd_s1
prompt ============================
connect ilap_bdd/ilap_bdd@eambdd_s1

drop database link if exists eambdd_s2.fi.unam;
drop database link if exists eambdd_s3.fi.unam;
drop database link if exists eambdd_s4.fi.unam;

-- liga a PDB local (mismo contenedor)
create database link eambdd_s2.fi.unam using 'EAMBDD_S2';
-- ligas a PDBs remotas (contenedor 2)
create database link eambdd_s3.fi.unam using 'EAMBDD_S3';
create database link eambdd_s4.fi.unam using 'EAMBDD_S4';

-- ============================================================
-- Ligas desde eambdd_s2 → s1, s3, s4
-- ============================================================
prompt ============================
prompt Creando ligas en eambdd_s2
prompt ============================
connect ilap_bdd/ilap_bdd@eambdd_s2

drop database link if exists eambdd_s1.fi.unam;
drop database link if exists eambdd_s3.fi.unam;
drop database link if exists eambdd_s4.fi.unam;

-- liga a PDB local (mismo contenedor)
create database link eambdd_s1.fi.unam using 'EAMBDD_S1';
-- ligas a PDBs remotas (contenedor 2)
create database link eambdd_s3.fi.unam using 'EAMBDD_S3';
create database link eambdd_s4.fi.unam using 'EAMBDD_S4';

-- ============================================================
-- Ligas desde eambdd_s3 → s1, s2, s4
-- ============================================================
prompt ============================
prompt Creando ligas en eambdd_s3
prompt ============================
connect ilap_bdd/ilap_bdd@eambdd_s3

drop database link if exists eambdd_s1.fi.unam;
drop database link if exists eambdd_s2.fi.unam;
drop database link if exists eambdd_s4.fi.unam;

-- ligas a PDBs remotas (contenedor 1)
create database link eambdd_s1.fi.unam using 'EAMBDD_S1';
create database link eambdd_s2.fi.unam using 'EAMBDD_S2';
-- liga a PDB local (mismo contenedor)
create database link eambdd_s4.fi.unam using 'EAMBDD_S4';

-- ============================================================
-- Ligas desde eambdd_s4 → s1, s2, s3
-- ============================================================
prompt ============================
prompt Creando ligas en eambdd_s4
prompt ============================
connect ilap_bdd/ilap_bdd@eambdd_s4

drop database link if exists eambdd_s1.fi.unam;
drop database link if exists eambdd_s2.fi.unam;
drop database link if exists eambdd_s3.fi.unam;

-- ligas a PDBs remotas (contenedor 1)
create database link eambdd_s1.fi.unam using 'EAMBDD_S1';
create database link eambdd_s2.fi.unam using 'EAMBDD_S2';
-- liga a PDB local (mismo contenedor)
create database link eambdd_s3.fi.unam using 'EAMBDD_S3';

prompt Listo!
disconnect
