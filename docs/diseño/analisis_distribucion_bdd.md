# Análisis de Distribución de la Base de Datos Distribuida (iLap)

Este documento presenta un análisis formal para la distribución de datos del proyecto de la materia de **Bases de Datos Distribuidas**. A partir de las reglas del negocio, el modelo relacional global y el perfil de hardware de cada uno de los 4 nodos, se valida y justifica la propuesta de diseño físico y fragmentación.

---

## 1. Modelo Relacional Global

El modelo relacional global consta de 12 entidades que administran la operación de venta, talleres, inventario y reparaciones de la empresa **iLap**. A continuación se visualiza el diagrama relacional global extraído del material de apoyo:

![Modelo Relacional Global](/home/erick/.gemini/antigravity/brain/5abe1f55-50f1-4e0d-b639-1e36b3f5ea42/artifacts/extracted-img-002.png)

### Tabla de Relaciones del Modelo Global

A continuación se detallan todas las relaciones existentes en el modelo global, su cardinalidad y el atributo que actúa como enlace (`Join Attribute`):

| # | Entidad Padre | Entidad Hija | Tipo de Relación | Cardinalidad | Atributo de Join | Descripción de la Relación |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | `SUCURSAL` | `SUCURSAL_TALLER` | Especialización (ISA) | 1:1 a 0..1 | `SUCURSAL_ID` | Una sucursal puede estar especializada como taller de reparación. |
| **2** | `SUCURSAL` | `SUCURSAL_VENTA` | Especialización (ISA) | 1:1 a 0..1 | `SUCURSAL_ID` | Una sucursal puede estar especializada como punto de venta. |
| **3** | `SUCURSAL_TALLER` | `SERVICIO_LAPTOP` | Uno a Muchos (1:N) | 1:1 a 0..* | `SUCURSAL_ID` | Una sucursal taller realiza cero o muchos servicios de reparación. |
| **4** | `LAPTOP` | `SERVICIO_LAPTOP` | Uno a Muchos (1:N) | 1:1 a 0..* | `LAPTOP_ID` | Una laptop (modelo/unidad) puede recibir cero o muchos servicios de reparación. |
| **5** | `LAPTOP` | `LAPTOP` (Recursiva) | Uno a Muchos (1:N) | 0..1 a 0..* | `LAPTOP_REEMPLAZO_ID` | Relación recursiva que asocia una laptop defectuosa con su equipo de reemplazo. |
| **6** | `TIPO_PROCESADOR` | `LAPTOP` | Uno a Muchos (1:N) | 1:1 a 0..* | `TIPO_PROCESADOR_ID` | Un tipo de procesador clasifica las características de CPU de múltiples laptops. |
| **7** | `TIPO_TARJETA_VIDEO`| `LAPTOP` | Uno a Muchos (1:N) | 1:1 a 0..* | `TIPO_TARJETA_VIDEO_ID` | Un tipo de GPU clasifica las características de tarjeta de video de múltiples laptops. |
| **8** | `TIPO_ALMACENAMIENTO`| `LAPTOP` | Uno a Muchos (1:N) | 1:1 a 0..* | `TIPO_ALMACENAMIENTO_ID` | Un tipo de disco define las características de almacenamiento de múltiples laptops. |
| **9** | `TIPO_MONITOR` | `LAPTOP` | Uno a Muchos (1:N) | 1:1 a 0..* | `TIPO_MONITOR_ID` | Un tipo de monitor define las características de pantalla de múltiples laptops. |
| **10** | `LAPTOP` | `LAPTOP_INVENTARIO` | Uno a Uno (1:1) | 1:1 a 0..1 | `LAPTOP_ID` | Una laptop física en inventario posee un único registro de estado y ubicación actual. |
| **11** | `SUCURSAL_VENTA` | `LAPTOP_INVENTARIO` | Uno a Muchos (1:N) | 0..1 a 0..* | `SUCURSAL_ID` | Una sucursal de venta almacena y administra cero o muchos equipos en su inventario físico. |
| **12** | `STATUS_LAPTOP` | `LAPTOP_INVENTARIO` | Uno a Muchos (1:N) | 1:1 a 0..* | `STATUS_LAPTOP_ID` | Un estatus de ciclo de vida es asignado a cero o muchas laptops en inventario. |
| **13** | `STATUS_LAPTOP` | `HISTORICO_STATUS_LAPTOP` | Uno a Muchos (1:N) | 1:1 a 0..* | `STATUS_LAPTOP_ID` | Un estatus del ciclo de vida se registra en múltiples entradas del historial. |
| **14** | `LAPTOP` | `HISTORICO_STATUS_LAPTOP` | Uno a Muchos (1:N) | 1:1 a 0..* | `LAPTOP_ID` | Una laptop registra todos sus cambios de estado en múltiples entradas históricas. |

