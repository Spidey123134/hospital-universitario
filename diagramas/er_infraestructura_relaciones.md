# Relaciones de Infraestructura - relaciones físicas

Identificadores Fxx impresos junto a conexiones del SVG. La cardinalidad expresa lo permitido por el DDL.

| ID | Padre | Hijo | Columnas FK → columnas padre | Padre requerido por hijo | Hijos por padre | Restricción |
| --- | --- | --- | --- | --- | --- | --- |
| F01 | `departamentos` | `habitaciones` | `departamento_id` → `departamento_id` | Sí | 0..N | `fk_habitacion_departamento` |
| F02 | `habitaciones` | `camillas` | `habitacion_id` → `habitacion_id` | Sí | 0..N | `fk_camilla_habitacion` |

Las FKs compuestas vinculan una combinación coherente. No deben interpretarse como relaciones independientes por columna. Las reglas transaccionales pueden imponer condiciones adicionales al DDL.
