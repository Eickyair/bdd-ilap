--@Autor:          Erick Yair Aguilar Martínez
--@Fecha creación: 04/06/2026
--@Descripción:    Eliminación y creación del usuario ilap_bdd en una PDB.
--                 Invocar desde s-01-ilap-main-usuario.sql conectado como sysdba.

prompt Creando al usuario ilap_bdd
drop user if exists ilap_bdd cascade;

create user ilap_bdd identified by ilap_bdd
  default tablespace users
  quota unlimited on users;

grant create session      to ilap_bdd;
grant create table        to ilap_bdd;
grant create sequence     to ilap_bdd;
grant create procedure    to ilap_bdd;
grant create view         to ilap_bdd;
grant create synonym      to ilap_bdd;
grant create database link to ilap_bdd;

prompt Usuario ilap_bdd creado correctamente.
