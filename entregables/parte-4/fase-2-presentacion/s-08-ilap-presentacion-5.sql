-- Autor       : erick
-- Fecha        : 2026-06-08
-- Descripcion  : Elimina la carga inicial oficial mediante un procedimiento
--                 almacenado que ejecuta los DELETE en orden de dependencias
--                 como transaccion distribuida controlada (Presentacion 5).

define p_pdb = '&1'

whenever oserror exit failure rollback;
whenever sqlerror exit failure rollback;

prompt ======================================
prompt Eliminando carga inicial oficial
prompt ======================================

prompt Deshabilitando FK temporal de laptop_reemplazo_id en S4
connect ilap_bdd/ilap_bdd@eambdd_s4
alter table laptop_f4_eam_s4 disable constraint fk_laptop_f4_f5_remp;
commit;

prompt Seleccionar la PDB para realizar la eliminacion de datos
connect ilap_bdd/ilap_bdd@&&p_pdb
set serveroutput on

prompt Creando procedimiento almacenado pr_elimina_carga_inicial
create or replace procedure pr_elimina_carga_inicial is
    -- Elimina los datos de todas las tablas globales en orden de dependencias.
    -- Las vistas con triggers INSTEAD OF propagan el borrado a los 4 nodos, por
    -- lo que la operacion conforma una transaccion distribuida: cualquier error
    -- provoca rollback de todo el proceso.
    v_formato varchar2(50) := 'yyyy-mm-dd hh24:mi:ss';
begin
    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de servicio_laptop');
    delete from servicio_laptop;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de historico_status_laptop');
    delete from historico_status_laptop;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de laptop_inventario');
    delete from laptop_inventario;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de laptop');
    delete from laptop;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de sucursal_taller');
    delete from sucursal_taller;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de sucursal_venta');
    delete from sucursal_venta;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de sucursal');
    delete from sucursal;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de tipo_monitor');
    delete from tipo_monitor;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de tipo_almacenamiento');
    delete from tipo_almacenamiento;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de tipo_tarjeta_video');
    delete from tipo_tarjeta_video;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de tipo_procesador');
    delete from tipo_procesador;

    dbms_output.put_line(to_char(sysdate, v_formato) || ' Eliminando datos de status_laptop');
    delete from status_laptop;

    commit;
exception
    when others then
        dbms_output.put_line('Errores detectados al realizar la eliminacion');
        dbms_output.put_line('Se hara rollback');
        dbms_output.put_line(dbms_utility.format_error_backtrace);
        rollback;
        raise;
end;
/
show errors

prompt Ejecutando pr_elimina_carga_inicial
begin
    pr_elimina_carga_inicial;
end;
/

prompt Reactivando FK temporal de laptop_reemplazo_id en S4
connect ilap_bdd/ilap_bdd@eambdd_s4
alter table laptop_f4_eam_s4 enable validate constraint fk_laptop_f4_f5_remp;
commit;

prompt Listo!
exit
