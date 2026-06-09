-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripcion  : Orquestador maestro para reconstruir la BDD distribuida de
--                 iLap con soporte BLOB hasta la Parte 4.

clear screen
whenever oserror exit failure rollback;
whenever sqlerror exit failure rollback;

prompt Iniciando con la creacion de la BDD.

@@../../parte-2/fase-2-usuarios/s-01-ilap-main-usuario.sql
@@../../parte-2/fase-3-ligas/s-02-ilap-ligas.sql
@@../../parte-2/fase-4-fragmentos/s-03-ilap-main-ddl.sql
@@../../parte-3/fase-1-sinonimos/s-04-ilap-main-sinonimos.sql
@@../../parte-3/fase-2-vistas/s-05-ilap-main-vistas.sql
@@../../parte-3/fase-3-triggers/s-06-ilap-main-triggers.sql
@@../fase-1-soporte-blob/s-07-ilap-main-soporte-blobs.sql

prompt Listo!
exit