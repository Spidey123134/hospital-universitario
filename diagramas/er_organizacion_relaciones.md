# Relaciones de Organización y personas - relaciones físicas

Identificadores Fxx impresos junto a conexiones del SVG. La cardinalidad expresa lo permitido por el DDL.

| ID | Padre | Hijo | Columnas FK → columnas padre | Padre requerido por hijo | Hijos por padre | Restricción |
| --- | --- | --- | --- | --- | --- | --- |
| F01 | `departamentos` | `personal` | `departamento_id` → `departamento_id` | Sí | 0..N | `fk_personal_departamento` |
| F02 | `personal` | `medicos` | `medico_id` → `personal_id` | Sí | 0..1 | `fk_medico_personal` |
| F03 | `medicos` | `medico_especialidad` | `medico_id` → `medico_id` | Sí | 0..N | `fk_me_medico` |
| F04 | `especialidades` | `medico_especialidad` | `especialidad_id` → `especialidad_id` | Sí | 0..N | `fk_me_especialidad` |
| F05 | `pacientes` | `contactos_emergencia` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_contacto_paciente` |
| F06 | `pacientes` | `polizas` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_poliza_paciente` |
| F07 | `aseguradoras` | `polizas` | `aseguradora_id` → `aseguradora_id` | Sí | 0..N | `fk_poliza_aseguradora` |

Las FKs compuestas vinculan una combinación coherente. No deben interpretarse como relaciones independientes por columna. Las reglas transaccionales pueden imponer condiciones adicionales al DDL.
