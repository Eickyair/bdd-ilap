--@Autor:          Erick Yair Aguilar Martínez
--@Fecha creación: 04/06/2026
--@Descripción:    Esquema local del Nodo 4 (Sur) — PDB eambdd_s4.
--                 Fragmentos: SUCURSAL_F4, SUCURSAL_TALLER_F4, SUCURSAL_VENTA_F4,
--                             LAPTOP_F5 (fotos globales), LAPTOP_F4,
--                             SERVICIO_LAPTOP_F4.
--                 Catálogos replicados: TIPO_*, STATUS_LAPTOP.
--                 Invocar desde s-03-ilap-main-ddl.sql conectado como ilap_bdd@eambdd_s4.

-- ============================================================
-- DROP en orden inverso de dependencias (Oracle 23ai)
-- ============================================================
drop table if exists servicio_laptop_f4_eam_s4       cascade constraints purge;
drop table if exists laptop_f4_eam_s4                cascade constraints purge;
drop table if exists laptop_f5_eam_s4                cascade constraints purge;
drop table if exists sucursal_venta_f4_eam_s4        cascade constraints purge;
drop table if exists sucursal_taller_f4_eam_s4       cascade constraints purge;
drop table if exists sucursal_f4_eam_s4              cascade constraints purge;
drop table if exists status_laptop                   cascade constraints purge;
drop table if exists tipo_monitor_r_eam_s4           cascade constraints purge;
drop table if exists tipo_almacenamiento_r_eam_s4    cascade constraints purge;
drop table if exists tipo_tarjeta_video_r_eam_s4     cascade constraints purge;
drop table if exists tipo_procesador_r_eam_s4        cascade constraints purge;

-- ============================================================
-- Catálogos replicados
-- ============================================================

create table tipo_procesador_r_eam_s4 (
    tipo_procesador_id    number(10, 0)   not null,
    clave                 varchar2(20)    not null,
    descripcion           varchar2(200)   not null,
    constraint pk_tipo_proc_r_eam_s4 primary key (tipo_procesador_id)
);

create table tipo_tarjeta_video_r_eam_s4 (
    tipo_tarjeta_video_id  number(10, 0)  not null,
    clave                  varchar2(20)   not null,
    descripcion            varchar2(200)  not null,
    constraint pk_tipo_tv_r_eam_s4 primary key (tipo_tarjeta_video_id)
);

create table tipo_almacenamiento_r_eam_s4 (
    tipo_almacenamiento_id  number(10, 0)  not null,
    clave                   varchar2(20)   not null,
    descripcion             varchar2(200)  not null,
    constraint pk_tipo_alm_r_eam_s4 primary key (tipo_almacenamiento_id)
);

create table tipo_monitor_r_eam_s4 (
    tipo_monitor_id  number(10, 0)  not null,
    clave            varchar2(20)   not null,
    descripcion      varchar2(200)  not null,
    constraint pk_tipo_mon_r_eam_s4 primary key (tipo_monitor_id)
);

create table status_laptop (
    status_laptop_id  number(2, 0)   not null,
    clave             varchar2(20)   not null,
    descripcion       varchar2(200)  not null,
    constraint pk_status_laptop_s4 primary key (status_laptop_id)
);

-- ============================================================
-- Fragmento horizontal primario de SUCURSAL
-- Predicado: NOT (ES_VENTA=1 AND ES_TALLER=1) AND SUBSTR(CLAVE,3,2)='SO'
-- ============================================================
create table sucursal_f4_eam_s4 (
    sucursal_id   number(10, 0)   not null,
    clave         varchar2(10)    not null,
    es_taller     number(1, 0)    not null,
    es_venta      number(1, 0)    not null,
    nombre        varchar2(100)   not null,
    latitud       number(10, 6),
    longitud      number(10, 6),
    url           varchar2(200),
    constraint pk_sucursal_f4_eam_s4 primary key (sucursal_id),
    constraint ck_suc_f4_taller check (es_taller in (0, 1)),
    constraint ck_suc_f4_venta  check (es_venta  in (0, 1))
);

