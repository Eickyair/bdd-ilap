-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Crea tablas temporales de soporte para select e insert sobre
--                 columnas BLOB en las vistas globales de iLap.

whenever sqlerror exit rollback;

drop table if exists ts_laptop_f5 purge;
drop table if exists ti_laptop_f5 purge;
drop table if exists ts_servicio_laptop_f1 purge;
drop table if exists ts_servicio_laptop_f2 purge;
drop table if exists ts_servicio_laptop_f3 purge;
drop table if exists ts_servicio_laptop_f4 purge;
drop table if exists ti_servicio_laptop_f1 purge;
drop table if exists ti_servicio_laptop_f2 purge;
drop table if exists ti_servicio_laptop_f3 purge;
drop table if exists ti_servicio_laptop_f4 purge;

create global temporary table ti_laptop_f5 (
    laptop_id  number(10, 0) constraint ti_laptop_f5_pk primary key,
    foto       blob not null
) on commit preserve rows;

create global temporary table ts_laptop_f5 (
    laptop_id  number(10, 0) constraint ts_laptop_f5_pk primary key,
    foto       blob not null
) on commit preserve rows;

create global temporary table ti_servicio_laptop_f1 (
    num_servicio  number(10, 0) not null,
    laptop_id     number(10, 0) not null,
    importe       number(12, 2),
    diagnostico   varchar2(2000),
    factura       blob,
    sucursal_id   number(10, 0) not null,
    constraint ti_servicio_laptop_f1_pk primary key (num_servicio, laptop_id)
) on commit preserve rows;

create global temporary table ti_servicio_laptop_f2 (
    num_servicio  number(10, 0) not null,
    laptop_id     number(10, 0) not null,
    importe       number(12, 2),
    diagnostico   varchar2(2000),
    factura       blob,
    sucursal_id   number(10, 0) not null,
    constraint ti_servicio_laptop_f2_pk primary key (num_servicio, laptop_id)
) on commit preserve rows;

create global temporary table ti_servicio_laptop_f3 (
    num_servicio  number(10, 0) not null,
    laptop_id     number(10, 0) not null,
    importe       number(12, 2),
    diagnostico   varchar2(2000),
    factura       blob,
    sucursal_id   number(10, 0) not null,
    constraint ti_servicio_laptop_f3_pk primary key (num_servicio, laptop_id)
) on commit preserve rows;

create global temporary table ti_servicio_laptop_f4 (
    num_servicio  number(10, 0) not null,
    laptop_id     number(10, 0) not null,
    importe       number(12, 2),
    diagnostico   varchar2(2000),
    factura       blob,
    sucursal_id   number(10, 0) not null,
    constraint ti_servicio_laptop_f4_pk primary key (num_servicio, laptop_id)
) on commit preserve rows;

create global temporary table ts_servicio_laptop_f1 (
    num_servicio  number(10, 0) not null,
    laptop_id     number(10, 0) not null,
    factura       blob,
    constraint ts_servicio_laptop_f1_pk primary key (num_servicio, laptop_id)
) on commit preserve rows;

create global temporary table ts_servicio_laptop_f2 (
    num_servicio  number(10, 0) not null,
    laptop_id     number(10, 0) not null,
    factura       blob,
    constraint ts_servicio_laptop_f2_pk primary key (num_servicio, laptop_id)
) on commit preserve rows;

create global temporary table ts_servicio_laptop_f3 (
    num_servicio  number(10, 0) not null,
    laptop_id     number(10, 0) not null,
    factura       blob,
    constraint ts_servicio_laptop_f3_pk primary key (num_servicio, laptop_id)
) on commit preserve rows;

create global temporary table ts_servicio_laptop_f4 (
    num_servicio  number(10, 0) not null,
    laptop_id     number(10, 0) not null,
    factura       blob,
    constraint ts_servicio_laptop_f4_pk primary key (num_servicio, laptop_id)
) on commit preserve rows;