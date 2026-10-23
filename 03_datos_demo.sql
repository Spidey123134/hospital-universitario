-- CARGA INICIAL DEL HOSPITAL UNIVERSITARIO.
-- Conjunto académico con identidades y operaciones inventadas, sin datos de pacientes reales.
-- Ejecutar una sola vez después de 01_esquema.sql y 02_reglas.sql.
-- Detenerse ante el primer error; no ejecutar COMMIT si falla un INSERT.
SET NAMES utf8mb4;
USE hospital_universitario;
START TRANSACTION;

INSERT INTO departamentos (departamento_id, codigo, nombre) VALUES
  (1, 'DEP-001', 'Consulta externa'),
  (2, 'DEP-002', 'Hospitalización'),
  (3, 'DEP-003', 'Farmacia'),
  (4, 'DEP-004', 'Recepción'),
  (5, 'DEP-005', 'Laboratorio');

INSERT INTO especialidades (especialidad_id, nombre) VALUES
  (1, 'Medicina general'),
  (2, 'Medicina interna'),
  (3, 'Pediatria');

INSERT INTO personal (personal_id, numero_empleado, departamento_id, nombre, apellido_paterno, apellido_materno, puesto, telefono, email, activo) VALUES
  (1, 'EMP-0001', 1, 'Elena', 'Márquez', 'Salinas', 'MEDICO', '5527904464', 'elena.marquez.1@example.com', 1),
  (2, 'EMP-0002', 1, 'Andrés', 'Cabrera', 'Nieto', 'MEDICO', '5585254603', 'andres.cabrera.2@example.com', 1),
  (3, 'EMP-0003', 2, 'Gabriela', 'Soto', 'Beltrán', 'MEDICO', '5579095214', 'gabriela.soto.3@example.com', 1),
  (4, 'EMP-0004', 2, 'Laura', 'Méndez', 'Ríos', 'ENFERMERIA', '5599112321', 'laura.mendez.4@example.com', 1),
  (5, 'EMP-0005', 2, 'Héctor', 'Salgado', 'Peña', 'ENFERMERIA', '5565057437', 'hector.salgado.5@example.com', 1),
  (6, 'EMP-0006', 3, 'Verónica', 'Ponce', 'Vega', 'FARMACIA', '5583518743', 'veronica.ponce.6@example.com', 1),
  (7, 'EMP-0007', 4, 'Óscar', 'Ávila', 'Duarte', 'RECEPCION', '5549790064', 'oscar.avila.7@example.com', 1),
  (8, 'EMP-0008', 5, 'Raquel', 'Campos', 'Luna', 'LABORATORIO', '5569598886', 'raquel.campos.8@example.com', 1);

INSERT INTO medicos (medico_id, cedula_profesional) VALUES
  (1, 'CP-1016'),
  (2, 'CP-1017'),
  (3, 'CP-1018');

INSERT INTO medico_especialidad (medico_id, especialidad_id) VALUES
  (1, 1),
  (1, 3),
  (2, 2),
  (3, 1);

INSERT INTO pacientes (paciente_id, expediente_clinico, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, sexo, telefono, email, domicilio, fecha_registro, activo) VALUES
  (1, 'EXP-2026-0001', 'Daniela', 'Serrano', 'Molina', '1998-02-15', 'F', '5558041452', 'daniela.serrano.1@example.com', 'Calle Fresno 107, Colonia Los Olivos, Ciudad de México', '2026-09-01 09:00:00', 1),
  (2, 'EXP-2026-0002', 'Arturo', 'Valdés', 'Campos', '1980-06-10', 'M', '5585616963', 'arturo.valdes.2@example.com', 'Calle Jacarandas 114, Colonia Jardines del Sur, Ciudad de México', '2026-09-01 09:10:00', 1),
  (3, 'EXP-2026-0003', 'Alex', 'Rojas', 'Medina', '2001-11-20', 'NO_ESPECIFICADO', '5565007084', 'alex.rojas.3@example.com', 'Calle Encinos 121, Colonia Las Fuentes, Ciudad de México', '2026-09-02 09:00:00', 1),
  (4, 'EXP-2026-0004', 'Lucía', 'Navarro', 'Ruiz', '2014-03-12', 'F', '5599168003', 'lucia.navarro.4@example.com', 'Calle Cedros 128, Colonia La Alameda, Ciudad de México', '2026-09-02 09:10:00', 1),
  (5, 'EXP-2026-0005', 'Ricardo', 'Espinosa', 'León', '1972-12-05', 'M', '5596100149', 'ricardo.espinosa.5@example.com', 'Calle Magnolias 135, Colonia Santa Clara, Ciudad de México', '2026-09-03 09:00:00', 1);

