-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Trigger INSTEAD OF para la vista TIPO_MONITOR con replicacion
--                 sincrona sobre las 4 replicas.

create or replace trigger t_dml_tipo_monitor
instead of insert or update or delete on tipo_monitor
begin
  case
    when inserting then
      insert into tipo_monitor_r1 (tipo_monitor_id, clave, descripcion)
      values (:new.tipo_monitor_id, :new.clave, :new.descripcion);
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible insertar la replica r1 de TIPO_MONITOR.');
      end if;
      insert into tipo_monitor_r2 (tipo_monitor_id, clave, descripcion)
      values (:new.tipo_monitor_id, :new.clave, :new.descripcion);
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible insertar la replica r2 de TIPO_MONITOR.');
      end if;
      insert into tipo_monitor_r3 (tipo_monitor_id, clave, descripcion)
      values (:new.tipo_monitor_id, :new.clave, :new.descripcion);
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible insertar la replica r3 de TIPO_MONITOR.');
      end if;
      insert into tipo_monitor_r4 (tipo_monitor_id, clave, descripcion)
      values (:new.tipo_monitor_id, :new.clave, :new.descripcion);
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible insertar la replica r4 de TIPO_MONITOR.');
      end if;

    when updating then
      update tipo_monitor_r1
      set clave = :new.clave,
          descripcion = :new.descripcion
      where tipo_monitor_id = :old.tipo_monitor_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible actualizar la replica r1 de TIPO_MONITOR.');
      end if;
      update tipo_monitor_r2
      set clave = :new.clave,
          descripcion = :new.descripcion
      where tipo_monitor_id = :old.tipo_monitor_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible actualizar la replica r2 de TIPO_MONITOR.');
      end if;
      update tipo_monitor_r3
      set clave = :new.clave,
          descripcion = :new.descripcion
      where tipo_monitor_id = :old.tipo_monitor_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible actualizar la replica r3 de TIPO_MONITOR.');
      end if;
      update tipo_monitor_r4
      set clave = :new.clave,
          descripcion = :new.descripcion
      where tipo_monitor_id = :old.tipo_monitor_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible actualizar la replica r4 de TIPO_MONITOR.');
      end if;

    when deleting then
      delete from tipo_monitor_r1 where tipo_monitor_id = :old.tipo_monitor_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible eliminar la replica r1 de TIPO_MONITOR.');
      end if;
      delete from tipo_monitor_r2 where tipo_monitor_id = :old.tipo_monitor_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible eliminar la replica r2 de TIPO_MONITOR.');
      end if;
      delete from tipo_monitor_r3 where tipo_monitor_id = :old.tipo_monitor_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible eliminar la replica r3 de TIPO_MONITOR.');
      end if;
      delete from tipo_monitor_r4 where tipo_monitor_id = :old.tipo_monitor_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible eliminar la replica r4 de TIPO_MONITOR.');
      end if;
  end case;
end;
/
