# Relaciones de Atención clínica - relaciones físicas

Identificadores Fxx impresos junto a conexiones del SVG. La cardinalidad expresa lo permitido por el DDL.

| ID | Padre | Hijo | Columnas FK → columnas padre | Padre requerido por hijo | Hijos por padre | Restricción |
| --- | --- | --- | --- | --- | --- | --- |
| F01 | `pacientes` | `citas` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_cita_paciente` |
| F02 | `medicos` | `citas` | `medico_id` → `medico_id` | Sí | 0..N | `fk_cita_medico` |
| F03 | `citas` | `consultas` | `cita_id, paciente_id, medico_id` → `cita_id, paciente_id, medico_id` | No | 0..1 | `fk_consulta_cita` |
| F04 | `pacientes` | `consultas` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_consulta_paciente` |
| F05 | `medicos` | `consultas` | `medico_id` → `medico_id` | Sí | 0..N | `fk_consulta_medico` |
| F06 | `consultas` | `consulta_diagnosticos` | `consulta_id` → `consulta_id` | Sí | 0..N | `fk_cd_consulta` |
| F07 | `diagnosticos` | `consulta_diagnosticos` | `diagnostico_id` → `diagnostico_id` | Sí | 0..N | `fk_cd_diagnostico` |
| F08 | `pacientes` | `alergias_paciente` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_alergia_paciente` |

Las FKs compuestas vinculan una combinación coherente. No deben interpretarse como relaciones independientes por columna. Las reglas transaccionales pueden imponer condiciones adicionales al DDL.