---

## 2. Contexto de Negocio, Distribución y Hardware

Para validar la propuesta de solución, primero debemos recordar el contexto del hardware y los criterios de fragmentación:

| Num. Nodo | Ubicación / Rol | Características de Hardware | Fragmentación Principal Aplicada |
| :---: | :--- | :--- | :--- |
| **1 (Norte)** | `EAM_S1` | **Máximo Procesamiento** | Sucursales de zona `NO` / mixtas. Laptops serie `[0-1]`. Inventario público (`LAPTOP_INVENTARIO` F2). Histórico reciente (> 2009). |
| **2 (Este)** | `EAM_S2` | **Máximo Almacenamiento** | Sucursales de zona `EA`. Laptops serie `[6-9]`. Histórico antiguo (<= 2009). |
| **3 (Oeste)** | `EAM_S3` | **Seguridad y Cifrado (Privacidad)** | Sucursales de zona `WS`. Laptops serie `[4-5]`. Inventario privado (`RFC_CLIENTE`, `NUM_TARJETA` - F1). |
| **4 (Sur)** | `EAM_S4` | **Especialista en Imágenes** | Sucursales de zona `SO`. Laptops serie `[2-3]`. Fotos de laptops (`FOTO` - F5). |

### Estrategia de Selección de Servicios
Para la tabla `SERVICIO_LAPTOP`, se ha seleccionado la **Estrategia 1 (distribuir con base en la sucursal taller)**. Esto garantiza que las facturas (`FACTURA` de tipo BLOB) y los diagnósticos extensos de reparación se guarden localmente en el nodo del taller que atendió la reparación, evitando tráficos de red masivos e innecesarios al insertar o consultar diagnósticos y archivos adjuntos.

---

## 3. Validación y Análisis Nodo a Nodo (Preservación de Relaciones)

En una base de datos distribuida, una relación lógica (FK) del modelo global **sólo puede preservarse como una restricción física (`Foreign Key` en la base de datos local)** si se cumple el **Principio de Co-localización**: *tanto el registro padre como el registro hijo deben garantizar que residirán en el mismo sitio físico (mismo nodo)*. Si existe la posibilidad de que el padre esté en un nodo y el hijo en otro, la relación debe declararse lógicamente como campo nativo (`Native`) y no como un constraint físico de integridad referencial.

A continuación, validamos cada una de las 14 relaciones globales en cada nodo:

### 3.1. Nodo 1: Norte (`EAM_S1`) - Sitio de Procesamiento

#### Relaciones que SÍ se preservan físicamente:
*   **`SUCURSAL` (F1) $\rightarrow$ `SUCURSAL_TALLER` (F1) y `SUCURSAL_VENTA` (F1)**:
    *   *Justificación:* Los subtipos se fragmentan con fragmentación horizontal derivada bajo el mismo predicado que `SUCURSAL_F1` (zona `NO` o mixtas). Por ende, si una sucursal con `SUCURSAL_ID = X` está en el Nodo 1, sus datos de taller y venta correspondientes también se alojarán en el Nodo 1.
