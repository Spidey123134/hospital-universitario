-- 20 CONSULTAS PARA PRESENTAR Y EXPLICAR EN CLASE. MySQL 8.0.16+.
-- Ejecutar despues de cargar 03_datos_demo.sql. Todas son de lectura.
-- La fecha fija permite repetir la demostracion con los mismos resultados.
SET NAMES utf8mb4;
USE hospital_universitario;
SET @fecha_referencia = DATE('2026-10-10');

-- 01. Pacientes y su contacto prioritario (LEFT JOIN conserva todos los pacientes).
SELECT p.expediente_clinico,
       CONCAT_WS(' ', p.nombre, p.apellido_paterno, p.apellido_materno) AS paciente,
       TIMESTAMPDIFF(YEAR, p.fecha_nacimiento, @fecha_referencia) AS edad_a_fecha_referencia,
       ce.nombre AS contacto_prioritario, ce.telefono AS telefono_contacto
FROM pacientes p
LEFT JOIN contactos_emergencia ce ON ce.paciente_id = p.paciente_id AND ce.prioridad = 1
ORDER BY p.paciente_id;

-- 02. Especialidades de cada medico (relacion muchos a muchos y GROUP_CONCAT).
SELECT m.medico_id, CONCAT_WS(' ', p.nombre, p.apellido_paterno) AS medico,
       d.nombre AS departamento,
       GROUP_CONCAT(e.nombre ORDER BY e.nombre SEPARATOR ', ') AS especialidades
FROM medicos m
JOIN personal p ON p.personal_id = m.medico_id
JOIN departamentos d ON d.departamento_id = p.departamento_id
LEFT JOIN medico_especialidad me ON me.medico_id = m.medico_id
LEFT JOIN especialidades e ON e.especialidad_id = me.especialidad_id
GROUP BY m.medico_id, p.nombre, p.apellido_paterno, d.nombre
ORDER BY m.medico_id;

-- 03. Agenda vigente del 12 de octubre de 2026 (filtro por intervalo, util para indice).
SELECT c.cita_id, c.inicio, c.fin, c.estado,
       p.expediente_clinico, p.nombre AS paciente, pe.nombre AS medico
FROM citas c
JOIN pacientes p ON p.paciente_id = c.paciente_id
JOIN personal pe ON pe.personal_id = c.medico_id
WHERE c.inicio >= '2026-10-12 00:00:00' AND c.inicio < '2026-10-13 00:00:00'
  AND c.estado IN ('PROGRAMADA', 'CONFIRMADA')
ORDER BY c.inicio, c.medico_id;

-- 04. Consultas con y sin cita (CASE explica el origen de la atencion).
SELECT co.consulta_id, co.fecha, p.expediente_clinico, pe.nombre AS medico,
       co.tipo, ci.cita_id,
       CASE WHEN ci.cita_id IS NULL THEN 'Sin cita previa' ELSE 'Con cita previa' END AS origen
FROM consultas co
JOIN pacientes p ON p.paciente_id = co.paciente_id
JOIN personal pe ON pe.personal_id = co.medico_id
LEFT JOIN citas ci ON ci.cita_id = co.cita_id
ORDER BY co.fecha, co.consulta_id;

-- 05. Diagnosticos por consulta, distinguiendo principal y secundarios.
SELECT co.consulta_id, p.expediente_clinico, di.codigo, di.descripcion,
       CASE WHEN cd.es_principal = 1 THEN 'Principal' ELSE 'Secundario' END AS categoria
FROM consulta_diagnosticos cd
JOIN consultas co ON co.consulta_id = cd.consulta_id
JOIN pacientes p ON p.paciente_id = co.paciente_id
JOIN diagnosticos di ON di.diagnostico_id = cd.diagnostico_id
ORDER BY co.consulta_id, cd.es_principal DESC, di.codigo;

-- 06. Alergias registradas de un paciente; ausencia de filas no prueba ausencia de alergias.
SELECT p.expediente_clinico, a.sustancia, a.reaccion, a.fecha_registro
FROM pacientes p
JOIN alergias_paciente a ON a.paciente_id = p.paciente_id
WHERE p.paciente_id = 1
ORDER BY a.fecha_registro, a.alergia_id;

