# Relaciones de Hospital universitario - modelo físico completo

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
| F08 | `departamentos` | `habitaciones` | `departamento_id` → `departamento_id` | Sí | 0..N | `fk_habitacion_departamento` |
| F09 | `habitaciones` | `camillas` | `habitacion_id` → `habitacion_id` | Sí | 0..N | `fk_camilla_habitacion` |
| F10 | `pacientes` | `citas` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_cita_paciente` |
| F11 | `medicos` | `citas` | `medico_id` → `medico_id` | Sí | 0..N | `fk_cita_medico` |
| F12 | `citas` | `consultas` | `cita_id, paciente_id, medico_id` → `cita_id, paciente_id, medico_id` | No | 0..1 | `fk_consulta_cita` |
| F13 | `pacientes` | `consultas` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_consulta_paciente` |
| F14 | `medicos` | `consultas` | `medico_id` → `medico_id` | Sí | 0..N | `fk_consulta_medico` |
| F15 | `consultas` | `consulta_diagnosticos` | `consulta_id` → `consulta_id` | Sí | 0..N | `fk_cd_consulta` |
| F16 | `diagnosticos` | `consulta_diagnosticos` | `diagnostico_id` → `diagnostico_id` | Sí | 0..N | `fk_cd_diagnostico` |
| F17 | `pacientes` | `alergias_paciente` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_alergia_paciente` |
| F18 | `consultas` | `hospitalizaciones` | `consulta_ingreso_id, paciente_id` → `consulta_id, paciente_id` | Sí | 0..1 | `fk_hosp_consulta` |
| F19 | `pacientes` | `hospitalizaciones` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_hosp_paciente` |
| F20 | `medicos` | `hospitalizaciones` | `medico_responsable_id` → `medico_id` | Sí | 0..N | `fk_hosp_medico` |
| F21 | `hospitalizaciones` | `asignaciones_camilla` | `hospitalizacion_id` → `hospitalizacion_id` | Sí | 0..N | `fk_asignacion_hosp` |
| F22 | `camillas` | `asignaciones_camilla` | `camilla_id` → `camilla_id` | Sí | 0..N | `fk_asignacion_camilla` |
| F23 | `hospitalizaciones` | `notas_enfermeria` | `hospitalizacion_id` → `hospitalizacion_id` | Sí | 0..N | `fk_nota_hosp` |
| F24 | `personal` | `notas_enfermeria` | `personal_id` → `personal_id` | Sí | 0..N | `fk_nota_personal` |
| F25 | `medicamentos` | `lotes_medicamento` | `medicamento_id` → `medicamento_id` | Sí | 0..N | `fk_lote_medicamento` |
| F26 | `proveedores` | `lotes_medicamento` | `proveedor_id` → `proveedor_id` | Sí | 0..N | `fk_lote_proveedor` |
| F27 | `consultas` | `recetas` | `consulta_id` → `consulta_id` | Sí | 0..N | `fk_receta_consulta` |
| F28 | `recetas` | `receta_detalle` | `receta_id` → `receta_id` | Sí | 0..N | `fk_rd_receta` |
| F29 | `medicamentos` | `receta_detalle` | `medicamento_id` → `medicamento_id` | Sí | 0..N | `fk_rd_medicamento` |
| F30 | `recetas` | `dispensaciones` | `receta_id` → `receta_id` | Sí | 0..N | `fk_disp_receta` |
| F31 | `personal` | `dispensaciones` | `personal_id` → `personal_id` | Sí | 0..N | `fk_disp_personal` |
| F32 | `dispensaciones` | `dispensacion_detalle` | `dispensacion_id, receta_id` → `dispensacion_id, receta_id` | Sí | 0..N | `fk_dd_dispensacion` |
| F33 | `receta_detalle` | `dispensacion_detalle` | `receta_id, renglon, medicamento_id` → `receta_id, renglon, medicamento_id` | Sí | 0..N | `fk_dd_receta_detalle` |
| F34 | `lotes_medicamento` | `dispensacion_detalle` | `lote_id, medicamento_id` → `lote_id, medicamento_id` | Sí | 0..N | `fk_dd_lote` |
| F35 | `lotes_medicamento` | `movimientos_inventario` | `lote_id` → `lote_id` | Sí | 0..N | `fk_mov_lote` |
| F36 | `personal` | `movimientos_inventario` | `personal_id` → `personal_id` | Sí | 0..N | `fk_mov_personal` |
| F37 | `dispensacion_detalle` | `movimientos_inventario` | `dispensacion_detalle_id, lote_id` → `dispensacion_detalle_id, lote_id` | No | 0..1 | `fk_mov_disp` |
| F38 | `consultas` | `ordenes_procedimiento` | `consulta_id` → `consulta_id` | Sí | 0..N | `fk_orden_consulta` |
| F39 | `procedimientos` | `ordenes_procedimiento` | `procedimiento_id` → `procedimiento_id` | Sí | 0..N | `fk_orden_procedimiento` |
| F40 | `ordenes_procedimiento` | `resultados_procedimiento` | `orden_id` → `orden_id` | Sí | 0..1 | `fk_resultado_orden` |
| F41 | `personal` | `resultados_procedimiento` | `personal_id` → `personal_id` | Sí | 0..N | `fk_resultado_personal` |
| F42 | `pacientes` | `facturas` | `paciente_id` → `paciente_id` | Sí | 0..N | `fk_factura_paciente` |
| F43 | `polizas` | `facturas` | `poliza_id, paciente_id` → `poliza_id, paciente_id` | No | 0..N | `fk_factura_poliza` |
| F44 | `facturas` | `factura_detalle` | `factura_id` → `factura_id` | Sí | 0..N | `fk_fd_factura` |
| F45 | `facturas` | `pagos` | `factura_id` → `factura_id` | Sí | 0..N | `fk_pago_factura` |
| F46 | `personal` | `usuarios` | `personal_id` → `personal_id` | Sí | 0..1 | `fk_usuario_personal` |
| F47 | `usuarios` | `usuario_roles` | `usuario_id` → `usuario_id` | Sí | 0..N | `fk_ur_usuario` |
| F48 | `roles` | `usuario_roles` | `rol_id` → `rol_id` | Sí | 0..N | `fk_ur_rol` |

Las FKs compuestas vinculan una combinación coherente. No deben interpretarse como relaciones independientes por columna. Las reglas transaccionales pueden imponer condiciones adicionales al DDL.
