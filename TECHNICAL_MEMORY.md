# Memoria Técnica de Arquitectura - BDD Distribuidas

## Control de Cambios
| Fecha | Autor | Versión | Descripción |
| :--- | :--- | :---: | :--- |
| 2026-05-24 | Erick Yair Aguilar Martínez | 1.0 | Diseño inicial del esquema de fragmentación (Proyecto Final Parte 1). |
| 2026-05-25 | Erick Yair Aguilar Martínez | 1.1 | Normalización de la nomenclatura de nodos, PDBs y dominios para respetar la secuencia S1, S2, S3 y S4. |
| 2026-06-04 | Erick Yair Aguilar Martínez | 2.0 | Implementación de Parte 2: infraestructura Docker, tnsnames, usuario ilap_bdd, database links y DDL de fragmentos. |
| 2026-06-07 | GitHub Copilot | 2.1 | Endurecimiento de Oracle Net en Parte 2: `/etc/hosts` se normaliza en ambos contenedores, `tnsnames.ora` y `listener.ora` se dejan legibles para `oracle`, y el listener ahora hace bind en `0.0.0.0` para evitar fallos por hostnames heredados de la imagen base. |
| 2026-06-07 | GitHub Copilot | 2.2 | Corrección de registro dinámico Oracle Net: `local_listener` ya no depende del alias compartido `LISTENER_FREE`; `02-oracle-config.sh` fija `local_listener` a la dirección propia de cada contenedor y ejecuta `alter system register` para registrar `eambdd_s1..s4` en su listener local. |

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
