-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Trigger INSTEAD OF para la vista TIPO_PROCESADOR. Replica de
--                 forma sincrona INSERT, UPDATE y DELETE en las 4 replicas.

create or replace trigger t_dml_tipo_procesador
instead of insert or update or delete on tipo_procesador
begin
  case
    when inserting then
      insert into tipo_procesador_r1 (tipo_procesador_id, clave, descripcion)
      values (:new.tipo_procesador_id, :new.clave, :new.descripcion);
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible insertar la replica r1 de TIPO_PROCESADOR.');
      end if;

      insert into tipo_procesador_r2 (tipo_procesador_id, clave, descripcion)
      values (:new.tipo_procesador_id, :new.clave, :new.descripcion);
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible insertar la replica r2 de TIPO_PROCESADOR.');
      end if;

      insert into tipo_procesador_r3 (tipo_procesador_id, clave, descripcion)
      values (:new.tipo_procesador_id, :new.clave, :new.descripcion);
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible insertar la replica r3 de TIPO_PROCESADOR.');
      end if;

      insert into tipo_procesador_r4 (tipo_procesador_id, clave, descripcion)
      values (:new.tipo_procesador_id, :new.clave, :new.descripcion);
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible insertar la replica r4 de TIPO_PROCESADOR.');
      end if;

    when updating then
      update tipo_procesador_r1
      set clave = :new.clave,
          descripcion = :new.descripcion
      where tipo_procesador_id = :old.tipo_procesador_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible actualizar la replica r1 de TIPO_PROCESADOR.');
      end if;

      update tipo_procesador_r2
      set clave = :new.clave,
          descripcion = :new.descripcion
      where tipo_procesador_id = :old.tipo_procesador_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible actualizar la replica r2 de TIPO_PROCESADOR.');
      end if;

      update tipo_procesador_r3
      set clave = :new.clave,
          descripcion = :new.descripcion
      where tipo_procesador_id = :old.tipo_procesador_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible actualizar la replica r3 de TIPO_PROCESADOR.');
      end if;

      update tipo_procesador_r4
      set clave = :new.clave,
          descripcion = :new.descripcion
      where tipo_procesador_id = :old.tipo_procesador_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible actualizar la replica r4 de TIPO_PROCESADOR.');
      end if;

    when deleting then
      delete from tipo_procesador_r1 where tipo_procesador_id = :old.tipo_procesador_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible eliminar la replica r1 de TIPO_PROCESADOR.');
      end if;

      delete from tipo_procesador_r2 where tipo_procesador_id = :old.tipo_procesador_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible eliminar la replica r2 de TIPO_PROCESADOR.');
      end if;

      delete from tipo_procesador_r3 where tipo_procesador_id = :old.tipo_procesador_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible eliminar la replica r3 de TIPO_PROCESADOR.');
      end if;

      delete from tipo_procesador_r4 where tipo_procesador_id = :old.tipo_procesador_id;
      if sql%rowcount <> 1 then
        raise_application_error(-20040, 'No fue posible eliminar la replica r4 de TIPO_PROCESADOR.');
      end if;
  end case;
end;
/