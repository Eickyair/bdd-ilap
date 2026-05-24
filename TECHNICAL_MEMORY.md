# Memoria Técnica de Arquitectura - BDD Distribuidas

## Control de Cambios
| Fecha | Autor | Versión | Descripción |
| :--- | :--- | :---: | :--- |
| 2026-05-24 | Erick Yair Aguilar Martínez | 1.0 | Diseño inicial del esquema de fragmentación (Proyecto Final Parte 1). |

---

## 1. Topología de Red y Asignación de Nodos
Se define un entorno de bases de datos distribuidas integrado por **4 nodos** (simulado de forma individual usando las iniciales `EAM` e `IAM`):

*   **Nodo 1 (Norte):** `eambdd_s1.fi.unam` (Sufijo: `EAM_S1`). Mayor capacidad de procesamiento.
*   **Nodo 2 (Este):** `eambdd_s2.fi.unam` (Sufijo: `EAM_S2`). Mayor capacidad de almacenamiento.
*   **Nodo 3 (Oeste):** `iambdd_s1.fi.unam` (Sufijo: `IAM_S1`). Suite de cifrado, seguridad y privacidad de datos.
*   **Nodo 4 (Sur):** `iambdd_s2.fi.unam` (Sufijo: `IAM_S2`). Especializado en procesamiento de imágenes.

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
*   `TIPO_PROCESADOR`, `TIPO_TARJETA_VIDEO`, `TIPO_ALMACENAMIENTO`, `TIPO_MONITOR`: Renombrados con sufijo `_R_<iniciales>_S<n>` y configurados para replicación asíncrona automática en futuras fases.
