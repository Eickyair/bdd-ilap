-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Crea las vistas globales de iLap que no requieren manejo
--                 especial de BLOB/CLOB. Este script es común para las 4 PDBs.

whenever sqlerror exit rollback;

create or replace view tipo_procesador as
select tipo_procesador_id, clave, descripcion
from tipo_procesador_r1;

create or replace view tipo_tarjeta_video as
select tipo_tarjeta_video_id, clave, descripcion
from tipo_tarjeta_video_r1;

create or replace view tipo_almacenamiento as
select tipo_almacenamiento_id, clave, descripcion
from tipo_almacenamiento_r1;

create or replace view tipo_monitor as
select tipo_monitor_id, clave, descripcion
from tipo_monitor_r1;

create or replace view sucursal as
select sucursal_id, clave, es_taller, es_venta, nombre, latitud, longitud, url
from sucursal_f1
union all
select sucursal_id, clave, es_taller, es_venta, nombre, latitud, longitud, url
from sucursal_f2
union all
select sucursal_id, clave, es_taller, es_venta, nombre, latitud, longitud, url
from sucursal_f3
union all
select sucursal_id, clave, es_taller, es_venta, nombre, latitud, longitud, url
from sucursal_f4;

create or replace view sucursal_taller as
select sucursal_id, dia_descanso, telefono_atencion
from sucursal_taller_f1
union all
select sucursal_id, dia_descanso, telefono_atencion
from sucursal_taller_f2
union all
select sucursal_id, dia_descanso, telefono_atencion
from sucursal_taller_f3
union all
select sucursal_id, dia_descanso, telefono_atencion
from sucursal_taller_f4;

create or replace view sucursal_venta as
select sucursal_id, hora_apertura, hora_cierre
from sucursal_venta_f1
union all
select sucursal_id, hora_apertura, hora_cierre
from sucursal_venta_f2
union all
select sucursal_id, hora_apertura, hora_cierre
from sucursal_venta_f3
union all
select sucursal_id, hora_apertura, hora_cierre
from sucursal_venta_f4;

create or replace view laptop_inventario as
select inv_f2.laptop_id,
       inv_f2.fecha_status,
       inv_f2.sucursal_id,
       inv_f2.status_laptop_id,
       inv_f1.rfc_cliente,
       inv_f1.num_tarjeta
from laptop_inventario_f2 inv_f2
join laptop_inventario_f1 inv_f1
  on inv_f1.laptop_id = inv_f2.laptop_id;

create or replace view historico_status_laptop as
select historico_status_laptop_id, fecha_status, status_laptop_id, laptop_id
from historico_status_laptop_f1
union all
select historico_status_laptop_id, fecha_status, status_laptop_id, laptop_id
from historico_status_laptop_f2;