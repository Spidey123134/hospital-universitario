# Relaciones de Hospitalización - relaciones físicas

Identificadores Fxx impresos junto a conexiones del SVG. La cardinalidad expresa lo permitido por el DDL.

| ID | Padre | Hijo | Columnas FK → columnas padre | Padre requerido por hijo | Hijos por padre | Restricción |
| --- | --- | --- | --- | --- | --- | --- |
| F01 | `consultas` | `hospitalizaciones` | `consulta_ingreso_id, paciente_id` → `consulta_id, paciente_id` | Sí | 0..1 | `fk_hosp_consulta` |
| F02 | `pacientes` | `hospitalizaciones` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_hosp_paciente` |
| F03 | `medicos` | `hospitalizaciones` | `medico_responsable_id` → `medico_id` | Sí | 0..N | `fk_hosp_medico` |
| F04 | `hospitalizaciones` | `asignaciones_camilla` | `hospitalizacion_id` → `hospitalizacion_id` | Sí | 0..N | `fk_asignacion_hosp` |
| F05 | `camillas` | `asignaciones_camilla` | `camilla_id` → `camilla_id` | Sí | 0..N | `fk_asignacion_camilla` |
| F06 | `hospitalizaciones` | `notas_enfermeria` | `hospitalizacion_id` → `hospitalizacion_id` | Sí | 0..N | `fk_nota_hosp` |
| F07 | `personal` | `notas_enfermeria` | `personal_id` → `personal_id` | Sí | 0..N | `fk_nota_personal` |
| F08 | `pacientes` | `consultas` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_consulta_paciente` |
| F09 | `medicos` | `consultas` | `medico_id` → `medico_id` | Sí | 0..N | `fk_consulta_medico` |
| F10 | `personal` | `medicos` | `medico_id` → `personal_id` | Sí | 0..1 | `fk_medico_personal` |

Las FKs compuestas vinculan una combinación coherente. No deben interpretarse como relaciones independientes por columna. Las reglas transaccionales pueden imponer condiciones adicionales al DDL.