*   **`SUCURSAL_TALLER` (F1) $\rightarrow$ `SERVICIO_LAPTOP` (F1)**:
    *   *Justificación:* Al utilizar la Estrategia 1, `SERVICIO_LAPTOP_F1` es una fragmentación horizontal derivada de `SUCURSAL_TALLER_F1`. Ambas tablas comparten la partición por zona geográfica (`NO`), co-localizando los servicios con la sucursal correspondiente.
*   **`STATUS_LAPTOP` (Replicada) $\rightarrow$ `LAPTOP_INVENTARIO` (F2)**:
    *   *Justificación:* `STATUS_LAPTOP` se encuentra cargada manualmente en todos los nodos (es local). Dado que `LAPTOP_INVENTARIO_F2` (datos públicos del inventario global) está en el Nodo 1, la relación con su estatus es local.
*   **`STATUS_LAPTOP` (Replicada) $\rightarrow$ `HISTORICO_STATUS_LAPTOP` (F2)**:
    *   *Justificación:* El fragmento de históricos posteriores a 2009 reside en este nodo. Como `STATUS_LAPTOP` está presente localmente, la clave foránea se puede validar físicamente.
*   **Catalogs (`TIPO_*` Replicados) $\rightarrow$ `LAPTOP` (F1)**:
    *   *Justificación:* Las especificaciones de hardware de laptops de la serie `[0-1]` (locales en `LAPTOP_F1`) apuntan a catálogos replicados físicamente en el mismo nodo.

#### Relaciones que NO se preservan físicamente (Campos "Native"):
*   **`LAPTOP` (F1) $\rightarrow$ `SERVICIO_LAPTOP` (F1)**:
    *   *Justificación:* `LAPTOP` se fragmenta por número de serie, mientras que `SERVICIO_LAPTOP` se fragmenta por ubicación del taller. Una laptop de la serie `[2-3]` (ubicada en el Nodo 4) puede recibir servicio en un taller de la zona `NO` (almacenado en el Nodo 1). Como el padre puede estar en otro nodo, no puede haber una restricción física FK.
*   **`LAPTOP` $\rightarrow$ `LAPTOP` (Reemplazo)**:
    *   *Justificación:* El reemplazo de una laptop defectuosa de la serie `[0-1]` puede ser un modelo de reemplazo de la serie `[6-9]` (cuyos datos residen en el Nodo 2). La relación cruza nodos.
*   **`LAPTOP` (F1) $\rightarrow$ `LAPTOP_INVENTARIO` (F2)**:
    *   *Justificación:* `LAPTOP_INVENTARIO_F2` es un fragmento vertical que almacena datos públicos de **todas** las laptops del inventario global, pero `LAPTOP_F1` solo almacena los datos generales de las laptops con serie `[0-1]`. Como el inventario en el Nodo 1 contiene registros de laptops de otras series, la relación cruza a los Nodos 2, 3 y 4.
*   **`SUCURSAL_VENTA` (F1) $\rightarrow$ `LAPTOP_INVENTARIO` (F2)**:
    *   *Justificación:* Una laptop en inventario (`LAPTOP_INVENTARIO_F2`) puede estar asignada físicamente a una sucursal de venta de la zona Este (`SUCURSAL_VENTA_F2` en Nodo 2). Por ende, el campo `SUCURSAL_ID` en el inventario local puede hacer referencia a una sucursal de otro nodo.
*   **`LAPTOP` (F1) $\rightarrow$ `HISTORICO_STATUS_LAPTOP` (F2)**:
    *   *Justificación:* El histórico en este nodo contiene el historial reciente (>2009) de **todas** las laptops globales. Las laptops correspondientes pueden tener sus datos generales en otros nodos.

---

### 3.2. Nodo 2: Este (`EAM_S2`) - Sitio de Almacenamiento

