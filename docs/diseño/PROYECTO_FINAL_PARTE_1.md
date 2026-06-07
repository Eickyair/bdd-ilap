# UNIVERSIDAD NACIONAL AUTÓNOMA DE MÉXICO

<!-- markdownlint-disable MD013 -->

## FACULTAD DE INGENIERÍA

### BASES DE DATOS DISTRIBUIDAS (SEMESTRE 2026-2)

### PROYECTO FINAL - PARTE 1: DISEÑO DEL ESQUEMA DE FRAGMENTACIÓN

---

**Alumno:** Erick Yair Aguilar Martínez  
**Correo:** [martinezerickaguilar@gmail.com](mailto:martinezerickaguilar@gmail.com)  
**Cuenta:** 319061280  
**Grupo:** 1
**Profesor:** Ing. Jorge A. Rodríguez C.  
**Entorno de Control:** Contenedor Docker: `c1-bdd-eam` (RDBMS Oracle 23ai Free)

---

## 1. Reglas de Negocio y Requerimientos

1. **Sucursales (`SUCURSAL` y subtipos):**
   - Clave: `EEZZ000000` (EE: Estado, ZZ: Zona, 000000: Consecutivo).
   - Zona `NO` y sucursales de venta y taller simultáneas $\rightarrow$ **Sitio Norte** (Nodo 1).
   - Resto de sucursales según su zona (`EA`, `WS`, `SO`) $\rightarrow$ Sitios **Este** (Nodo 2), **Oeste** (Nodo 3) y **Sur** (Nodo 4).
   - Los subtipos `SUCURSAL_TALLER` y `SUCURSAL_VENTA` se fragmentan mediante **fragmentación horizontal derivada** del fragmento correspondiente de `SUCURSAL`.

2. **Laptops (`LAPTOP`):**
   - Fragmentación por el primer dígito de `NUM_SERIE`:
     - `[0-1]` $\rightarrow$ **Sitio Norte** (Nodo 1).
     - `[6-9]` $\rightarrow$ **Sitio Este** (Nodo 2).
     - `[4-5]` $\rightarrow$ **Sitio Oeste** (Nodo 3).
     - `[2-3]` $\rightarrow$ **Sitio Sur** (Nodo 4).
   - **Excepción de Foto:** Las fotos de todas las laptops se almacenan en el **Sitio Sur** (Nodo 4), que es el especialista en tratamiento de imágenes (fragmentación vertical/híbrida).

3. **Datos de Inventario (`LAPTOP_INVENTARIO`):**
   - Es una extensión 1:1 de `LAPTOP` que se fragmenta verticalmente:
     - Datos seguros (`RFC_CLIENTE`, `NUM_TARJETA`) $\rightarrow$ **Sitio Oeste** (Nodo 3), que cuenta con herramientas de cifrado y privacidad.
     - Resto de atributos (`FECHA_STATUS`, `STATUS_LAPTOP_ID`, `SUCURSAL_ID`) $\rightarrow$ **Sitio Norte** (Nodo 1) (mayor capacidad de procesamiento).

4. **Histórico de Estatus (`HISTORICO_STATUS_LAPTOP`):**
   - Historial hasta el año 2009 $\rightarrow$ **Sitio Este** (Nodo 2) (mayor almacenamiento).
   - Historial posterior a 2009 (2010 en adelante) $\rightarrow$ **Sitio Norte** (Nodo 1) (mayor procesamiento).

5. **Servicios de Reparación (`SERVICIO_LAPTOP`):**
   - **Estrategia Seleccionada:** Distribuir con base en la ubicación de las sucursales (talleres). Los servicios se fragmentan horizontalmente de forma derivada de `SUCURSAL_TALLER` para mantener la co-localización de los diagnósticos y facturas con la sucursal que prestó el servicio.

---

## 2. Tabla de Asignación de Sitios

