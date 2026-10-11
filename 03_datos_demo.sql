-- DATOS TOTALMENTE FICTICIOS PARA DEMOSTRACION ACADEMICA.
-- Ejecutar UNA VEZ, despues de 01_esquema.sql y las reglas de negocio.
-- Los identificadores explicitos facilitan explicar las relaciones en clase.
-- Ningun nombre, expediente, telefono, diagnostico o medicamento corresponde
-- a una persona, producto o indicacion clinica real. Los codigos DEMO-* NO son CIE.
-- Los usuarios de aplicacion estan inactivos y sus hashes son marcadores inutilizables.
-- En MySQL Workbench, detener la ejecucion ante el primer error y hacer ROLLBACK;
-- no ejecutar COMMIT si algun INSERT fallo. No usar mysql --force al importar.
SET NAMES utf8mb4;
USE hospital_universitario;
START TRANSACTION;

INSERT INTO departamentos (departamento_id, codigo, nombre) VALUES
  (1, 'DEP-DEMO-01', 'Consulta externa de demostracion'),
  (2, 'DEP-DEMO-02', 'Hospitalizacion de demostracion'),
  (3, 'DEP-DEMO-03', 'Farmacia de demostracion'),
  (4, 'DEP-DEMO-04', 'Recepcion de demostracion'),
  (5, 'DEP-DEMO-05', 'Laboratorio de demostracion');

INSERT INTO especialidades (especialidad_id, nombre) VALUES
  (1, 'Medicina general'), (2, 'Medicina interna'), (3, 'Pediatria');

INSERT INTO personal
  (personal_id, numero_empleado, departamento_id, nombre, apellido_paterno,
   apellido_materno, puesto, telefono, email, activo) VALUES
  (1, 'EMP-DEMO-001', 1, 'Medica Uno', 'Ejemplo', 'Ficticio', 'MEDICO',
   'TEL-DEMO-001', 'medica.uno@example.invalid', 1),
  (2, 'EMP-DEMO-002', 1, 'Medico Dos', 'Ejemplo', 'Ficticio', 'MEDICO',
   'TEL-DEMO-002', 'medico.dos@example.invalid', 1),
  (3, 'EMP-DEMO-003', 2, 'Medica Tres', 'Ejemplo', 'Ficticio', 'MEDICO',
   'TEL-DEMO-003', 'medica.tres@example.invalid', 1),
  (4, 'EMP-DEMO-004', 2, 'Enfermeria Uno', 'Ejemplo', 'Ficticio', 'ENFERMERIA',
   'TEL-DEMO-004', 'enfermeria.uno@example.invalid', 1),
  (5, 'EMP-DEMO-005', 2, 'Enfermeria Dos', 'Ejemplo', 'Ficticio', 'ENFERMERIA',
   'TEL-DEMO-005', 'enfermeria.dos@example.invalid', 1),
  (6, 'EMP-DEMO-006', 3, 'Farmacia Uno', 'Ejemplo', 'Ficticio', 'FARMACIA',
   'TEL-DEMO-006', 'farmacia.uno@example.invalid', 1),
  (7, 'EMP-DEMO-007', 4, 'Recepcion Uno', 'Ejemplo', 'Ficticio', 'RECEPCION',
   'TEL-DEMO-007', 'recepcion.uno@example.invalid', 1),
  (8, 'EMP-DEMO-008', 5, 'Laboratorio Uno', 'Ejemplo', 'Ficticio', 'LABORATORIO',
   'TEL-DEMO-008', 'laboratorio.uno@example.invalid', 1);

INSERT INTO medicos (medico_id, cedula_profesional) VALUES
  (1, 'CEDULA-FICTICIA-001'), (2, 'CEDULA-FICTICIA-002'), (3, 'CEDULA-FICTICIA-003');

INSERT INTO medico_especialidad (medico_id, especialidad_id) VALUES
  (1, 1), (1, 3), (2, 2), (3, 1);

