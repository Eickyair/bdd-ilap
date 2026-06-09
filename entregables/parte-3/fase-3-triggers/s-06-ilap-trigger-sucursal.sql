-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Trigger INSTEAD OF para la vista SUCURSAL. Implementa
--                 transparencia para INSERT y DELETE con fragmentación
--                 horizontal primaria.

create or replace trigger t_dml_sucursal
instead of insert or update or delete on sucursal
declare
  v_zona varchar2(2);
begin
  case
    when inserting then
      v_zona := substr(:new.clave, 3, 2);

      if nvl(:new.es_taller, -1) not in (0, 1)
         or nvl(:new.es_venta, -1) not in (0, 1)
         or (:new.es_taller = 0 and :new.es_venta = 0) then
        raise_application_error(
          -20010,
          'El registro no cumple con el esquema de fragmentacion horizontal primaria de SUCURSAL.'
        );
      end if;

      if v_zona not in ('NO', 'EA', 'WS', 'SO') then
        raise_application_error(
          -20010,
          'El registro no cumple con el esquema de fragmentacion horizontal primaria de SUCURSAL.'
        );
      end if;

      -- Nodo 1: zona NO, o bien sucursal con ambas funciones (taller y venta),
      -- conforme al predicado oficial F1 = (ES_TALLER=1 AND ES_VENTA=1) OR zona='NO'.
      if v_zona = 'NO' or (:new.es_taller = 1 and :new.es_venta = 1) then
        insert into sucursal_f1 (
          sucursal_id, clave, es_taller, es_venta, nombre, latitud, longitud, url
        ) values (
          :new.sucursal_id, :new.clave, :new.es_taller, :new.es_venta,
          :new.nombre, :new.latitud, :new.longitud, :new.url
        );
      elsif not (:new.es_venta = 1 and :new.es_taller = 1) and v_zona = 'EA' then
        insert into sucursal_f2 (
          sucursal_id, clave, es_taller, es_venta, nombre, latitud, longitud, url
        ) values (
          :new.sucursal_id, :new.clave, :new.es_taller, :new.es_venta,
          :new.nombre, :new.latitud, :new.longitud, :new.url
        );
      elsif not (:new.es_venta = 1 and :new.es_taller = 1) and v_zona = 'WS' then
        insert into sucursal_f3 (
          sucursal_id, clave, es_taller, es_venta, nombre, latitud, longitud, url
        ) values (
          :new.sucursal_id, :new.clave, :new.es_taller, :new.es_venta,
          :new.nombre, :new.latitud, :new.longitud, :new.url
        );
      elsif not (:new.es_venta = 1 and :new.es_taller = 1) and v_zona = 'SO' then
        insert into sucursal_f4 (
          sucursal_id, clave, es_taller, es_venta, nombre, latitud, longitud, url
        ) values (
          :new.sucursal_id, :new.clave, :new.es_taller, :new.es_venta,
          :new.nombre, :new.latitud, :new.longitud, :new.url
        );
      else
        raise_application_error(
          -20010,
          'El registro no cumple con el esquema de fragmentacion horizontal primaria de SUCURSAL.'
        );
      end if;

    when updating then
      raise_application_error(
        -20030,
        'Las operaciones UPDATE aun no estan implementadas para tablas fragmentadas.'
      );

    when deleting then
      v_zona := substr(:old.clave, 3, 2);

      -- Nodo 1: mismo predicado que en INSERT (ambas funciones o zona NO).
      if v_zona = 'NO' or (:old.es_taller = 1 and :old.es_venta = 1) then
        delete from sucursal_taller_f1 where sucursal_id = :old.sucursal_id;
        delete from sucursal_venta_f1 where sucursal_id = :old.sucursal_id;
        delete from sucursal_f1 where sucursal_id = :old.sucursal_id;
      elsif not (:old.es_venta = 1 and :old.es_taller = 1) and v_zona = 'EA' then
        delete from sucursal_taller_f2 where sucursal_id = :old.sucursal_id;
        delete from sucursal_venta_f2 where sucursal_id = :old.sucursal_id;
        delete from sucursal_f2 where sucursal_id = :old.sucursal_id;
      elsif not (:old.es_venta = 1 and :old.es_taller = 1) and v_zona = 'WS' then
        delete from sucursal_taller_f3 where sucursal_id = :old.sucursal_id;
        delete from sucursal_venta_f3 where sucursal_id = :old.sucursal_id;
        delete from sucursal_f3 where sucursal_id = :old.sucursal_id;
      elsif not (:old.es_venta = 1 and :old.es_taller = 1) and v_zona = 'SO' then
        delete from sucursal_taller_f4 where sucursal_id = :old.sucursal_id;
        delete from sucursal_venta_f4 where sucursal_id = :old.sucursal_id;
        delete from sucursal_f4 where sucursal_id = :old.sucursal_id;
      else
        raise_application_error(
          -20010,
          'El registro no cumple con el esquema de fragmentacion horizontal primaria de SUCURSAL.'
        );
      end if;
  end case;
end;
/
