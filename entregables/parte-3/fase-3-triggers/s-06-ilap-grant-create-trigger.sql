-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Otorga el privilegio CREATE TRIGGER al usuario ilap_bdd en las
--                 4 PDBs para la compilación de triggers INSTEAD OF.

clear screen
whenever sqlerror exit rollback;
set verify off

accept syspass char prompt 'Proporcione el password de sys: ' hide

prompt ============================================
prompt Otorgando CREATE TRIGGER en eambdd_s1
prompt ============================================
connect sys/&&syspass@eambdd_s1 as sysdba
grant create trigger to ilap_bdd;

prompt ============================================
prompt Otorgando CREATE TRIGGER en eambdd_s2
prompt ============================================
connect sys/&&syspass@eambdd_s2 as sysdba
grant create trigger to ilap_bdd;

prompt ============================================
prompt Otorgando CREATE TRIGGER en eambdd_s3
prompt ============================================
connect sys/&&syspass@eambdd_s3 as sysdba
grant create trigger to ilap_bdd;

prompt ============================================
prompt Otorgando CREATE TRIGGER en eambdd_s4
prompt ============================================
connect sys/&&syspass@eambdd_s4 as sysdba
grant create trigger to ilap_bdd;

prompt Listo!
disconnect
