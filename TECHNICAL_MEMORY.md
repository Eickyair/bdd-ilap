# Memoria Técnica de Arquitectura - BDD Distribuidas

## Control de Cambios
| Fecha | Autor | Versión | Descripción |
| :--- | :--- | :---: | :--- |
| 2026-05-24 | Erick Yair Aguilar Martínez | 1.0 | Diseño inicial del esquema de fragmentación (Proyecto Final Parte 1). |
| 2026-05-25 | Erick Yair Aguilar Martínez | 1.1 | Normalización de la nomenclatura de nodos, PDBs y dominios para respetar la secuencia S1, S2, S3 y S4. |
| 2026-06-04 | Erick Yair Aguilar Martínez | 2.0 | Implementación de Parte 2: infraestructura Docker, tnsnames, usuario ilap_bdd, database links y DDL de fragmentos. |
| 2026-06-07 | GitHub Copilot | 2.1 | Endurecimiento de Oracle Net en Parte 2: `/etc/hosts` se normaliza en ambos contenedores, `tnsnames.ora` y `listener.ora` se dejan legibles para `oracle`, y el listener ahora hace bind en `0.0.0.0` para evitar fallos por hostnames heredados de la imagen base. |
| 2026-06-07 | GitHub Copilot | 2.2 | Corrección de registro dinámico Oracle Net: `local_listener` ya no depende del alias compartido `LISTENER_FREE`; `02-oracle-config.sh` fija `local_listener` a la dirección propia de cada contenedor y ejecuta `alter system register` para registrar `eambdd_s1..s4` en su listener local. |
| 2026-06-07 | GitHub Copilot | 3.0 | Implementación de Parte 3 completa: Fase 1 redefine sinónimos lógicos `*_f<n>` y `*_r<n>` con validador; Fase 2 crea vistas globales, tablas temporales y funciones BLOB; Fase 3 agrega triggers `INSTEAD OF` y un validador estructural separado para la entrega. |
| 2026-06-07 | GitHub Copilot | 4.0 | Implementación de Parte 4: soporte BLOB con `DIRECTORY` y `fx_carga_blob`, integración del paquete oficial `carga-inicial/`, generación de archivos BLOB y orquestador `run-parte-4.sh`. |
| 2026-06-08 | Erick Yair Aguilar Martínez | 4.1 | Alineación de Parte 4 con `pf-04.pdf`: regeneración de los 4 archivos de carga BLOB con `fx_carga_blob` aleatorio (`dbms_random`/`round`, 100 reales por tabla, `.png`), `presentacion-5` migrado a procedimiento almacenado `pr_elimina_carga_inicial`, eliminación del paso `ajuste-catalogos` (redundante con DDL actualizado), flag `--validate` en `run-parte-4.sh`, corrección del predicado F1 en el trigger `SUCURSAL` y limpieza del `.gitignore`. |
| 2026-06-09 | Erick Yair Aguilar Martínez | 4.2 | Migración de scripts a `docker_sqlplus` (usuario erick), corrección de resolución `@@` con `../` en Oracle 23ai, y adición de reporte Markdown en `--validate`. |

---

## 1. Topología de Red y Asignación de Nodos
Se define un entorno de bases de datos distribuidas integrado por **4 nodos**. Para mantener una nomenclatura consistente con la numeración lógica y física del proyecto, los cuatro sitios se nombran de forma homogénea con la secuencia `S1`, `S2`, `S3` y `S4`.

*   **Nodo 1 (Norte):** `eambdd_s1.fi.unam` (Sufijo: `EAM_S1`). Mayor capacidad de procesamiento.
*   **Nodo 2 (Este):** `eambdd_s2.fi.unam` (Sufijo: `EAM_S2`). Mayor capacidad de almacenamiento.
*   **Nodo 3 (Oeste):** `eambdd_s3.fi.unam` (Sufijo: `EAM_S3`). Suite de cifrado, seguridad y privacidad de datos.
*   **Nodo 4 (Sur):** `eambdd_s4.fi.unam` (Sufijo: `EAM_S4`). Especializado en procesamiento de imágenes.

---

## 2. Decisiones de Diseño de Fragmentación y Reconstrucción

