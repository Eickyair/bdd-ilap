-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Trigger INSTEAD OF para la vista LAPTOP_INVENTARIO. Inserta y
--                 elimina en ambos fragmentos verticales del esquema global.

create or replace trigger t_dml_laptop_inventario
instead of insert or update or delete on laptop_inventario
begin
    case
        when inserting then
            insert into laptop_inventario_f1 (
                laptop_id, rfc_cliente, num_tarjeta
            ) values (
                :new.laptop_id, :new.rfc_cliente, :new.num_tarjeta
            );

            insert into laptop_inventario_f2 (
                laptop_id, fecha_status, sucursal_id, status_laptop_id
            ) values (
                :new.laptop_id, :new.fecha_status, :new.sucursal_id, :new.status_laptop_id
            );

        when updating then
            raise_application_error(
                -20030,
                'Las operaciones UPDATE aun no estan implementadas para tablas fragmentadas.'
            );

        when deleting then
            delete from laptop_inventario_f1 where laptop_id = :old.laptop_id;
            delete from laptop_inventario_f2 where laptop_id = :old.laptop_id;
    end case;
end;
/