INSERT INTO pacientes
  (paciente_id, expediente_clinico, nombre, apellido_paterno, apellido_materno,
   fecha_nacimiento, sexo, telefono, email, domicilio, fecha_registro, activo) VALUES
  (1, 'EXP-DEMO-001', 'Paciente Uno', 'Ejemplo', 'Ficticio', '1998-02-15', 'F',
   'TEL-PAC-DEMO-001', 'paciente.uno@example.invalid', 'Domicilio ficticio 1', '2026-09-01 09:00:00', 1),
  (2, 'EXP-DEMO-002', 'Paciente Dos', 'Ejemplo', 'Ficticio', '1980-06-10', 'M',
   'TEL-PAC-DEMO-002', 'paciente.dos@example.invalid', 'Domicilio ficticio 2', '2026-09-01 09:10:00', 1),
  (3, 'EXP-DEMO-003', 'Paciente Tres', 'Ejemplo', 'Ficticio', '2001-11-20', 'NO_ESPECIFICADO',
   'TEL-PAC-DEMO-003', 'paciente.tres@example.invalid', 'Domicilio ficticio 3', '2026-09-02 09:00:00', 1),
  (4, 'EXP-DEMO-004', 'Paciente Cuatro', 'Ejemplo', 'Ficticio', '2014-03-12', 'F',
   'TEL-PAC-DEMO-004', 'paciente.cuatro@example.invalid', 'Domicilio ficticio 4', '2026-09-02 09:10:00', 1),
  (5, 'EXP-DEMO-005', 'Paciente Cinco', 'Ejemplo', 'Ficticio', '1972-12-05', 'M',
   'TEL-PAC-DEMO-005', 'paciente.cinco@example.invalid', 'Domicilio ficticio 5', '2026-09-03 09:00:00', 1);

INSERT INTO contactos_emergencia (contacto_id, paciente_id, nombre, parentesco, telefono, prioridad) VALUES
  (1, 1, 'Contacto ficticio Uno A', 'Familiar de prueba', 'TEL-CON-DEMO-001', 1),
  (2, 1, 'Contacto ficticio Uno B', 'Contacto de prueba', 'TEL-CON-DEMO-002', 2),
  (3, 2, 'Contacto ficticio Dos', 'Familiar de prueba', 'TEL-CON-DEMO-003', 1),
  (4, 3, 'Contacto ficticio Tres', 'Familiar de prueba', 'TEL-CON-DEMO-004', 1),
  (5, 4, 'Contacto ficticio Cuatro', 'Tutor de prueba', 'TEL-CON-DEMO-005', 1),
  (6, 5, 'Contacto ficticio Cinco', 'Familiar de prueba', 'TEL-CON-DEMO-006', 1);

INSERT INTO aseguradoras (aseguradora_id, nombre, telefono) VALUES
  (1, 'Aseguradora ficticia Alfa', 'TEL-ASEG-DEMO-001'),
  (2, 'Aseguradora ficticia Beta', 'TEL-ASEG-DEMO-002');

INSERT INTO polizas (poliza_id, paciente_id, aseguradora_id, numero_poliza, fecha_inicio, fecha_fin) VALUES
  (1, 1, 1, 'POLIZA-DEMO-001', '2026-01-01', '2026-12-31'),
  (2, 2, 2, 'POLIZA-DEMO-002', '2026-01-01', '2027-06-30'),
  (3, 5, 1, 'POLIZA-DEMO-003', '2026-09-01', '2027-08-31');

INSERT INTO habitaciones (habitacion_id, departamento_id, codigo, edificio, piso, tipo) VALUES
  (1, 2, 'HAB-DEMO-101', 'Edificio de prueba A', 1, 'GENERAL'),
  (2, 2, 'HAB-DEMO-102', 'Edificio de prueba A', 1, 'PRIVADA'),
  (3, 2, 'HAB-DEMO-201', 'Edificio de prueba A', 2, 'UCI'),
  (4, 2, 'HAB-DEMO-001', 'Edificio de prueba B', 0, 'URGENCIAS');

