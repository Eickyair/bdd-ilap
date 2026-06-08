-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Valida la Parte 3 revisando sinónimos, vistas y triggers en
--                 cada PDB mediante consultas al diccionario y conteos básicos.

whenever sqlerror exit failure rollback;
set linesize 200
set pagesize 100

prompt ============================================
prompt Validando Parte 3 en eambdd_s1
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s1
select count(*) as total_synonyms from user_synonyms;
select count(*) as total_views from user_views;
select count(*) as total_temp_tables
from user_tables
where table_name like 'TI\_%' escape '\'
   or table_name like 'TS\_%' escape '\';
select count(*) as total_functions
from user_objects
where object_type = 'FUNCTION'
  and object_name like 'GET\_REMOTE\_%' escape '\';
select count(*) as total_triggers from user_triggers where trigger_name like 'T\_DML\_%' escape '\';
select object_type, object_name, status
from user_objects
where object_type in ('VIEW','FUNCTION','TRIGGER')
  and status <> 'VALID'
order by object_type, object_name;
declare
  v_invalid number;
begin
  select count(*)
    into v_invalid
    from user_objects
   where object_type in ('VIEW', 'FUNCTION', 'TRIGGER')
     and status <> 'VALID';

  if v_invalid > 0 then
    raise_application_error(-20050, 'Existen objetos invalidos en eambdd_s1.');
  end if;
end;
/

prompt ============================================
prompt Validando Parte 3 en eambdd_s2
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s2
select count(*) as total_synonyms from user_synonyms;
select count(*) as total_views from user_views;
select count(*) as total_temp_tables
from user_tables
where table_name like 'TI\_%' escape '\'
   or table_name like 'TS\_%' escape '\';
select count(*) as total_functions
from user_objects
where object_type = 'FUNCTION'
  and object_name like 'GET\_REMOTE\_%' escape '\';
select count(*) as total_triggers from user_triggers where trigger_name like 'T\_DML\_%' escape '\';
select object_type, object_name, status
from user_objects
where object_type in ('VIEW','FUNCTION','TRIGGER')
  and status <> 'VALID'
order by object_type, object_name;
declare
  v_invalid number;
begin
  select count(*)
    into v_invalid
    from user_objects
   where object_type in ('VIEW', 'FUNCTION', 'TRIGGER')
     and status <> 'VALID';

  if v_invalid > 0 then
    raise_application_error(-20050, 'Existen objetos invalidos en eambdd_s2.');
  end if;
end;
/

prompt ============================================
prompt Validando Parte 3 en eambdd_s3
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s3
select count(*) as total_synonyms from user_synonyms;
select count(*) as total_views from user_views;
select count(*) as total_temp_tables
from user_tables
where table_name like 'TI\_%' escape '\'
   or table_name like 'TS\_%' escape '\';
select count(*) as total_functions
from user_objects
where object_type = 'FUNCTION'
  and object_name like 'GET\_REMOTE\_%' escape '\';
select count(*) as total_triggers from user_triggers where trigger_name like 'T\_DML\_%' escape '\';
select object_type, object_name, status
from user_objects
where object_type in ('VIEW','FUNCTION','TRIGGER')
  and status <> 'VALID'
order by object_type, object_name;
declare
  v_invalid number;
begin
  select count(*)
    into v_invalid
    from user_objects
   where object_type in ('VIEW', 'FUNCTION', 'TRIGGER')
     and status <> 'VALID';

  if v_invalid > 0 then
    raise_application_error(-20050, 'Existen objetos invalidos en eambdd_s3.');
  end if;
end;
/

prompt ============================================
prompt Validando Parte 3 en eambdd_s4
prompt ============================================
connect ilap_bdd/ilap_bdd@eambdd_s4
select count(*) as total_synonyms from user_synonyms;
select count(*) as total_views from user_views;
select count(*) as total_temp_tables
from user_tables
where table_name like 'TI\_%' escape '\'
   or table_name like 'TS\_%' escape '\';
select count(*) as total_functions
from user_objects
where object_type = 'FUNCTION'
  and object_name like 'GET\_REMOTE\_%' escape '\';
select count(*) as total_triggers from user_triggers where trigger_name like 'T\_DML\_%' escape '\';
select object_type, object_name, status
from user_objects
where object_type in ('VIEW','FUNCTION','TRIGGER')
  and status <> 'VALID'
order by object_type, object_name;
declare
  v_invalid number;
begin
  select count(*)
    into v_invalid
    from user_objects
   where object_type in ('VIEW', 'FUNCTION', 'TRIGGER')
     and status <> 'VALID';

  if v_invalid > 0 then
    raise_application_error(-20050, 'Existen objetos invalidos en eambdd_s4.');
  end if;
end;
/

prompt Listo!
disconnect
