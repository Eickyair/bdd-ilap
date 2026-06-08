-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Vistas globales con soporte BLOB para el nodo eambdd_s4.

whenever sqlerror exit rollback;

create or replace view laptop as
select q1.laptop_id,
       q1.num_serie,
       q1.cantidad_ram,
       q1.caracteristicas_extras,
       q1.tipo_tarjeta_video_id,
       q1.tipo_procesador_id,
       q1.tipo_almacenamiento_id,
       q1.tipo_monitor_id,
       q1.laptop_reemplazo_id,
       f5.foto
from (
    select laptop_id, num_serie, cantidad_ram, caracteristicas_extras,
           tipo_tarjeta_video_id, tipo_procesador_id, tipo_almacenamiento_id,
           tipo_monitor_id, laptop_reemplazo_id
    from laptop_f1
    union all
    select laptop_id, num_serie, cantidad_ram, caracteristicas_extras,
           tipo_tarjeta_video_id, tipo_procesador_id, tipo_almacenamiento_id,
           tipo_monitor_id, laptop_reemplazo_id
    from laptop_f2
    union all
    select laptop_id, num_serie, cantidad_ram, caracteristicas_extras,
           tipo_tarjeta_video_id, tipo_procesador_id, tipo_almacenamiento_id,
           tipo_monitor_id, laptop_reemplazo_id
    from laptop_f3
    union all
    select laptop_id, num_serie, cantidad_ram, caracteristicas_extras,
           tipo_tarjeta_video_id, tipo_procesador_id, tipo_almacenamiento_id,
           tipo_monitor_id, laptop_reemplazo_id
    from laptop_f4
) q1
join laptop_f5 f5
  on f5.laptop_id = q1.laptop_id;

create or replace view servicio_laptop as
select num_servicio, laptop_id, importe, diagnostico,
       get_remote_factura_f1_by_id(num_servicio, laptop_id) as factura,
       sucursal_id
from servicio_laptop_f1
union all
select num_servicio, laptop_id, importe, diagnostico,
       get_remote_factura_f2_by_id(num_servicio, laptop_id) as factura,
       sucursal_id
from servicio_laptop_f2
union all
select num_servicio, laptop_id, importe, diagnostico,
       get_remote_factura_f3_by_id(num_servicio, laptop_id) as factura,
       sucursal_id
from servicio_laptop_f3
union all
select num_servicio, laptop_id, importe, diagnostico, factura, sucursal_id
from servicio_laptop_f4;