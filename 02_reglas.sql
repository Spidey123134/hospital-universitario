-- Ejecutar despues de 01_esquema.sql. Cada CALL administra su propia transaccion.
-- No llamar estos procedimientos dentro de otra transaccion.
USE hospital_universitario;

CREATE VIEW v_stock_lotes AS
SELECT l.lote_id, l.medicamento_id, l.numero_lote, l.fecha_caducidad,
       COALESCE(SUM(m.cantidad), 0) AS stock
FROM lotes_medicamento l LEFT JOIN movimientos_inventario m ON m.lote_id = l.lote_id
GROUP BY l.lote_id, l.medicamento_id, l.numero_lote, l.fecha_caducidad;

CREATE VIEW v_stock_medicamentos AS
SELECT m.medicamento_id, m.codigo, m.principio_activo, m.unidad_inventario, m.stock_minimo,
       COALESCE(SUM(s.stock), 0) AS stock_total,
       COALESCE(SUM(CASE WHEN s.fecha_caducidad >= CURRENT_DATE THEN s.stock ELSE 0 END), 0) AS stock_vigente
FROM medicamentos m LEFT JOIN v_stock_lotes s ON s.medicamento_id = m.medicamento_id
GROUP BY m.medicamento_id, m.codigo, m.principio_activo, m.unidad_inventario, m.stock_minimo;

CREATE VIEW v_camillas_estado AS
SELECT c.camilla_id, c.codigo, c.habitacion_id, c.estado_operativo, a.hospitalizacion_id,
       CASE WHEN a.asignacion_id IS NOT NULL THEN 'OCUPADA'
            WHEN c.estado_operativo = 'OPERATIVA' THEN 'DISPONIBLE'
            ELSE c.estado_operativo END AS disponibilidad
FROM camillas c LEFT JOIN asignaciones_camilla a ON a.camilla_id = c.camilla_id AND a.fin IS NULL;

CREATE VIEW v_facturas_saldo AS
SELECT f.factura_id, f.folio, f.paciente_id, f.estado,
       COALESCE(d.total, 0) AS total, COALESCE(p.pagado, 0) AS pagado,
       COALESCE(d.total, 0) - COALESCE(p.pagado, 0) AS saldo
FROM facturas f
LEFT JOIN (SELECT factura_id, SUM(importe) AS total FROM factura_detalle GROUP BY factura_id) d ON d.factura_id = f.factura_id
LEFT JOIN (SELECT factura_id, SUM(monto) AS pagado FROM pagos GROUP BY factura_id) p ON p.factura_id = f.factura_id;

CREATE VIEW v_recetas_pendientes AS
SELECT rd.receta_id, rd.renglon, rd.medicamento_id, rd.cantidad_prescrita,
       COALESCE(dd.entregada, 0) AS cantidad_entregada,
       rd.cantidad_prescrita - COALESCE(dd.entregada, 0) AS cantidad_pendiente
FROM receta_detalle rd
LEFT JOIN (SELECT receta_id, renglon, SUM(cantidad) AS entregada FROM dispensacion_detalle GROUP BY receta_id, renglon) dd
ON dd.receta_id = rd.receta_id AND dd.renglon = rd.renglon;

CREATE VIEW v_expediente_consultas AS
SELECT p.paciente_id, p.expediente_clinico, CONCAT_WS(' ', p.nombre, p.apellido_paterno, p.apellido_materno) AS paciente,
       c.consulta_id, c.fecha, c.tipo, c.motivo, c.medico_id,
       CONCAT_WS(' ', pe.nombre, pe.apellido_paterno, pe.apellido_materno) AS medico
FROM consultas c JOIN pacientes p ON p.paciente_id = c.paciente_id JOIN personal pe ON pe.personal_id = c.medico_id;

DELIMITER $$

CREATE TRIGGER tr_medico_insert BEFORE INSERT ON medicos FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM personal WHERE personal_id = NEW.medico_id AND puesto = 'MEDICO' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El medico debe ser personal MEDICO activo';
  END IF;
