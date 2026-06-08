-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripción  : Sinónimos lógicos de transparencia para el nodo eambdd_s1.
--                 Expone fragmentos como <tabla>_f<n> y réplicas como
--                 <tabla>_r<n> para ocultar la ubicación física.

whenever sqlerror exit rollback;

prompt   Creando sinónimos lógicos en eambdd_s1

create or replace synonym tipo_procesador_r1      for tipo_procesador_r_eam_s1;
create or replace synonym tipo_procesador_r2      for tipo_procesador_r_eam_s2@eambdd_s2.fi.unam;
create or replace synonym tipo_procesador_r3      for tipo_procesador_r_eam_s3@eambdd_s3.fi.unam;
create or replace synonym tipo_procesador_r4      for tipo_procesador_r_eam_s4@eambdd_s4.fi.unam;
create or replace synonym tipo_tarjeta_video_r1   for tipo_tarjeta_video_r_eam_s1;
create or replace synonym tipo_tarjeta_video_r2   for tipo_tarjeta_video_r_eam_s2@eambdd_s2.fi.unam;
create or replace synonym tipo_tarjeta_video_r3   for tipo_tarjeta_video_r_eam_s3@eambdd_s3.fi.unam;
create or replace synonym tipo_tarjeta_video_r4   for tipo_tarjeta_video_r_eam_s4@eambdd_s4.fi.unam;
create or replace synonym tipo_almacenamiento_r1  for tipo_almacenamiento_r_eam_s1;
create or replace synonym tipo_almacenamiento_r2  for tipo_almacenamiento_r_eam_s2@eambdd_s2.fi.unam;
create or replace synonym tipo_almacenamiento_r3  for tipo_almacenamiento_r_eam_s3@eambdd_s3.fi.unam;
create or replace synonym tipo_almacenamiento_r4  for tipo_almacenamiento_r_eam_s4@eambdd_s4.fi.unam;
create or replace synonym tipo_monitor_r1         for tipo_monitor_r_eam_s1;
create or replace synonym tipo_monitor_r2         for tipo_monitor_r_eam_s2@eambdd_s2.fi.unam;
create or replace synonym tipo_monitor_r3         for tipo_monitor_r_eam_s3@eambdd_s3.fi.unam;
create or replace synonym tipo_monitor_r4         for tipo_monitor_r_eam_s4@eambdd_s4.fi.unam;

create or replace synonym sucursal_f1             for sucursal_f1_eam_s1;
create or replace synonym sucursal_f2             for sucursal_f2_eam_s2@eambdd_s2.fi.unam;
create or replace synonym sucursal_f3             for sucursal_f3_eam_s3@eambdd_s3.fi.unam;
create or replace synonym sucursal_f4             for sucursal_f4_eam_s4@eambdd_s4.fi.unam;
create or replace synonym sucursal_taller_f1      for sucursal_taller_f1_eam_s1;
create or replace synonym sucursal_taller_f2      for sucursal_taller_f2_eam_s2@eambdd_s2.fi.unam;
create or replace synonym sucursal_taller_f3      for sucursal_taller_f3_eam_s3@eambdd_s3.fi.unam;
create or replace synonym sucursal_taller_f4      for sucursal_taller_f4_eam_s4@eambdd_s4.fi.unam;
create or replace synonym sucursal_venta_f1       for sucursal_venta_f1_eam_s1;
create or replace synonym sucursal_venta_f2       for sucursal_venta_f2_eam_s2@eambdd_s2.fi.unam;
create or replace synonym sucursal_venta_f3       for sucursal_venta_f3_eam_s3@eambdd_s3.fi.unam;
create or replace synonym sucursal_venta_f4       for sucursal_venta_f4_eam_s4@eambdd_s4.fi.unam;

create or replace synonym laptop_f1               for laptop_f1_eam_s1;
create or replace synonym laptop_f2               for laptop_f2_eam_s2@eambdd_s2.fi.unam;
create or replace synonym laptop_f3               for laptop_f3_eam_s3@eambdd_s3.fi.unam;
create or replace synonym laptop_f4               for laptop_f4_eam_s4@eambdd_s4.fi.unam;
create or replace synonym laptop_f5               for laptop_f5_eam_s4@eambdd_s4.fi.unam;
create or replace synonym laptop_inventario_f1    for laptop_inventario_f1_eam_s3@eambdd_s3.fi.unam;
create or replace synonym laptop_inventario_f2    for laptop_inventario_f2_eam_s1;
create or replace synonym historico_status_laptop_f1 for historico_status_laptop_f1_eam_s2@eambdd_s2.fi.unam;
create or replace synonym historico_status_laptop_f2 for historico_status_laptop_f2_eam_s1;
create or replace synonym servicio_laptop_f1      for servicio_laptop_f1_eam_s1;
create or replace synonym servicio_laptop_f2      for servicio_laptop_f2_eam_s2@eambdd_s2.fi.unam;
create or replace synonym servicio_laptop_f3      for servicio_laptop_f3_eam_s3@eambdd_s3.fi.unam;
create or replace synonym servicio_laptop_f4      for servicio_laptop_f4_eam_s4@eambdd_s4.fi.unam;