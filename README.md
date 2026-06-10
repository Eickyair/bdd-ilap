# iLap · Base de Datos Distribuida en Oracle 23ai

Diseñé y construí una base de datos distribuida de 4 nodos para iLap, una empresa de venta y servicio de laptops. El proyecto va del diseño de fragmentación hasta una demo ejecutable, corriendo sobre Oracle 23ai y Docker.

## Qué resuelve

iLap maneja datos muy distintos entre sí: inventario, históricos, catálogos, diagnósticos y archivos binarios. Un solo servidor no aprovecha la especialización de cada nodo ni protege bien los datos sensibles. La solución reparte el modelo según reglas de negocio y según para qué es bueno cada nodo:

- **Nodo 1** procesamiento
- **Nodo 2** almacenamiento
- **Nodo 3** seguridad y datos sensibles
- **Nodo 4** imágenes

## En números

- 4 nodos Oracle 23ai en 2 contenedores Docker
- 12 database links bidireccionales entre nodos
- Fragmentación horizontal, derivada, vertical e híbrida en un mismo sistema
- Transparencia total de lectura y escritura para quien consume los datos
- 100 fotos y 100 facturas reales cargadas como BLOB para validar la operación

## Cómo lo hice (STAR)

### Arquitectura distribuida con sentido de negocio

**S** — Los datos de iLap tienen necesidades distintas de rendimiento, seguridad y espacio.
**T** — Distribuir el modelo en 4 nodos sin romper la consistencia global.
**A** — Combiné fragmentación horizontal, derivada, vertical e híbrida, y asigné cada fragmento al nodo que mejor lo soporta.
**R** — Arquitectura completa, con ubicación determinista de los datos y reconstrucción global verificable.

### Transparencia de distribución

**S** — Una BDD distribuida pierde valor si el usuario tiene que saber dónde vive cada fragmento.
**T** — Exponer una sola capa lógica para consultar e insertar sin pensar en nodos.
**A** — Construí sinónimos lógicos, vistas globales y triggers `INSTEAD OF` para `INSERT` y `DELETE`, más replicación síncrona de catálogos.
**R** — El usuario trabaja sobre tablas globales; el sistema rutea solo y mantiene los catálogos iguales en los 4 nodos.

### Operación reproducible

**S** — Las demos distribuidas suelen fallar en lo operativo: BLOBs, permisos y orquestación.
**T** — Dejar todo el flujo ejecutable de punta a punta.
**A** — Configuré objetos `DIRECTORY`, la función `FX_CARGA_BLOB` y orquestadores por fase; automaticé la carga oficial y sus validaciones.
**R** — Con un comando se reconstruye la BDD, se puebla con binarios reales y se validan inserción, replicación y borrado distribuidos.

## Stack

Oracle 23ai · SQL · PL/SQL · triggers `INSTEAD OF` · database links · Docker · Bash

## Probar la demo

```bash
./entregables/parte-4/run-parte-4.sh            # reconstruye y puebla la BDD
./entregables/parte-4/run-parte-4.sh --validate # valida insert, replicación y delete
```

> La validación de borrado deja la base vacía; vuelve a correr el primer comando para repoblarla.

## Por dónde mirar

- [docs/CONTEXTO_PROYECTO.md](docs/CONTEXTO_PROYECTO.md) — alcance, topología y fragmentación
- [TECHNICAL_MEMORY.md](TECHNICAL_MEMORY.md) — decisiones técnicas y bitácora
- [entregables/parte-2](entregables/parte-2) — usuarios, links y DDL por nodo
- [entregables/parte-3](entregables/parte-3) — sinónimos, vistas y triggers
- [entregables/parte-4/run-parte-4.sh](entregables/parte-4/run-parte-4.sh) — carga final y validaciones

## Autor

**Erick Yair Aguilar Martínez** · Facultad de Ingeniería, UNAM · Semestre 2026-2
