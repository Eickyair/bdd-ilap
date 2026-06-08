-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Trigger INSTEAD OF para la vista LAPTOP.

create or replace trigger t_dml_laptop
instead of insert or update or delete on laptop
begin
    if inserting then
        insert into ti_laptop_f5 (laptop_id, foto)
        values (:new.laptop_id, :new.foto);

        insert into laptop_f5
        select laptop_id, foto
        from ti_laptop_f5
        where laptop_id = :new.laptop_id;

        delete from ti_laptop_f5 where laptop_id = :new.laptop_id;

        if substr(:new.num_serie, 1, 1) in ('0', '1') then
            insert into laptop_f1 (
                laptop_id, num_serie, cantidad_ram, caracteristicas_extras,
                tipo_tarjeta_video_id, tipo_procesador_id, tipo_almacenamiento_id,
                tipo_monitor_id, laptop_reemplazo_id
            ) values (
                :new.laptop_id, :new.num_serie, :new.cantidad_ram, :new.caracteristicas_extras,
                :new.tipo_tarjeta_video_id, :new.tipo_procesador_id, :new.tipo_almacenamiento_id,
                :new.tipo_monitor_id, :new.laptop_reemplazo_id
            );
        elsif substr(:new.num_serie, 1, 1) in ('6', '7', '8', '9') then
            insert into laptop_f2 (
                laptop_id, num_serie, cantidad_ram, caracteristicas_extras,
                tipo_tarjeta_video_id, tipo_procesador_id, tipo_almacenamiento_id,
                tipo_monitor_id, laptop_reemplazo_id
            ) values (
                :new.laptop_id, :new.num_serie, :new.cantidad_ram, :new.caracteristicas_extras,
                :new.tipo_tarjeta_video_id, :new.tipo_procesador_id, :new.tipo_almacenamiento_id,
                :new.tipo_monitor_id, :new.laptop_reemplazo_id
            );
        elsif substr(:new.num_serie, 1, 1) in ('4', '5') then
            insert into laptop_f3 (
                laptop_id, num_serie, cantidad_ram, caracteristicas_extras,
                tipo_tarjeta_video_id, tipo_procesador_id, tipo_almacenamiento_id,
                tipo_monitor_id, laptop_reemplazo_id
            ) values (
                :new.laptop_id, :new.num_serie, :new.cantidad_ram, :new.caracteristicas_extras,
                :new.tipo_tarjeta_video_id, :new.tipo_procesador_id, :new.tipo_almacenamiento_id,
                :new.tipo_monitor_id, :new.laptop_reemplazo_id
            );
        elsif substr(:new.num_serie, 1, 1) in ('2', '3') then
            insert into laptop_f4 (
                laptop_id, num_serie, cantidad_ram, caracteristicas_extras,
                tipo_tarjeta_video_id, tipo_procesador_id, tipo_almacenamiento_id,
                tipo_monitor_id, laptop_reemplazo_id
            ) values (
                :new.laptop_id, :new.num_serie, :new.cantidad_ram, :new.caracteristicas_extras,
                :new.tipo_tarjeta_video_id, :new.tipo_procesador_id, :new.tipo_almacenamiento_id,
                :new.tipo_monitor_id, :new.laptop_reemplazo_id
            );
        else
            raise_application_error(-20010,
                'El registro de LAPTOP no cumple con el esquema de fragmentacion primaria.');
        end if;
    elsif updating then
        raise_application_error(-20030,
            'Las operaciones UPDATE sobre LAPTOP aun no estan implementadas.');
    elsif deleting then
        if substr(:old.num_serie, 1, 1) in ('0', '1') then
            delete from laptop_f1 where laptop_id = :old.laptop_id;
        elsif substr(:old.num_serie, 1, 1) in ('6', '7', '8', '9') then
            delete from laptop_f2 where laptop_id = :old.laptop_id;
        elsif substr(:old.num_serie, 1, 1) in ('4', '5') then
            delete from laptop_f3 where laptop_id = :old.laptop_id;
        elsif substr(:old.num_serie, 1, 1) in ('2', '3') then
            delete from laptop_f4 where laptop_id = :old.laptop_id;
        else
            raise_application_error(-20010,
                'El registro de LAPTOP no cumple con el esquema de fragmentacion primaria.');
        end if;

        delete from laptop_f5 where laptop_id = :old.laptop_id;
    end if;
end;
/