END$$

CREATE TRIGGER tr_personal_puesto BEFORE UPDATE ON personal FOR EACH ROW
BEGIN
  IF NEW.puesto <> 'MEDICO' AND EXISTS (SELECT 1 FROM medicos WHERE medico_id = OLD.personal_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puede cambiar el puesto de un medico registrado';
  END IF;
END$$

CREATE TRIGGER tr_consulta_identidad BEFORE UPDATE ON consultas FOR EACH ROW
BEGIN
  IF NEW.paciente_id <> OLD.paciente_id OR NEW.medico_id <> OLD.medico_id OR NOT (NEW.cita_id <=> OLD.cita_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La identidad de una consulta registrada es inmutable';
  END IF;
END$$

CREATE TRIGGER tr_receta_identidad BEFORE UPDATE ON recetas FOR EACH ROW
BEGIN
  IF NEW.consulta_id <> OLD.consulta_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una receta no puede reasignarse a otra consulta';
  END IF;
END$$

CREATE TRIGGER tr_receta_detalle_update BEFORE UPDATE ON receta_detalle FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM dispensacion_detalle WHERE receta_id = OLD.receta_id AND renglon = OLD.renglon) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puede modificar una linea de receta ya dispensada';
  END IF;
END$$

CREATE TRIGGER tr_nota_insert BEFORE INSERT ON notas_enfermeria FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM personal WHERE personal_id = NEW.personal_id AND puesto = 'ENFERMERIA' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La nota requiere personal de ENFERMERIA activo';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM hospitalizaciones WHERE hospitalizacion_id = NEW.hospitalizacion_id
                 AND NEW.fecha >= fecha_ingreso AND (fecha_alta IS NULL OR NEW.fecha <= fecha_alta)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La nota debe estar dentro de la hospitalizacion';
  END IF;
END$$

CREATE TRIGGER tr_resultado_insert BEFORE INSERT ON resultados_procedimiento FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ordenes_procedimiento WHERE orden_id = NEW.orden_id
                 AND estado <> 'CANCELADA' AND NEW.fecha_resultado >= fecha_solicitud) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Orden cancelada, inexistente o fecha de resultado invalida';
  END IF;
END$$

CREATE TRIGGER tr_resultado_estado AFTER INSERT ON resultados_procedimiento FOR EACH ROW
BEGIN
  UPDATE ordenes_procedimiento SET estado = 'REALIZADA' WHERE orden_id = NEW.orden_id;
END$$

CREATE TRIGGER tr_resultado_update BEFORE UPDATE ON resultados_procedimiento FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El informe registrado es inmutable en este modelo academico';
END$$