-- 07. Hospitalizaciones abiertas y ubicacion actual.
SELECT h.hospitalizacion_id, p.expediente_clinico, p.nombre AS paciente,
       h.fecha_ingreso, pe.nombre AS medico_responsable,
       ca.codigo AS camilla, ha.codigo AS habitacion
FROM hospitalizaciones h
JOIN pacientes p ON p.paciente_id = h.paciente_id
JOIN personal pe ON pe.personal_id = h.medico_responsable_id
LEFT JOIN asignaciones_camilla ac ON ac.hospitalizacion_id = h.hospitalizacion_id AND ac.fin IS NULL
LEFT JOIN camillas ca ON ca.camilla_id = ac.camilla_id
LEFT JOIN habitaciones ha ON ha.habitacion_id = ca.habitacion_id
WHERE h.fecha_alta IS NULL
ORDER BY h.fecha_ingreso;

-- 08. Historial de traslados: LEAD encuentra la siguiente camilla de la misma estancia.
SELECT ac.hospitalizacion_id, ca.codigo AS camilla, ac.inicio, ac.fin,
       LEAD(ca.codigo) OVER
         (PARTITION BY ac.hospitalizacion_id ORDER BY ac.inicio, ac.asignacion_id) AS siguiente_camilla
FROM asignaciones_camilla ac
JOIN camillas ca ON ca.camilla_id = ac.camilla_id
ORDER BY ac.hospitalizacion_id, ac.inicio, ac.asignacion_id;

-- 09. Camillas operativas disponibles ahora (subconsulta correlacionada NOT EXISTS).
SELECT ca.camilla_id, ca.codigo AS camilla, ha.codigo AS habitacion, ha.tipo
FROM camillas ca
JOIN habitaciones ha ON ha.habitacion_id = ca.habitacion_id
WHERE ca.estado_operativo = 'OPERATIVA'
  AND NOT EXISTS (
    SELECT 1 FROM asignaciones_camilla ac
    WHERE ac.camilla_id = ca.camilla_id AND ac.fin IS NULL
  )
ORDER BY ha.codigo, ca.codigo;

-- 10. Stock util por medicamento y alerta de minimo. Se suman solo lotes no caducados
-- a la fecha de referencia y movimientos registrados hasta el final de ese dia.
SELECT m.codigo, m.principio_activo, m.unidad_inventario, m.stock_minimo,
       COALESCE(s.stock, 0) AS stock_util,
       CASE WHEN COALESCE(s.stock, 0) < m.stock_minimo THEN 'REABASTECER' ELSE 'SUFICIENTE' END AS alerta
FROM medicamentos m
LEFT JOIN (
  SELECT l.medicamento_id, SUM(mi.cantidad) AS stock
  FROM lotes_medicamento l
  JOIN movimientos_inventario mi ON mi.lote_id = l.lote_id
  WHERE l.fecha_caducidad >= @fecha_referencia
    AND mi.fecha < DATE_ADD(@fecha_referencia, INTERVAL 1 DAY)
  GROUP BY l.medicamento_id
) s ON s.medicamento_id = m.medicamento_id
ORDER BY m.medicamento_id;

-- 11. Lotes con existencias ordenados por caducidad (FEFO); HAVING filtra el agregado.
SELECT m.codigo, l.lote_id, l.numero_lote, l.fecha_caducidad,
       SUM(mi.cantidad) AS stock_lote
FROM lotes_medicamento l
JOIN medicamentos m ON m.medicamento_id = l.medicamento_id
JOIN movimientos_inventario mi ON mi.lote_id = l.lote_id
WHERE l.fecha_caducidad >= @fecha_referencia
  AND mi.fecha < DATE_ADD(@fecha_referencia, INTERVAL 1 DAY)
GROUP BY m.codigo, l.lote_id, l.numero_lote, l.fecha_caducidad
HAVING SUM(mi.cantidad) > 0
ORDER BY m.codigo, l.fecha_caducidad, l.lote_id;

