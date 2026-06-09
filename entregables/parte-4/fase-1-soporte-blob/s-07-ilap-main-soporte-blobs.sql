-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripcion  : Ejecuta la configuracion de soporte BLOB en las 4 PDBs de
--                 iLap.

whenever oserror exit failure rollback;
whenever sqlerror exit failure rollback;

prompt Configurando directorios y funcion fx_carga_blob.

prompt ============================================
prompt Configurando soporte BLOB para eambdd_s1
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s1
@@s-07-ilap-configuracion-soporte-blobs.sql

prompt ============================================
prompt Configurando soporte BLOB para eambdd_s2
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s2
@@s-07-ilap-configuracion-soporte-blobs.sql

prompt ============================================
prompt Configurando soporte BLOB para eambdd_s3
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s3
@@s-07-ilap-configuracion-soporte-blobs.sql

prompt ============================================
prompt Configurando soporte BLOB para eambdd_s4
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s4
@@s-07-ilap-configuracion-soporte-blobs.sql

prompt Listo!
disconnect