-- COPIA NUEVA PARA PRACTICAR. Ejecutar completa una sola vez.
-- No es un respaldo de datos modificados.
-- INSTALACIÓN INICIAL: estructura, reglas y 143 registros.
-- Conjunto académico con datos inventados; no corresponde a pacientes reales.
-- HOSPITAL: proyecto universitario de sistemas. MySQL 8.0.16 o posterior.
-- Ejecutar una vez en un esquema NUEVO. No elimina ninguna base existente.
-- Los datos del prototipo .ibd NO se importan con este archivo.
SET NAMES utf8mb4;
CREATE DATABASE hospital_practica CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE hospital_practica;

-- 1. ORGANIZACION Y PERSONAS
CREATE TABLE departamentos (
  departamento_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(20) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE especialidades (
  especialidad_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE personal (
  personal_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  numero_empleado VARCHAR(25) NOT NULL UNIQUE,
  departamento_id INT UNSIGNED NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  apellido_paterno VARCHAR(100) NOT NULL,
  apellido_materno VARCHAR(100),
  puesto ENUM('MEDICO','ENFERMERIA','FARMACIA','RECEPCION','ADMINISTRACION','LABORATORIO') NOT NULL,
  telefono VARCHAR(25),
  email VARCHAR(150),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_personal_departamento FOREIGN KEY (departamento_id) REFERENCES departamentos(departamento_id),
  CONSTRAINT ck_personal_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE medicos (
  medico_id INT UNSIGNED PRIMARY KEY,
  cedula_profesional VARCHAR(50) NOT NULL UNIQUE,
  CONSTRAINT fk_medico_personal FOREIGN KEY (medico_id) REFERENCES personal(personal_id)
) ENGINE=InnoDB;

CREATE TABLE medico_especialidad (
  medico_id INT UNSIGNED NOT NULL,
  especialidad_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (medico_id, especialidad_id),
  CONSTRAINT fk_me_medico FOREIGN KEY (medico_id) REFERENCES medicos(medico_id),
  CONSTRAINT fk_me_especialidad FOREIGN KEY (especialidad_id) REFERENCES especialidades(especialidad_id)
) ENGINE=InnoDB;

CREATE TABLE pacientes (
  paciente_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  expediente_clinico VARCHAR(30) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  apellido_paterno VARCHAR(100) NOT NULL,
  apellido_materno VARCHAR(100),
  fecha_nacimiento DATE NOT NULL,
  sexo ENUM('F','M','NO_ESPECIFICADO') NOT NULL DEFAULT 'NO_ESPECIFICADO',
  telefono VARCHAR(25),
  email VARCHAR(150),
  domicilio VARCHAR(250),
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT ck_paciente_activo CHECK (activo IN (0,1)),
  CONSTRAINT ck_paciente_nacimiento CHECK (fecha_nacimiento <= DATE(fecha_registro))
) ENGINE=InnoDB;

CREATE TABLE contactos_emergencia (
  contacto_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  paciente_id INT UNSIGNED NOT NULL,
  nombre VARCHAR(200) NOT NULL,
  parentesco VARCHAR(50) NOT NULL,
  telefono VARCHAR(25) NOT NULL,
  prioridad TINYINT UNSIGNED NOT NULL DEFAULT 1,
  UNIQUE (paciente_id, prioridad),
  CONSTRAINT fk_contacto_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes(paciente_id),
  CONSTRAINT ck_contacto_prioridad CHECK (prioridad > 0)
) ENGINE=InnoDB;

CREATE TABLE aseguradoras (
  aseguradora_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL UNIQUE,
  telefono VARCHAR(25)
) ENGINE=InnoDB;

CREATE TABLE polizas (
  poliza_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  paciente_id INT UNSIGNED NOT NULL,
  aseguradora_id INT UNSIGNED NOT NULL,
  numero_poliza VARCHAR(60) NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  UNIQUE (aseguradora_id, numero_poliza, paciente_id),
  UNIQUE (poliza_id, paciente_id),
  CONSTRAINT fk_poliza_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes(paciente_id),
  CONSTRAINT fk_poliza_aseguradora FOREIGN KEY (aseguradora_id) REFERENCES aseguradoras(aseguradora_id),
  CONSTRAINT ck_poliza_fechas CHECK (fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

-- 2. INFRAESTRUCTURA
CREATE TABLE habitaciones (
  habitacion_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  departamento_id INT UNSIGNED NOT NULL,
  codigo VARCHAR(30) NOT NULL UNIQUE,
  edificio VARCHAR(50) NOT NULL,
  piso SMALLINT NOT NULL,
  tipo ENUM('GENERAL','PRIVADA','UCI','URGENCIAS') NOT NULL,
  CONSTRAINT fk_habitacion_departamento FOREIGN KEY (departamento_id) REFERENCES departamentos(departamento_id)
) ENGINE=InnoDB;

CREATE TABLE camillas (
  camilla_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  habitacion_id INT UNSIGNED NOT NULL,
  codigo VARCHAR(30) NOT NULL UNIQUE,
  estado_operativo ENUM('OPERATIVA','MANTENIMIENTO','FUERA_SERVICIO') NOT NULL DEFAULT 'OPERATIVA',
  CONSTRAINT fk_camilla_habitacion FOREIGN KEY (habitacion_id) REFERENCES habitaciones(habitacion_id)
) ENGINE=InnoDB;

-- 3. ATENCION CLINICA
CREATE TABLE citas (
  cita_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  paciente_id INT UNSIGNED NOT NULL,
  medico_id INT UNSIGNED NOT NULL,
  inicio DATETIME NOT NULL,
  fin DATETIME NOT NULL,
  motivo VARCHAR(250) NOT NULL,
  estado ENUM('PROGRAMADA','CONFIRMADA','ATENDIDA','CANCELADA','NO_ASISTIO') NOT NULL DEFAULT 'PROGRAMADA',
  medico_agenda INT UNSIGNED GENERATED ALWAYS AS (CASE WHEN estado <> 'CANCELADA' THEN medico_id END) STORED,
  paciente_agenda INT UNSIGNED GENERATED ALWAYS AS (CASE WHEN estado <> 'CANCELADA' THEN paciente_id END) STORED,
  UNIQUE (medico_agenda, inicio),
  UNIQUE (paciente_agenda, inicio),
  UNIQUE (cita_id, paciente_id, medico_id),
  KEY ix_cita_paciente_fecha (paciente_id, inicio),
  KEY ix_cita_medico_intervalo (medico_id, inicio, fin),
  CONSTRAINT fk_cita_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes(paciente_id),
  CONSTRAINT fk_cita_medico FOREIGN KEY (medico_id) REFERENCES medicos(medico_id),
  CONSTRAINT ck_cita_intervalo CHECK (fin > inicio)
) ENGINE=InnoDB;

CREATE TABLE consultas (
  consulta_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cita_id INT UNSIGNED UNIQUE,
  paciente_id INT UNSIGNED NOT NULL,
  medico_id INT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tipo ENUM('PROGRAMADA','URGENCIA','SEGUIMIENTO') NOT NULL,
  motivo VARCHAR(250) NOT NULL,
  notas TEXT,
  peso_kg DECIMAL(6,2),
  talla_cm DECIMAL(5,2),
  temperatura_c DECIMAL(4,1),
  UNIQUE (consulta_id, paciente_id),
  KEY ix_consulta_paciente_fecha (paciente_id, fecha),
  CONSTRAINT fk_consulta_cita FOREIGN KEY (cita_id, paciente_id, medico_id) REFERENCES citas(cita_id, paciente_id, medico_id),
  CONSTRAINT fk_consulta_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes(paciente_id),
  CONSTRAINT fk_consulta_medico FOREIGN KEY (medico_id) REFERENCES medicos(medico_id),
  CONSTRAINT ck_consulta_peso CHECK (peso_kg IS NULL OR peso_kg > 0),
  CONSTRAINT ck_consulta_talla CHECK (talla_cm IS NULL OR talla_cm > 0)
) ENGINE=InnoDB;

CREATE TABLE diagnosticos (
  diagnostico_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(20) NOT NULL UNIQUE,
  descripcion VARCHAR(250) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE consulta_diagnosticos (
  consulta_id INT UNSIGNED NOT NULL,
  diagnostico_id INT UNSIGNED NOT NULL,
  es_principal BOOLEAN NOT NULL DEFAULT FALSE,
  diagnostico_principal INT UNSIGNED GENERATED ALWAYS AS (CASE WHEN es_principal = 1 THEN consulta_id END) STORED,
  observaciones VARCHAR(250),
  PRIMARY KEY (consulta_id, diagnostico_id),
  UNIQUE (diagnostico_principal),
  CONSTRAINT fk_cd_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(consulta_id),
  CONSTRAINT fk_cd_diagnostico FOREIGN KEY (diagnostico_id) REFERENCES diagnosticos(diagnostico_id),
  CONSTRAINT ck_cd_principal CHECK (es_principal IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE alergias_paciente (
  alergia_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  paciente_id INT UNSIGNED NOT NULL,
  sustancia VARCHAR(150) NOT NULL,
  reaccion VARCHAR(250) NOT NULL,
  fecha_registro DATE NOT NULL,
  UNIQUE (paciente_id, sustancia),
  CONSTRAINT fk_alergia_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes(paciente_id)
) ENGINE=InnoDB;

CREATE TABLE hospitalizaciones (
  hospitalizacion_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  consulta_ingreso_id INT UNSIGNED NOT NULL UNIQUE,
  paciente_id INT UNSIGNED NOT NULL,
  medico_responsable_id INT UNSIGNED NOT NULL,
  fecha_ingreso DATETIME NOT NULL,
  fecha_alta DATETIME,
  motivo VARCHAR(250) NOT NULL,
  resumen_alta TEXT,
  paciente_internado INT UNSIGNED GENERATED ALWAYS AS (CASE WHEN fecha_alta IS NULL THEN paciente_id END) STORED,
  UNIQUE (paciente_internado),
  CONSTRAINT fk_hosp_consulta FOREIGN KEY (consulta_ingreso_id, paciente_id) REFERENCES consultas(consulta_id, paciente_id),
  CONSTRAINT fk_hosp_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes(paciente_id),
  CONSTRAINT fk_hosp_medico FOREIGN KEY (medico_responsable_id) REFERENCES medicos(medico_id),
  CONSTRAINT ck_hosp_fechas CHECK (fecha_alta IS NULL OR fecha_alta >= fecha_ingreso)
) ENGINE=InnoDB;

CREATE TABLE asignaciones_camilla (
  asignacion_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  hospitalizacion_id INT UNSIGNED NOT NULL,
  camilla_id INT UNSIGNED NOT NULL,
  inicio DATETIME NOT NULL,
  fin DATETIME,
  camilla_ocupada INT UNSIGNED GENERATED ALWAYS AS (CASE WHEN fin IS NULL THEN camilla_id END) STORED,
  hospitalizacion_asignada INT UNSIGNED GENERATED ALWAYS AS (CASE WHEN fin IS NULL THEN hospitalizacion_id END) STORED,
  UNIQUE (camilla_ocupada),
  UNIQUE (hospitalizacion_asignada),
  KEY ix_asignacion_historial (camilla_id, inicio, fin),
  CONSTRAINT fk_asignacion_hosp FOREIGN KEY (hospitalizacion_id) REFERENCES hospitalizaciones(hospitalizacion_id),
  CONSTRAINT fk_asignacion_camilla FOREIGN KEY (camilla_id) REFERENCES camillas(camilla_id),
  CONSTRAINT ck_asignacion_fechas CHECK (fin IS NULL OR fin > inicio)
) ENGINE=InnoDB;

CREATE TABLE notas_enfermeria (
  nota_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  hospitalizacion_id INT UNSIGNED NOT NULL,
  personal_id INT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  observacion TEXT NOT NULL,
  CONSTRAINT fk_nota_hosp FOREIGN KEY (hospitalizacion_id) REFERENCES hospitalizaciones(hospitalizacion_id),
  CONSTRAINT fk_nota_personal FOREIGN KEY (personal_id) REFERENCES personal(personal_id)
) ENGINE=InnoDB;

-- 4. FARMACIA: PRESCRIBIR Y ENTREGAR SON OPERACIONES DISTINTAS.
CREATE TABLE medicamentos (
  medicamento_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(30) NOT NULL UNIQUE,
  principio_activo VARCHAR(150) NOT NULL,
  concentracion VARCHAR(60) NOT NULL,
  presentacion VARCHAR(100) NOT NULL,
  unidad_inventario VARCHAR(40) NOT NULL,
  stock_minimo INT UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE proveedores (
  proveedor_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL UNIQUE,
  telefono VARCHAR(25),
  email VARCHAR(150)
) ENGINE=InnoDB;

CREATE TABLE lotes_medicamento (
  lote_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  medicamento_id INT UNSIGNED NOT NULL,
  proveedor_id INT UNSIGNED NOT NULL,
  numero_lote VARCHAR(50) NOT NULL,
  fecha_recepcion DATE NOT NULL,
  fecha_caducidad DATE NOT NULL,
  costo_unitario DECIMAL(12,2) NOT NULL,
  UNIQUE (medicamento_id, proveedor_id, numero_lote),
  UNIQUE (lote_id, medicamento_id),
  CONSTRAINT fk_lote_medicamento FOREIGN KEY (medicamento_id) REFERENCES medicamentos(medicamento_id),
  CONSTRAINT fk_lote_proveedor FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
  CONSTRAINT ck_lote_fechas CHECK (fecha_caducidad >= fecha_recepcion),
  CONSTRAINT ck_lote_costo CHECK (costo_unitario >= 0)
) ENGINE=InnoDB;

CREATE TABLE recetas (
  receta_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  consulta_id INT UNSIGNED NOT NULL,
  fecha_prescripcion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  observaciones TEXT,
  CONSTRAINT fk_receta_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(consulta_id)
) ENGINE=InnoDB;

CREATE TABLE receta_detalle (
  receta_id INT UNSIGNED NOT NULL,
  renglon SMALLINT UNSIGNED NOT NULL,
  medicamento_id INT UNSIGNED NOT NULL,
  dosis VARCHAR(100) NOT NULL,
  frecuencia VARCHAR(100) NOT NULL,
  duracion_dias SMALLINT UNSIGNED NOT NULL,
  via_administracion VARCHAR(50) NOT NULL,
  cantidad_prescrita INT UNSIGNED NOT NULL,
  PRIMARY KEY (receta_id, renglon),
  UNIQUE (receta_id, renglon, medicamento_id),
  CONSTRAINT fk_rd_receta FOREIGN KEY (receta_id) REFERENCES recetas(receta_id),
  CONSTRAINT fk_rd_medicamento FOREIGN KEY (medicamento_id) REFERENCES medicamentos(medicamento_id),
  CONSTRAINT ck_rd_renglon CHECK (renglon > 0),
  CONSTRAINT ck_rd_cantidad CHECK (cantidad_prescrita > 0),
  CONSTRAINT ck_rd_duracion CHECK (duracion_dias > 0)
) ENGINE=InnoDB;

CREATE TABLE dispensaciones (
  dispensacion_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  receta_id INT UNSIGNED NOT NULL,
  personal_id INT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (dispensacion_id, receta_id),
  CONSTRAINT fk_disp_receta FOREIGN KEY (receta_id) REFERENCES recetas(receta_id),
  CONSTRAINT fk_disp_personal FOREIGN KEY (personal_id) REFERENCES personal(personal_id)
) ENGINE=InnoDB;

CREATE TABLE dispensacion_detalle (
  dispensacion_detalle_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  dispensacion_id INT UNSIGNED NOT NULL,
  receta_id INT UNSIGNED NOT NULL,
  renglon SMALLINT UNSIGNED NOT NULL,
  medicamento_id INT UNSIGNED NOT NULL,
  lote_id INT UNSIGNED NOT NULL,
  cantidad INT UNSIGNED NOT NULL,
  UNIQUE (dispensacion_detalle_id, lote_id),
  KEY ix_dd_prescrito (receta_id, renglon),
  CONSTRAINT fk_dd_dispensacion FOREIGN KEY (dispensacion_id, receta_id) REFERENCES dispensaciones(dispensacion_id, receta_id),
  CONSTRAINT fk_dd_receta_detalle FOREIGN KEY (receta_id, renglon, medicamento_id) REFERENCES receta_detalle(receta_id, renglon, medicamento_id),
  CONSTRAINT fk_dd_lote FOREIGN KEY (lote_id, medicamento_id) REFERENCES lotes_medicamento(lote_id, medicamento_id),
  CONSTRAINT ck_dd_cantidad CHECK (cantidad > 0)
) ENGINE=InnoDB;

CREATE TABLE movimientos_inventario (
  movimiento_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  lote_id INT UNSIGNED NOT NULL,
  dispensacion_detalle_id INT UNSIGNED UNIQUE,
  personal_id INT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tipo ENUM('ENTRADA','SALIDA','AJUSTE') NOT NULL,
  cantidad INT NOT NULL,
  motivo VARCHAR(250) NOT NULL,
  KEY ix_mov_lote (lote_id, movimiento_id),
  CONSTRAINT fk_mov_lote FOREIGN KEY (lote_id) REFERENCES lotes_medicamento(lote_id),
  CONSTRAINT fk_mov_personal FOREIGN KEY (personal_id) REFERENCES personal(personal_id),
  CONSTRAINT fk_mov_disp FOREIGN KEY (dispensacion_detalle_id, lote_id) REFERENCES dispensacion_detalle(dispensacion_detalle_id, lote_id),
  CONSTRAINT ck_mov_signo CHECK ((tipo = 'ENTRADA' AND cantidad > 0) OR (tipo = 'SALIDA' AND cantidad < 0) OR (tipo = 'AJUSTE' AND cantidad <> 0)),
  CONSTRAINT ck_mov_disp_tipo CHECK (dispensacion_detalle_id IS NULL OR tipo = 'SALIDA')
) ENGINE=InnoDB;

-- 5. ESTUDIOS Y PROCEDIMIENTOS (incluye laboratorio, imagen y cirugia).
CREATE TABLE procedimientos (
  procedimiento_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(30) NOT NULL UNIQUE,
  nombre VARCHAR(150) NOT NULL,
  tipo ENUM('LABORATORIO','IMAGEN','CIRUGIA','OTRO') NOT NULL,
  precio_referencia DECIMAL(12,2) NOT NULL,
  CONSTRAINT ck_procedimiento_precio CHECK (precio_referencia >= 0)
) ENGINE=InnoDB;

CREATE TABLE ordenes_procedimiento (
  orden_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  consulta_id INT UNSIGNED NOT NULL,
  procedimiento_id INT UNSIGNED NOT NULL,
  fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_programada DATETIME,
  estado ENUM('SOLICITADA','PROGRAMADA','REALIZADA','CANCELADA') NOT NULL DEFAULT 'SOLICITADA',
  indicaciones TEXT,
  CONSTRAINT fk_orden_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(consulta_id),
  CONSTRAINT fk_orden_procedimiento FOREIGN KEY (procedimiento_id) REFERENCES procedimientos(procedimiento_id)
) ENGINE=InnoDB;

CREATE TABLE resultados_procedimiento (
  resultado_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  orden_id INT UNSIGNED NOT NULL UNIQUE,
  personal_id INT UNSIGNED NOT NULL,
  fecha_resultado DATETIME NOT NULL,
  informe TEXT NOT NULL,
  CONSTRAINT fk_resultado_orden FOREIGN KEY (orden_id) REFERENCES ordenes_procedimiento(orden_id),
  CONSTRAINT fk_resultado_personal FOREIGN KEY (personal_id) REFERENCES personal(personal_id)
) ENGINE=InnoDB;

-- 6. COBROS: IMPORTES HISTORICOS Y PAGOS PARCIALES.
CREATE TABLE facturas (
  factura_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  folio VARCHAR(40) NOT NULL UNIQUE,
  paciente_id INT UNSIGNED NOT NULL,
  poliza_id INT UNSIGNED,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('ABIERTA','EMITIDA','ANULADA') NOT NULL DEFAULT 'ABIERTA',
  CONSTRAINT fk_factura_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes(paciente_id),
  CONSTRAINT fk_factura_poliza FOREIGN KEY (poliza_id, paciente_id) REFERENCES polizas(poliza_id, paciente_id)
) ENGINE=InnoDB;

CREATE TABLE factura_detalle (
  factura_id INT UNSIGNED NOT NULL,
  renglon SMALLINT UNSIGNED NOT NULL,
  descripcion VARCHAR(250) NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL,
  precio_unitario DECIMAL(12,2) NOT NULL,
  descuento DECIMAL(12,2) NOT NULL DEFAULT 0,
  importe DECIMAL(14,2) GENERATED ALWAYS AS (ROUND(cantidad * precio_unitario - descuento, 2)) STORED,
  PRIMARY KEY (factura_id, renglon),
  CONSTRAINT fk_fd_factura FOREIGN KEY (factura_id) REFERENCES facturas(factura_id),
  CONSTRAINT ck_fd_renglon CHECK (renglon > 0),
  CONSTRAINT ck_fd_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_fd_precio CHECK (precio_unitario >= 0),
  CONSTRAINT ck_fd_descuento CHECK (descuento >= 0 AND descuento <= cantidad * precio_unitario)
) ENGINE=InnoDB;

CREATE TABLE pagos (
  pago_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  factura_id INT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  monto DECIMAL(14,2) NOT NULL,
  metodo ENUM('EFECTIVO','TARJETA','TRANSFERENCIA','ASEGURADORA') NOT NULL,
  referencia VARCHAR(100),
  CONSTRAINT fk_pago_factura FOREIGN KEY (factura_id) REFERENCES facturas(factura_id),
  CONSTRAINT ck_pago_monto CHECK (monto > 0)
) ENGINE=InnoDB;

-- 7. ACCESO DE LA FUTURA APLICACION; NO SON USUARIOS DEL SERVIDOR MySQL.
CREATE TABLE roles (
  rol_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion VARCHAR(250) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE usuarios (
  usuario_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  personal_id INT UNSIGNED NOT NULL UNIQUE,
  nombre_usuario VARCHAR(80) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_usuario_personal FOREIGN KEY (personal_id) REFERENCES personal(personal_id),
  CONSTRAINT ck_usuario_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE usuario_roles (
  usuario_id INT UNSIGNED NOT NULL,
  rol_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (usuario_id, rol_id),
  CONSTRAINT fk_ur_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
  CONSTRAINT fk_ur_rol FOREIGN KEY (rol_id) REFERENCES roles(rol_id)
) ENGINE=InnoDB;


-- Ejecutar despues de 01_esquema.sql. Cada CALL administra su propia transaccion.
-- No llamar estos procedimientos dentro de otra transaccion.
USE hospital_practica;

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


-- CARGA INICIAL DEL HOSPITAL UNIVERSITARIO.
-- Conjunto académico con identidades y operaciones inventadas, sin datos de pacientes reales.
-- Ejecutar una sola vez después de 01_esquema.sql y 02_reglas.sql.
-- Detenerse ante el primer error; no ejecutar COMMIT si falla un INSERT.
SET NAMES utf8mb4;
USE hospital_practica;
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