-- 12. Prescrito, entregado y pendiente por renglon de receta.
-- Preagregar entregas evita duplicar la cantidad prescrita al unir varias dispensaciones.
SELECT r.receta_id, rd.renglon, p.expediente_clinico, m.codigo,
       rd.cantidad_prescrita, COALESCE(en.entregado, 0) AS cantidad_entregada,
       rd.cantidad_prescrita - COALESCE(en.entregado, 0) AS cantidad_pendiente
FROM recetas r
JOIN consultas co ON co.consulta_id = r.consulta_id
JOIN pacientes p ON p.paciente_id = co.paciente_id
JOIN receta_detalle rd ON rd.receta_id = r.receta_id
JOIN medicamentos m ON m.medicamento_id = rd.medicamento_id
LEFT JOIN (
  SELECT receta_id, renglon, SUM(cantidad) AS entregado
  FROM dispensacion_detalle GROUP BY receta_id, renglon
) en ON en.receta_id = rd.receta_id AND en.renglon = rd.renglon
ORDER BY r.receta_id, rd.renglon;

-- 13. Recetas que tienen al menos un renglon pendiente (subconsulta EXISTS).
SELECT r.receta_id, r.fecha_prescripcion, p.expediente_clinico
FROM recetas r
JOIN consultas co ON co.consulta_id = r.consulta_id
JOIN pacientes p ON p.paciente_id = co.paciente_id
WHERE EXISTS (
  SELECT 1 FROM receta_detalle rd
  WHERE rd.receta_id = r.receta_id
    AND rd.cantidad_prescrita > COALESCE((
      SELECT SUM(dd.cantidad) FROM dispensacion_detalle dd
      WHERE dd.receta_id = rd.receta_id AND dd.renglon = rd.renglon
    ), 0)
)
ORDER BY r.receta_id;

-- 14. Estudios realizados con informe y autor del resultado.
SELECT op.orden_id, p.expediente_clinico, pr.nombre AS procedimiento,
       rp.fecha_resultado, pe.nombre AS autor, rp.informe
FROM ordenes_procedimiento op
JOIN consultas co ON co.consulta_id = op.consulta_id
JOIN pacientes p ON p.paciente_id = co.paciente_id
JOIN procedimientos pr ON pr.procedimiento_id = op.procedimiento_id
JOIN resultados_procedimiento rp ON rp.orden_id = op.orden_id
JOIN personal pe ON pe.personal_id = rp.personal_id
WHERE op.estado = 'REALIZADA'
ORDER BY rp.fecha_resultado;

-- 15. Estudios y procedimientos pendientes con o sin fecha programada.
SELECT op.orden_id, p.expediente_clinico, pr.nombre, pr.tipo,
       op.estado, op.fecha_solicitud, op.fecha_programada
FROM ordenes_procedimiento op
JOIN consultas co ON co.consulta_id = op.consulta_id
JOIN pacientes p ON p.paciente_id = co.paciente_id
JOIN procedimientos pr ON pr.procedimiento_id = op.procedimiento_id
WHERE op.estado IN ('SOLICITADA', 'PROGRAMADA')
ORDER BY op.fecha_programada IS NULL, op.fecha_programada, op.orden_id;

-- 16. Facturas, pagos parciales y saldo mediante CTE.
-- Detalles y pagos se agregan por separado para impedir que los JOIN multipliquen importes.
WITH totales AS (
  SELECT factura_id, SUM(importe) AS total FROM factura_detalle GROUP BY factura_id
), abonado AS (
  SELECT factura_id, SUM(monto) AS pagado FROM pagos GROUP BY factura_id
)
SELECT f.folio, p.expediente_clinico, f.estado,
       COALESCE(t.total, 0) AS total, COALESCE(a.pagado, 0) AS pagado,
       COALESCE(t.total, 0) - COALESCE(a.pagado, 0) AS saldo
FROM facturas f
JOIN pacientes p ON p.paciente_id = f.paciente_id
LEFT JOIN totales t ON t.factura_id = f.factura_id
LEFT JOIN abonado a ON a.factura_id = f.factura_id
WHERE f.estado <> 'ANULADA'
ORDER BY f.factura_id;

-- 17. Ingresos efectivamente cobrados por mes y metodo de pago.
SELECT DATE_FORMAT(pa.fecha, '%Y-%m') AS mes, pa.metodo,
       COUNT(*) AS numero_pagos, SUM(pa.monto) AS monto_cobrado
