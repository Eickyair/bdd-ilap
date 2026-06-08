-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Orquesta la creación de vistas globales y objetos auxiliares
--                 de soporte BLOB para las 4 PDBs de iLap.

clear screen
whenever oserror exit failure rollback;
whenever sqlerror exit rollback;

prompt ============================================
prompt Creando vistas para eambdd_s1
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s1
@@s-05-ilap-vistas.sql
@@s-05-ilap-tablas-temporales.sql
@@s-05-ilap-funciones-blob.sql
@@s-05-ilap-eam-s1-vistas-blob.sql

prompt ============================================
prompt Creando vistas para eambdd_s2
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s2
@@s-05-ilap-vistas.sql
@@s-05-ilap-tablas-temporales.sql
@@s-05-ilap-funciones-blob.sql
@@s-05-ilap-eam-s2-vistas-blob.sql

prompt ============================================
prompt Creando vistas para eambdd_s3
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s3
@@s-05-ilap-vistas.sql
@@s-05-ilap-tablas-temporales.sql
@@s-05-ilap-funciones-blob.sql
@@s-05-ilap-eam-s3-vistas-blob.sql

prompt ============================================
prompt Creando vistas para eambdd_s4
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s4
@@s-05-ilap-vistas.sql
@@s-05-ilap-tablas-temporales.sql
@@s-05-ilap-funciones-blob.sql
@@s-05-ilap-eam-s4-vistas-blob.sql

prompt Listo!
disconnect