INSERT INTO camillas (camilla_id, habitacion_id, codigo, estado_operativo) VALUES
  (1, 1, 'CAM-DEMO-01', 'OPERATIVA'), (2, 1, 'CAM-DEMO-02', 'OPERATIVA'),
  (3, 2, 'CAM-DEMO-03', 'OPERATIVA'), (4, 3, 'CAM-DEMO-04', 'OPERATIVA'),
  (5, 4, 'CAM-DEMO-05', 'OPERATIVA'), (6, 4, 'CAM-DEMO-06', 'MANTENIMIENTO');

INSERT INTO citas (cita_id, paciente_id, medico_id, inicio, fin, motivo, estado) VALUES
  (1, 1, 1, '2026-10-06 09:00:00', '2026-10-06 09:30:00', 'Caso academico A', 'ATENDIDA'),
  (2, 2, 2, '2026-10-07 10:00:00', '2026-10-07 10:30:00', 'Caso academico B', 'ATENDIDA'),
  (3, 4, 1, '2026-10-08 09:00:00', '2026-10-08 09:30:00', 'Caso academico C', 'ATENDIDA'),
  (4, 1, 1, '2026-10-12 09:00:00', '2026-10-12 09:30:00', 'Seguimiento ficticio A', 'PROGRAMADA'),
  (5, 2, 2, '2026-10-12 10:00:00', '2026-10-12 10:30:00', 'Seguimiento ficticio B', 'CONFIRMADA'),
  (6, 3, 3, '2026-10-09 11:00:00', '2026-10-09 11:30:00', 'Ejemplo de cancelacion', 'CANCELADA');

-- Dos consultas sin cita muestran que una urgencia no necesita cita previa.
INSERT INTO consultas
  (consulta_id, cita_id, paciente_id, medico_id, fecha, tipo, motivo, notas,
   peso_kg, talla_cm, temperatura_c) VALUES
  (1, 1, 1, 1, '2026-10-06 09:05:00', 'PROGRAMADA', 'Caso academico A',
   'Nota simulada para practicar el expediente; sin contenido clinico real.', 60.00, 160.00, 36.5),
  (2, 2, 2, 2, '2026-10-07 10:05:00', 'PROGRAMADA', 'Caso academico B',
   'Nota simulada para practicar relaciones entre tablas.', 75.00, 175.00, 36.6),
  (3, NULL, 3, 3, '2026-10-08 11:00:00', 'URGENCIA', 'Ingreso ficticio A',
   'Caso inventado con hospitalizacion cerrada y traslado.', 65.00, 168.00, 36.7),
  (4, 3, 4, 1, '2026-10-08 09:05:00', 'PROGRAMADA', 'Caso academico C',
   'Nota simulada; valores numericos unicamente para probar tipos de datos.', 40.00, 145.00, 36.5),
  (5, NULL, 5, 2, '2026-10-09 14:00:00', 'URGENCIA', 'Ingreso ficticio B',
   'Caso inventado con hospitalizacion abierta.', 80.00, 172.00, 36.8);

INSERT INTO diagnosticos (diagnostico_id, codigo, descripcion) VALUES
  (1, 'DEMO-A', 'Diagnostico ficticio A; no es un codigo CIE'),
  (2, 'DEMO-B', 'Diagnostico ficticio B; no es un codigo CIE'),
  (3, 'DEMO-C', 'Diagnostico ficticio C; no es un codigo CIE');

INSERT INTO consulta_diagnosticos (consulta_id, diagnostico_id, es_principal, observaciones) VALUES
  (1, 1, 1, 'Registro principal de prueba'), (1, 2, 0, 'Registro secundario de prueba'),
  (2, 2, 1, 'Registro principal de prueba'), (3, 3, 1, 'Registro principal de prueba'),
  (4, 1, 1, 'Registro principal de prueba'), (5, 3, 1, 'Registro principal de prueba');

INSERT INTO alergias_paciente (alergia_id, paciente_id, sustancia, reaccion, fecha_registro) VALUES
  (1, 1, 'Sustancia ficticia X', 'Descripcion simulada A', '2026-09-01'),
  (2, 3, 'Sustancia ficticia Y', 'Descripcion simulada B', '2026-09-02');