FROM pagos pa
JOIN facturas f ON f.factura_id = pa.factura_id
WHERE f.estado <> 'ANULADA'
GROUP BY DATE_FORMAT(pa.fecha, '%Y-%m'), pa.metodo
ORDER BY mes, pa.metodo;

-- 18. Medicos con mas de una consulta registrada (GROUP BY y HAVING).
SELECT m.medico_id, pe.nombre AS medico, COUNT(co.consulta_id) AS consultas_realizadas
FROM medicos m
JOIN personal pe ON pe.personal_id = m.medico_id
LEFT JOIN consultas co ON co.medico_id = m.medico_id
GROUP BY m.medico_id, pe.nombre
HAVING COUNT(co.consulta_id) > 1
ORDER BY consultas_realizadas DESC, m.medico_id;

-- 19. Pacientes sin cita futura vigente a la fecha de referencia (NOT EXISTS).
SELECT p.paciente_id, p.expediente_clinico, p.nombre
FROM pacientes p
WHERE p.activo = 1 AND NOT EXISTS (
  SELECT 1 FROM citas ci
  WHERE ci.paciente_id = p.paciente_id
    AND ci.inicio >= @fecha_referencia
    AND ci.estado IN ('PROGRAMADA', 'CONFIRMADA')
)
ORDER BY p.paciente_id;

-- 20. Ultima consulta de cada paciente (ROW_NUMBER y desempate determinista por id).
WITH consultas_ordenadas AS (
  SELECT co.*,
         ROW_NUMBER() OVER
           (PARTITION BY co.paciente_id ORDER BY co.fecha DESC, co.consulta_id DESC) AS posicion
  FROM consultas co
)
SELECT p.expediente_clinico, p.nombre, co.consulta_id, co.fecha, co.tipo
FROM pacientes p
LEFT JOIN consultas_ordenadas co ON co.paciente_id = p.paciente_id AND co.posicion = 1
ORDER BY p.paciente_id;

-- EJEMPLO A: DML reversible. Esta seccion es comentario y no se ejecuta.
-- Descomentar solo este bloque para explicar START TRANSACTION / ROLLBACK.
-- START TRANSACTION;
-- SELECT contacto_id, telefono FROM contactos_emergencia WHERE contacto_id = 1 FOR UPDATE;
-- UPDATE contactos_emergencia SET telefono = 'TEL-PRUEBA-ROLLBACK' WHERE contacto_id = 1;
-- SELECT contacto_id, telefono FROM contactos_emergencia WHERE contacto_id = 1;
-- ROLLBACK;
-- SELECT contacto_id, telefono FROM contactos_emergencia WHERE contacto_id = 1;

-- EJEMPLO B: abono con bloqueo y condicion de saldo. NO se ejecuta automaticamente.
-- El bloqueo de la factura serializa operaciones si todos los escritores lo respetan.
-- Usar en la misma conexion y revertir la demostracion con ROLLBACK.
-- START TRANSACTION;
-- SET @factura_demo = 1;
-- SET @abono_demo = 25.00;
-- SET @factura_bloqueada = NULL;
-- SELECT factura_id INTO @factura_bloqueada
--   FROM facturas WHERE factura_id = @factura_demo AND estado = 'EMITIDA' FOR UPDATE;
-- INSERT INTO pagos (factura_id, fecha, monto, metodo, referencia)
-- SELECT f.factura_id, '2026-10-10 10:00:00', @abono_demo, 'EFECTIVO', 'ABONO-REVERSIBLE-DEMO'
-- FROM facturas f
-- WHERE f.factura_id = @factura_bloqueada AND @abono_demo > 0
--   AND @abono_demo <= COALESCE((SELECT SUM(fd.importe) FROM factura_detalle fd
--                               WHERE fd.factura_id = f.factura_id), 0)
--                     - COALESCE((SELECT SUM(pa.monto) FROM pagos pa
--                                 WHERE pa.factura_id = f.factura_id), 0);
-- SELECT ROW_COUNT() AS filas_insertadas; -- 1 = aceptado; 0 = factura o saldo no validos.
-- ROLLBACK;