### 2.1. Sucursales (`SUCURSAL`, `SUCURSAL_TALLER`, `SUCURSAL_VENTA`)
*   **Esquema de Fragmentación:** Horizontal Primario para `SUCURSAL` basado en la zona (`SUBSTR(CLAVE, 3, 2)`) y en la regla de negocio (ambas funciones o zona NO van a Nodo 1).
*   **Subtipos:** Fragmentación Horizontal Derivada (`SUCURSAL_TALLER ⋉ SUCURSAL_F_i` y `SUCURSAL_VENTA ⋉ SUCURSAL_F_i`).
*   **Expresión de Reconstrucción:**
    $$\text{SUCURSAL} = \bigcup_{i=1}^{4} \text{SUCURSAL\_F\_i}$$

### 2.2. Laptops y Fotos (`LAPTOP`)
*   **Esquema de Fragmentación:** Híbrido. 
    1.  **Vertical:** Separa la columna `FOTO` de los atributos generales.
    2.  **Horizontal:** El fragmento de atributos generales se distribuye en 4 nodos según el primer dígito del número de serie (`[0-1]` $\rightarrow$ N1, `[6-9]` $\rightarrow$ N2, `[4-5]` $\rightarrow$ N3, `[2-3]` $\rightarrow$ N4).
    3.  El fragmento de fotos (`LAPTOP_F5`) se almacena 100% en el **Nodo 4 (Sur)**.
*   **Expresión de Reconstrucción:**
    $$\text{LAPTOP} = \left( \bigcup_{i=1}^{4} \text{LAPTOP\_F\_i} \right) \bowtie_{\text{LAPTOP\_ID}} \text{LAPTOP\_F5}$$

### 2.3. Datos Sensibles de Inventario (`LAPTOP_INVENTARIO`)
*   **Esquema de Fragmentación:** Vertical de 2 vías para aislar datos bancarios/fiscales:
    1.  `LAPTOP_INVENTARIO_F1` (Oeste / Nodo 3): `LAPTOP_ID`, `RFC_CLIENTE`, `NUM_TARJETA` (Cifrado seguro).
    2.  `LAPTOP_INVENTARIO_F2` (Norte / Nodo 1): `LAPTOP_ID`, `FECHA_STATUS`, `SUCURSAL_ID`, `STATUS_LAPTOP_ID`.
*   **Expresión de Reconstrucción:**
    $$\text{LAPTOP\_INVENTARIO} = \text{LAPTOP\_INVENTARIO\_F1} \bowtie_{\text{LAPTOP\_ID}} \text{LAPTOP\_INVENTARIO\_F2}$$

### 2.4. Histórico de Estatus (`HISTORICO_STATUS_LAPTOP`)
*   **Esquema de Fragmentación:** Horizontal Primario basado en rango de fecha:
    -   Hasta 2009 $\rightarrow$ Nodo 2 (Este, Alta Capacidad de Almacenamiento).
    -   A partir de 2010 $\rightarrow$ Nodo 1 (Norte, Alta Capacidad de Procesamiento).
*   **Reconstrucción:** $\text{HISTORICO\_STATUS\_LAPTOP} = \text{HISTORICO\_STATUS\_LAPTOP\_F1} \cup \text{HISTORICO\_STATUS\_LAPTOP\_F2}$

### 2.5. Servicios de Reparación (`SERVICIO_LAPTOP`)
*   **Estrategia:** Fragmentación Horizontal Derivada basada en la sucursal taller donde se realizó la reparación (`SERVICIO_LAPTOP ⋉ SUCURSAL_TALLER_F_i`). Esto asegura la co-localización de facturas PDF y diagnósticos con el nodo donde se encuentra físicamente el taller.
*   **Reconstrucción:** $\text{SERVICIO\_LAPTOP} = \bigcup_{i=1}^{4} \text{SERVICIO\_LAPTOP\_F\_i}$

---

## 3. Catálogos Replicados y Copias Locales
*   `STATUS_LAPTOP`: Copia local estática (Carga manual idéntica en los 4 nodos).
*   `TIPO_PROCESADOR`, `TIPO_TARJETA_VIDEO`, `TIPO_ALMACENAMIENTO`, `TIPO_MONITOR`: Renombrados con sufijo `_R_EAM_S<n>` y configurados para replicación asíncrona automática en futuras fases.

---

## 4. Infraestructura Docker (Parte 2)

### 4.1. Topología de contenedores (equipo individual — iniciales `eam`)

