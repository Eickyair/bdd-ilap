-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Trigger INSTEAD OF para la vista SERVICIO_LAPTOP.

create or replace trigger t_dml_servicio_laptop
instead of insert or update or delete on servicio_laptop
declare
    v_count number;
begin
    if inserting then
        select count(*) into v_count from sucursal_taller_f1 where sucursal_id = :new.sucursal_id;
        if v_count > 0 then
            insert into ti_servicio_laptop_f1 (
                num_servicio, laptop_id, importe, diagnostico, factura, sucursal_id
            ) values (
                :new.num_servicio, :new.laptop_id, :new.importe, :new.diagnostico,
                :new.factura, :new.sucursal_id
            );
            insert into servicio_laptop_f1
            select num_servicio, laptop_id, importe, diagnostico, factura, sucursal_id
            from ti_servicio_laptop_f1
            where num_servicio = :new.num_servicio
              and laptop_id = :new.laptop_id;
            delete from ti_servicio_laptop_f1
            where num_servicio = :new.num_servicio
              and laptop_id = :new.laptop_id;
        else
            select count(*) into v_count from sucursal_taller_f2 where sucursal_id = :new.sucursal_id;
            if v_count > 0 then
                insert into ti_servicio_laptop_f2 (
                    num_servicio, laptop_id, importe, diagnostico, factura, sucursal_id
                ) values (
                    :new.num_servicio, :new.laptop_id, :new.importe, :new.diagnostico,
                    :new.factura, :new.sucursal_id
                );
                insert into servicio_laptop_f2
                select num_servicio, laptop_id, importe, diagnostico, factura, sucursal_id
                from ti_servicio_laptop_f2
                where num_servicio = :new.num_servicio
                  and laptop_id = :new.laptop_id;
                delete from ti_servicio_laptop_f2
                where num_servicio = :new.num_servicio
                  and laptop_id = :new.laptop_id;
            else
                select count(*) into v_count from sucursal_taller_f3 where sucursal_id = :new.sucursal_id;
                if v_count > 0 then
                    insert into ti_servicio_laptop_f3 (
                        num_servicio, laptop_id, importe, diagnostico, factura, sucursal_id
                    ) values (
                        :new.num_servicio, :new.laptop_id, :new.importe, :new.diagnostico,
                        :new.factura, :new.sucursal_id
                    );
                    insert into servicio_laptop_f3
                    select num_servicio, laptop_id, importe, diagnostico, factura, sucursal_id
                    from ti_servicio_laptop_f3
                    where num_servicio = :new.num_servicio
                      and laptop_id = :new.laptop_id;
                    delete from ti_servicio_laptop_f3
                    where num_servicio = :new.num_servicio
                      and laptop_id = :new.laptop_id;
                else
                    select count(*) into v_count from sucursal_taller_f4 where sucursal_id = :new.sucursal_id;
                    if v_count > 0 then
                        insert into ti_servicio_laptop_f4 (
                            num_servicio, laptop_id, importe, diagnostico, factura, sucursal_id
                        ) values (
                            :new.num_servicio, :new.laptop_id, :new.importe, :new.diagnostico,
                            :new.factura, :new.sucursal_id
                        );
                        insert into servicio_laptop_f4
                        select num_servicio, laptop_id, importe, diagnostico, factura, sucursal_id
                        from ti_servicio_laptop_f4
                        where num_servicio = :new.num_servicio
                          and laptop_id = :new.laptop_id;
                        delete from ti_servicio_laptop_f4
                        where num_servicio = :new.num_servicio
                          and laptop_id = :new.laptop_id;
                    else
                        raise_application_error(-20020,
                            'No se encontro la sucursal taller padre para SERVICIO_LAPTOP.');
                    end if;
                end if;
            end if;
        end if;
    elsif updating then
        raise_application_error(-20030,
            'Las operaciones UPDATE sobre SERVICIO_LAPTOP aun no estan implementadas.');
    elsif deleting then
        delete from servicio_laptop_f1
        where num_servicio = :old.num_servicio
          and laptop_id = :old.laptop_id;
        if sql%rowcount = 0 then
            delete from servicio_laptop_f2
            where num_servicio = :old.num_servicio
              and laptop_id = :old.laptop_id;
            if sql%rowcount = 0 then
                delete from servicio_laptop_f3
                where num_servicio = :old.num_servicio
                  and laptop_id = :old.laptop_id;
                if sql%rowcount = 0 then
                    delete from servicio_laptop_f4
                    where num_servicio = :old.num_servicio
                      and laptop_id = :old.laptop_id;
                    if sql%rowcount = 0 then
                        raise_application_error(-20020,
                            'No se encontro el fragmento de SERVICIO_LAPTOP a eliminar.');
                    end if;
                end if;
            end if;
        end if;
    end if;
end;
/
