-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Creación y validación de sinónimos lógicos para la Parte 3 de iLap.
--                 Los fragmentos se exponen como <tabla>_f<n> y las tablas
--                 replicadas como <tabla>_r<n>, ocultando la ubicación física
--                 real de cada fragmento o réplica.

whenever oserror exit failure rollback;
whenever sqlerror exit rollback;

prompt ====================================
prompt Creando sinónimos para eambdd_s1
prompt ====================================
connect ilap_bdd/ilap_bdd@eambdd_s1
@@s-04-ilap-eam-s1-sinonimos.sql
@@s-04-ilap-valida-sinonimos.sql

prompt ====================================
prompt Creando sinónimos para eambdd_s2
prompt ====================================
connect ilap_bdd/ilap_bdd@eambdd_s2
@@s-04-ilap-eam-s2-sinonimos.sql
@@s-04-ilap-valida-sinonimos.sql

prompt ====================================
prompt Creando sinónimos para eambdd_s3
prompt ====================================
connect ilap_bdd/ilap_bdd@eambdd_s3
@@s-04-ilap-eam-s3-sinonimos.sql
@@s-04-ilap-valida-sinonimos.sql

prompt ====================================
prompt Creando sinónimos para eambdd_s4
prompt ====================================
connect ilap_bdd/ilap_bdd@eambdd_s4
@@s-04-ilap-eam-s4-sinonimos.sql
@@s-04-ilap-valida-sinonimos.sql

prompt Listo!
disconnect