| Contenedor | Hostname | IP | PDBs alojadas |
| :--- | :--- | :--- | :--- |
| `c1-bdd-proy-eam` | `h1-bdd-proy-eam.fi.unam` | `172.20.0.21` | `eambdd_s1`, `eambdd_s2` |
| `c2-bdd-proy-eam` | `h2-bdd-proy-eam.fi.unam` | `172.20.0.22` | `eambdd_s3`, `eambdd_s4` |

*   Red Docker: `bdd-proy-net` (subnet `172.20.0.0/16`).
*   Imagen base: `bdd-eam:1.0` (generada con `docker commit c1-bdd-eam`).
*   Archivo `tnsnames.ora` idéntico en ambos contenedores (`proyecto-final/tnsnames.ora`).

### 4.2. Scripts SQL generados

| Archivo | Descripción |
| :--- | :--- |
| `s-01-ilap-usuario.sql` | Crea el usuario `ilap_bdd` con los 7 privilegios mínimos requeridos. |
| `s-01-ilap-main-usuario.sql` | Orquestador: ejecuta el script anterior en los 4 nodos como `sysdba`. |
| `s-02-ilap-ligas.sql` | Crea 12 database links (3 por nodo). Nombre de liga = nombre global de la PDB destino. |
| `s-03-ilap-eam-s1-ddl.sql` | DDL del Nodo 1 (Norte): 12 tablas con sus restricciones físicas. |
| `s-03-ilap-eam-s2-ddl.sql` | DDL del Nodo 2 (Este): 11 tablas con sus restricciones físicas. |
| `s-03-ilap-eam-s3-ddl.sql` | DDL del Nodo 3 (Oeste): 11 tablas con sus restricciones físicas. |
| `s-03-ilap-eam-s4-ddl.sql` | DDL del Nodo 4 (Sur): 11 tablas; `laptop_f5_eam_s4` precede a `laptop_f4_eam_s4`. |
| `s-03-ilap-main-ddl.sql` | Orquestador: conecta como `ilap_bdd` a cada PDB e invoca el DDL correspondiente. |

### 4.4. Endurecimiento Oracle Net (2026-06-07)

*   `01-docker-up.sh` ahora reescribe `/etc/hosts` dentro de `c1-bdd-proy-eam` y `c2-bdd-proy-eam` para garantizar resolución local de `h1-bdd-proy-eam.fi.unam` / `h2-bdd-proy-eam.fi.unam` y sus shortnames.
*   `tnsnames.ora` y `listener.ora` quedan con permisos de lectura para el usuario `oracle` tras copiarse/escribirse.
*   `listener.ora` usa `HOST = 0.0.0.0` en lugar del FQDN del contenedor para desacoplar el arranque del listener del hostname heredado en la imagen `bdd-eam:1.0`, manteniendo los aliases TNS basados en FQDN.
*   `02-oracle-config.sh` fija `LOCAL_LISTENER` con un `ADDRESS` explícito por contenedor (`h1-bdd-proy-eam.fi.unam:1521` en `c1`, `h2-bdd-proy-eam.fi.unam:1521` en `c2`) y fuerza `alter system register` para evitar que el registro dinámico use el alias compartido `LISTENER_FREE` del `tnsnames.ora` común.

### 4.3. Decisiones de implementación DDL

*   **Tipos Oracle usados:** `NUMBER(10,0)` para IDs, `NUMBER(2,0)` para status, `NUMBER(1,0)` con `CHECK IN (0,1)` para booleanos (ES_TALLER, ES_VENTA), `NUMBER(10,6)` para coordenadas, `DATE` para fechas y horas, `VARCHAR2` con longitudes ajustadas al dominio, `BLOB` para facturas y fotos.
*   **Referencias nativas (cross-node):** Las FK que cruzan nodos se eliminan como restricción física pero el campo se conserva. Están marcadas con el comentario `-- native: cross-node` en cada DDL.
*   **Orden de creación:** catálogos replicados → `STATUS_LAPTOP` → fragmentos de `SUCURSAL` → subtipos → `LAPTOP_F5` (solo Nodo 4) → fragmentos de `LAPTOP` → fragmentos de inventario/histórico → fragmentos de `SERVICIO_LAPTOP`.
*   **`DROP TABLE IF EXISTS`:** Cada DDL inicia con drops en orden inverso usando sintaxis Oracle 23ai; garantiza idempotencia.

---

## 5. Transparencia de Distribución (Parte 3)