INSERT INTO contactos_emergencia (contacto_id, paciente_id, nombre, parentesco, telefono, prioridad) VALUES
  (1, 1, 'Ana Serrano Torres', 'Madre', '5582388335', 1),
  (2, 1, 'Jorge Serrano Robles', 'Padre', '5530033475', 2),
  (3, 2, 'Mariana Valdés Santos', 'Hermana', '5522569209', 1),
  (4, 3, 'Rodrigo Rojas Duarte', 'Hermano', '5564048857', 1),
  (5, 4, 'Patricia Navarro Román', 'Madre', '5569916691', 1),
  (6, 5, 'Daniel Espinosa Vega', 'Cónyuge', '5573663211', 1);

INSERT INTO aseguradoras (aseguradora_id, nombre, telefono) VALUES
  (1, 'Protección Horizonte', '5527162206'),
  (2, 'Salud Integral Metropolitana', '5564750698');

INSERT INTO polizas (poliza_id, paciente_id, aseguradora_id, numero_poliza, fecha_inicio, fecha_fin) VALUES
  (1, 1, 1, 'POL-2026-00001', '2026-01-01', '2026-12-31'),
  (2, 2, 2, 'POL-2026-00002', '2026-01-01', '2027-06-30'),
  (3, 5, 1, 'POL-2026-00003', '2026-09-01', '2027-08-31');

INSERT INTO habitaciones (habitacion_id, departamento_id, codigo, edificio, piso, tipo) VALUES
  (1, 2, 'HAB-101', 'Torre A', 1, 'GENERAL'),
  (2, 2, 'HAB-102', 'Torre A', 1, 'PRIVADA'),
  (3, 2, 'HAB-201', 'Torre A', 2, 'UCI'),
  (4, 2, 'HAB-U01', 'Torre B', 0, 'URGENCIAS');

INSERT INTO camillas (camilla_id, habitacion_id, codigo, estado_operativo) VALUES
  (1, 1, 'CAM-01', 'OPERATIVA'),
  (2, 1, 'CAM-02', 'OPERATIVA'),
  (3, 2, 'CAM-03', 'OPERATIVA'),
  (4, 3, 'CAM-04', 'OPERATIVA'),
  (5, 4, 'CAM-05', 'OPERATIVA'),
  (6, 4, 'CAM-06', 'MANTENIMIENTO');

INSERT INTO citas (cita_id, paciente_id, medico_id, inicio, fin, motivo, estado) VALUES
  (1, 1, 1, '2026-10-06 09:00:00', '2026-10-06 09:30:00', 'Valoración por cefalea', 'ATENDIDA'),
  (2, 2, 2, '2026-10-07 10:00:00', '2026-10-07 10:30:00', 'Valoración por dolor abdominal', 'ATENDIDA'),
  (3, 4, 1, '2026-10-08 09:00:00', '2026-10-08 09:30:00', 'Valoración por cefalea', 'ATENDIDA'),
  (4, 1, 1, '2026-10-12 09:00:00', '2026-10-12 09:30:00', 'Consulta de seguimiento y revisión de evolución', 'PROGRAMADA'),
  (5, 2, 2, '2026-10-12 10:00:00', '2026-10-12 10:30:00', 'Consulta de seguimiento y revisión de evolución', 'CONFIRMADA'),
  (6, 3, 3, '2026-10-09 11:00:00', '2026-10-09 11:30:00', 'Consulta de seguimiento y revisión de evolución', 'CANCELADA');

