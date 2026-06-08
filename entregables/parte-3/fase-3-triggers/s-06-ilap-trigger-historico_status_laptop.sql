-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Trigger INSTEAD OF para la vista HISTORICO_STATUS_LAPTOP.
--                 Implementa fragmentación horizontal por fecha.

create or replace trigger t_dml_historico_status_laptop
instead of insert or update or delete on historico_status_laptop
begin
  case
    when inserting then
      if :new.fecha_status < to_date('2010-01-01', 'yyyy-mm-dd') then
        insert into historico_status_laptop_f1 (
          historico_status_laptop_id, fecha_status, status_laptop_id, laptop_id
        ) values (
          :new.historico_status_laptop_id, :new.fecha_status,
          :new.status_laptop_id, :new.laptop_id
        );
      else
        insert into historico_status_laptop_f2 (
          historico_status_laptop_id, fecha_status, status_laptop_id, laptop_id
        ) values (
          :new.historico_status_laptop_id, :new.fecha_status,
          :new.status_laptop_id, :new.laptop_id
        );
      end if;

    when updating then
      raise_application_error(
        -20030,
        'Las operaciones UPDATE aun no estan implementadas para tablas fragmentadas.'
      );

    when deleting then
      if :old.fecha_status < to_date('2010-01-01', 'yyyy-mm-dd') then
        delete from historico_status_laptop_f1
        where historico_status_laptop_id = :old.historico_status_laptop_id;
      else
        delete from historico_status_laptop_f2
        where historico_status_laptop_id = :old.historico_status_laptop_id;
      end if;
  end case;
end;
/
