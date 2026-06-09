-- Autor       : erick
-- Fecha        : 2026-06-08
-- Descripcion  : Carga inicial oficial con transparencia de distribucion y
--                 soporte BLOB conforme al flujo de la Presentacion 3.

define p_pdb = '&1'

whenever oserror exit failure rollback;
whenever sqlerror exit failure rollback;
set serveroutput on
set linesize 200

prompt ======================================
prompt Preparando carga de datos
prompt ======================================
prompt => Seleccionar la PDB para insertar datos
prompt => Asegurarse que las imagenes existen en ambos servidores
prompt => Ejecutar s-08-ilap-presentacion-3.sh en ambos antes de continuar
connect ilap_bdd/ilap_bdd@&&p_pdb

alter session set nls_date_format = 'yyyy-mm-dd hh24:mi:ss';

prompt Ejecutando copia local de imagenes de muestra
host bash s-08-ilap-presentacion-3.sh

prompt => Realizando limpieza inicial ....
set feedback off
prompt Eliminando datos de servicio_laptop
delete from servicio_laptop;
prompt Eliminando datos de historico_status_laptop
delete from historico_status_laptop;
prompt Eliminando datos de laptop_inventario
delete from laptop_inventario;
prompt Eliminando datos de laptop
delete from laptop;
prompt Eliminando datos de sucursal_taller
delete from sucursal_taller;
prompt Eliminando datos de sucursal_venta
delete from sucursal_venta;
prompt Eliminando datos de sucursal
delete from sucursal;
prompt Eliminando datos de tipo_monitor
delete from tipo_monitor;
prompt Eliminando datos de tipo_almacenamiento
delete from tipo_almacenamiento;
prompt Eliminando datos de tipo_tarjeta_video
delete from tipo_tarjeta_video;
prompt Eliminando datos de tipo_procesador
delete from tipo_procesador;
commit;

prompt Deshabilitando FK temporal de laptop_reemplazo_id en S4
connect ilap_bdd/ilap_bdd@eambdd_s4
alter table laptop_f4_eam_s4 disable constraint fk_laptop_f4_f5_remp;
commit;

prompt => Realizando carga de datos ....

prompt cargando tipo_tarjeta_video
connect ilap_bdd/ilap_bdd@&&p_pdb
alter session set nls_date_format = 'yyyy-mm-dd hh24:mi:ss';
@@../../../carga-inicial/tipo_tarjeta_video.sql

prompt cargando tipo_procesador
@@../../../carga-inicial/tipo_procesador.sql

prompt cargando tipo_monitor
@@../../../carga-inicial/tipo_monitor.sql

prompt cargando tipo_almacenamiento
@@../../../carga-inicial/tipo_almacenamiento.sql

prompt cargando sucursal
@@../../../carga-inicial/sucursal-1.sql
@@../../../carga-inicial/sucursal-2.sql
@@../../../carga-inicial/sucursal-3.sql

prompt cargando sucursal_taller
@@../../../carga-inicial/sucursal_taller-1.sql
@@../../../carga-inicial/sucursal_taller-2.sql

prompt cargando sucursal_venta
@@../../../carga-inicial/sucursal_venta-1.sql
@@../../../carga-inicial/sucursal_venta-2.sql

prompt cargando laptop (con datos BLOB)
@@../../../carga-inicial/laptop-1.sql
@@../../../carga-inicial/laptop-2.sql

prompt cargando laptop_inventario
@@../../../carga-inicial/laptop_inventario.sql

prompt cargando historico_status_laptop
@@../../../carga-inicial/historico_status_laptop-1.sql
@@../../../carga-inicial/historico_status_laptop-2.sql

prompt cargando servicio_laptop (con datos BLOB)
@@../../../carga-inicial/servicio_laptop-1.sql
@@../../../carga-inicial/servicio_laptop-2.sql

commit;

prompt Reactivando FK temporal de laptop_reemplazo_id en S4
connect ilap_bdd/ilap_bdd@eambdd_s4
alter table laptop_f4_eam_s4 enable validate constraint fk_laptop_f4_f5_remp;
commit;

prompt Listo!
exit