INSERT INTO consultas (consulta_id, cita_id, paciente_id, medico_id, fecha, tipo, motivo, notas, peso_kg, talla_cm, temperatura_c) VALUES
  (1, 1, 1, 1, '2026-10-06 09:05:00', 'PROGRAMADA', 'Valoración por cefalea', 'Daniela Serrano, 28 años. Dolor frontal opresivo desde la tarde anterior, asociado a una jornada prolongada frente a la pantalla. También refiere molestia epigástrica ocasional después de comer; niega vómito y traumatismo y permanece alerta y orientada. Mediciones del encuentro: peso 60 kg, talla 160 cm, temperatura 36.5 °C.', 60.0, 160.0, 36.5),
  (2, 2, 2, 2, '2026-10-07 10:05:00', 'PROGRAMADA', 'Valoración por dolor abdominal', 'Arturo Valdés, 46 años. Dolor en la parte alta del abdomen después de comer, acompañado de distensión. A la palpación refiere molestia epigástrica sin rigidez abdominal. Mediciones del encuentro: peso 75 kg, talla 175 cm, temperatura 36.6 °C.', 75.0, 175.0, 36.6),
  (3, NULL, 3, 3, '2026-10-08 11:00:00', 'URGENCIA', 'Valoración por dolor lumbar', 'Alex Rojas, 24 años. Dolor lumbar tras levantar una caja, que aumenta al incorporarse. Camina con lentitud y niega pérdida de fuerza; antecedente de urticaria con ibuprofeno. Comenta que está concluyendo el tratamiento de una infección dental; la receta de este encuentro cubre el último día del ciclo y no corresponde al dolor lumbar. Mediciones del encuentro: peso 65 kg, talla 168 cm, temperatura 36.7 °C.', 65.0, 168.0, 36.7),
  (4, 3, 4, 1, '2026-10-08 09:05:00', 'PROGRAMADA', 'Valoración por cefalea', 'Lucía Navarro, 12 años. Acude acompañada por su madre por dolor de cabeza al salir de la escuela. Niega caída, vómito y alteración visual; responde al interrogatorio de acuerdo con su edad. Mediciones del encuentro: peso 40 kg, talla 145 cm, temperatura 36.5 °C.', 40.0, 145.0, 36.5),
  (5, NULL, 5, 2, '2026-10-09 14:00:00', 'URGENCIA', 'Valoración por dolor lumbar', 'Ricardo Espinosa, 53 años. Dolor en región lumbar que dificulta girar el tronco. No refiere caída ni adormecimiento de piernas; se solicita observación por limitación para caminar. Mediciones del encuentro: peso 80 kg, talla 172 cm, temperatura 36.8 °C.', 80.0, 172.0, 36.8);

INSERT INTO diagnosticos (diagnostico_id, codigo, descripcion) VALUES
  (1, 'DX-001', 'Cefalea'),
  (2, 'DX-002', 'Dolor abdominal'),
  (3, 'DX-003', 'Dolor lumbar');

INSERT INTO consulta_diagnosticos (consulta_id, diagnostico_id, es_principal, observaciones) VALUES
  (1, 1, 1, 'Dolor frontal opresivo desde la tarde anterior, asociado a una jornada prolongada frente a la pantalla.'),
  (1, 2, 0, 'Molestia epigástrica ocasional después de comer, secundaria a la cefalea que motiva el encuentro.'),
  (2, 2, 1, 'Dolor en la parte alta del abdomen después de comer, acompañado de distensión.'),
  (3, 3, 1, 'Dolor lumbar tras levantar una caja, que aumenta al incorporarse.'),
  (4, 1, 1, 'Acude acompañada por su madre por dolor de cabeza al salir de la escuela.'),
  (5, 3, 1, 'Dolor en región lumbar que dificulta girar el tronco.');

INSERT INTO alergias_paciente (alergia_id, paciente_id, sustancia, reaccion, fecha_registro) VALUES
  (1, 1, 'Penicilina', 'Erupción cutánea', '2026-09-01'),
  (2, 3, 'Ibuprofeno', 'Urticaria', '2026-09-02');

INSERT INTO hospitalizaciones (hospitalizacion_id, consulta_ingreso_id, paciente_id, medico_responsable_id, fecha_ingreso, fecha_alta, motivo, resumen_alta) VALUES
  (1, 3, 3, 3, '2026-10-08 12:00:00', '2026-10-09 12:00:00', 'Observación hospitalaria por dolor lumbar', 'Observación de Alex Rojas del 08/10 al 09/10 por dolor lumbar posterior a esfuerzo. Al egreso puede incorporarse y caminar con menor limitación; no refiere pérdida de fuerza. Se informa a su acompañante el antecedente de urticaria con ibuprofeno y se entrega el resumen de atención.'),
  (2, 5, 5, 2, '2026-10-09 15:00:00', NULL, 'Observación hospitalaria por dolor lumbar', NULL);

