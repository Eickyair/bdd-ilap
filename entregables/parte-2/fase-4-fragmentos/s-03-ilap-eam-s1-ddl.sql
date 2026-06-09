-- Autor       : erick
-- Fecha        : 2026-06-04
-- Descripción  : Esquema local del Nodo 1 (Norte) — PDB eambdd_s1.
--                 Fragmentos: SUCURSAL_F1, SUCURSAL_TALLER_F1, SUCURSAL_VENTA_F1,
--                             LAPTOP_F1, LAPTOP_INVENTARIO_F2,
--                             HISTORICO_STATUS_LAPTOP_F2, SERVICIO_LAPTOP_F1.
--                 Catálogos replicados: TIPO_*, STATUS_LAPTOP.
--                 Invocar desde s-03-ilap-main-ddl.sql conectado como ilap_bdd@eambdd_s1.

-- ============================================================
-- DROP en orden inverso de dependencias (Oracle 23ai)
-- ============================================================
drop table if exists servicio_laptop_f1_eam_s1        cascade constraints purge;
drop table if exists historico_status_laptop_f2_eam_s1 cascade constraints purge;
drop table if exists laptop_inventario_f2_eam_s1       cascade constraints purge;
drop table if exists laptop_f1_eam_s1                  cascade constraints purge;
drop table if exists sucursal_venta_f1_eam_s1          cascade constraints purge;
drop table if exists sucursal_taller_f1_eam_s1         cascade constraints purge;
drop table if exists sucursal_f1_eam_s1                cascade constraints purge;
drop table if exists status_laptop                     cascade constraints purge;
drop table if exists tipo_monitor_r_eam_s1             cascade constraints purge;
drop table if exists tipo_almacenamiento_r_eam_s1      cascade constraints purge;
drop table if exists tipo_tarjeta_video_r_eam_s1       cascade constraints purge;
drop table if exists tipo_procesador_r_eam_s1          cascade constraints purge;

-- ============================================================
-- Catálogos replicados
-- ============================================================

create table tipo_procesador_r_eam_s1 (
    tipo_procesador_id    number(10, 0)   not null,
    clave                 varchar2(40)    not null,
    descripcion           varchar2(200)   not null,
    constraint pk_tipo_proc_r_eam_s1 primary key (tipo_procesador_id)
);

create table tipo_tarjeta_video_r_eam_s1 (
    tipo_tarjeta_video_id  number(10, 0)  not null,
    clave                  varchar2(20)   not null,
    descripcion            varchar2(200)  not null,
    constraint pk_tipo_tv_r_eam_s1 primary key (tipo_tarjeta_video_id)
);

create table tipo_almacenamiento_r_eam_s1 (
    tipo_almacenamiento_id  number(10, 0)  not null,
    clave                   varchar2(20)   not null,
    descripcion             varchar2(200)  not null,
    constraint pk_tipo_alm_r_eam_s1 primary key (tipo_almacenamiento_id)
);

create table tipo_monitor_r_eam_s1 (
    tipo_monitor_id  number(10, 0)  not null,
    clave            varchar2(20)   not null,
    descripcion      varchar2(200)  not null,
    constraint pk_tipo_mon_r_eam_s1 primary key (tipo_monitor_id)
);

create table status_laptop (
    status_laptop_id  number(2, 0)   not null,
    clave             varchar2(20)   not null,
    descripcion       varchar2(200)  not null,
    constraint pk_status_laptop_s1 primary key (status_laptop_id)
);

-- ============================================================
-- Fragmento horizontal primario de SUCURSAL
-- Predicado: (ES_VENTA=1 AND ES_TALLER=1) OR SUBSTR(CLAVE,3,2)='NO'
-- ============================================================
create table sucursal_f1_eam_s1 (
    sucursal_id   number(10, 0)   not null,
    clave         varchar2(10)    not null,
    es_taller     number(1, 0)    not null,
    es_venta      number(1, 0)    not null,
    nombre        varchar2(100)   not null,
    latitud       number(10, 6),
    longitud      number(10, 6),
    url           varchar2(200),
    constraint pk_sucursal_f1_eam_s1 primary key (sucursal_id),
    constraint ck_suc_f1_taller check (es_taller in (0, 1)),
    constraint ck_suc_f1_venta  check (es_venta  in (0, 1))
);

-- ============================================================
-- Fragmento horizontal derivado de SUCURSAL_TALLER
-- Derivado de: SUCURSAL_TALLER ⋉ SUCURSAL_F1_EAM_S1
-- ============================================================
create table sucursal_taller_f1_eam_s1 (
    sucursal_id          number(10, 0)  not null,
    dia_descanso         number(1, 0),
    telefono_atencion    varchar2(20),
    constraint pk_suc_taller_f1_eam_s1 primary key (sucursal_id),
    constraint fk_suc_taller_f1_eam_s1 foreign key (sucursal_id)
        references sucursal_f1_eam_s1 (sucursal_id)
);

