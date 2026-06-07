# Contexto del Proyecto iLap — BDD Distribuida (UNAM FI, Semestre 2026-2)

> Archivo de referencia importado por `CLAUDE.md` (`@docs/CONTEXTO_PROYECTO.md`). Describe el alcance, modelo y estado del proyecto. **No** contiene decisiones de implementación congeladas: esas viven en `TECHNICAL_MEMORY.md`.

## Contexto general
Diseñar, implementar y optimizar una Base de Datos Distribuida de **4 nodos** con Oracle 23ai sobre Docker, para administrar el negocio de la empresa ficticia **iLap** (venta y mantenimiento de laptops de alto desempeño). Proyecto **individual** (los 4 nodos a cargo de Erick Yair Aguilar Martínez).

## Modelo de datos global
| Tabla | Descripción |
|---|---|
| `SUCURSAL` | Catálogo central. Subtipos: `SUCURSAL_VENTA` (hora apertura/cierre) y `SUCURSAL_TALLER` (teléfono, día de descanso). Una sucursal puede ser ambos. |
| `LAPTOP` | Equipos: número de serie (18 chars), RAM, características extra, foto (BLOB) y catálogos de componentes. |
| `STATUS_LAPTOP` | Ciclo de vida: EN PEDIDO, EN SUCURSAL, DEFECTUOSO, EN VENTA, VENDIDO, EN REPARACIÓN, REPARADO. |
| `LAPTOP_INVENTARIO` | Inventario: estatus actual, fecha, RFC cliente, número de tarjeta, sucursal. |
| `HISTORICO_STATUS_LAPTOP` | Historia completa de cambios de estatus de cada laptop. |
| `SERVICIO_LAPTOP` | Reparaciones: diagnóstico, importe, factura PDF (BLOB). |
| Catálogos | `TIPO_PROCESADOR`, `TIPO_TARJETA_VIDEO`, `TIPO_ALMACENAMIENTO`, `TIPO_MONITOR`. |

## Topología de los 4 nodos (iniciales EAM)
| Nodo | Nombre | PDB | Sufijo | Especialización |
|---|---|---|---|---|
| 1 | Norte (NO) | `eambdd_s1.fi.unam` | `EAM_S1` | Mayor capacidad de procesamiento |
| 2 | Este (EA) | `eambdd_s2.fi.unam` | `EAM_S2` | Mayor capacidad de almacenamiento |
| 3 | Oeste (WS) | `eambdd_s3.fi.unam` | `EAM_S3` | Seguridad y cifrado de datos |
| 4 | Sur (SO) | `eambdd_s4.fi.unam` | `EAM_S4` | Procesamiento de imágenes |

**Infraestructura Docker:** 2 contenedores — `c1-bdd-proy-eam` (S1+S2) y `c2-bdd-proy-eam` (S3+S4) — en la red `bdd-proy-net` (172.20.0.0/16).

## Esquema de fragmentación
| Tabla | Tipo | Regla / Predicado |
|---|---|---|
| `SUCURSAL` | Horizontal primario (4 frags) | Zona en clave (`SUBSTR(CLAVE,3,2)`); ambas funciones o zona NO → N1; EA→N2, WS→N3, SO→N4 |
| `SUCURSAL_TALLER`, `SUCURSAL_VENTA` | Horizontal derivado | Sigue a `SUCURSAL` (semijoin) |
| `LAPTOP` (atributos) | Horizontal (4 frags) | Primer dígito del núm. de serie: [0-1]→N1, [6-9]→N2, [4-5]→N3, [2-3]→N4 |
| `LAPTOP` (foto) | Vertical → N4 | `FOTO` siempre en Nodo 4 (procesamiento de imágenes) |
| `LAPTOP_INVENTARIO` | Vertical (2 frags) | `RFC_CLIENTE` + `NUM_TARJETA` → N3 (cifrado); resto → N1 |
| `HISTORICO_STATUS_LAPTOP` | Horizontal por fecha | `FECHA_STATUS <= 2009` → N2; `> 2009` → N1 |
| `SERVICIO_LAPTOP` | Horizontal derivado | Sigue a la sucursal taller donde se hizo la reparación |
| `STATUS_LAPTOP` | Copia manual | Idéntica en los 4 nodos |
| `TIPO_*` (4 catálogos) | Tabla replicada | Renombradas con sufijo `_R_EAM_S<n>` |

## Las 4 partes del proyecto
- **Parte 1 — Diseño (COMPLETADA).** Esquema global, tabla de fragmentación, modelos ER locales (Crow's Foot) por nodo, tabla de asignación de sitios. Documentado en `entregables/PROYECTO_FINAL_PARTE_1.md`.
- **Parte 2 — Infraestructura y DDL (COMPLETADA).** Scripts en `entregables/parte-2/`:
  - `s-01-ilap-usuario.sql` — crea usuario `ilap_bdd` con 7 privilegios mínimos
  - `s-01-ilap-main-usuario.sql` — ejecuta el anterior en los 4 nodos
  - `s-02-ilap-ligas.sql` — 12 database links (3 por nodo, bidireccionales)
  - `s-03-ilap-eam-s{1..4}-ddl.sql` — DDL de fragmentos por nodo (~11–12 tablas c/u)
  - `s-03-ilap-main-ddl.sql` — orquestador DDL
- **Parte 3 — Transparencia de distribución (PENDIENTE, siguiente paso).**
  - Sinónimos `s-04-ilap-<pdb>-sinonimos.sql` — ocultan sufijos (`sucursal_f1` → `sucursal_f1_eam_s1`; replicadas: `tipo_monitor_r1..r4`)
  - Vistas globales `s-05-ilap-vistas.sql` — reconstruyen tablas completas con `UNION ALL` sobre los sinónimos; BLOB/CLOB con manejo especial (tablas temporales y funciones)
  - Triggers DML `s-06-ilap-triggers.sql` — `INSTEAD OF` para INSERT/DELETE sobre vistas; en replicadas el trigger propaga a las 4 réplicas de forma síncrona
  - Scripts main orquestadores de sinónimos, vistas y triggers
- **Parte 4 — Carga de datos y presentación final (PENDIENTE).**
  - `s-07-ilap-configuracion-soporte-blobs.sql` — objetos `DIRECTORY` + función `fx_carga_blob`
  - `s-08-ilap-presentacion-1.sql` — orquestador maestro (s-01 a s-07)
  - `s-08-ilap-presentacion-2.sql` — carga manual de `STATUS_LAPTOP`
  - `s-08-ilap-presentacion-3.sql` — carga con transparencia (INSERT vía vistas)
  - `s-08-ilap-presentacion-4.sql` — validación INSERT + replicadas (`.plb` ya existe)
  - `s-08-ilap-presentacion-5.sql` — eliminación transparente (DELETE vía vistas)
  - `s-08-ilap-presentacion-6.sql` — validación DELETE (`.plb` ya existe)

## Estado actual
| Fase | Estado |
|---|---|
| Parte 1: Diseño de fragmentación | Completada |
| Parte 2: Docker + usuarios + ligas + DDL | Completada |
| Parte 3: Sinónimos + Vistas + Triggers | **Pendiente — siguiente paso** |
| Parte 4: Soporte BLOB + carga + presentación | Pendiente |