INSERT INTO asignaciones_camilla (asignacion_id, hospitalizacion_id, camilla_id, inicio, fin) VALUES
  (1, 1, 1, '2026-10-08 12:00:00', '2026-10-08 18:00:00'),
  (2, 1, 3, '2026-10-08 18:00:00', '2026-10-09 12:00:00'),
  (3, 2, 2, '2026-10-09 15:00:00', NULL);

INSERT INTO notas_enfermeria (nota_id, hospitalizacion_id, personal_id, fecha, observacion) VALUES
  (1, 1, 4, '2026-10-08 12:30:00', 'Alex Rojas, camilla 1. Ingresa por dolor lumbar; se incorpora con apoyo y reconoce a la persona que lo acompaña. Se informa el antecedente de urticaria con ibuprofeno en la entrega inicial.'),
  (2, 1, 5, '2026-10-08 18:30:00', 'Alex Rojas, camilla 3. Tras el cambio de camilla, refiere menor molestia al permanecer de lado y utiliza el timbre para solicitar ayuda al levantarse. Se entrega el turno con la alergia a ibuprofeno identificada.'),
  (3, 2, 4, '2026-10-09 15:30:00', 'Ricardo Espinosa, camilla 2. Permanece en observación por dolor lumbar y pide apoyo para cambiar de posición. Acepta líquidos por vía oral y conserva comunicación clara durante el cuidado de ingreso.');

INSERT INTO medicamentos (medicamento_id, codigo, principio_activo, concentracion, presentacion, unidad_inventario, stock_minimo) VALUES
  (1, 'MED-001', 'Paracetamol', '500 mg', 'Tableta', 'tableta', 20),
  (2, 'MED-002', 'Ibuprofeno', '400 mg', 'Tableta recubierta', 'tableta', 15),
  (3, 'MED-003', 'Amoxicilina', '250 mg/5 mL', 'Polvo para suspensión oral, frasco de 100 mL', 'frasco', 50);

INSERT INTO proveedores (proveedor_id, nombre, telefono, email) VALUES
  (1, 'Suministros Médicos Horizonte', '5551578519', 'ventas.suministros.medicos.horizonte@example.com'),
  (2, 'Distribuidora Clínica Central', '5592728394', 'ventas.distribuidora.clinica.central@example.com');

INSERT INTO lotes_medicamento (lote_id, medicamento_id, proveedor_id, numero_lote, fecha_recepcion, fecha_caducidad, costo_unitario) VALUES
  (1, 1, 1, 'LT-2026-0001', '2026-09-30', '2027-06-30', 12.5),
  (2, 2, 1, 'LT-2026-0002', '2026-09-30', '2027-09-30', 20.0),
  (3, 3, 2, 'LT-2026-0003', '2026-09-30', '2028-01-31', 5.0),
  (4, 1, 2, 'LT-2026-0004', '2026-10-01', '2027-12-31', 13.0);

INSERT INTO recetas (receta_id, consulta_id, fecha_prescripcion, observaciones) VALUES
  (1, 1, '2026-10-06 09:20:00', 'Daniela Serrano. Paracetamol 500 mg: prescrito 8 tabletas, dispensado 8; Ibuprofeno 400 mg: prescrito 3 tabletas, dispensado 3. Cantidades expresadas en unidades de inventario o envases; no equivalen al número de administraciones.'),
  (2, 3, '2026-10-08 11:30:00', 'Alex Rojas. Amoxicilina 250 mg/5 mL: prescrito 4 frascos, dispensado 0; Paracetamol 500 mg: prescrito 2 tabletas, dispensado 0. Cantidades expresadas en unidades de inventario o envases; no equivalen al número de administraciones. La amoxicilina cubre el último día del tratamiento dental concurrente.'),
  (3, 4, '2026-10-08 09:20:00', 'Lucía Navarro. Ibuprofeno 400 mg: prescrito 2 tabletas, dispensado 0. Cantidades expresadas en unidades de inventario o envases; no equivalen al número de administraciones.');