-- ============================================================
-- Fragmento horizontal derivado de SUCURSAL_TALLER
-- Derivado de: SUCURSAL_TALLER ⋉ SUCURSAL_F4_EAM_S4
-- ============================================================
create table sucursal_taller_f4_eam_s4 (
    sucursal_id          number(10, 0)  not null,
    dia_descanso         number(1, 0),
    telefono_atencion    varchar2(15),
    constraint pk_suc_taller_f4_eam_s4 primary key (sucursal_id),
    constraint fk_suc_taller_f4_eam_s4 foreign key (sucursal_id)
        references sucursal_f4_eam_s4 (sucursal_id)
);

-- ============================================================
-- Fragmento horizontal derivado de SUCURSAL_VENTA
-- Derivado de: SUCURSAL_VENTA ⋉ SUCURSAL_F4_EAM_S4
-- ============================================================
create table sucursal_venta_f4_eam_s4 (
    sucursal_id    number(10, 0)  not null,
    hora_apertura  date,
    hora_cierre    date,
    constraint pk_suc_venta_f4_eam_s4 primary key (sucursal_id),
    constraint fk_suc_venta_f4_eam_s4 foreign key (sucursal_id)
        references sucursal_f4_eam_s4 (sucursal_id)
);

-- ============================================================
-- Fragmento vertical de LAPTOP — FOTOS GLOBALES
-- Proyección: LAPTOP_ID, FOTO  (almacena fotos de TODOS los nodos)
-- Debe crearse antes que LAPTOP_F4 porque éste lo referencia.
-- ============================================================
create table laptop_f5_eam_s4 (
    laptop_id  number(10, 0)  not null,
    foto       blob           not null,
    constraint pk_laptop_f5_eam_s4 primary key (laptop_id)
);

-- ============================================================
-- Fragmento híbrido (vertical + horizontal) de LAPTOP
-- Predicado: SUBSTR(NUM_SERIE,1,1) IN ('2','3') — excluye FOTO
-- LAPTOP_ID y LAPTOP_REEMPLAZO_ID referencian LAPTOP_F5 co-localizado.
-- ============================================================
create table laptop_f4_eam_s4 (
    laptop_id               number(10, 0)  not null,
    num_serie               varchar2(20)   not null,
    cantidad_ram            number(5, 0),
    caracteristicas_extras  varchar2(500),
    tipo_tarjeta_video_id   number(10, 0)  not null,
    tipo_procesador_id      number(10, 0)  not null,
    tipo_almacenamiento_id  number(10, 0)  not null,
    tipo_monitor_id         number(10, 0)  not null,
    laptop_reemplazo_id     number(10, 0),
    constraint pk_laptop_f4_eam_s4 primary key (laptop_id),
    constraint fk_laptop_f4_f5      foreign key (laptop_id)
        references laptop_f5_eam_s4 (laptop_id),
    constraint fk_laptop_f4_f5_remp foreign key (laptop_reemplazo_id)
        references laptop_f5_eam_s4 (laptop_id),
    constraint fk_laptop_f4_tv  foreign key (tipo_tarjeta_video_id)
        references tipo_tarjeta_video_r_eam_s4 (tipo_tarjeta_video_id),
    constraint fk_laptop_f4_tp  foreign key (tipo_procesador_id)
        references tipo_procesador_r_eam_s4 (tipo_procesador_id),
    constraint fk_laptop_f4_ta  foreign key (tipo_almacenamiento_id)
        references tipo_almacenamiento_r_eam_s4 (tipo_almacenamiento_id),
    constraint fk_laptop_f4_tm  foreign key (tipo_monitor_id)
        references tipo_monitor_r_eam_s4 (tipo_monitor_id)
);

-- ============================================================
-- Fragmento horizontal derivado de SERVICIO_LAPTOP
-- Derivado de: SERVICIO_LAPTOP ⋉ SUCURSAL_TALLER_F4_EAM_S4
-- ============================================================
create table servicio_laptop_f4_eam_s4 (
    num_servicio  number(10, 0)   not null,
    laptop_id     number(10, 0)   not null,            -- native: cross-node
    importe       number(12, 2),
    diagnostico   varchar2(2000),
    factura       blob,
    sucursal_id   number(10, 0)   not null,
    constraint pk_sl_f4_eam_s4 primary key (num_servicio, laptop_id),
    constraint fk_sl_f4_taller foreign key (sucursal_id)
        references sucursal_taller_f4_eam_s4 (sucursal_id)
);

prompt Fragmentos del Nodo 4 (eambdd_s4) creados correctamente.
