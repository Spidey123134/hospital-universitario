# Relaciones de Farmacia e inventario - relaciones físicas

Identificadores Fxx impresos junto a conexiones del SVG. La cardinalidad expresa lo permitido por el DDL.

| ID | Padre | Hijo | Columnas FK → columnas padre | Padre requerido por hijo | Hijos por padre | Restricción |
| --- | --- | --- | --- | --- | --- | --- |
| F01 | `medicamentos` | `lotes_medicamento` | `medicamento_id` → `medicamento_id` | Sí | 0..N | `fk_lote_medicamento` |
| F02 | `proveedores` | `lotes_medicamento` | `proveedor_id` → `proveedor_id` | Sí | 0..N | `fk_lote_proveedor` |
| F03 | `consultas` | `recetas` | `consulta_id` → `consulta_id` | Sí | 0..N | `fk_receta_consulta` |
| F04 | `recetas` | `receta_detalle` | `receta_id` → `receta_id` | Sí | 0..N | `fk_rd_receta` |
| F05 | `medicamentos` | `receta_detalle` | `medicamento_id` → `medicamento_id` | Sí | 0..N | `fk_rd_medicamento` |
| F06 | `recetas` | `dispensaciones` | `receta_id` → `receta_id` | Sí | 0..N | `fk_disp_receta` |
| F07 | `personal` | `dispensaciones` | `personal_id` → `personal_id` | Sí | 0..N | `fk_disp_personal` |
| F08 | `dispensaciones` | `dispensacion_detalle` | `dispensacion_id, receta_id` → `dispensacion_id, receta_id` | Sí | 0..N | `fk_dd_dispensacion` |
| F09 | `receta_detalle` | `dispensacion_detalle` | `receta_id, renglon, medicamento_id` → `receta_id, renglon, medicamento_id` | Sí | 0..N | `fk_dd_receta_detalle` |
| F10 | `lotes_medicamento` | `dispensacion_detalle` | `lote_id, medicamento_id` → `lote_id, medicamento_id` | Sí | 0..N | `fk_dd_lote` |
| F11 | `lotes_medicamento` | `movimientos_inventario` | `lote_id` → `lote_id` | Sí | 0..N | `fk_mov_lote` |
| F12 | `personal` | `movimientos_inventario` | `personal_id` → `personal_id` | Sí | 0..N | `fk_mov_personal` |
| F13 | `dispensacion_detalle` | `movimientos_inventario` | `dispensacion_detalle_id, lote_id` → `dispensacion_detalle_id, lote_id` | No | 0..1 | `fk_mov_disp` |

Las FKs compuestas vinculan una combinación coherente. No deben interpretarse como relaciones independientes por columna. Las reglas transaccionales pueden imponer condiciones adicionales al DDL.