INSERT INTO hospitalizaciones
  (hospitalizacion_id, consulta_ingreso_id, paciente_id, medico_responsable_id,
   fecha_ingreso, fecha_alta, motivo, resumen_alta) VALUES
  (1, 3, 3, 3, '2026-10-08 12:00:00', '2026-10-09 12:00:00',
   'Hospitalizacion ficticia A', 'Cierre de caso academico sin indicaciones clinicas.'),
  (2, 5, 5, 2, '2026-10-09 15:00:00', NULL, 'Hospitalizacion ficticia B', NULL);

-- El fin de una asignacion coincide con el inicio del traslado siguiente.
INSERT INTO asignaciones_camilla (asignacion_id, hospitalizacion_id, camilla_id, inicio, fin) VALUES
  (1, 1, 1, '2026-10-08 12:00:00', '2026-10-08 18:00:00'),
  (2, 1, 3, '2026-10-08 18:00:00', '2026-10-09 12:00:00'),
  (3, 2, 2, '2026-10-09 15:00:00', NULL);

INSERT INTO notas_enfermeria (nota_id, hospitalizacion_id, personal_id, fecha, observacion) VALUES
  (1, 1, 4, '2026-10-08 12:30:00', 'Observacion ficticia de ingreso para prueba de registro.'),
  (2, 1, 5, '2026-10-08 18:30:00', 'Observacion ficticia posterior al traslado.'),
  (3, 2, 4, '2026-10-09 15:30:00', 'Observacion ficticia de un caso abierto.');

INSERT INTO medicamentos
  (medicamento_id, codigo, principio_activo, concentracion, presentacion,
   unidad_inventario, stock_minimo) VALUES
  (1, 'MED-DEMO-A', 'Sustancia de prueba A', 'Valor didactico', 'Envase ficticio A', 'unidad de prueba', 20),
  (2, 'MED-DEMO-B', 'Sustancia de prueba B', 'Valor didactico', 'Envase ficticio B', 'unidad de prueba', 15),
  (3, 'MED-DEMO-C', 'Sustancia de prueba C', 'Valor didactico', 'Envase ficticio C', 'unidad de prueba', 50);

INSERT INTO proveedores (proveedor_id, nombre, telefono, email) VALUES
  (1, 'Proveedor ficticio Alfa', 'TEL-PROV-DEMO-001', 'proveedor.alfa@example.invalid'),
  (2, 'Proveedor ficticio Beta', 'TEL-PROV-DEMO-002', 'proveedor.beta@example.invalid');

INSERT INTO lotes_medicamento
  (lote_id, medicamento_id, proveedor_id, numero_lote, fecha_recepcion, fecha_caducidad, costo_unitario) VALUES
  (1, 1, 1, 'LOTE-DEMO-A1', '2026-09-30', '2027-06-30', 12.50),
  (2, 2, 1, 'LOTE-DEMO-B1', '2026-09-30', '2027-09-30', 20.00),
  (3, 3, 2, 'LOTE-DEMO-C1', '2026-09-30', '2028-01-31', 5.00),
  (4, 1, 2, 'LOTE-DEMO-A2', '2026-10-01', '2027-12-31', 13.00);

INSERT INTO recetas (receta_id, consulta_id, fecha_prescripcion, observaciones) VALUES
  (1, 1, '2026-10-06 09:20:00', 'Receta simulada. Ningun dato constituye una prescripcion real.'),
  (2, 3, '2026-10-08 11:30:00', 'Receta simulada pendiente de entrega.'),
  (3, 4, '2026-10-08 09:20:00', 'Receta simulada pendiente de entrega.');