Dado que el proyecto debe respetar una nomenclatura uniforme entre número de nodo, nombre de PDB y dominio global, los cuatro sitios se identifican de forma homogénea con el prefijo `EAM` y la secuencia `S1`, `S2`, `S3` y `S4`.

| Num. Nodo |  Nombre Nodo   |            Características del Sitio             | Nombre Global de la PDB | Sufijo para Fragmentos |
| :-------: | :------------: | :----------------------------------------------: | :---------------------: | :--------------------: |
|   **1**   | **Norte (NO)** |         Mayor capacidad de procesamiento         |   `eambdd_s1.fi.unam`   |        `EAM_S1`        |
|   **2**   | **Este (EA)**  |        Mayor capacidad de almacenamiento         |   `eambdd_s2.fi.unam`   |        `EAM_S2`        |
|   **3**   | **Oeste (WS)** | Herramientas de seguridad y privacidad (cifrado) |   `eambdd_s3.fi.unam`   |        `EAM_S3`        |
|   **4**   |  **Sur (SO)**  |     Especializado en tratamiento de imágenes     |   `eambdd_s4.fi.unam`   |        `EAM_S4`        |

---

## 3. Tabla de Fragmentación de la BDD

Los predicados se especifican como expresiones SQL válidas listas:

| Nombre del Fragmento                  | Tipo de Fragmentación | Ubicación (Nodo / PDB) | Expresión Algebraica / Predicado SQL                                           |
| :------------------------------------ | :-------------------- | :--------------------: | :----------------------------------------------------------------------------- |
| **SUCURSAL_F1_EAM_S1**                | Horizontal Primaria   |   Nodo 1 (`EAM_S1`)    | `(ES_VENTA = 1 AND ES_TALLER = 1) OR SUBSTR(CLAVE, 3, 2) = 'NO'`               |
| **SUCURSAL_F2_EAM_S2**                | Horizontal Primaria   |   Nodo 2 (`EAM_S2`)    | `NOT (ES_VENTA = 1 AND ES_TALLER = 1) AND SUBSTR(CLAVE, 3, 2) = 'EA'`          |
| **SUCURSAL_F3_EAM_S3**                | Horizontal Primaria   |   Nodo 3 (`EAM_S3`)    | `NOT (ES_VENTA = 1 AND ES_TALLER = 1) AND SUBSTR(CLAVE, 3, 2) = 'WS'`          |
| **SUCURSAL_F4_EAM_S4**                | Horizontal Primaria   |   Nodo 4 (`EAM_S4`)    | `NOT (ES_VENTA = 1 AND ES_TALLER = 1) AND SUBSTR(CLAVE, 3, 2) = 'SO'`          |
| **SUCURSAL_TALLER_F1_EAM_S1**         | Horizontal Derivada   |   Nodo 1 (`EAM_S1`)    | `SUCURSAL_TALLER ⋉ SUCURSAL_F1_EAM_S1`                                         |
| **SUCURSAL_TALLER_F2_EAM_S2**         | Horizontal Derivada   |   Nodo 2 (`EAM_S2`)    | `SUCURSAL_TALLER ⋉ SUCURSAL_F2_EAM_S2`                                         |
| **SUCURSAL_TALLER_F3_EAM_S3**         | Horizontal Derivada   |   Nodo 3 (`EAM_S3`)    | `SUCURSAL_TALLER ⋉ SUCURSAL_F3_EAM_S3`                                         |
| **SUCURSAL_TALLER_F4_EAM_S4**         | Horizontal Derivada   |   Nodo 4 (`EAM_S4`)    | `SUCURSAL_TALLER ⋉ SUCURSAL_F4_EAM_S4`                                         |
| **SUCURSAL_VENTA_F1_EAM_S1**          | Horizontal Derivada   |   Nodo 1 (`EAM_S1`)    | `SUCURSAL_VENTA ⋉ SUCURSAL_F1_EAM_S1`                                          |
| **SUCURSAL_VENTA_F2_EAM_S2**          | Horizontal Derivada   |   Nodo 2 (`EAM_S2`)    | `SUCURSAL_VENTA ⋉ SUCURSAL_F2_EAM_S2`                                          |
| **SUCURSAL_VENTA_F3_EAM_S3**          | Horizontal Derivada   |   Nodo 3 (`EAM_S3`)    | `SUCURSAL_VENTA ⋉ SUCURSAL_F3_EAM_S3`                                          |
| **SUCURSAL_VENTA_F4_EAM_S4**          | Horizontal Derivada   |   Nodo 4 (`EAM_S4`)    | `SUCURSAL_VENTA ⋉ SUCURSAL_F4_EAM_S4`                                          |
| **LAPTOP_F1_EAM_S1**                  | Híbrida (V + H)       |   Nodo 1 (`EAM_S1`)    | `SUBSTR(NUM_SERIE, 1, 1) IN ('0', '1')` (Excluye columna `FOTO`)               |
| **LAPTOP_F2_EAM_S2**                  | Híbrida (V + H)       |   Nodo 2 (`EAM_S2`)    | `SUBSTR(NUM_SERIE, 1, 1) IN ('6', '7', '8', '9')` (Excluye columna `FOTO`)     |
| **LAPTOP_F3_EAM_S3**                  | Híbrida (V + H)       |   Nodo 3 (`EAM_S3`)    | `SUBSTR(NUM_SERIE, 1, 1) IN ('4', '5')` (Excluye columna `FOTO`)               |
| **LAPTOP_F4_EAM_S4**                  | Híbrida (V + H)       |   Nodo 4 (`EAM_S4`)    | `SUBSTR(NUM_SERIE, 1, 1) IN ('2', '3')` (Excluye columna `FOTO`)               |
| **LAPTOP_F5_EAM_S4**                  | Vertical              |   Nodo 4 (`EAM_S4`)    | `π LAPTOP_ID, FOTO (LAPTOP)` (Almacena todas las fotos globales)               |
| **LAPTOP_INVENTARIO_F1_EAM_S3**       | Vertical              |   Nodo 3 (`EAM_S3`)    | `π LAPTOP_ID, RFC_CLIENTE, NUM_TARJETA (LAPTOP_INVENTARIO)`                    |
| **LAPTOP_INVENTARIO_F2_EAM_S1**       | Vertical              |   Nodo 1 (`EAM_S1`)    | `π LAPTOP_ID, FECHA_STATUS, SUCURSAL_ID, STATUS_LAPTOP_ID (LAPTOP_INVENTARIO)` |
| **HISTORICO_STATUS_LAPTOP_F1_EAM_S2** | Horizontal Primaria   |   Nodo 2 (`EAM_S2`)    | `FECHA_STATUS < TO_DATE('01/01/2010', 'DD/MM/YYYY')`                           |
| **HISTORICO_STATUS_LAPTOP_F2_EAM_S1** | Horizontal Primaria   |   Nodo 1 (`EAM_S1`)    | `FECHA_STATUS >= TO_DATE('01/01/2010', 'DD/MM/YYYY')`                          |
| **SERVICIO_LAPTOP_F1_EAM_S1**         | Horizontal Derivada   |   Nodo 1 (`EAM_S1`)    | `SERVICIO_LAPTOP ⋉ SUCURSAL_TALLER_F1_EAM_S1`                                  |
| **SERVICIO_LAPTOP_F2_EAM_S2**         | Horizontal Derivada   |   Nodo 2 (`EAM_S2`)    | `SERVICIO_LAPTOP ⋉ SUCURSAL_TALLER_F2_EAM_S2`                                  |
| **SERVICIO_LAPTOP_F3_EAM_S3**         | Horizontal Derivada   |   Nodo 3 (`EAM_S3`)    | `SERVICIO_LAPTOP ⋉ SUCURSAL_TALLER_F3_EAM_S3`                                  |
| **SERVICIO_LAPTOP_F4_EAM_S4**         | Horizontal Derivada   |   Nodo 4 (`EAM_S4`)    | `SERVICIO_LAPTOP ⋉ SUCURSAL_TALLER_F4_EAM_S4`                                  |
| **STATUS_LAPTOP**                     | Copia Local Estática  |   Todos (1, 2, 3, 4)   | `COPIA MANUAL` / `TABLA REPLICADA`                                             |
| `TIPO_PROCESADOR_R_*`                 | Tabla Replicada       |   Todos (1, 2, 3, 4)   | `TABLA REPLICADA`                                                              |
| `TIPO_TARJETA_VIDEO_R_*`              | Tabla Replicada       |   Todos (1, 2, 3, 4)   | `TABLA REPLICADA`                                                              |
| `TIPO_ALMACENAMIENTO_R_*`             | Tabla Replicada       |   Todos (1, 2, 3, 4)   | `TABLA REPLICADA`                                                              |
| `TIPO_MONITOR_R_*`                    | Tabla Replicada       |   Todos (1, 2, 3, 4)   | `TABLA REPLICADA`                                                              |

