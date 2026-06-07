-- Autor       : erick
-- Fecha        : 2026-06-04
-- Descripción  : Validaciones de consistencia de la BDD distribuida iLap.
--                 Verifica en cada nodo: usuario, database links, tablas
--                 de fragmento, catálogos y conectividad vía DB links.
--                 Invocar desde v-01-run-validations.sh.

set serveroutput on
set linesize 120
set pagesize 50
set feedback off
set heading on

-- ============================================================
-- Procedimiento auxiliar para reportar resultado
-- ============================================================
-- (usamos prompts directos para compatibilidad sin PL/SQL)

-- ============================================================
-- NODO 1: eambdd_s1
-- ============================================================
prompt
prompt ########################################
prompt  NODO 1 — eambdd_s1 (Norte)
prompt ########################################
connect ilap_bdd/ilap_bdd@eambdd_s1

prompt --- 1.1 Usuario activo ---
select user as "Usuario conectado" from dual;

prompt --- 1.2 Database links creados (esperado: 3) ---
select db_link, username, host
from   user_db_links
order  by db_link;

prompt --- 1.3 Tablas del fragmento (esperado: 12) ---
select table_name
from   user_tables
order  by table_name;

prompt --- 1.4 Conectividad vía DB links ---
select 'eambdd_s2' as "Nodo destino",
       count(*)    as "Accesible (1=si)"
from   dual@eambdd_s2.fi.unam;

select 'eambdd_s3' as "Nodo destino",
       count(*)    as "Accesible (1=si)"
from   dual@eambdd_s3.fi.unam;

select 'eambdd_s4' as "Nodo destino",
       count(*)    as "Accesible (1=si)"
from   dual@eambdd_s4.fi.unam;

prompt --- 1.5 Conteo de tablas clave ---
select 'SUCURSAL_F1_EAM_S1'                 as "Tabla",          count(*) as "Filas" from sucursal_f1_eam_s1
union all
select 'SUCURSAL_TALLER_F1_EAM_S1',                              count(*) from sucursal_taller_f1_eam_s1
union all
select 'SUCURSAL_VENTA_F1_EAM_S1',                               count(*) from sucursal_venta_f1_eam_s1
union all
select 'LAPTOP_F1_EAM_S1',                                       count(*) from laptop_f1_eam_s1
union all
select 'LAPTOP_INVENTARIO_F2_EAM_S1',                            count(*) from laptop_inventario_f2_eam_s1
union all
select 'HISTORICO_STATUS_LAPTOP_F2_EAM_S1',                      count(*) from historico_status_laptop_f2_eam_s1
union all
select 'SERVICIO_LAPTOP_F1_EAM_S1',                              count(*) from servicio_laptop_f1_eam_s1
union all
select 'STATUS_LAPTOP',                                           count(*) from status_laptop
order by 1;

-- ============================================================
-- NODO 2: eambdd_s2
-- ============================================================
prompt
prompt ########################################
prompt  NODO 2 — eambdd_s2 (Este)
prompt ########################################
connect ilap_bdd/ilap_bdd@eambdd_s2

prompt --- 2.1 Usuario activo ---
select user as "Usuario conectado" from dual;

prompt --- 2.2 Database links creados (esperado: 3) ---
select db_link, username, host
from   user_db_links
order  by db_link;

prompt --- 2.3 Tablas del fragmento (esperado: 11) ---
select table_name
from   user_tables
order  by table_name;

prompt --- 2.4 Conectividad vía DB links ---
select 'eambdd_s1' as "Nodo destino", count(*) as "Accesible (1=si)"
from   dual@eambdd_s1.fi.unam;
select 'eambdd_s3' as "Nodo destino", count(*) as "Accesible (1=si)"
from   dual@eambdd_s3.fi.unam;
select 'eambdd_s4' as "Nodo destino", count(*) as "Accesible (1=si)"
from   dual@eambdd_s4.fi.unam;

-- ============================================================
-- NODO 3: eambdd_s3
-- ============================================================
prompt
prompt ########################################
prompt  NODO 3 — eambdd_s3 (Oeste)
prompt ########################################
connect ilap_bdd/ilap_bdd@eambdd_s3

prompt --- 3.1 Usuario activo ---
select user as "Usuario conectado" from dual;

prompt --- 3.2 Database links creados (esperado: 3) ---
select db_link, username, host
from   user_db_links
order  by db_link;

prompt --- 3.3 Tablas del fragmento (esperado: 11) ---
select table_name
from   user_tables
order  by table_name;

prompt --- 3.4 Conectividad vía DB links ---
select 'eambdd_s1' as "Nodo destino", count(*) as "Accesible (1=si)"
from   dual@eambdd_s1.fi.unam;
select 'eambdd_s2' as "Nodo destino", count(*) as "Accesible (1=si)"
from   dual@eambdd_s2.fi.unam;
select 'eambdd_s4' as "Nodo destino", count(*) as "Accesible (1=si)"
from   dual@eambdd_s4.fi.unam;

prompt --- 3.5 Tabla de datos sensibles ---
select 'LAPTOP_INVENTARIO_F1_EAM_S3 (datos cifrados)', count(*) as "Filas"
from   laptop_inventario_f1_eam_s3;

-- ============================================================
-- NODO 4: eambdd_s4
-- ============================================================
prompt
prompt ########################################
prompt  NODO 4 — eambdd_s4 (Sur)
prompt ########################################
connect ilap_bdd/ilap_bdd@eambdd_s4

prompt --- 4.1 Usuario activo ---
select user as "Usuario conectado" from dual;

prompt --- 4.2 Database links creados (esperado: 3) ---
select db_link, username, host
from   user_db_links
order  by db_link;

prompt --- 4.3 Tablas del fragmento (esperado: 11) ---
select table_name
from   user_tables
order  by table_name;

prompt --- 4.4 Conectividad vía DB links ---
select 'eambdd_s1' as "Nodo destino", count(*) as "Accesible (1=si)"
from   dual@eambdd_s1.fi.unam;
select 'eambdd_s2' as "Nodo destino", count(*) as "Accesible (1=si)"
from   dual@eambdd_s2.fi.unam;
select 'eambdd_s3' as "Nodo destino", count(*) as "Accesible (1=si)"
from   dual@eambdd_s3.fi.unam;

prompt --- 4.5 Tablas exclusivas del nodo 4 (fotos globales) ---
select 'LAPTOP_F5_EAM_S4 (fotos globales)', count(*) as "Filas"
from   laptop_f5_eam_s4;

-- ============================================================
-- RESUMEN GLOBAL — total de tablas por nodo (desde nodo 1)
-- ============================================================
prompt
prompt ########################################
prompt  RESUMEN GLOBAL
prompt ########################################
connect ilap_bdd/ilap_bdd@eambdd_s1

prompt --- Tablas en nodo 1 (local) ---
select count(*) as "Tablas en eambdd_s1" from user_tables;

prompt --- Tablas en nodo 2 (remoto via DB link) ---
select count(*) as "Tablas en eambdd_s2"
from   user_tables@eambdd_s2.fi.unam;

prompt --- Tablas en nodo 3 (remoto via DB link) ---
select count(*) as "Tablas en eambdd_s3"
from   user_tables@eambdd_s3.fi.unam;

prompt --- Tablas en nodo 4 (remoto via DB link) ---
select count(*) as "Tablas en eambdd_s4"
from   user_tables@eambdd_s4.fi.unam;

prompt
prompt ########################################
prompt  Validacion completada.
prompt ########################################
disconnect
exit;