CREATE TRIGGER tr_orden_update BEFORE UPDATE ON ordenes_procedimiento FOR EACH ROW
BEGIN
  IF NEW.consulta_id <> OLD.consulta_id OR NEW.procedimiento_id <> OLD.procedimiento_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La identidad de una orden registrada es inmutable';
  END IF;
  IF NEW.estado <> 'REALIZADA' AND EXISTS (SELECT 1 FROM resultados_procedimiento WHERE orden_id = OLD.orden_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una orden con resultado debe permanecer REALIZADA';
  END IF;
END$$

CREATE TRIGGER tr_disp_insert BEFORE INSERT ON dispensaciones FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM personal WHERE personal_id = NEW.personal_id AND puesto = 'FARMACIA' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La entrega requiere personal de FARMACIA activo';
  END IF;
END$$

CREATE TRIGGER tr_disp_detalle_update BEFORE UPDATE ON dispensacion_detalle FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una entrega registrada es inmutable';
END$$

CREATE TRIGGER tr_disp_detalle_delete BEFORE DELETE ON dispensacion_detalle FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una entrega registrada es inmutable';
END$$

CREATE TRIGGER tr_mov_insert BEFORE INSERT ON movimientos_inventario FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM personal WHERE personal_id = NEW.personal_id AND puesto = 'FARMACIA' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El movimiento requiere personal de FARMACIA activo';
  END IF;
  IF NEW.dispensacion_detalle_id IS NOT NULL AND NOT EXISTS
    (SELECT 1 FROM dispensacion_detalle WHERE dispensacion_detalle_id = NEW.dispensacion_detalle_id
     AND lote_id = NEW.lote_id AND NEW.cantidad = -CAST(cantidad AS SIGNED)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La salida debe coincidir con la cantidad entregada';
  END IF;
END$$

CREATE TRIGGER tr_mov_update BEFORE UPDATE ON movimientos_inventario FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inventario es inmutable: registre un movimiento de ajuste';
END$$
CREATE TRIGGER tr_mov_delete BEFORE DELETE ON movimientos_inventario FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inventario es inmutable: registre un movimiento de ajuste';
END$$

CREATE TRIGGER tr_factura_detalle_insert BEFORE INSERT ON factura_detalle FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM facturas WHERE factura_id = NEW.factura_id AND estado = 'ABIERTA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo puede agregar conceptos a una factura ABIERTA';
  END IF;
END$$
CREATE TRIGGER tr_factura_detalle_update BEFORE UPDATE ON factura_detalle FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM facturas WHERE factura_id = OLD.factura_id AND estado = 'ABIERTA')
     OR NOT EXISTS (SELECT 1 FROM facturas WHERE factura_id = NEW.factura_id AND estado = 'ABIERTA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los conceptos de una factura emitida son inmutables';
  END IF;
END$$
CREATE TRIGGER tr_factura_detalle_delete BEFORE DELETE ON factura_detalle FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM facturas WHERE factura_id = OLD.factura_id AND estado = 'ABIERTA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los conceptos de una factura emitida son inmutables';
  END IF;
END$$

CREATE TRIGGER tr_factura_estado BEFORE UPDATE ON facturas FOR EACH ROW
BEGIN
  IF OLD.estado = 'ANULADA' AND NEW.estado <> OLD.estado THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una factura anulada no puede reabrirse';
  END IF;
  IF OLD.estado = 'EMITIDA' AND (NEW.estado = 'ABIERTA' OR NEW.paciente_id <> OLD.paciente_id
      OR NOT (NEW.poliza_id <=> OLD.poliza_id) OR NEW.fecha <> OLD.fecha OR NEW.folio <> OLD.folio) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La identidad y conceptos de la factura emitida estan cerrados';
  END IF;
  IF NEW.estado = 'EMITIDA' AND NOT EXISTS (SELECT 1 FROM factura_detalle WHERE factura_id = OLD.factura_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puede emitir una factura sin conceptos';
  END IF;
  IF NEW.estado = 'ANULADA' AND EXISTS (SELECT 1 FROM pagos WHERE factura_id = OLD.factura_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puede anular una factura con pagos registrados';
  END IF;
END$$

CREATE TRIGGER tr_factura_insert BEFORE INSERT ON facturas FOR EACH ROW
BEGIN
  IF NEW.estado <> 'ABIERTA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Toda factura debe crearse ABIERTA y emitirse despues de sus conceptos';
  END IF;
END$$

CREATE TRIGGER tr_pago_update BEFORE UPDATE ON pagos FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un pago registrado es inmutable en este modelo academico';
END$$
CREATE TRIGGER tr_pago_delete BEFORE DELETE ON pagos FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un pago registrado es inmutable en este modelo academico';
END$$

-- Las reglas con agregados/intervalos usan procedimientos y bloqueos de filas.
-- Para una aplicacion: conceder EXECUTE; evitar INSERT/UPDATE/DELETE directos
-- en citas, asignaciones, entregas, movimientos y pagos al usuario operativo.
CREATE PROCEDURE sp_agendar_cita(IN p_paciente INT UNSIGNED, IN p_medico INT UNSIGNED,
  IN p_inicio DATETIME, IN p_fin DATETIME, IN p_motivo VARCHAR(250), OUT p_cita INT UNSIGNED)
BEGIN
  DECLARE v_activo INT DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION;
  SELECT pe.activo INTO v_activo FROM medicos m JOIN personal pe ON pe.personal_id = m.medico_id
    WHERE m.medico_id = p_medico FOR UPDATE;
  IF v_activo IS NULL OR v_activo <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medico inexistente o inactivo'; END IF;
  SET v_activo = NULL;
  SELECT activo INTO v_activo FROM pacientes WHERE paciente_id = p_paciente FOR UPDATE;
  IF v_activo IS NULL OR v_activo <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Paciente inexistente o inactivo'; END IF;
  IF p_inicio IS NULL OR p_fin IS NULL OR p_fin <= p_inicio THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Intervalo de cita invalido'; END IF;
  IF EXISTS (SELECT 1 FROM citas WHERE estado <> 'CANCELADA' AND (medico_id = p_medico OR paciente_id = p_paciente)
             AND inicio < p_fin AND fin > p_inicio) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cita se solapa con otra del medico o paciente';
  END IF;
  INSERT INTO citas(paciente_id, medico_id, inicio, fin, motivo) VALUES(p_paciente, p_medico, p_inicio, p_fin, p_motivo);
  SET p_cita = LAST_INSERT_ID();
  COMMIT;
END$$

-- Si existe una asignacion abierta, se cierra y se registra el traslado.
CREATE PROCEDURE sp_asignar_camilla(IN p_hosp INT UNSIGNED, IN p_camilla INT UNSIGNED,
  IN p_inicio DATETIME, OUT p_asignacion INT UNSIGNED)
BEGIN
  DECLARE v_ingreso DATETIME DEFAULT NULL;
  DECLARE v_alta DATETIME DEFAULT NULL;
  DECLARE v_estado VARCHAR(30) DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION;
  SELECT fecha_ingreso, fecha_alta INTO v_ingreso, v_alta FROM hospitalizaciones WHERE hospitalizacion_id = p_hosp FOR UPDATE;
  IF v_ingreso IS NULL OR v_alta IS NOT NULL OR p_inicio IS NULL OR p_inicio < v_ingreso THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hospitalizacion cerrada, inexistente o fecha invalida';
  END IF;
  SELECT estado_operativo INTO v_estado FROM camillas WHERE camilla_id = p_camilla FOR UPDATE;
  IF v_estado IS NULL OR v_estado <> 'OPERATIVA' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Camilla inexistente o no operativa'; END IF;
  IF EXISTS (SELECT 1 FROM asignaciones_camilla WHERE camilla_id = p_camilla AND (fin IS NULL OR fin > p_inicio)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Camilla ocupada o intervalo incompatible';
  END IF;
  IF EXISTS (SELECT 1 FROM asignaciones_camilla WHERE hospitalizacion_id = p_hosp
              AND ((fin IS NULL AND inicio >= p_inicio) OR (fin IS NOT NULL AND fin > p_inicio))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El traslado no puede preceder al historial de asignaciones';
  END IF;
  UPDATE asignaciones_camilla SET fin = p_inicio WHERE hospitalizacion_id = p_hosp AND fin IS NULL;
  INSERT INTO asignaciones_camilla(hospitalizacion_id, camilla_id, inicio) VALUES(p_hosp, p_camilla, p_inicio);
  SET p_asignacion = LAST_INSERT_ID();
  COMMIT;
END$$

CREATE PROCEDURE sp_alta_hospitalaria(IN p_hosp INT UNSIGNED, IN p_fecha DATETIME, IN p_resumen TEXT)
BEGIN
  DECLARE v_ingreso DATETIME DEFAULT NULL;
  DECLARE v_alta DATETIME DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION;
  SELECT fecha_ingreso, fecha_alta INTO v_ingreso, v_alta FROM hospitalizaciones WHERE hospitalizacion_id = p_hosp FOR UPDATE;
  IF v_ingreso IS NULL OR v_alta IS NOT NULL OR p_fecha IS NULL OR p_fecha < v_ingreso THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hospitalizacion cerrada, inexistente o fecha de alta invalida';
  END IF;
  IF EXISTS (SELECT 1 FROM asignaciones_camilla WHERE hospitalizacion_id = p_hosp
             AND (inicio >= p_fecha OR (fin IS NOT NULL AND fin > p_fecha))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El alta no puede preceder a las asignaciones';
  END IF;
  IF EXISTS (SELECT 1 FROM notas_enfermeria WHERE hospitalizacion_id = p_hosp AND fecha > p_fecha) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El alta no puede preceder a las notas de enfermeria';
  END IF;
  UPDATE asignaciones_camilla SET fin = p_fecha WHERE hospitalizacion_id = p_hosp AND fin IS NULL;
  UPDATE hospitalizaciones SET fecha_alta = p_fecha, resumen_alta = p_resumen WHERE hospitalizacion_id = p_hosp;
  COMMIT;
END$$

CREATE PROCEDURE sp_registrar_movimiento(IN p_lote INT UNSIGNED, IN p_personal INT UNSIGNED,
  IN p_fecha DATETIME, IN p_tipo VARCHAR(10), IN p_cantidad INT, IN p_motivo VARCHAR(250), OUT p_movimiento INT UNSIGNED)
BEGIN
  DECLARE v_recepcion DATE DEFAULT NULL;
  DECLARE v_stock BIGINT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION;
  SELECT fecha_recepcion INTO v_recepcion FROM lotes_medicamento WHERE lote_id = p_lote FOR UPDATE;
  IF v_recepcion IS NULL OR p_fecha IS NULL OR DATE(p_fecha) < v_recepcion THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lote inexistente o movimiento anterior a recepcion';
  END IF;
  IF EXISTS (SELECT 1 FROM movimientos_inventario WHERE lote_id = p_lote AND fecha > p_fecha) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los movimientos del lote deben registrarse cronologicamente';
  END IF;
  SELECT COALESCE(SUM(cantidad),0) INTO v_stock FROM movimientos_inventario WHERE lote_id = p_lote;
  IF p_cantidad IS NULL OR v_stock + p_cantidad < 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El movimiento dejaria stock negativo'; END IF;
  INSERT INTO movimientos_inventario(lote_id, personal_id, fecha, tipo, cantidad, motivo)
    VALUES(p_lote, p_personal, p_fecha, p_tipo, p_cantidad, p_motivo);
  SET p_movimiento = LAST_INSERT_ID();
  COMMIT;
END$$

-- Entrega de una linea y un lote; repetir CALL permite entregas parciales.
CREATE PROCEDURE sp_dispensar(IN p_receta INT UNSIGNED, IN p_renglon SMALLINT UNSIGNED,
  IN p_lote INT UNSIGNED, IN p_cantidad INT UNSIGNED, IN p_personal INT UNSIGNED,
  IN p_fecha DATETIME, OUT p_dispensacion INT UNSIGNED)
BEGIN
  DECLARE v_med INT UNSIGNED DEFAULT NULL;
  DECLARE v_med_lote INT UNSIGNED DEFAULT NULL;
  DECLARE v_prescrita INT UNSIGNED DEFAULT NULL;
  DECLARE v_entregada BIGINT DEFAULT 0;
  DECLARE v_stock BIGINT DEFAULT 0;
  DECLARE v_caducidad DATE;
  DECLARE v_recepcion DATE;
  DECLARE v_prescripcion DATETIME;
  DECLARE v_detalle INT UNSIGNED;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION;
  SELECT medicamento_id, cantidad_prescrita INTO v_med, v_prescrita
    FROM receta_detalle WHERE receta_id = p_receta AND renglon = p_renglon FOR UPDATE;
  IF v_med IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Linea de receta inexistente'; END IF;
  SELECT medicamento_id, fecha_caducidad, fecha_recepcion INTO v_med_lote, v_caducidad, v_recepcion
    FROM lotes_medicamento WHERE lote_id = p_lote FOR UPDATE;
  SELECT fecha_prescripcion INTO v_prescripcion FROM recetas WHERE receta_id = p_receta;
  IF v_med_lote IS NULL OR v_med_lote <> v_med THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El lote no corresponde al medicamento recetado'; END IF;
  IF p_fecha IS NULL OR p_fecha < v_prescripcion OR DATE(p_fecha) < v_recepcion OR DATE(p_fecha) > v_caducidad THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fecha de entrega invalida o lote caducado';
  END IF;
  IF EXISTS (SELECT 1 FROM movimientos_inventario WHERE lote_id = p_lote AND fecha > p_fecha) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La entrega no puede preceder al ultimo movimiento del lote';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM personal WHERE personal_id = p_personal AND puesto = 'FARMACIA' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La entrega requiere personal de FARMACIA activo';
  END IF;
  SELECT COALESCE(SUM(cantidad),0) INTO v_entregada FROM dispensacion_detalle WHERE receta_id = p_receta AND renglon = p_renglon;
  SELECT COALESCE(SUM(cantidad),0) INTO v_stock FROM movimientos_inventario WHERE lote_id = p_lote;
  IF p_cantidad IS NULL OR p_cantidad = 0 OR v_entregada + p_cantidad > v_prescrita THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad excede lo pendiente de la receta';
  END IF;
  IF p_cantidad > v_stock THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente'; END IF;
  INSERT INTO dispensaciones(receta_id, personal_id, fecha) VALUES(p_receta, p_personal, p_fecha);
  SET p_dispensacion = LAST_INSERT_ID();
  INSERT INTO dispensacion_detalle(dispensacion_id, receta_id, renglon, medicamento_id, lote_id, cantidad)
    VALUES(p_dispensacion, p_receta, p_renglon, v_med, p_lote, p_cantidad);
  SET v_detalle = LAST_INSERT_ID();
  INSERT INTO movimientos_inventario(lote_id, dispensacion_detalle_id, personal_id, fecha, tipo, cantidad, motivo)
    VALUES(p_lote, v_detalle, p_personal, p_fecha, 'SALIDA', -CAST(p_cantidad AS SIGNED), 'Dispensacion de receta');
  COMMIT;
END$$

CREATE PROCEDURE sp_registrar_pago(IN p_factura INT UNSIGNED, IN p_fecha DATETIME,
  IN p_monto DECIMAL(14,2), IN p_metodo VARCHAR(20), IN p_referencia VARCHAR(100), OUT p_pago INT UNSIGNED)
BEGIN
  DECLARE v_estado VARCHAR(15) DEFAULT NULL;
  DECLARE v_fecha DATETIME;
  DECLARE v_total DECIMAL(14,2) DEFAULT 0;
  DECLARE v_pagado DECIMAL(14,2) DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  START TRANSACTION;
  SELECT estado, fecha INTO v_estado, v_fecha FROM facturas WHERE factura_id = p_factura FOR UPDATE;
  IF v_estado IS NULL OR v_estado <> 'EMITIDA' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo puede pagar una factura EMITIDA'; END IF;
  IF p_fecha IS NULL OR p_fecha < v_fecha THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pago anterior a la factura'; END IF;
  SELECT COALESCE(SUM(importe),0) INTO v_total FROM factura_detalle WHERE factura_id = p_factura;
  SELECT COALESCE(SUM(monto),0) INTO v_pagado FROM pagos WHERE factura_id = p_factura;
  IF p_monto IS NULL OR p_monto <= 0 OR p_monto > v_total - v_pagado THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Monto invalido o superior al saldo pendiente';
  END IF;
  INSERT INTO pagos(factura_id, fecha, monto, metodo, referencia) VALUES(p_factura, p_fecha, p_monto, p_metodo, p_referencia);
  SET p_pago = LAST_INSERT_ID();
  COMMIT;
END$$

DELIMITER ;