---

## 4. Expresiones de Reconstrucción Global

La reconstrucción en el DDBMS se define mediante álgebra relacional para asegurar la transparencia de fragmentación.

1. **Sucursales y subtipos:**
   $$\text{SUCURSAL} = \text{SUCURSAL\_F1} \cup \text{SUCURSAL\_F2} \cup \text{SUCURSAL\_F3} \cup \text{SUCURSAL\_F4}$$
   $$\text{SUCURSAL\_TALLER} = \text{SUCURSAL\_TALLER\_F1} \cup \text{SUCURSAL\_TALLER\_F2} \cup \text{SUCURSAL\_TALLER\_F3} \cup \text{SUCURSAL\_TALLER\_F4}$$
   $$\text{SUCURSAL\_VENTA} = \text{SUCURSAL\_VENTA\_F1} \cup \text{SUCURSAL\_VENTA\_F2} \cup \text{SUCURSAL\_VENTA\_F3} \cup \text{SUCURSAL\_VENTA\_F4}$$

2. **Laptops (Reconstrucción Híbrida):**
   $$\text{LAPTOP} = (\text{LAPTOP\_F1} \cup \text{LAPTOP\_F2} \cup \text{LAPTOP\_F3} \cup \text{LAPTOP\_F4}) \bowtie_{\text{LAPTOP\_ID}} \text{LAPTOP\_F5}$$

