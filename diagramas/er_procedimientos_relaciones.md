# Relaciones de Estudios y procedimientos - relaciones físicas

Identificadores Fxx impresos junto a conexiones del SVG. La cardinalidad expresa lo permitido por el DDL.

| ID | Padre | Hijo | Columnas FK → columnas padre | Padre requerido por hijo | Hijos por padre | Restricción |
| --- | --- | --- | --- | --- | --- | --- |
| F01 | `consultas` | `ordenes_procedimiento` | `consulta_id` → `consulta_id` | Sí | 0..N | `fk_orden_consulta` |
| F02 | `procedimientos` | `ordenes_procedimiento` | `procedimiento_id` → `procedimiento_id` | Sí | 0..N | `fk_orden_procedimiento` |
| F03 | `ordenes_procedimiento` | `resultados_procedimiento` | `orden_id` → `orden_id` | Sí | 0..1 | `fk_resultado_orden` |
| F04 | `personal` | `resultados_procedimiento` | `personal_id` → `personal_id` | Sí | 0..N | `fk_resultado_personal` |

Las FKs compuestas vinculan una combinación coherente. No deben interpretarse como relaciones independientes por columna. Las reglas transaccionales pueden imponer condiciones adicionales al DDL.