-- ============================================================
-- Fragmento horizontal derivado de SUCURSAL_VENTA
-- Derivado de: SUCURSAL_VENTA ⋉ SUCURSAL_F1_EAM_S1
-- ============================================================
create table sucursal_venta_f1_eam_s1 (
    sucursal_id    number(10, 0)  not null,
    hora_apertura  date,
    hora_cierre    date,
    constraint pk_suc_venta_f1_eam_s1 primary key (sucursal_id),
    constraint fk_suc_venta_f1_eam_s1 foreign key (sucursal_id)
        references sucursal_f1_eam_s1 (sucursal_id)
);

-- ============================================================
-- Fragmento híbrido (vertical + horizontal) de LAPTOP
-- Predicado: SUBSTR(NUM_SERIE,1,1) IN ('0','1')  — excluye columna FOTO
-- ============================================================
create table laptop_f1_eam_s1 (
    laptop_id               number(10, 0)  not null,
    num_serie               varchar2(20)   not null,
    cantidad_ram            number(5, 0),
    caracteristicas_extras  varchar2(600),
    tipo_tarjeta_video_id   number(10, 0)  not null,
    tipo_procesador_id      number(10, 0)  not null,
    tipo_almacenamiento_id  number(10, 0)  not null,
    tipo_monitor_id         number(10, 0)  not null,
    laptop_reemplazo_id     number(10, 0),            -- native: cross-node
    constraint pk_laptop_f1_eam_s1 primary key (laptop_id),
    constraint fk_laptop_f1_tv  foreign key (tipo_tarjeta_video_id)
        references tipo_tarjeta_video_r_eam_s1 (tipo_tarjeta_video_id),
    constraint fk_laptop_f1_tp  foreign key (tipo_procesador_id)
        references tipo_procesador_r_eam_s1 (tipo_procesador_id),
    constraint fk_laptop_f1_ta  foreign key (tipo_almacenamiento_id)
        references tipo_almacenamiento_r_eam_s1 (tipo_almacenamiento_id),
    constraint fk_laptop_f1_tm  foreign key (tipo_monitor_id)
        references tipo_monitor_r_eam_s1 (tipo_monitor_id)
);

-- ============================================================
-- Fragmento vertical de LAPTOP_INVENTARIO  (atributos no sensibles)
-- Proyección: LAPTOP_ID, FECHA_STATUS, SUCURSAL_ID, STATUS_LAPTOP_ID
-- ============================================================
create table laptop_inventario_f2_eam_s1 (
    laptop_id         number(10, 0)  not null,
    fecha_status      date,
    sucursal_id       number(10, 0),                  -- native: cross-node
    status_laptop_id  number(2, 0)   not null,
    constraint pk_lap_inv_f2_eam_s1 primary key (laptop_id),
    constraint fk_lap_inv_f2_sl foreign key (status_laptop_id)
        references status_laptop (status_laptop_id)
);

-- ============================================================
-- Fragmento horizontal primario de HISTORICO_STATUS_LAPTOP
-- Predicado: FECHA_STATUS >= TO_DATE('01/01/2010','DD/MM/YYYY')
-- ============================================================
create table historico_status_laptop_f2_eam_s1 (
    historico_status_laptop_id  number(10, 0)  not null,
    fecha_status                date           not null,
    status_laptop_id            number(2, 0)   not null,
    laptop_id                   number(10, 0),          -- native: cross-node
    constraint pk_hsl_f2_eam_s1 primary key (historico_status_laptop_id),
    constraint fk_hsl_f2_sl foreign key (status_laptop_id)
        references status_laptop (status_laptop_id)
);

-- ============================================================
-- Fragmento horizontal derivado de SERVICIO_LAPTOP
-- Derivado de: SERVICIO_LAPTOP ⋉ SUCURSAL_TALLER_F1_EAM_S1
-- ============================================================
create table servicio_laptop_f1_eam_s1 (
    num_servicio  number(10, 0)   not null,
    laptop_id     number(10, 0)   not null,            -- native: cross-node
    importe       number(12, 2),
    diagnostico   varchar2(2000),
    factura       blob,
    sucursal_id   number(10, 0)   not null,
    constraint pk_sl_f1_eam_s1 primary key (num_servicio, laptop_id),
    constraint fk_sl_f1_taller foreign key (sucursal_id)
        references sucursal_taller_f1_eam_s1 (sucursal_id)
);

prompt Fragmentos del Nodo 1 (eambdd_s1) creados correctamente.