### 5.1. Fase 1 — Sinónimos lógicos

* **Convención adoptada:** la capa de transparencia expone fragmentos con la convención `*_f<n>` y tablas replicadas con `*_r<n>`, siguiendo literalmente la guía de `pf-03.pdf`. La ubicación física `*_eam_s<n>` queda encapsulada detrás del sinónimo.
* **Regla operativa:** cada PDB crea sinónimos tanto locales como remotos para que el mismo nombre lógico resuelva en cualquier nodo. Para tablas replicadas, `r1` siempre apunta a la réplica local del nodo actual y `r2..r4` a las demás réplicas.
* **Cobertura:** `SUCURSAL`, `SUCURSAL_TALLER`, `SUCURSAL_VENTA`, `LAPTOP`, `LAPTOP_INVENTARIO`, `HISTORICO_STATUS_LAPTOP`, `SERVICIO_LAPTOP` y los cuatro catálogos replicados `TIPO_*`.
* **Objetos generados:** `s-04-ilap-main-sinonimos.sql`, `s-04-ilap-valida-sinonimos.sql`, `s-04-ilap-eam-s1-sinonimos.sql`, `s-04-ilap-eam-s2-sinonimos.sql`, `s-04-ilap-eam-s3-sinonimos.sql`, `s-04-ilap-eam-s4-sinonimos.sql` y `06-run-sinonimos.sh`.

### 5.2. Fase 2 — Vistas globales y soporte BLOB

* **Vistas comunes:** `TIPO_PROCESADOR`, `TIPO_TARJETA_VIDEO`, `TIPO_ALMACENAMIENTO`, `TIPO_MONITOR`, `SUCURSAL`, `SUCURSAL_TALLER`, `SUCURSAL_VENTA`, `LAPTOP_INVENTARIO` y `HISTORICO_STATUS_LAPTOP` se reconstruyen con columnas explícitas y `UNION ALL` o `JOIN` según el esquema de fragmentación.
* **Manejo BLOB:** `LAPTOP` y `SERVICIO_LAPTOP` usan tablas temporales `TI_*` y `TS_*` junto con funciones `GET_REMOTE_*_BY_ID` para resolver acceso remoto a `FOTO` y `FACTURA`.
* **Vistas por PDB:** cada nodo tiene su propio script `s-05-ilap-eam-s<n>-vistas-blob.sql` para decidir cuándo leer el BLOB localmente y cuándo invocar una función remota.
* **Objetos generados:** `s-05-ilap-vistas.sql`, `s-05-ilap-tablas-temporales.sql`, `s-05-ilap-funciones-blob.sql`, `s-05-ilap-eam-s1-vistas-blob.sql`, `s-05-ilap-eam-s2-vistas-blob.sql`, `s-05-ilap-eam-s3-vistas-blob.sql`, `s-05-ilap-eam-s4-vistas-blob.sql`, `s-05-ilap-main-vistas.sql` y `07-run-vistas.sh`.

### 5.3. Fase 3 — Triggers `INSTEAD OF`

* **Tablas fragmentadas:** `SUCURSAL`, `SUCURSAL_TALLER`, `SUCURSAL_VENTA`, `LAPTOP`, `LAPTOP_INVENTARIO`, `HISTORICO_STATUS_LAPTOP` y `SERVICIO_LAPTOP` implementan transparencia para `INSERT` y `DELETE`; `UPDATE` lanza `-20030`.
* **Errores controlados:** `-20010` para violaciones del esquema de fragmentación horizontal primaria, `-20020` para no localizar el fragmento padre en fragmentación derivada, `-20030` para `UPDATE` no implementado en tablas fragmentadas y `-20040` para fallos de replicación síncrona en catálogos `TIPO_*`.
* **Tablas replicadas:** los catálogos `TIPO_*` propagan `INSERT`, `UPDATE` y `DELETE` de forma síncrona a las 4 réplicas mediante los alias `r1..r4`.
* **Objetos generados:** `s-06-ilap-grant-create-trigger.sql`, `s-06-ilap-main-triggers.sql`, los `s-06-ilap-trigger-*.sql` y `08-run-triggers.sh`.

### 5.4. Validación estructural de la Parte 3

* **Validador separado:** se añadió el par `09-validate-parte-3.sql` y `09-validate-parte-3.sh`.
* **Cobertura del validador:** revisa sinónimos, vistas, tablas temporales, funciones y triggers, además de listar objetos inválidos por PDB.

