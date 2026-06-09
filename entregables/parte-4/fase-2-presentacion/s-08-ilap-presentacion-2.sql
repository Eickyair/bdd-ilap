-- Autor       : erick
-- Fecha        : 2026-06-08
-- Descripcion  : Carga manual del catalogo STATUS_LAPTOP oficial en las 4 PDBs
--                 de iLap conforme al flujo de la Presentacion 2.

whenever oserror exit failure rollback;
whenever sqlerror exit failure rollback;

prompt ======================================
prompt Cargando STATUS_LAPTOP de forma manual
prompt ======================================

prompt ======================================
prompt Cargando catalogo en eambdd_s1
prompt ======================================
connect ilap_bdd/ilap_bdd@eambdd_s1
delete from status_laptop;
@@../../../carga-inicial/status_laptop.sql
commit;

prompt ======================================
prompt Cargando catalogo en eambdd_s2
prompt ======================================
connect ilap_bdd/ilap_bdd@eambdd_s2
delete from status_laptop;
@@../../../carga-inicial/status_laptop.sql
commit;

prompt ======================================
prompt Cargando catalogo en eambdd_s3
prompt ======================================
connect ilap_bdd/ilap_bdd@eambdd_s3
delete from status_laptop;
@@../../../carga-inicial/status_laptop.sql
commit;

prompt ======================================
prompt Cargando catalogo en eambdd_s4
prompt ======================================
connect ilap_bdd/ilap_bdd@eambdd_s4
delete from status_laptop;
@@../../../carga-inicial/status_laptop.sql
commit;

prompt Listo!
exit