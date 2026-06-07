-- Autor       : erick
-- Fecha        : 2026-06-04
-- Descripción  : Creación de fragmentos en los 4 nodos de la BDD distribuida iLap.
--                 Orquesta la ejecución de los 4 scripts DDL individuales.
--                 Ejecutar desde SQL*Plus con: sqlplus /nolog @s-03-ilap-main-ddl.sql

clear screen
whenever sqlerror exit rollback;

prompt ====================================
prompt Creando fragmentos para eambdd_s1
prompt ====================================
connect ilap_bdd/ilap_bdd@eambdd_s1
@s-03-ilap-eam-s1-ddl.sql

prompt ====================================
prompt Creando fragmentos para eambdd_s2
prompt ====================================
connect ilap_bdd/ilap_bdd@eambdd_s2
@s-03-ilap-eam-s2-ddl.sql

prompt ====================================
prompt Creando fragmentos para eambdd_s3
prompt ====================================
connect ilap_bdd/ilap_bdd@eambdd_s3
@s-03-ilap-eam-s3-ddl.sql

prompt ====================================
prompt Creando fragmentos para eambdd_s4
prompt ====================================
connect ilap_bdd/ilap_bdd@eambdd_s4
@s-03-ilap-eam-s4-ddl.sql

prompt Listo!
disconnect