INSERT INTO receta_detalle
  (receta_id, renglon, medicamento_id, dosis, frecuencia, duracion_dias,
   via_administracion, cantidad_prescrita) VALUES
  (1, 1, 1, 'Valor didactico', 'Texto de prueba sin uso clinico', 1, 'Campo de prueba', 8),
  (1, 2, 2, 'Valor didactico', 'Texto de prueba sin uso clinico', 1, 'Campo de prueba', 3),
  (2, 1, 3, 'Valor didactico', 'Texto de prueba sin uso clinico', 1, 'Campo de prueba', 4),
  (2, 2, 1, 'Valor didactico', 'Texto de prueba sin uso clinico', 1, 'Campo de prueba', 2),
  (3, 1, 2, 'Valor didactico', 'Texto de prueba sin uso clinico', 1, 'Campo de prueba', 2);

-- Entradas antes de dispensar. El stock se calcula sumando movimientos.
INSERT INTO movimientos_inventario
  (movimiento_id, lote_id, dispensacion_detalle_id, personal_id, fecha, tipo, cantidad, motivo) VALUES
  (1, 1, NULL, 6, '2026-09-30 12:00:00', 'ENTRADA', 100, 'Recepcion ficticia A1'),
  (2, 2, NULL, 6, '2026-09-30 12:05:00', 'ENTRADA', 60, 'Recepcion ficticia B1'),
  (3, 3, NULL, 6, '2026-09-30 12:10:00', 'ENTRADA', 40, 'Recepcion ficticia C1'),
  (4, 4, NULL, 6, '2026-10-01 12:00:00', 'ENTRADA', 50, 'Recepcion ficticia A2');

INSERT INTO dispensaciones (dispensacion_id, receta_id, personal_id, fecha) VALUES
  (1, 1, 6, '2026-10-06 10:00:00');

INSERT INTO dispensacion_detalle
  (dispensacion_detalle_id, dispensacion_id, receta_id, renglon, medicamento_id, lote_id, cantidad) VALUES
  (1, 1, 1, 1, 1, 1, 8), (2, 1, 1, 2, 2, 2, 3);

-- Cada detalle entregado tiene UNA salida por el mismo lote y cantidad opuesta.
INSERT INTO movimientos_inventario
  (movimiento_id, lote_id, dispensacion_detalle_id, personal_id, fecha, tipo, cantidad, motivo) VALUES
  (5, 1, 1, 6, '2026-10-06 10:00:00', 'SALIDA', -8, 'Entrega ficticia de receta 1, renglon 1'),
  (6, 2, 2, 6, '2026-10-06 10:00:00', 'SALIDA', -3, 'Entrega ficticia de receta 1, renglon 2');

INSERT INTO procedimientos (procedimiento_id, codigo, nombre, tipo, precio_referencia) VALUES
  (1, 'PROC-DEMO-LAB', 'Estudio ficticio de laboratorio A', 'LABORATORIO', 300.00),
  (2, 'PROC-DEMO-IMG', 'Estudio ficticio de imagen B', 'IMAGEN', 200.00),
  (3, 'PROC-DEMO-OTR', 'Procedimiento ficticio C', 'OTRO', 150.00),
  (4, 'PROC-DEMO-CIR', 'Procedimiento ficticio de cirugia D', 'CIRUGIA', 800.00);

INSERT INTO ordenes_procedimiento
  (orden_id, consulta_id, procedimiento_id, fecha_solicitud, fecha_programada, estado, indicaciones) VALUES
  (1, 1, 1, '2026-10-06 09:20:00', '2026-10-06 11:00:00', 'REALIZADA', 'Indicacion ficticia sin uso clinico.'),
  (2, 2, 2, '2026-10-07 10:20:00', '2026-10-13 11:00:00', 'PROGRAMADA', 'Indicacion ficticia sin uso clinico.'),
  (3, 3, 3, '2026-10-08 11:30:00', '2026-10-08 13:00:00', 'REALIZADA', 'Indicacion ficticia sin uso clinico.'),
  (4, 5, 4, '2026-10-09 14:30:00', NULL, 'SOLICITADA', 'Indicacion ficticia sin uso clinico.');

INSERT INTO resultados_procedimiento (resultado_id, orden_id, personal_id, fecha_resultado, informe) VALUES
  (1, 1, 8, '2026-10-06 12:00:00', 'Resultado simulado A: texto de prueba sin interpretacion medica.'),
  (2, 3, 3, '2026-10-08 14:00:00', 'Resultado simulado C: procedimiento de demostracion registrado.');