3. **Inventario de Laptops (Reconstrucción Vertical):**
   $$\text{LAPTOP\_INVENTARIO} = \text{LAPTOP\_INVENTARIO\_F1} \bowtie_{\text{LAPTOP\_ID}} \text{LAPTOP\_INVENTARIO\_F2}$$

4. **Histórico de Estatus:**
   $$\text{HISTORICO\_STATUS\_LAPTOP} = \text{HISTORICO\_STATUS\_LAPTOP\_F1} \cup \text{HISTORICO\_STATUS\_LAPTOP\_F2}$$

5. **Servicios de Reparación:**
   $$\text{SERVICIO\_LAPTOP} = \text{SERVICIO\_LAPTOP\_F1} \cup \text{SERVICIO\_LAPTOP\_F2} \cup \text{SERVICIO\_LAPTOP\_F3} \cup \text{SERVICIO\_LAPTOP\_F4}$$

### 4.1. Verificación de las Propiedades de Fragmentación

Cada reconstrucción global cumple lo siguiente:

1. **`SUCURSAL`:**
   Cumple **completitud** porque toda sucursal cae en alguno de los predicados por zona o en la regla especial del Nodo 1; cumple **reconstrucción** porque la unión de `SUCURSAL_F1` a `SUCURSAL_F4` recompone la tabla global; y cumple **exclusión** porque los predicados son mutuamente excluyentes.

