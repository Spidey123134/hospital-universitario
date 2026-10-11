# Relaciones de Cobros - relaciones físicas

Identificadores Fxx impresos junto a conexiones del SVG. La cardinalidad expresa lo permitido por el DDL.

| ID | Padre | Hijo | Columnas FK → columnas padre | Padre requerido por hijo | Hijos por padre | Restricción |
| --- | --- | --- | --- | --- | --- | --- |
| F01 | `pacientes` | `facturas` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_factura_paciente` |
| F02 | `polizas` | `facturas` | `poliza_id, paciente_id` → `poliza_id, paciente_id` | No | 0..N | `fk_factura_poliza` |
| F03 | `facturas` | `factura_detalle` | `factura_id` → `factura_id` | Sí | 0..N | `fk_fd_factura` |
| F04 | `facturas` | `pagos` | `factura_id` → `factura_id` | Sí | 0..N | `fk_pago_factura` |
| F05 | `pacientes` | `polizas` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_poliza_paciente` |

Las FKs compuestas vinculan una combinación coherente. No deben interpretarse como relaciones independientes por columna. Las reglas transaccionales pueden imponer condiciones adicionales al DDL.