INSERT INTO receta_detalle (receta_id, renglon, medicamento_id, dosis, frecuencia, duracion_dias, via_administracion, cantidad_prescrita) VALUES
  (1, 1, 1, '1 tableta', 'Cada 24 horas', 1, 'Oral', 8),
  (1, 2, 2, '1 tableta', 'Cada 24 horas', 1, 'Oral', 3),
  (2, 1, 3, '500 mg (10 mL de suspensión de 250 mg/5 mL)', 'Cada 8 horas', 1, 'Oral', 4),
  (2, 2, 1, '1 tableta', 'Cada 24 horas', 1, 'Oral', 2),
  (3, 1, 2, '1 tableta', 'Cada 24 horas', 1, 'Oral', 2);

INSERT INTO movimientos_inventario (movimiento_id, lote_id, dispensacion_detalle_id, personal_id, fecha, tipo, cantidad, motivo) VALUES
  (1, 1, NULL, 6, '2026-09-30 12:00:00', 'ENTRADA', 100, 'Recepción de mercancía y registro de lote en farmacia'),
  (2, 2, NULL, 6, '2026-09-30 12:05:00', 'ENTRADA', 60, 'Recepción de mercancía y registro de lote en farmacia'),
  (3, 3, NULL, 6, '2026-09-30 12:10:00', 'ENTRADA', 40, 'Recepción de mercancía y registro de lote en farmacia'),
  (4, 4, NULL, 6, '2026-10-01 12:00:00', 'ENTRADA', 50, 'Recepción de mercancía y registro de lote en farmacia');

INSERT INTO dispensaciones (dispensacion_id, receta_id, personal_id, fecha) VALUES
  (1, 1, 6, '2026-10-06 10:00:00');

INSERT INTO dispensacion_detalle (dispensacion_detalle_id, dispensacion_id, receta_id, renglon, medicamento_id, lote_id, cantidad) VALUES
  (1, 1, 1, 1, 1, 1, 8),
  (2, 1, 1, 2, 2, 2, 3);

INSERT INTO movimientos_inventario (movimiento_id, lote_id, dispensacion_detalle_id, personal_id, fecha, tipo, cantidad, motivo) VALUES
  (5, 1, 1, 6, '2026-10-06 10:00:00', 'SALIDA', -8, 'Entrega a paciente conforme al detalle de dispensación'),
  (6, 2, 2, 6, '2026-10-06 10:00:00', 'SALIDA', -3, 'Entrega a paciente conforme al detalle de dispensación');

INSERT INTO procedimientos (procedimiento_id, codigo, nombre, tipo, precio_referencia) VALUES
  (1, 'PROC-001', 'Biometría hemática', 'LABORATORIO', 300.0),
  (2, 'PROC-002', 'Radiografía de tórax', 'IMAGEN', 200.0),
  (3, 'PROC-003', 'Electrocardiograma', 'OTRO', 150.0),
  (4, 'PROC-004', 'Apendicectomía', 'CIRUGIA', 800.0);

INSERT INTO ordenes_procedimiento (orden_id, consulta_id, procedimiento_id, fecha_solicitud, fecha_programada, estado, indicaciones) VALUES
  (1, 1, 1, '2026-10-06 09:20:00', '2026-10-06 11:00:00', 'REALIZADA', 'EXP-2026-0001. Biometría hemática en sangre venosa para la valoración del encuentro. Identificar la muestra con expediente y nombre; informar hemoglobina, hematocrito, leucocitos y plaquetas.'),
  (2, 2, 2, '2026-10-07 10:20:00', '2026-10-13 11:00:00', 'PROGRAMADA', 'EXP-2026-0002. Radiografía de tórax en la fecha programada para completar la valoración. Verificar identidad y retirar objetos metálicos del campo antes de la adquisición; emitir descripción de las imágenes.'),
  (3, 3, 3, '2026-10-08 11:30:00', '2026-10-08 13:00:00', 'REALIZADA', 'EXP-2026-0003. Electrocardiograma de 12 derivaciones durante la observación hospitalaria. Registrar frecuencia, intervalos y calidad del trazado con la identificación del expediente.'),
  (4, 5, 4, '2026-10-09 14:30:00', NULL, 'SOLICITADA', 'EXP-2026-0005. Solicitud de apendicectomía para evaluación por el equipo quirúrgico. Confirmar indicación, consentimiento, valoración preoperatoria y disponibilidad de sala antes de fijar la fecha.');

