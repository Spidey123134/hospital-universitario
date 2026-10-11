# Relaciones de Acceso de la aplicación - relaciones físicas

Identificadores Fxx impresos junto a conexiones del SVG. La cardinalidad expresa lo permitido por el DDL.

| ID | Padre | Hijo | Columnas FK → columnas padre | Padre requerido por hijo | Hijos por padre | Restricción |
| --- | --- | --- | --- | --- | --- | --- |
| F01 | `personal` | `usuarios` | `personal_id` → `personal_id` | Sí | 0..1 | `fk_usuario_personal` |
| F02 | `usuarios` | `usuario_roles` | `usuario_id` → `usuario_id` | Sí | 0..N | `fk_ur_usuario` |
| F03 | `roles` | `usuario_roles` | `rol_id` → `rol_id` | Sí | 0..N | `fk_ur_rol` |

Las FKs compuestas vinculan una combinación coherente. No deben interpretarse como relaciones independientes por columna. Las reglas transaccionales pueden imponer condiciones adicionales al DDL.
