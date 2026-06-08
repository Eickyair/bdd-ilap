-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Trigger INSTEAD OF para la vista SUCURSAL_VENTA.

create or replace trigger t_dml_sucursal_venta
instead of insert or update or delete on sucursal_venta
declare
    v_count number;
begin
    if inserting then
        select count(*) into v_count from sucursal_f1 where sucursal_id = :new.sucursal_id;
        if v_count > 0 then
            insert into sucursal_venta_f1 (sucursal_id, hora_apertura, hora_cierre)
            values (:new.sucursal_id, :new.hora_apertura, :new.hora_cierre);
        else
            select count(*) into v_count from sucursal_f2 where sucursal_id = :new.sucursal_id;
            if v_count > 0 then
                insert into sucursal_venta_f2 (sucursal_id, hora_apertura, hora_cierre)
                values (:new.sucursal_id, :new.hora_apertura, :new.hora_cierre);
            else
                select count(*) into v_count from sucursal_f3 where sucursal_id = :new.sucursal_id;
                if v_count > 0 then
                    insert into sucursal_venta_f3 (sucursal_id, hora_apertura, hora_cierre)
                    values (:new.sucursal_id, :new.hora_apertura, :new.hora_cierre);
                else
                    select count(*) into v_count from sucursal_f4 where sucursal_id = :new.sucursal_id;
                    if v_count > 0 then
                        insert into sucursal_venta_f4 (sucursal_id, hora_apertura, hora_cierre)
                        values (:new.sucursal_id, :new.hora_apertura, :new.hora_cierre);
                    else
                        raise_application_error(-20020,
                            'No se encontro el registro padre de SUCURSAL para SUCURSAL_VENTA.');
                    end if;
                end if;
            end if;
        end if;
    elsif updating then
        raise_application_error(-20030,
            'Las operaciones UPDATE sobre SUCURSAL_VENTA aun no estan implementadas.');
    elsif deleting then
        delete from sucursal_venta_f1 where sucursal_id = :old.sucursal_id;
        if sql%rowcount = 0 then
            delete from sucursal_venta_f2 where sucursal_id = :old.sucursal_id;
            if sql%rowcount = 0 then
                delete from sucursal_venta_f3 where sucursal_id = :old.sucursal_id;
                if sql%rowcount = 0 then
                    delete from sucursal_venta_f4 where sucursal_id = :old.sucursal_id;
                    if sql%rowcount = 0 then
                        raise_application_error(-20020,
                            'No se encontro el fragmento de SUCURSAL_VENTA a eliminar.');
                    end if;
                end if;
            end if;
        end if;
    end if;
end;
/