INSERT INTO facturas (factura_id, folio, paciente_id, poliza_id, fecha, estado) VALUES
  (1, 'FAC-DEMO-001', 1, 1, '2026-10-06 13:00:00', 'ABIERTA'),
  (2, 'FAC-DEMO-002', 2, 2, '2026-10-07 12:00:00', 'ABIERTA'),
  (3, 'FAC-DEMO-003', 3, NULL, '2026-10-09 12:30:00', 'ABIERTA'),
  (4, 'FAC-DEMO-004', 5, 3, '2026-10-10 09:00:00', 'ABIERTA');

-- Los precios son historicos y ficticios. No modelan tarifas ni impuestos reales.
INSERT INTO factura_detalle (factura_id, renglon, descripcion, cantidad, precio_unitario, descuento) VALUES
  (1, 1, 'Consulta ficticia A', 1.00, 500.00, 50.00),
  (1, 2, 'Estudio ficticio de laboratorio A', 1.00, 300.00, 0.00),
  (1, 3, 'Unidades ficticias A', 8.00, 12.50, 0.00),
  (2, 1, 'Consulta ficticia B', 1.00, 600.00, 0.00),
  (2, 2, 'Servicio ficticio de imagen programado', 1.00, 200.00, 0.00),
  (3, 1, 'Consulta ficticia de ingreso A', 1.00, 450.00, 0.00),
  (3, 2, 'Dos unidades ficticias de estancia', 2.00, 300.00, 0.00),
  (3, 3, 'Procedimiento ficticio C', 1.00, 150.00, 0.00),
  (4, 1, 'Consulta ficticia de ingreso B', 1.00, 450.00, 0.00),
  (4, 2, 'Unidad ficticia de estancia', 1.00, 300.00, 0.00);

-- Primero se capturan conceptos y despues se emiten. La factura 4 queda abierta.
UPDATE facturas SET estado = 'EMITIDA' WHERE factura_id IN (1, 2, 3);

INSERT INTO pagos (pago_id, factura_id, fecha, monto, metodo, referencia) VALUES
  (1, 1, '2026-10-06 13:15:00', 200.00, 'EFECTIVO', 'ABONO-DEMO-001'),
  (2, 1, '2026-10-07 09:00:00', 300.00, 'TRANSFERENCIA', 'ABONO-DEMO-002'),
  (3, 2, '2026-10-07 12:15:00', 800.00, 'TARJETA', 'PAGO-DEMO-003'),
  (4, 3, '2026-10-09 13:00:00', 400.00, 'EFECTIVO', 'ABONO-DEMO-004');

INSERT INTO roles (rol_id, nombre, descripcion) VALUES
  (1, 'ADMINISTRACION', 'Rol de prueba para administrar configuracion de la futura aplicacion.'),
  (2, 'MEDICO', 'Rol de prueba para acceder a atencion clinica.'),
  (3, 'FARMACIA', 'Rol de prueba para manejar recetas, entregas e inventario.'),
  (4, 'RECEPCION', 'Rol de prueba para registrar pacientes y citas.');

INSERT INTO usuarios (usuario_id, personal_id, nombre_usuario, password_hash, activo) VALUES
  (1, 1, 'demo.medica.uno', 'MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION', 0),
  (2, 6, 'demo.farmacia.uno', 'MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION', 0),
  (3, 7, 'demo.recepcion.uno', 'MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION', 0);

INSERT INTO usuario_roles (usuario_id, rol_id) VALUES (1, 2), (2, 3), (3, 4);

COMMIT;
-- Resultados esperados: 5 pacientes, 3 medicos, 5 consultas (2 sin cita),
-- 1 hospitalizacion abierta y 1 cerrada; stock A=142, B=57 y C=40.
-- Facturas: total/pagado/saldo -> 1:850/500/350; 2:800/800/0;
-- 3:1200/400/800; 4:750/0/750. Ninguna tabla queda vacia.