INSERT INTO resultados_procedimiento (resultado_id, orden_id, personal_id, fecha_resultado, informe) VALUES
  (1, 1, 8, '2026-10-06 12:00:00', 'Biometría hemática en sangre venosa: hemoglobina 13.4 g/dL; hematocrito 40.1 %; leucocitos 6.8 × 10^9/L; neutrófilos 57 %; linfocitos 33 %; plaquetas 258 × 10^9/L. Muestra sin coágulos visibles al procesamiento.'),
  (2, 3, 3, '2026-10-08 14:00:00', 'Electrocardiograma de 12 derivaciones: frecuencia 74 latidos/min; intervalo PR 160 ms; QRS 88 ms; QTc 410 ms. Ondas P preceden a cada complejo QRS y el trazado conserva una secuencia regular; sin artefactos que impidan la lectura.');

INSERT INTO facturas (factura_id, folio, paciente_id, poliza_id, fecha, estado) VALUES
  (1, 'FAC-2026-00001', 1, 1, '2026-10-06 13:00:00', 'ABIERTA'),
  (2, 'FAC-2026-00002', 2, 2, '2026-10-07 12:00:00', 'ABIERTA'),
  (3, 'FAC-2026-00003', 3, NULL, '2026-10-09 12:30:00', 'ABIERTA'),
  (4, 'FAC-2026-00004', 5, 3, '2026-10-10 09:00:00', 'ABIERTA');

INSERT INTO factura_detalle (factura_id, renglon, descripcion, cantidad, precio_unitario, descuento) VALUES
  (1, 1, 'Consulta de medicina general', 1.0, 500.0, 50.0),
  (1, 2, 'Biometría hemática', 1.0, 300.0, 0.0),
  (1, 3, 'Paracetamol 500 mg, tableta; dispensación 1, renglón 1', 8.0, 12.5, 0.0),
  (2, 1, 'Consulta de medicina interna', 1.0, 600.0, 0.0),
  (2, 2, 'Radiografía de tórax', 1.0, 200.0, 0.0),
  (3, 1, 'Valoración médica de ingreso', 1.0, 450.0, 0.0),
  (3, 2, 'Estancia hospitalaria', 2.0, 300.0, 0.0),
  (3, 3, 'Electrocardiograma', 1.0, 150.0, 0.0),
  (4, 1, 'Valoración médica de ingreso', 1.0, 450.0, 0.0),
  (4, 2, 'Estancia hospitalaria', 1.0, 300.0, 0.0);

UPDATE facturas SET estado = 'EMITIDA' WHERE factura_id IN (1, 2, 3);

INSERT INTO pagos (pago_id, factura_id, fecha, monto, metodo, referencia) VALUES
  (1, 1, '2026-10-06 13:15:00', 200.0, 'EFECTIVO', 'EFE-202610-000001'),
  (2, 1, '2026-10-07 09:00:00', 300.0, 'TRANSFERENCIA', 'TRA-202610-000002'),
  (3, 2, '2026-10-07 12:15:00', 800.0, 'TARJETA', 'TAR-202610-000003'),
  (4, 3, '2026-10-09 13:00:00', 400.0, 'EFECTIVO', 'EFE-202610-000004');

INSERT INTO roles (rol_id, nombre, descripcion) VALUES
  (1, 'ADMINISTRACION', 'Administración de catálogos y configuración del sistema.'),
  (2, 'MEDICO', 'Registro de consultas, diagnósticos y recetas.'),
  (3, 'FARMACIA', 'Gestión de lotes, existencias y entregas de medicamentos.'),
  (4, 'RECEPCION', 'Registro de pacientes y programación de citas.');

INSERT INTO usuarios (usuario_id, personal_id, nombre_usuario, password_hash, activo) VALUES
  (1, 1, 'elena.marquez', 'pbkdf2_sha256$120000$f8517112f6cc82d80ff33a1e$PGoXYAHqQNIuWox8S/lvNolS6UlrDpwrRMNsgAIMPF0=', 0),
  (2, 6, 'veronica.ponce', 'pbkdf2_sha256$120000$fb849e41a7e1b88e17054171$l2L561V4bAPE9CRt4C+OGWmWUOd9UOlHwmF75nXzHNM=', 0),
  (3, 7, 'oscar.avila', 'pbkdf2_sha256$120000$1e4df47ee6a86f1db0c77477$IOktvsiOMy9Za1wvit4MSkhfrJz3axKwFqGPUnxPJ78=', 0);

INSERT INTO usuario_roles (usuario_id, rol_id) VALUES
  (1, 2),
  (2, 3),
  (3, 4);

COMMIT;