#### Relaciones que SÍ se preservan físicamente:
*   **`SUCURSAL` (F2) $\rightarrow$ `SUCURSAL_TALLER` (F2) y `SUCURSAL_VENTA` (F2)**:
    *   *Justificación:* Fragmentación derivada bajo el mismo predicado (zona `EA`). La co-localización está garantizada.
*   **`SUCURSAL_TALLER` (F2) $\rightarrow$ `SERVICIO_LAPTOP` (F2)**:
    *   *Justificación:* Los servicios en este nodo corresponden al fragmento derivado de los talleres de la zona Este. Ambos residen en el mismo nodo.
*   **`STATUS_LAPTOP` (Replicada) $\rightarrow$ `HISTORICO_STATUS_LAPTOP` (F1)**:
    *   *Justificación:* El fragmento de históricos antiguos (<=2009) reside en este nodo y tiene acceso local a la tabla replicada `STATUS_LAPTOP`.
*   **Catalogs (`TIPO_*` Replicados) $\rightarrow$ `LAPTOP` (F2)**:
    *   *Justificación:* Las laptops de la serie `[6-9]` apuntan a los catálogos replicados locales.

#### Relaciones que NO se preservan físicamente (Campos "Native"):
*   **`LAPTOP` (F2) $\rightarrow$ `SERVICIO_LAPTOP` (F2)**:
    *   *Justificación:* Un taller del Este (`SERVICIO_LAPTOP_F2`) puede dar servicio a una laptop con serie `[0-1]` (Nodo 1). No hay co-localización garantizada.
*   **`LAPTOP` $\rightarrow$ `LAPTOP` (Reemplazo)**:
    *   *Justificación:* El reemplazo puede pertenecer a un rango de serie almacenado en otro nodo.
*   **`LAPTOP` (F2) $\rightarrow$ `HISTORICO_STATUS_LAPTOP` (F1)**:
    *   *Justificación:* Contiene los históricos antiguos de todas las laptops de la empresa. El padre de una fila histórica puede estar en el Nodo 1, 3 o 4.

> [!NOTE]
> En este nodo no existe ningún fragmento de `LAPTOP_INVENTARIO` (ya que se dividió verticalmente entre el Nodo 1 y el Nodo 3). Por lo tanto, las relaciones **10, 11 y 12** de la tabla global no aplican para el esquema físico local de este nodo.

---

### 3.3. Nodo 3: Oeste (`EAM_S3`) - Sitio de Seguridad y Cifrado

#### Relaciones que SÍ se preservan físicamente:
*   **`SUCURSAL` (F3) $\rightarrow$ `SUCURSAL_TALLER` (F3) y `SUCURSAL_VENTA` (F3)**:
    *   *Justificación:* Fragmentación derivada bajo el mismo predicado (zona `WS`). Co-localización garantizada.
*   **`SUCURSAL_TALLER` (F3) $\rightarrow$ `SERVICIO_LAPTOP` (F3)**:
    *   *Justificación:* Fragmento derivado de servicios de talleres de la zona Oeste. Ambos residen en el mismo nodo.
*   **Catalogs (`TIPO_*` Replicados) $\rightarrow$ `LAPTOP` (F3)**:
    *   *Justificación:* Laptops de serie `[4-5]` se asocian localmente a los catálogos replicados.

#### Relaciones que NO se preservan físicamente (Campos "Native"):
*   **`LAPTOP` (F3) $\rightarrow$ `SERVICIO_LAPTOP` (F3)**:
    *   *Justificación:* Un servicio en un taller de la zona Oeste puede ser para una laptop de cualquier serie.
*   **`LAPTOP` $\rightarrow$ `LAPTOP` (Reemplazo)**:
    *   *Justificación:* El equipo de reemplazo puede estar en otro nodo.