---

## 6. Carga de Datos y Presentación Final (Parte 4)

### 6.1. Fase 1 — Soporte BLOB local

* **Privilegio adicional:** `s-01-ilap-usuario.sql` concede `CREATE ANY DIRECTORY` a `ilap_bdd` para habilitar la creación de objetos `DIRECTORY` desde la capa de aplicación.
* **Objetos generados:** `s-07-ilap-configuracion-soporte-blobs.sql` crea `PROYECTO_FINAL_LAPTOPS_DIR`, `PROYECTO_FINAL_FACTURAS_DIR` y la función `FX_CARGA_BLOB` en cada PDB.
* **Orquestación:** `s-07-ilap-main-soporte-blobs.sql` ejecuta la configuración en `eambdd_s1..s4`, mientras `07-run-soporte-blobs.sh` automatiza el grant a nivel `SYSDBA` y la compilación desde el contenedor `c1-bdd-proy-eam`.

### 6.2. Fase 2 — Presentación y carga inicial oficial

* **Orquestador SQL:** `s-08-ilap-presentacion-1.sql` recompone toda la BDD hasta Parte 4 reutilizando los scripts de Partes 2 y 3, más el soporte BLOB de `s-07`.
* **Carga manual:** `s-08-ilap-presentacion-2.sql` conecta a cada PDB, ejecuta `DELETE FROM STATUS_LAPTOP`, invoca `@carga-inicial/status_laptop.sql` y hace `COMMIT`.
* **Carga transparente:** `s-08-ilap-presentacion-3.sql` reproduce la secuencia de `pf-04.pdf`: limpieza inicial por dependencias, deshabilitado temporal de `FK_LAPTOP_F4_F5_REMP` en `eambdd_s4`, ejecución de los SQL oficiales de `carga-inicial/` vía vistas globales y reactivación de la restricción al final.
* **Soporte de binarios:** `s-08-ilap-presentacion-3.sh` prepara `laptops` y `facturas` en `/tmp/bdd/proyecto-final/imagenes`, aceptando tanto el ZIP oficial como la carpeta ya descomprimida.
* **Carga BLOB alineada al validador oficial (2026-06-08):** se generaron `carga-inicial/laptop-1.sql`, `carga-inicial/laptop-2.sql`, `carga-inicial/servicio_laptop-1.sql` y `carga-inicial/servicio_laptop-2.sql` a partir de los `*-empty-blob.sql` siguiendo la pág. 10 de `pf-04.pdf`. En `laptop-1.sql` y `servicio_laptop-1.sql` los **primeros 100 inserts** sustituyen `empty_blob()` por `FX_CARGA_BLOB('PROYECTO_FINAL_LAPTOPS_DIR', 'lap'||round(dbms_random.value(1,40))||'.png')` y `FX_CARGA_BLOB('PROYECTO_FINAL_FACTURAS_DIR', 'fa'||round(dbms_random.value(1,40))||'.png')` respectivamente; los 300 inserts restantes y los archivos `-2` conservan `empty_blob()`. Resultado: 100 BLOB reales en `LAPTOP` y 100 en `SERVICIO_LAPTOP`, umbral verificado por `s-08-ilap-presentacion-4.plb`.
* **Eliminación transparente vía procedimiento almacenado (2026-06-08):** `s-08-ilap-presentacion-5.sql` crea `CREATE OR REPLACE PROCEDURE pr_elimina_carga_inicial` que ejecuta los `DELETE` en orden de dependencias con `COMMIT` y `ROLLBACK`+`RAISE` ante cualquier error. Se deshabilita temporalmente `FK_LAPTOP_F4_F5_REMP` en `eambdd_s4` antes del borrado y se reactiva al final.
* **Corrección del trigger `SUCURSAL` (2026-06-08):** `t_dml_sucursal` enrutaba a `SUCURSAL_F1` solo cuando `zona='NO'`, ignorando sucursales con ambas funciones en zonas EA/WS/SO (→ `ORA-20010`). Se restauró el predicado oficial `F1 = (ES_TALLER=1 AND ES_VENTA=1) OR zona='NO'` en las ramas INSERT y DELETE.

### 6.3. Paquete oficial y automatización local