2. **`SUCURSAL_TALLER`:**
   Cumple **completitud** porque todo taller pertenece a una sucursal ubicada en algún fragmento de `SUCURSAL`; cumple **reconstrucción** porque la unión de los fragmentos derivados recompone todos los talleres; y cumple **exclusión** porque un taller solo puede derivarse del fragmento de su sucursal padre.

3. **`SUCURSAL_VENTA`:**
   Cumple **completitud** porque toda sucursal de venta pertenece a una sucursal fragmentada en algún nodo; cumple **reconstrucción** porque la unión de `SUCURSAL_VENTA_F1` a `SUCURSAL_VENTA_F4` restituye la relación global; y cumple **exclusión** porque cada fila se deriva de un único fragmento padre.

4. **`LAPTOP`:**
   Cumple **completitud** porque todos los equipos quedan cubiertos por alguno de los rangos de `NUM_SERIE` y además todas las fotos quedan en `LAPTOP_F5`; cumple **reconstrucción** porque la unión horizontal de `LAPTOP_F1` a `LAPTOP_F4`, seguida del join con `LAPTOP_F5`, recupera la relación global; y cumple **exclusión** bajo la convención de fragmentación híbrida, ya que los rangos de serie no se traslapan y el único atributo repetido intencionalmente es `LAPTOP_ID`, necesario para la reconstrucción vertical.

5. **`LAPTOP_INVENTARIO`:**
   Cumple **completitud** porque entre `LAPTOP_INVENTARIO_F1` y `LAPTOP_INVENTARIO_F2` se cubren todos los atributos del inventario; cumple **reconstrucción** porque ambas proyecciones se recomponen mediante join por `LAPTOP_ID`; y cumple **exclusión** con la salvedad teórica de la clave de enlace, pues los atributos de negocio no se repiten entre fragmentos y solo `LAPTOP_ID` aparece en ambos para permitir la reconstrucción.

6. **`HISTORICO_STATUS_LAPTOP`:**
   Cumple **completitud** porque toda fecha pertenece o bien al conjunto anterior a 2010 o bien al conjunto desde 2010 en adelante; cumple **reconstrucción** porque la unión de ambos fragmentos devuelve todo el histórico; y cumple **exclusión** porque los rangos de fechas son disjuntos.

7. **`SERVICIO_LAPTOP`:**
   Cumple **completitud** porque todo servicio queda asociado a algún `SUCURSAL_TALLER_Fi`; cumple **reconstrucción** porque la unión de `SERVICIO_LAPTOP_F1` a `SERVICIO_LAPTOP_F4` recompone la relación global; y cumple **exclusión** porque cada servicio solo puede pertenecer al fragmento derivado del taller que lo atendió.

---

## 5. Modelos Relacionales Locales (Notación Crow's Foot)

Para mantener la integridad física en cada sitio, solo se declaran como restricciones físicas (`Foreign Keys`) aquellas relaciones en las que tanto el registro padre como el hijo se encuentran **co-localizados** en la misma PDB. Las relaciones que cruzan nodos se declaran como campos nativos (sin restricción física `CONSTRAINT FK`).

### 5.1. Nodo 1: Norte (`EAM_S1`)

[Ver diagrama Mermaid del nodo 1](./nodo1-er.mmd)

### 5.2. Nodo 2: Este (`EAM_S2`)

[Ver diagrama Mermaid del nodo 2](./nodo2-er.mmd)

### 5.3. Nodo 3: Oeste (`EAM_S3`)

[Ver diagrama Mermaid del nodo 3](./nodo3-er.mmd)

### 5.4. Nodo 4: Sur (`EAM_S4`)

[Ver diagrama Mermaid del nodo 4](./nodo4-er.mmd)

---
