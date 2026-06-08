-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Orquesta la compilacion de triggers INSTEAD OF para la Parte 3
--                 en las 4 PDBs de iLap.

whenever oserror exit failure rollback;
whenever sqlerror exit failure rollback;

prompt ============================================
prompt Creando triggers en eambdd_s1
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s1
@@s-06-ilap-trigger-sucursal.sql
show errors
@@s-06-ilap-trigger-sucursal_taller.sql
show errors
@@s-06-ilap-trigger-sucursal_venta.sql
show errors
@@s-06-ilap-trigger-laptop.sql
show errors
@@s-06-ilap-trigger-laptop_inventario.sql
show errors
@@s-06-ilap-trigger-historico_status_laptop.sql
show errors
@@s-06-ilap-trigger-servicio_laptop.sql
show errors
@@s-06-ilap-trigger-tipo_procesador.sql
show errors
@@s-06-ilap-trigger-tipo_tarjeta_video.sql
show errors
@@s-06-ilap-trigger-tipo_almacenamiento.sql
show errors
@@s-06-ilap-trigger-tipo_monitor.sql
show errors
declare
	v_invalid number;
begin
	select count(*)
		into v_invalid
		from user_objects
	 where object_type = 'TRIGGER'
		 and status <> 'VALID'
		 and object_name like 'T\_DML\_%' escape '\';

	if v_invalid > 0 then
		raise_application_error(-20041, 'Existen triggers invalidos en eambdd_s1.');
	end if;
end;
/

prompt ============================================
prompt Creando triggers en eambdd_s2
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s2
@@s-06-ilap-trigger-sucursal.sql
show errors
@@s-06-ilap-trigger-sucursal_taller.sql
show errors
@@s-06-ilap-trigger-sucursal_venta.sql
show errors
@@s-06-ilap-trigger-laptop.sql
show errors
@@s-06-ilap-trigger-laptop_inventario.sql
show errors
@@s-06-ilap-trigger-historico_status_laptop.sql
show errors
@@s-06-ilap-trigger-servicio_laptop.sql
show errors
@@s-06-ilap-trigger-tipo_procesador.sql
show errors
@@s-06-ilap-trigger-tipo_tarjeta_video.sql
show errors
@@s-06-ilap-trigger-tipo_almacenamiento.sql
show errors
@@s-06-ilap-trigger-tipo_monitor.sql
show errors
declare
	v_invalid number;
begin
	select count(*)
		into v_invalid
		from user_objects
	 where object_type = 'TRIGGER'
		 and status <> 'VALID'
		 and object_name like 'T\_DML\_%' escape '\';

	if v_invalid > 0 then
		raise_application_error(-20041, 'Existen triggers invalidos en eambdd_s2.');
	end if;
end;
/

prompt ============================================
prompt Creando triggers en eambdd_s3
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s3
@@s-06-ilap-trigger-sucursal.sql
show errors
@@s-06-ilap-trigger-sucursal_taller.sql
show errors
@@s-06-ilap-trigger-sucursal_venta.sql
show errors
@@s-06-ilap-trigger-laptop.sql
show errors
@@s-06-ilap-trigger-laptop_inventario.sql
show errors
@@s-06-ilap-trigger-historico_status_laptop.sql
show errors
@@s-06-ilap-trigger-servicio_laptop.sql
show errors
@@s-06-ilap-trigger-tipo_procesador.sql
show errors
@@s-06-ilap-trigger-tipo_tarjeta_video.sql
show errors
@@s-06-ilap-trigger-tipo_almacenamiento.sql
show errors
@@s-06-ilap-trigger-tipo_monitor.sql
show errors
declare
	v_invalid number;
begin
	select count(*)
		into v_invalid
		from user_objects
	 where object_type = 'TRIGGER'
		 and status <> 'VALID'
		 and object_name like 'T\_DML\_%' escape '\';

	if v_invalid > 0 then
		raise_application_error(-20041, 'Existen triggers invalidos en eambdd_s3.');
	end if;
end;
/

prompt ============================================
prompt Creando triggers en eambdd_s4
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s4
@@s-06-ilap-trigger-sucursal.sql
show errors
@@s-06-ilap-trigger-sucursal_taller.sql
show errors
@@s-06-ilap-trigger-sucursal_venta.sql
show errors
@@s-06-ilap-trigger-laptop.sql
show errors
@@s-06-ilap-trigger-laptop_inventario.sql
show errors
@@s-06-ilap-trigger-historico_status_laptop.sql
show errors
@@s-06-ilap-trigger-servicio_laptop.sql
show errors
@@s-06-ilap-trigger-tipo_procesador.sql
show errors
@@s-06-ilap-trigger-tipo_tarjeta_video.sql
show errors
@@s-06-ilap-trigger-tipo_almacenamiento.sql
show errors
@@s-06-ilap-trigger-tipo_monitor.sql
show errors
declare
	v_invalid number;
begin
	select count(*)
		into v_invalid
		from user_objects
	 where object_type = 'TRIGGER'
		 and status <> 'VALID'
		 and object_name like 'T\_DML\_%' escape '\';

	if v_invalid > 0 then
		raise_application_error(-20041, 'Existen triggers invalidos en eambdd_s4.');
	end if;
end;
/

prompt Listo!
disconnect