* **Paquete oficial:** `carga-inicial/` contiene los SQL fuente y sus carpetas de imágenes extraídas; `run-parte-4.sh` acepta ZIP o carpeta, depura archivos no `png` y copia `lap*.png` / `fa*.png` a `/tmp/bdd/proyecto-final/imagenes/{laptops,facturas}` en ambos contenedores.
* **Archivos derivados ignorados en git:** `carga-inicial/laptop-1.sql`, `laptop-2.sql`, `servicio_laptop-1.sql` y `servicio_laptop-2.sql` se listan en `.gitignore` por ser generados desde los `*-empty-blob.sql`; se regeneran ejecutando el script Python de la sesión.
* **Logs de ejecución:** `run-parte-4.sh` genera logs en `entregables/parte-4/logs/` con sello de tiempo (ignorados por `.gitignore`).
* **Ejecución interna en contenedores:** `run-parte-4.sh` copia `carga-inicial/` y `fase-2-presentacion/` a `/tmp/bdd/proyecto-final/workdir` dentro de ambos contenedores para evitar problemas de permisos del usuario `oracle`.
* **Flag `--validate`:** `run-parte-4.sh -v` ejecuta automáticamente Presentación 4 (INSERT + replicación) en las 4 PDBs, luego Presentación 5 (DELETE) y Presentación 6 (validación DELETE). La validación de DELETE deja la BDD vacía; relanzar sin la flag para repoblar.
* **Validadores conservados:** `s-08-ilap-presentacion-4.plb` y `s-08-ilap-presentacion-6.plb` son los validadores interactivos oficiales. Para `SERVICIO_LAPTOP` la técnica vigente es `S` (fragmentación derivada por `SUCURSAL_TALLER`).

### 6.4. Migración a docker_sqlplus y corrección de @@ en Oracle 23ai (2026-06-09)

* **Problema:** Oracle 23ai sqlplus con `whenever oserror exit failure rollback` activa trata la falla de resolución de `@@../../../path` con `..` como un `O/S Message: No such file or directory` (error fatal). Los `@@` con rutas relativas (`../../../`) no se resuelven correctamente desde el directorio del script cuando se carga con `@/absolute/path/script.sql`. CWD por defecto de `docker exec --user erick` es `/`, no el directorio del script.

* **Solución aplicada:**
  - Scripts de orquestación (`.sh`) ahora usan `source utils.sh` + `docker_sqlplus CONTAINER /nolog @/abs/path.sql` (ejecuta como usuario `erick`, inyecta `ORACLE_HOME`, `ORACLE_SID`, `PATH`).
  - Los `@@../../../carga-inicial/...` en archivos `.sql` se reemplazaron por `@@/tmp/bdd/proyecto-final/workdir/carga-inicial/...` (rutas absolutas).
  - El `host bash script.sh` en línea 24 de `s-08-ilap-presentacion-3.sql` se corrigió a ruta absoluta similar.

* **Wrapper `docker_sqlplus`** (`entregables/utils.sh` + `entregables/bin/docker_sqlplus.sh`):
  - Función `docker_sqlplus()` en `utils.sh` invoca `${UTILS_BIN}/docker_sqlplus.sh`
  - El wrapper ejecuta: `docker exec -i --user erick -e ORACLE_HOME=... -e ORACLE_SID=free -e PATH=... "$C" sqlplus "$@"`
  - El ejecutable (`bin/docker_sqlplus.sh`) es requerido porque `timeout(1)` no puede invocar funciones bash directamente.
  - `02-oracle-config.sh` NO se migró — retiene sus 16 `su - oracle` (tareas administrativas).

* **Reporte Markdown de validaciones:** `run-parte-4.sh --validate` ahora genera `entregables/parte-4/validacion-parte-4.md` con:
  - Resumen: total/aprobadas/fallidas por validación
  - Detalle por paso: nodo, comando, timestamps, código de salida, output completo del log
  - Funciones `log_validation_result()` y `generate_validation_report()` acumulando resultados.
  - Corrección de bug: `((passed++))` devolvía exit status 1 bajo `set -e` → usar `$((passed + 1))`.

* **Archivos nuevos:** `entregables/utils.sh`, `entregables/bin/docker_sqlplus.sh`, `.opencode/skills/read-pdf/SKILL.md`, `opencode.jsonc`.
* **Scripts modificados:** 10 scripts de orquestación en partes 2, 3 y 4 + 2 archivos `.sql` de presentacion.
