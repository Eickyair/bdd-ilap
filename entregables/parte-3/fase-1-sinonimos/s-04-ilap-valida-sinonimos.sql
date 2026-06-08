-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Valida la creación de sinónimos lógicos de la Parte 3 mediante
--                 conteos básicos sobre fragmentos y réplicas accesibles desde
--                 la PDB actual.

whenever sqlerror exit rollback;

prompt Validando sinónimos para tablas replicadas
select
  (select count(*) from tipo_procesador_r1)     as tipo_procesador_r1,
  (select count(*) from tipo_procesador_r2)     as tipo_procesador_r2,
  (select count(*) from tipo_procesador_r3)     as tipo_procesador_r3,
  (select count(*) from tipo_procesador_r4)     as tipo_procesador_r4,
  (select count(*) from tipo_tarjeta_video_r1)  as tipo_tarjeta_video_r1,
  (select count(*) from tipo_tarjeta_video_r2)  as tipo_tarjeta_video_r2,
  (select count(*) from tipo_tarjeta_video_r3)  as tipo_tarjeta_video_r3,
  (select count(*) from tipo_tarjeta_video_r4)  as tipo_tarjeta_video_r4,
  (select count(*) from tipo_almacenamiento_r1) as tipo_almacenamiento_r1,
  (select count(*) from tipo_almacenamiento_r2) as tipo_almacenamiento_r2,
  (select count(*) from tipo_almacenamiento_r3) as tipo_almacenamiento_r3,
  (select count(*) from tipo_almacenamiento_r4) as tipo_almacenamiento_r4,
  (select count(*) from tipo_monitor_r1)        as tipo_monitor_r1,
  (select count(*) from tipo_monitor_r2)        as tipo_monitor_r2,
  (select count(*) from tipo_monitor_r3)        as tipo_monitor_r3,
  (select count(*) from tipo_monitor_r4)        as tipo_monitor_r4
from dual;

prompt Validando sinónimos para sucursal y subtipos
select
  (select count(*) from sucursal_f1)         as sucursal_f1,
  (select count(*) from sucursal_f2)         as sucursal_f2,
  (select count(*) from sucursal_f3)         as sucursal_f3,
  (select count(*) from sucursal_f4)         as sucursal_f4,
  (select count(*) from sucursal_taller_f1)  as sucursal_taller_f1,
  (select count(*) from sucursal_taller_f2)  as sucursal_taller_f2,
  (select count(*) from sucursal_taller_f3)  as sucursal_taller_f3,
  (select count(*) from sucursal_taller_f4)  as sucursal_taller_f4,
  (select count(*) from sucursal_venta_f1)   as sucursal_venta_f1,
  (select count(*) from sucursal_venta_f2)   as sucursal_venta_f2,
  (select count(*) from sucursal_venta_f3)   as sucursal_venta_f3,
  (select count(*) from sucursal_venta_f4)   as sucursal_venta_f4
from dual;

prompt Validando sinónimos para laptop e inventario
select
  (select count(*) from laptop_f1)             as laptop_f1,
  (select count(*) from laptop_f2)             as laptop_f2,
  (select count(*) from laptop_f3)             as laptop_f3,
  (select count(*) from laptop_f4)             as laptop_f4,
  (select count(*) from laptop_f5)             as laptop_f5,
  (select count(*) from laptop_inventario_f1)  as laptop_inventario_f1,
  (select count(*) from laptop_inventario_f2)  as laptop_inventario_f2,
  (select count(*) from historico_status_laptop_f1) as historico_status_laptop_f1,
  (select count(*) from historico_status_laptop_f2) as historico_status_laptop_f2
from dual;

prompt Validando sinónimos para servicio_laptop
select
  (select count(*) from servicio_laptop_f1) as servicio_laptop_f1,
  (select count(*) from servicio_laptop_f2) as servicio_laptop_f2,
  (select count(*) from servicio_laptop_f3) as servicio_laptop_f3,
  (select count(*) from servicio_laptop_f4) as servicio_laptop_f4
from dual;