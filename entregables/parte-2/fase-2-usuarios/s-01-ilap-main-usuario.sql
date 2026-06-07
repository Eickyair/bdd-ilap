-- Autor       : erick
-- Fecha        : 2026-06-04
-- Descripción  : Creación del usuario ilap_bdd en los 4 nodos de la BDD.
--                 Ejecutar desde SQL*Plus con: sqlplus /nolog @s-01-ilap-main-usuario.sql

clear screen
whenever sqlerror exit rollback;
set serveroutput on

prompt Iniciando creación/eliminación de usuarios.
accept syspass char prompt 'Proporcione el password de sys: ' hide

prompt ====================================
prompt Creando usuario en eambdd_s1
prompt ====================================
connect sys/&&syspass@eambdd_s1 as sysdba
@s-01-ilap-usuario.sql

prompt ====================================
prompt Creando usuario en eambdd_s2
prompt ====================================
connect sys/&&syspass@eambdd_s2 as sysdba
@s-01-ilap-usuario.sql

prompt ====================================
prompt Creando usuario en eambdd_s3
prompt ====================================
connect sys/&&syspass@eambdd_s3 as sysdba
@s-01-ilap-usuario.sql

prompt ====================================
prompt Creando usuario en eambdd_s4
prompt ====================================
connect sys/&&syspass@eambdd_s4 as sysdba
@s-01-ilap-usuario.sql

prompt Listo!
disconnect