*   **`LAPTOP` (F3) $\rightarrow$ `LAPTOP_INVENTARIO` (F1)**:
    *   *Justificación:* `LAPTOP_INVENTARIO_F1` contiene los datos privados (`RFC_CLIENTE`, `NUM_TARJETA`) de **todas** las laptops, pero `LAPTOP_F3` solo tiene datos generales de las de serie `[4-5]`. El padre de una transacción puede estar en otro sitio.

> [!IMPORTANT]
> En el fragmento vertical `LAPTOP_INVENTARIO_F1` se omitieron los atributos `STATUS_LAPTOP_ID` y `SUCURSAL_ID` por requerimientos de distribución (estos se guardan en el Nodo 1 por capacidad de procesamiento). Por lo tanto, las relaciones globales **11 y 12** no aplican para este nodo. Tampoco hay históricos en este nodo (relación **13 y 14**).

---

### 3.4. Nodo 4: Sur (`EAM_S4`) - Sitio de Imágenes

#### Relaciones que SÍ se preservan físicamente en el Nodo 4

* **`SUCURSAL` (F4) $\rightarrow$ `SUCURSAL_TALLER` (F4) y `SUCURSAL_VENTA` (F4)**:
    *Justificación:* Fragmentación derivada bajo el predicado de zona `SO`. Co-localización garantizada.
* **`SUCURSAL_TALLER` (F4) $\rightarrow$ `SERVICIO_LAPTOP` (F4)**:
    *Justificación:* Fragmento derivado de servicios de talleres de la zona Sur. Ambos residen localmente.
* **Catalogs (`TIPO_*` Replicados) $\rightarrow$ `LAPTOP` (F4)**:
    *Justificación:* Laptops de serie `[2-3]` se asocian localmente a los catálogos replicados.
* **`LAPTOP_F5` $\rightarrow$ `LAPTOP_F4` (validación de `LAPTOP_ID`)**:
    *Justificación:* `LAPTOP_F5` almacena la proyección global `π LAPTOP_ID, FOTO (LAPTOP)`, por lo que en el Nodo 4 puede validar localmente la existencia del `LAPTOP_ID` de cada fila de `LAPTOP_F4`.
* **`LAPTOP_F5` $\rightarrow$ `LAPTOP_F4` (validación recursiva de `LAPTOP_REEMPLAZO_ID`)**:
    *Justificación:* Como `LAPTOP_F5` contiene el conjunto completo de identificadores globales, el campo `LAPTOP_REEMPLAZO_ID` puede restringirse localmente en el Nodo 4 como una relación recursiva de cardinalidad 1:1 opcional.

#### Relaciones que NO se preservan físicamente en el Nodo 4 (Campos "Native")

* **`LAPTOP` (F4) $\rightarrow$ `SERVICIO_LAPTOP` (F4)**:
    *Justificación:* El taller del Sur puede dar servicio a una laptop con número de serie almacenado en otro nodo.

> [!NOTE]
> En este nodo no existe ningún fragmento de `LAPTOP_INVENTARIO` ni de `HISTORICO_STATUS_LAPTOP`, por lo que las relaciones **10, 11, 12, 13 y 14** no aplican para el esquema físico local.

---

## 4. Resumen y Conclusiones del Análisis

El diseño físico propuesto en los entregables **es correcto y consistente** con los fundamentos del diseño de Bases de Datos Distribuidas:

1. **Integridad Física Preservada:** Se declaran restricciones de llave foránea (`FK`) únicamente para relaciones co-localizadas (como subtipos de sucursal, servicios derivados y catálogos replicados). Esto previene que el motor de base de datos local intente validar datos remotos, lo cual provocaría fallas operacionales y cuellos de botella severos.
2. **Integridad Distribuidora Lógica (Nativos):** Las relaciones que cruzan nodos (como el inventario vertical, las fotos centralizadas en el Sur, el histórico dividido por fechas y la asignación de laptops a servicios) se manejan correctamente mediante lógica a nivel de DDBMS, middleware o a través de enlaces de base de datos (DBLinks) en vistas de reconstrucción global, representándolas en el modelo local como atributos simples (`Native`).
