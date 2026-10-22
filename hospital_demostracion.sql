-- INSTALACIÓN COMPLETA CON 789 REGISTROS EN 36 TABLAS.
-- Ejecutar una sola vez en una base nueva; no ejecutar también hospital_completo.sql.
-- INSTALACIÓN INICIAL: estructura, reglas y 143 registros.
-- Conjunto académico con datos inventados; no corresponde a pacientes reales.
-- HOSPITAL: proyecto universitario de sistemas. MySQL 8.0.16 o posterior.
-- Ejecutar una vez en un esquema NUEVO. No elimina ninguna base existente.
-- Los datos del prototipo .ibd NO se importan con este archivo.
SET NAMES utf8mb4;
CREATE DATABASE hospital_universitario CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE hospital_universitario;

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
  (1, 1, 1, 1, '2026-10-06 09:05:00', 'PROGRAMADA', 'Valoración por cefalea', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 60.0, 160.0, 36.5),
  (2, 2, 2, 2, '2026-10-07 10:05:00', 'PROGRAMADA', 'Valoración por dolor abdominal', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 75.0, 175.0, 36.6),
  (3, NULL, 3, 3, '2026-10-08 11:00:00', 'URGENCIA', 'Valoración por dolor lumbar', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 65.0, 168.0, 36.7),
  (4, 3, 4, 1, '2026-10-08 09:05:00', 'PROGRAMADA', 'Valoración por cefalea', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 40.0, 145.0, 36.5),
  (5, NULL, 5, 2, '2026-10-09 14:00:00', 'URGENCIA', 'Valoración por dolor lumbar', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 80.0, 172.0, 36.8);

INSERT INTO diagnosticos (diagnostico_id, codigo, descripcion) VALUES
  (1, 'DX-001', 'Cefalea'),
  (2, 'DX-002', 'Dolor abdominal'),
  (3, 'DX-003', 'Dolor lumbar');

INSERT INTO consulta_diagnosticos (consulta_id, diagnostico_id, es_principal, observaciones) VALUES
  (1, 1, 1, 'Diagnóstico principal registrado en la consulta.'),
  (1, 2, 0, 'Diagnóstico complementario registrado en el expediente.'),
  (2, 2, 1, 'Diagnóstico principal registrado en la consulta.'),
  (3, 3, 1, 'Diagnóstico principal registrado en la consulta.'),
  (4, 1, 1, 'Diagnóstico principal registrado en la consulta.'),
  (5, 3, 1, 'Diagnóstico principal registrado en la consulta.');

INSERT INTO alergias_paciente (alergia_id, paciente_id, sustancia, reaccion, fecha_registro) VALUES
  (1, 1, 'Penicilina', 'Erupción cutánea', '2026-09-01'),
  (2, 3, 'Ibuprofeno', 'Urticaria', '2026-09-02');

INSERT INTO hospitalizaciones (hospitalizacion_id, consulta_ingreso_id, paciente_id, medico_responsable_id, fecha_ingreso, fecha_alta, motivo, resumen_alta) VALUES
  (1, 3, 3, 3, '2026-10-08 12:00:00', '2026-10-09 12:00:00', 'Observación hospitalaria por dolor lumbar', 'Alta registrada tras valoración del médico responsable. Resumen de atención integrado al expediente.'),
  (2, 5, 5, 2, '2026-10-09 15:00:00', NULL, 'Observación hospitalaria por dolor lumbar', NULL);

INSERT INTO asignaciones_camilla (asignacion_id, hospitalizacion_id, camilla_id, inicio, fin) VALUES
  (1, 1, 1, '2026-10-08 12:00:00', '2026-10-08 18:00:00'),
  (2, 1, 3, '2026-10-08 18:00:00', '2026-10-09 12:00:00'),
  (3, 2, 2, '2026-10-09 15:00:00', NULL);

INSERT INTO notas_enfermeria (nota_id, hospitalizacion_id, personal_id, fecha, observacion) VALUES
  (1, 1, 4, '2026-10-08 12:30:00', 'Se verificó identificación del paciente y ubicación en la camilla asignada.'),
  (2, 1, 5, '2026-10-08 18:30:00', 'Se registró la entrega de turno y la continuidad de los cuidados indicados.'),
  (3, 2, 4, '2026-10-09 15:30:00', 'Se registraron signos vitales y cuidados del turno en la hoja de enfermería.');

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
  (1, 1, '2026-10-06 09:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (2, 3, '2026-10-08 11:30:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (3, 4, '2026-10-08 09:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.');

INSERT INTO receta_detalle (receta_id, renglon, medicamento_id, dosis, frecuencia, duracion_dias, via_administracion, cantidad_prescrita) VALUES
  (1, 1, 1, '1 tableta', 'Cada 24 horas', 1, 'Oral', 8),
  (1, 2, 2, '1 tableta', 'Cada 24 horas', 1, 'Oral', 3),
  (2, 1, 3, '5 mL', 'Cada 24 horas', 1, 'Oral', 4),
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
  (1, 1, 1, '2026-10-06 09:20:00', '2026-10-06 11:00:00', 'REALIZADA', 'Realizar biometría hemática y anexar el informe al expediente.'),
  (2, 2, 2, '2026-10-07 10:20:00', '2026-10-13 11:00:00', 'PROGRAMADA', 'Realizar radiografía de tórax y anexar el informe al expediente.'),
  (3, 3, 3, '2026-10-08 11:30:00', '2026-10-08 13:00:00', 'REALIZADA', 'Realizar electrocardiograma y anexar el informe al expediente.'),
  (4, 5, 4, '2026-10-09 14:30:00', NULL, 'SOLICITADA', 'Realizar apendicectomía y anexar el informe al expediente.');

INSERT INTO resultados_procedimiento (resultado_id, orden_id, personal_id, fecha_resultado, informe) VALUES
  (1, 1, 8, '2026-10-06 12:00:00', 'Informe de biometría hemática. Documento recibido y registrado en el expediente EXP-2026-0001.'),
  (2, 3, 3, '2026-10-08 14:00:00', 'Informe de electrocardiograma. Documento recibido y registrado en el expediente EXP-2026-0003.');

INSERT INTO facturas (factura_id, folio, paciente_id, poliza_id, fecha, estado) VALUES
  (1, 'FAC-2026-00001', 1, 1, '2026-10-06 13:00:00', 'ABIERTA'),
  (2, 'FAC-2026-00002', 2, 2, '2026-10-07 12:00:00', 'ABIERTA'),
  (3, 'FAC-2026-00003', 3, NULL, '2026-10-09 12:30:00', 'ABIERTA'),
  (4, 'FAC-2026-00004', 5, 3, '2026-10-10 09:00:00', 'ABIERTA');

INSERT INTO factura_detalle (factura_id, renglon, descripcion, cantidad, precio_unitario, descuento) VALUES
  (1, 1, 'Consulta de medicina general', 1.0, 500.0, 50.0),
  (1, 2, 'Biometría hemática', 1.0, 300.0, 0.0),
  (1, 3, 'Medicamento dispensado en farmacia', 8.0, 12.5, 0.0),
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


-- CARGA AMPLIADA DEL HOSPITAL UNIVERSITARIO.
-- Conjunto académico con identidades y operaciones inventadas, sin datos de pacientes reales.
-- Agrega 646 registros a los 143 de 03_datos_demo.sql. Ejecutar una sola vez.
-- Los CSV de aporte_equipo conservan la transcripción y procedencia del trabajo del equipo.
-- Detenerse ante el primer error; no ejecutar COMMIT si falla un INSERT.
SET NAMES utf8mb4;
USE hospital_universitario;
START TRANSACTION;

INSERT INTO departamentos (departamento_id, codigo, nombre) VALUES
  (6, 'DEP-006', 'Imagenología'),
  (7, 'DEP-007', 'Cuidados intensivos'),
  (8, 'DEP-008', 'Urgencias');

INSERT INTO especialidades (especialidad_id, nombre) VALUES
  (4, 'Cardiologia'),
  (5, 'Traumatologia'),
  (6, 'Ginecologia'),
  (7, 'Neurologia'),
  (8, 'Dermatologia'),
  (9, 'Oftalmologia'),
  (10, 'Otorrinolaringologia'),
  (11, 'Oncologia'),
  (12, 'Psiquiatria'),
  (13, 'Nefrologia'),
  (14, 'Endocrinologia'),
  (15, 'Urologia'),
  (16, 'Urgencias');

INSERT INTO personal (personal_id, numero_empleado, departamento_id, nombre, apellido_paterno, apellido_materno, puesto, telefono, email, activo) VALUES
  (9, 'EMP-0009', 1, 'Carlos', 'Mendoza', 'García', 'MEDICO', '5533379453', 'carlos.mendoza.9@example.com', 1),
  (10, 'EMP-0010', 8, 'Ana', 'Gómez', 'Torres', 'MEDICO', '5523225344', 'ana.gomez.10@example.com', 1),
  (11, 'EMP-0011', 2, 'Luis', 'Hernández', 'Robles', 'MEDICO', '5588719837', 'luis.hernandez.11@example.com', 1),
  (12, 'EMP-0012', 6, 'María', 'López', 'Santos', 'MEDICO', '5580647355', 'maria.lopez.12@example.com', 1),
  (13, 'EMP-0013', 1, 'Jorge', 'Martínez', 'Duarte', 'MEDICO', '5540955534', 'jorge.martinez.13@example.com', 1),
  (14, 'EMP-0014', 8, 'Sofía', 'Ramírez', 'Román', 'MEDICO', '5581157387', 'sofia.ramirez.14@example.com', 1),
  (15, 'EMP-0015', 2, 'Miguel', 'Torres', 'Vega', 'MEDICO', '5546122686', 'miguel.torres.15@example.com', 1),
  (16, 'EMP-0016', 6, 'Lucía', 'Flores', 'Ponce', 'MEDICO', '5517122981', 'lucia.flores.16@example.com', 1),
  (17, 'EMP-0017', 1, 'David', 'Rivera', 'Salinas', 'MEDICO', '5532315333', 'david.rivera.17@example.com', 1),
  (18, 'EMP-0018', 8, 'Elena', 'Vargas', 'Cortés', 'MEDICO', '5594236597', 'elena.vargas.18@example.com', 1),
  (19, 'EMP-0019', 2, 'Fernando', 'Castro', 'Lara', 'MEDICO', '5595002421', 'fernando.castro.19@example.com', 1),
  (20, 'EMP-0020', 6, 'Carmen', 'Morales', 'Nieto', 'MEDICO', '5596325414', 'carmen.morales.20@example.com', 1),
  (21, 'EMP-0021', 1, 'Javier', 'Jiménez', 'Beltrán', 'MEDICO', '5598057896', 'javier.jimenez.21@example.com', 1),
  (22, 'EMP-0022', 8, 'Patricia', 'Ruiz', 'Ríos', 'MEDICO', '5518248845', 'patricia.ruiz.22@example.com', 1),
  (23, 'EMP-0023', 2, 'Roberto', 'Díaz', 'Soto', 'MEDICO', '5510433163', 'roberto.diaz.23@example.com', 1),
  (24, 'EMP-0024', 2, 'Mariana', 'Vega', 'Medina', 'ENFERMERIA', '5590753483', 'mariana.vega.24@example.com', 1),
  (25, 'EMP-0025', 2, 'Daniel', 'Leon', 'Luna', 'ENFERMERIA', '5573363680', 'daniel.leon.25@example.com', 1);

INSERT INTO medicos (medico_id, cedula_profesional) VALUES
  (9, 'CP-1001'),
  (10, 'CP-1002'),
  (11, 'CP-1003'),
  (12, 'CP-1004'),
  (13, 'CP-1005'),
  (14, 'CP-1006'),
  (15, 'CP-1007'),
  (16, 'CP-1008'),
  (17, 'CP-1009'),
  (18, 'CP-1010'),
  (19, 'CP-1011'),
  (20, 'CP-1012'),
  (21, 'CP-1013'),
  (22, 'CP-1014'),
  (23, 'CP-1015');

INSERT INTO medico_especialidad (medico_id, especialidad_id) VALUES
  (9, 1),
  (10, 16),
  (11, 4),
  (12, 3),
  (13, 5),
  (14, 6),
  (15, 7),
  (16, 8),
  (17, 9),
  (18, 10),
  (19, 11),
  (20, 12),
  (21, 13),
  (22, 14),
  (23, 15);

INSERT INTO pacientes (paciente_id, expediente_clinico, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, sexo, telefono, email, domicilio, fecha_registro, activo) VALUES
  (6, 'EXP-2026-0006', 'Andrea', 'Perez', 'Cortés', '1970-01-01', 'F', '5595034277', 'andrea.perez.6@example.com', 'Calle Pinos 142, Colonia Los Olivos, Ciudad de México', '2026-09-15 09:00:00', 1),
  (7, 'EXP-2026-0007', 'Diego', 'Sanchez', 'Lara', '1973-02-02', 'M', '5558283861', 'diego.sanchez.7@example.com', 'Calle Laurel 149, Colonia Jardines del Sur, Ciudad de México', '2026-09-15 09:00:00', 1),
  (8, 'EXP-2026-0008', 'Valeria', 'Romero', 'Nieto', '1976-03-03', 'F', '5589444820', 'valeria.romero.8@example.com', 'Calle Sauces 156, Colonia Las Fuentes, Ciudad de México', '2026-09-15 09:00:00', 1),
  (9, 'EXP-2026-0009', 'Mateo', 'Ortiz', 'Beltrán', '1979-04-04', 'M', '5562935362', 'mateo.ortiz.9@example.com', 'Calle Amapolas 163, Colonia La Alameda, Ciudad de México', '2026-09-15 09:00:00', 1),
  (10, 'EXP-2026-0010', 'Camila', 'Reyes', 'Ríos', '1982-05-05', 'F', '5572592430', 'camila.reyes.10@example.com', 'Calle Olmos 170, Colonia Santa Clara, Ciudad de México', '2026-09-15 09:00:00', 1),
  (11, 'EXP-2026-0011', 'Sebastian', 'Cruz', 'Soto', '1985-06-06', 'M', '5526174248', 'sebastian.cruz.11@example.com', 'Calle Fresno 177, Colonia Los Olivos, Ciudad de México', '2026-09-15 09:00:00', 1),
  (12, 'EXP-2026-0012', 'Renata', 'Aguilar', 'Medina', '1988-07-07', 'F', '5567858460', 'renata.aguilar.12@example.com', 'Calle Jacarandas 184, Colonia Jardines del Sur, Ciudad de México', '2026-09-15 09:00:00', 1),
  (13, 'EXP-2026-0013', 'Emiliano', 'Jimenez', 'Luna', '1991-08-08', 'M', '5595454144', 'emiliano.jimenez.13@example.com', 'Calle Encinos 191, Colonia Las Fuentes, Ciudad de México', '2026-09-15 09:00:00', 1),
  (14, 'EXP-2026-0014', 'Paula', 'Rojas', 'García', '1994-09-09', 'F', '5566457548', 'paula.rojas.14@example.com', 'Calle Cedros 198, Colonia La Alameda, Ciudad de México', '2026-09-15 09:00:00', 1),
  (15, 'EXP-2026-0015', 'Nicolas', 'Chavez', 'Torres', '1997-10-10', 'M', '5556605764', 'nicolas.chavez.15@example.com', 'Calle Magnolias 205, Colonia Santa Clara, Ciudad de México', '2026-09-15 09:00:00', 1),
  (16, 'EXP-2026-0016', 'Fernanda', 'Molina', 'Robles', '2000-11-11', 'F', '5518103238', 'fernanda.molina.16@example.com', 'Calle Pinos 212, Colonia Los Olivos, Ciudad de México', '2026-09-15 09:00:00', 1),
  (17, 'EXP-2026-0017', 'Alejandro', 'Silva', 'Santos', '2003-12-12', 'M', '5577223791', 'alejandro.silva.17@example.com', 'Calle Laurel 219, Colonia Jardines del Sur, Ciudad de México', '2026-09-15 09:00:00', 1),
  (18, 'EXP-2026-0018', 'Regina', 'Castillo', 'Duarte', '2006-01-13', 'F', '5591059756', 'regina.castillo.18@example.com', 'Calle Sauces 226, Colonia Las Fuentes, Ciudad de México', '2026-09-15 09:00:00', 1),
  (19, 'EXP-2026-0019', 'Leonardo', 'Herrera', 'Román', '2009-02-14', 'M', '5541068101', 'leonardo.herrera.19@example.com', 'Calle Amapolas 233, Colonia La Alameda, Ciudad de México', '2026-09-15 09:00:00', 1),
  (20, 'EXP-2026-0020', 'Daniela', 'Vazquez', 'Vega', '2012-03-15', 'F', '5598702249', 'daniela.vazquez.20@example.com', 'Calle Olmos 240, Colonia Santa Clara, Ciudad de México', '2026-09-15 09:00:00', 1),
  (21, 'EXP-2026-0021', 'Santiago', 'Navarro', 'Ponce', '1970-04-16', 'M', '5513794089', 'santiago.navarro.21@example.com', 'Calle Fresno 247, Colonia Los Olivos, Ciudad de México', '2026-09-15 09:00:00', 1),
  (22, 'EXP-2026-0022', 'Isabella', 'Acosta', 'Salinas', '1973-05-17', 'F', '5573744375', 'isabella.acosta.22@example.com', 'Calle Jacarandas 254, Colonia Jardines del Sur, Ciudad de México', '2026-09-15 09:00:00', 1),
  (23, 'EXP-2026-0023', 'Gabriel', 'Luna', 'Cortés', '1976-06-18', 'M', '5539965520', 'gabriel.luna.23@example.com', 'Calle Encinos 261, Colonia Las Fuentes, Ciudad de México', '2026-09-15 09:00:00', 1),
  (24, 'EXP-2026-0024', 'Ximena', 'Salazar', 'Lara', '1979-07-19', 'F', '5584621011', 'ximena.salazar.24@example.com', 'Calle Cedros 268, Colonia La Alameda, Ciudad de México', '2026-09-15 09:00:00', 1),
  (25, 'EXP-2026-0025', 'Rodrigo', 'Guerrero', 'Nieto', '1982-08-20', 'M', '5578390034', 'rodrigo.guerrero.25@example.com', 'Calle Magnolias 275, Colonia Santa Clara, Ciudad de México', '2026-09-15 09:00:00', 1),
  (26, 'EXP-2026-0026', 'Natalia', 'Campos', 'Beltrán', '1985-09-21', 'F', '5552101549', 'natalia.campos.26@example.com', 'Calle Pinos 282, Colonia Los Olivos, Ciudad de México', '2026-09-15 09:00:00', 1),
  (27, 'EXP-2026-0027', 'Mauricio', 'Delgado', 'Ríos', '1988-10-22', 'M', '5529792698', 'mauricio.delgado.27@example.com', 'Calle Laurel 289, Colonia Jardines del Sur, Ciudad de México', '2026-09-15 09:00:00', 1),
  (28, 'EXP-2026-0028', 'Carolina', 'Paredes', 'Soto', '1991-11-23', 'F', '5528459448', 'carolina.paredes.28@example.com', 'Calle Sauces 296, Colonia Las Fuentes, Ciudad de México', '2026-09-15 09:00:00', 1),
  (29, 'EXP-2026-0029', 'Joaquin', 'Fuentes', 'Medina', '1994-12-24', 'M', '5543823562', 'joaquin.fuentes.29@example.com', 'Calle Amapolas 303, Colonia La Alameda, Ciudad de México', '2026-09-15 09:00:00', 1),
  (30, 'EXP-2026-0030', 'Adriana', 'Mejia', 'Luna', '1997-01-25', 'F', '5579849652', 'adriana.mejia.30@example.com', 'Calle Olmos 310, Colonia Santa Clara, Ciudad de México', '2026-09-15 09:00:00', 1);

INSERT INTO contactos_emergencia (contacto_id, paciente_id, nombre, parentesco, telefono, prioridad) VALUES
  (7, 6, 'Ana Perez Ponce', 'Madre', '5520421006', 1),
  (8, 7, 'Jorge Sanchez Salinas', 'Padre', '5548217525', 1),
  (9, 8, 'Mariana Romero Cortés', 'Hermana', '5528358798', 1),
  (10, 9, 'Rodrigo Ortiz Lara', 'Hermano', '5526365809', 1),
  (11, 10, 'Patricia Reyes Nieto', 'Tutora', '5531353768', 1),
  (12, 11, 'Daniel Cruz Beltrán', 'Cónyuge', '5550991152', 1),
  (13, 12, 'Ana Aguilar Ríos', 'Madre', '5594637664', 1),
  (14, 13, 'Jorge Jimenez Soto', 'Padre', '5555888939', 1),
  (15, 14, 'Mariana Rojas Medina', 'Hermana', '5594391544', 1),
  (16, 15, 'Rodrigo Chavez Luna', 'Hermano', '5524835763', 1),
  (17, 16, 'Patricia Molina García', 'Tutora', '5572391854', 1),
  (18, 17, 'Daniel Silva Torres', 'Cónyuge', '5556396586', 1),
  (19, 18, 'Ana Castillo Robles', 'Madre', '5590242300', 1),
  (20, 19, 'Jorge Herrera Santos', 'Padre', '5591252176', 1),
  (21, 20, 'Mariana Vazquez Duarte', 'Hermana', '5594204797', 1),
  (22, 21, 'Rodrigo Navarro Román', 'Hermano', '5517209811', 1),
  (23, 22, 'Patricia Acosta Vega', 'Tutora', '5518879145', 1),
  (24, 23, 'Daniel Luna Ponce', 'Cónyuge', '5553415024', 1),
  (25, 24, 'Ana Salazar Salinas', 'Madre', '5522273263', 1),
  (26, 25, 'Jorge Guerrero Cortés', 'Padre', '5556866143', 1),
  (27, 26, 'Mariana Campos Lara', 'Hermana', '5518448799', 1),
  (28, 27, 'Rodrigo Delgado Nieto', 'Hermano', '5583736837', 1),
  (29, 28, 'Patricia Paredes Beltrán', 'Tutora', '5518786093', 1),
  (30, 29, 'Daniel Fuentes Ríos', 'Cónyuge', '5561793484', 1),
  (31, 30, 'Ana Mejia Soto', 'Madre', '5518716767', 1);

INSERT INTO aseguradoras (aseguradora_id, nombre, telefono) VALUES
  (3, 'Cobertura Médica del Valle', '5578075862'),
  (4, 'Previsión Familiar', '5525501726'),
  (5, 'Seguros Salud y Bienestar', '5534793683');

INSERT INTO polizas (poliza_id, paciente_id, aseguradora_id, numero_poliza, fecha_inicio, fecha_fin) VALUES
  (4, 6, 3, 'POL-2026-00004', '2026-01-01', '2027-12-31'),
  (5, 7, 4, 'POL-2026-00005', '2026-01-01', '2027-12-31'),
  (6, 8, 5, 'POL-2026-00006', '2026-01-01', '2027-12-31'),
  (7, 9, 3, 'POL-2026-00007', '2026-01-01', '2027-12-31'),
  (8, 10, 4, 'POL-2026-00008', '2026-01-01', '2027-12-31'),
  (9, 11, 5, 'POL-2026-00009', '2026-01-01', '2027-12-31'),
  (10, 12, 3, 'POL-2026-00010', '2026-01-01', '2027-12-31'),
  (11, 13, 4, 'POL-2026-00011', '2026-01-01', '2027-12-31'),
  (12, 14, 5, 'POL-2026-00012', '2026-01-01', '2027-12-31'),
  (13, 15, 3, 'POL-2026-00013', '2026-01-01', '2027-12-31'),
  (14, 16, 4, 'POL-2026-00014', '2026-01-01', '2027-12-31'),
  (15, 17, 5, 'POL-2026-00015', '2026-01-01', '2027-12-31'),
  (16, 18, 3, 'POL-2026-00016', '2026-01-01', '2027-12-31'),
  (17, 19, 4, 'POL-2026-00017', '2026-01-01', '2027-12-31'),
  (18, 20, 5, 'POL-2026-00018', '2026-01-01', '2027-12-31');

INSERT INTO habitaciones (habitacion_id, departamento_id, codigo, edificio, piso, tipo) VALUES
  (5, 2, 'HAB-202', 'Torre C', 2, 'GENERAL'),
  (6, 2, 'HAB-203', 'Torre C', 2, 'PRIVADA'),
  (7, 2, 'HAB-204', 'Torre C', 2, 'UCI'),
  (8, 2, 'HAB-301', 'Torre C', 3, 'GENERAL'),
  (9, 2, 'HAB-302', 'Torre C', 3, 'URGENCIAS');

INSERT INTO camillas (camilla_id, habitacion_id, codigo, estado_operativo) VALUES
  (7, 5, 'CAM-07', 'OPERATIVA'),
  (8, 5, 'CAM-08', 'OPERATIVA'),
  (9, 6, 'CAM-09', 'OPERATIVA'),
  (10, 6, 'CAM-10', 'OPERATIVA'),
  (11, 7, 'CAM-11', 'OPERATIVA'),
  (12, 7, 'CAM-12', 'OPERATIVA'),
  (13, 8, 'CAM-13', 'OPERATIVA'),
  (14, 8, 'CAM-14', 'OPERATIVA'),
  (15, 9, 'CAM-15', 'MANTENIMIENTO');

INSERT INTO citas (cita_id, paciente_id, medico_id, inicio, fin, motivo, estado) VALUES
  (7, 6, 9, '2026-10-01 09:00:00', '2026-10-01 09:30:00', 'Valoración por infección respiratoria de vías superiores', 'ATENDIDA'),
  (8, 7, 10, '2026-10-01 09:45:00', '2026-10-01 10:15:00', 'Valoración por gastritis', 'ATENDIDA'),
  (9, 8, 11, '2026-10-01 10:30:00', '2026-10-01 11:00:00', 'Valoración por rinitis alérgica', 'ATENDIDA'),
  (10, 9, 12, '2026-10-01 11:15:00', '2026-10-01 11:45:00', 'Valoración por control de hipertensión arterial', 'ATENDIDA'),
  (11, 10, 13, '2026-10-01 12:00:00', '2026-10-01 12:30:00', 'Valoración por dolor articular', 'ATENDIDA'),
  (12, 11, 14, '2026-10-02 09:00:00', '2026-10-02 09:30:00', 'Valoración por infección respiratoria de vías superiores', 'ATENDIDA'),
  (13, 12, 15, '2026-10-02 09:45:00', '2026-10-02 10:15:00', 'Valoración por gastritis', 'ATENDIDA'),
  (14, 13, 16, '2026-10-02 10:30:00', '2026-10-02 11:00:00', 'Valoración por rinitis alérgica', 'ATENDIDA'),
  (15, 14, 17, '2026-10-02 11:15:00', '2026-10-02 11:45:00', 'Valoración por control de hipertensión arterial', 'ATENDIDA'),
  (16, 15, 18, '2026-10-02 12:00:00', '2026-10-02 12:30:00', 'Valoración por dolor articular', 'ATENDIDA'),
  (17, 16, 19, '2026-10-03 09:00:00', '2026-10-03 09:30:00', 'Valoración por infección respiratoria de vías superiores', 'ATENDIDA'),
  (18, 17, 20, '2026-10-03 09:45:00', '2026-10-03 10:15:00', 'Valoración por gastritis', 'ATENDIDA'),
  (19, 18, 21, '2026-10-03 10:30:00', '2026-10-03 11:00:00', 'Valoración por rinitis alérgica', 'ATENDIDA'),
  (20, 19, 22, '2026-10-03 11:15:00', '2026-10-03 11:45:00', 'Valoración por control de hipertensión arterial', 'ATENDIDA'),
  (21, 20, 23, '2026-10-03 12:00:00', '2026-10-03 12:30:00', 'Valoración por dolor articular', 'ATENDIDA'),
  (22, 21, 9, '2026-10-04 09:00:00', '2026-10-04 09:30:00', 'Valoración por infección respiratoria de vías superiores', 'ATENDIDA'),
  (23, 22, 10, '2026-10-04 09:45:00', '2026-10-04 10:15:00', 'Valoración por gastritis', 'ATENDIDA'),
  (24, 23, 11, '2026-10-04 10:30:00', '2026-10-04 11:00:00', 'Valoración por rinitis alérgica', 'ATENDIDA'),
  (25, 24, 12, '2026-10-04 11:15:00', '2026-10-04 11:45:00', 'Valoración por control de hipertensión arterial', 'ATENDIDA'),
  (26, 25, 13, '2026-10-04 12:00:00', '2026-10-04 12:30:00', 'Valoración por dolor articular', 'ATENDIDA'),
  (27, 26, 14, '2026-10-05 09:00:00', '2026-10-05 09:30:00', 'Valoración por infección respiratoria de vías superiores', 'ATENDIDA'),
  (28, 27, 15, '2026-10-05 09:45:00', '2026-10-05 10:15:00', 'Valoración por gastritis', 'ATENDIDA'),
  (29, 28, 16, '2026-10-05 10:30:00', '2026-10-05 11:00:00', 'Valoración por rinitis alérgica', 'ATENDIDA'),
  (30, 29, 17, '2026-10-05 11:15:00', '2026-10-05 11:45:00', 'Valoración por control de hipertensión arterial', 'ATENDIDA'),
  (31, 30, 18, '2026-10-05 12:00:00', '2026-10-05 12:30:00', 'Valoración por dolor articular', 'ATENDIDA'),
  (32, 6, 9, '2026-10-20 09:00:00', '2026-10-20 09:30:00', 'Consulta de seguimiento y revisión de evolución', 'PROGRAMADA'),
  (33, 7, 10, '2026-10-20 10:00:00', '2026-10-20 10:30:00', 'Consulta de seguimiento y revisión de evolución', 'CONFIRMADA'),
  (34, 8, 11, '2026-10-20 11:00:00', '2026-10-20 11:30:00', 'Consulta de seguimiento y revisión de evolución', 'PROGRAMADA'),
  (35, 9, 12, '2026-10-20 12:00:00', '2026-10-20 12:30:00', 'Consulta de seguimiento y revisión de evolución', 'CONFIRMADA'),
  (36, 10, 13, '2026-10-21 09:00:00', '2026-10-21 09:30:00', 'Consulta de seguimiento y revisión de evolución', 'PROGRAMADA'),
  (37, 11, 14, '2026-10-21 10:00:00', '2026-10-21 10:30:00', 'Consulta de seguimiento y revisión de evolución', 'CONFIRMADA'),
  (38, 12, 15, '2026-10-21 11:00:00', '2026-10-21 11:30:00', 'Consulta de seguimiento y revisión de evolución', 'PROGRAMADA'),
  (39, 13, 16, '2026-10-21 12:00:00', '2026-10-21 12:30:00', 'Consulta de seguimiento y revisión de evolución', 'CONFIRMADA');

INSERT INTO consultas (consulta_id, cita_id, paciente_id, medico_id, fecha, tipo, motivo, notas, peso_kg, talla_cm, temperatura_c) VALUES
  (6, 7, 6, 9, '2026-10-01 09:05:00', 'PROGRAMADA', 'Valoración por infección respiratoria de vías superiores', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 55, 155, 36.5),
  (7, 8, 7, 10, '2026-10-01 09:50:00', 'PROGRAMADA', 'Valoración por gastritis', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 56, 156, 36.6),
  (8, 9, 8, 11, '2026-10-01 10:35:00', 'PROGRAMADA', 'Valoración por rinitis alérgica', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 57, 157, 36.7),
  (9, 10, 9, 12, '2026-10-01 11:20:00', 'PROGRAMADA', 'Valoración por control de hipertensión arterial', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 58, 158, 36.5),
  (10, 11, 10, 13, '2026-10-01 12:05:00', 'PROGRAMADA', 'Valoración por dolor articular', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 59, 159, 36.6),
  (11, 12, 11, 14, '2026-10-02 09:05:00', 'PROGRAMADA', 'Valoración por infección respiratoria de vías superiores', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 60, 160, 36.7),
  (12, 13, 12, 15, '2026-10-02 09:50:00', 'PROGRAMADA', 'Valoración por gastritis', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 61, 161, 36.5),
  (13, 14, 13, 16, '2026-10-02 10:35:00', 'PROGRAMADA', 'Valoración por rinitis alérgica', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 62, 162, 36.6),
  (14, 15, 14, 17, '2026-10-02 11:20:00', 'PROGRAMADA', 'Valoración por control de hipertensión arterial', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 63, 163, 36.7),
  (15, 16, 15, 18, '2026-10-02 12:05:00', 'PROGRAMADA', 'Valoración por dolor articular', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 64, 164, 36.5),
  (16, 17, 16, 19, '2026-10-03 09:05:00', 'PROGRAMADA', 'Valoración por infección respiratoria de vías superiores', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 65, 165, 36.6),
  (17, 18, 17, 20, '2026-10-03 09:50:00', 'PROGRAMADA', 'Valoración por gastritis', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 66, 166, 36.7),
  (18, 19, 18, 21, '2026-10-03 10:35:00', 'PROGRAMADA', 'Valoración por rinitis alérgica', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 67, 167, 36.5),
  (19, 20, 19, 22, '2026-10-03 11:20:00', 'PROGRAMADA', 'Valoración por control de hipertensión arterial', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 68, 168, 36.6),
  (20, 21, 20, 23, '2026-10-03 12:05:00', 'PROGRAMADA', 'Valoración por dolor articular', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 69, 169, 36.7),
  (21, 22, 21, 9, '2026-10-04 09:05:00', 'PROGRAMADA', 'Valoración por infección respiratoria de vías superiores', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 70, 170, 36.5),
  (22, 23, 22, 10, '2026-10-04 09:50:00', 'PROGRAMADA', 'Valoración por gastritis', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 71, 171, 36.6),
  (23, 24, 23, 11, '2026-10-04 10:35:00', 'PROGRAMADA', 'Valoración por rinitis alérgica', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 72, 172, 36.7),
  (24, 25, 24, 12, '2026-10-04 11:20:00', 'PROGRAMADA', 'Valoración por control de hipertensión arterial', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 73, 173, 36.5),
  (25, 26, 25, 13, '2026-10-04 12:05:00', 'PROGRAMADA', 'Valoración por dolor articular', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 74, 174, 36.6),
  (26, 27, 26, 14, '2026-10-05 09:05:00', 'PROGRAMADA', 'Valoración por infección respiratoria de vías superiores', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 75, 175, 36.7),
  (27, 28, 27, 15, '2026-10-05 09:50:00', 'PROGRAMADA', 'Valoración por gastritis', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 76, 176, 36.5),
  (28, 29, 28, 16, '2026-10-05 10:35:00', 'PROGRAMADA', 'Valoración por rinitis alérgica', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 77, 177, 36.6),
  (29, 30, 29, 17, '2026-10-05 11:20:00', 'PROGRAMADA', 'Valoración por control de hipertensión arterial', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 78, 178, 36.7),
  (30, 31, 30, 18, '2026-10-05 12:05:00', 'PROGRAMADA', 'Valoración por dolor articular', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.', 79, 179, 36.5);

INSERT INTO diagnosticos (diagnostico_id, codigo, descripcion) VALUES
  (4, 'DX-004', 'Infección respiratoria de vías superiores'),
  (5, 'DX-005', 'Gastritis'),
  (6, 'DX-006', 'Rinitis alérgica'),
  (7, 'DX-007', 'Control de hipertensión arterial'),
  (8, 'DX-008', 'Dolor articular');

INSERT INTO consulta_diagnosticos (consulta_id, diagnostico_id, es_principal, observaciones) VALUES
  (6, 4, 1, 'Diagnóstico principal registrado en la consulta.'),
  (6, 2, 0, 'Diagnóstico complementario registrado en el expediente.'),
  (7, 5, 1, 'Diagnóstico principal registrado en la consulta.'),
  (8, 6, 1, 'Diagnóstico principal registrado en la consulta.'),
  (9, 7, 1, 'Diagnóstico principal registrado en la consulta.'),
  (9, 2, 0, 'Diagnóstico complementario registrado en el expediente.'),
  (10, 8, 1, 'Diagnóstico principal registrado en la consulta.'),
  (11, 4, 1, 'Diagnóstico principal registrado en la consulta.'),
  (12, 5, 1, 'Diagnóstico principal registrado en la consulta.'),
  (12, 2, 0, 'Diagnóstico complementario registrado en el expediente.'),
  (13, 6, 1, 'Diagnóstico principal registrado en la consulta.'),
  (14, 7, 1, 'Diagnóstico principal registrado en la consulta.'),
  (15, 8, 1, 'Diagnóstico principal registrado en la consulta.'),
  (15, 2, 0, 'Diagnóstico complementario registrado en el expediente.'),
  (16, 4, 1, 'Diagnóstico principal registrado en la consulta.'),
  (17, 5, 1, 'Diagnóstico principal registrado en la consulta.'),
  (18, 6, 1, 'Diagnóstico principal registrado en la consulta.'),
  (18, 2, 0, 'Diagnóstico complementario registrado en el expediente.'),
  (19, 7, 1, 'Diagnóstico principal registrado en la consulta.'),
  (20, 8, 1, 'Diagnóstico principal registrado en la consulta.'),
  (21, 4, 1, 'Diagnóstico principal registrado en la consulta.'),
  (21, 2, 0, 'Diagnóstico complementario registrado en el expediente.'),
  (22, 5, 1, 'Diagnóstico principal registrado en la consulta.'),
  (23, 6, 1, 'Diagnóstico principal registrado en la consulta.'),
  (24, 7, 1, 'Diagnóstico principal registrado en la consulta.'),
  (24, 2, 0, 'Diagnóstico complementario registrado en el expediente.'),
  (25, 8, 1, 'Diagnóstico principal registrado en la consulta.'),
  (26, 4, 1, 'Diagnóstico principal registrado en la consulta.'),
  (27, 5, 1, 'Diagnóstico principal registrado en la consulta.'),
  (27, 2, 0, 'Diagnóstico complementario registrado en el expediente.'),
  (28, 6, 1, 'Diagnóstico principal registrado en la consulta.'),
  (29, 7, 1, 'Diagnóstico principal registrado en la consulta.'),
  (30, 8, 1, 'Diagnóstico principal registrado en la consulta.'),
  (30, 2, 0, 'Diagnóstico complementario registrado en el expediente.');

INSERT INTO alergias_paciente (alergia_id, paciente_id, sustancia, reaccion, fecha_registro) VALUES
  (3, 6, 'Látex', 'Enrojecimiento y prurito', '2026-09-15'),
  (4, 10, 'Mariscos', 'Urticaria', '2026-09-15'),
  (5, 14, 'Sulfonamidas', 'Erupción cutánea', '2026-09-15'),
  (6, 18, 'Polen', 'Estornudos y congestión nasal', '2026-09-15'),
  (7, 22, 'Amoxicilina', 'Erupción cutánea', '2026-09-15'),
  (8, 26, 'Medio de contraste yodado', 'Urticaria', '2026-09-15'),
  (9, 30, 'Clorhexidina', 'Irritación de la piel', '2026-09-15');

INSERT INTO hospitalizaciones (hospitalizacion_id, consulta_ingreso_id, paciente_id, medico_responsable_id, fecha_ingreso, fecha_alta, motivo, resumen_alta) VALUES
  (3, 6, 6, 9, '2026-10-01 10:05:00', NULL, 'Observación hospitalaria por infección respiratoria de vías superiores', NULL),
  (4, 7, 7, 10, '2026-10-01 10:50:00', NULL, 'Observación hospitalaria por gastritis', NULL),
  (5, 8, 8, 11, '2026-10-01 11:35:00', NULL, 'Observación hospitalaria por rinitis alérgica', NULL),
  (6, 9, 9, 12, '2026-10-01 12:20:00', NULL, 'Observación hospitalaria por control de hipertensión arterial', NULL),
  (7, 10, 10, 13, '2026-10-01 13:05:00', NULL, 'Observación hospitalaria por dolor articular', NULL),
  (8, 11, 11, 14, '2026-10-02 10:05:00', NULL, 'Observación hospitalaria por infección respiratoria de vías superiores', NULL),
  (9, 12, 12, 15, '2026-10-02 10:50:00', '2026-10-03 10:50:00', 'Observación hospitalaria por gastritis', 'Alta registrada tras valoración del médico responsable. Resumen de atención integrado al expediente.'),
  (10, 13, 13, 16, '2026-10-02 11:35:00', '2026-10-03 11:35:00', 'Observación hospitalaria por rinitis alérgica', 'Alta registrada tras valoración del médico responsable. Resumen de atención integrado al expediente.'),
  (11, 14, 14, 17, '2026-10-02 12:20:00', '2026-10-03 12:20:00', 'Observación hospitalaria por control de hipertensión arterial', 'Alta registrada tras valoración del médico responsable. Resumen de atención integrado al expediente.');

INSERT INTO asignaciones_camilla (asignacion_id, hospitalizacion_id, camilla_id, inicio, fin) VALUES
  (4, 3, 7, '2026-10-01 10:05:00', NULL),
  (5, 4, 8, '2026-10-01 10:50:00', NULL),
  (6, 5, 9, '2026-10-01 11:35:00', NULL),
  (7, 6, 10, '2026-10-01 12:20:00', NULL),
  (8, 7, 11, '2026-10-01 13:05:00', NULL),
  (9, 8, 12, '2026-10-02 10:05:00', NULL),
  (10, 9, 13, '2026-10-02 10:50:00', '2026-10-03 10:50:00'),
  (11, 10, 14, '2026-10-02 11:35:00', '2026-10-03 11:35:00'),
  (12, 11, 3, '2026-10-02 12:20:00', '2026-10-03 12:20:00');

INSERT INTO notas_enfermeria (nota_id, hospitalizacion_id, personal_id, fecha, observacion) VALUES
  (4, 3, 24, '2026-10-01 10:35:00', 'Se verificó identificación del paciente y ubicación en la camilla asignada.'),
  (5, 3, 25, '2026-10-01 12:35:00', 'Se registró la entrega de turno y la continuidad de los cuidados indicados.'),
  (6, 4, 24, '2026-10-01 11:20:00', 'Se registraron signos vitales y cuidados del turno en la hoja de enfermería.'),
  (7, 4, 25, '2026-10-01 13:20:00', 'Se verificó identificación del paciente y ubicación en la camilla asignada.'),
  (8, 5, 24, '2026-10-01 12:05:00', 'Se registró la entrega de turno y la continuidad de los cuidados indicados.'),
  (9, 5, 25, '2026-10-01 14:05:00', 'Se registraron signos vitales y cuidados del turno en la hoja de enfermería.'),
  (10, 6, 24, '2026-10-01 12:50:00', 'Se verificó identificación del paciente y ubicación en la camilla asignada.'),
  (11, 6, 25, '2026-10-01 14:50:00', 'Se registró la entrega de turno y la continuidad de los cuidados indicados.'),
  (12, 7, 24, '2026-10-01 13:35:00', 'Se registraron signos vitales y cuidados del turno en la hoja de enfermería.'),
  (13, 7, 25, '2026-10-01 15:35:00', 'Se verificó identificación del paciente y ubicación en la camilla asignada.'),
  (14, 8, 24, '2026-10-02 10:35:00', 'Se registró la entrega de turno y la continuidad de los cuidados indicados.'),
  (15, 8, 25, '2026-10-02 12:35:00', 'Se registraron signos vitales y cuidados del turno en la hoja de enfermería.'),
  (16, 9, 24, '2026-10-02 11:20:00', 'Se verificó identificación del paciente y ubicación en la camilla asignada.'),
  (17, 9, 25, '2026-10-02 13:20:00', 'Se registró la entrega de turno y la continuidad de los cuidados indicados.'),
  (18, 10, 24, '2026-10-02 12:05:00', 'Se registraron signos vitales y cuidados del turno en la hoja de enfermería.'),
  (19, 10, 25, '2026-10-02 14:05:00', 'Se verificó identificación del paciente y ubicación en la camilla asignada.'),
  (20, 11, 24, '2026-10-02 12:50:00', 'Se registró la entrega de turno y la continuidad de los cuidados indicados.'),
  (21, 11, 25, '2026-10-02 14:50:00', 'Se registraron signos vitales y cuidados del turno en la hoja de enfermería.');

INSERT INTO medicamentos (medicamento_id, codigo, principio_activo, concentracion, presentacion, unidad_inventario, stock_minimo) VALUES
  (4, 'MED-004', 'Omeprazol', '20 mg', 'Cápsula gastrorresistente', 'cápsula', 15),
  (5, 'MED-005', 'Ketorolaco trometamol', '30 mg/mL', 'Solución inyectable, ampolla de 1 mL', 'ampolla', 20),
  (6, 'MED-006', 'Salbutamol', '100 microgramos/dosis', 'Inhalador de 200 dosis', 'inhalador', 25),
  (7, 'MED-007', 'Loratadina', '10 mg', 'Tableta', 'tableta', 30),
  (8, 'MED-008', 'Metformina', '850 mg de hidrocloruro de metformina', 'Tableta recubierta', 'tableta', 15),
  (9, 'MED-009', 'Losartán potásico', '50 mg', 'Tableta recubierta', 'tableta', 20),
  (10, 'MED-010', 'Diclofenaco sódico', '10 mg/g (1 %)', 'Gel, tubo de 60 g', 'tubo', 25),
  (11, 'MED-011', 'Insulina humana', '100 UI/mL', 'Solución inyectable, vial de 10 mL', 'vial', 30),
  (12, 'MED-012', 'Ceftriaxona', '1 g por vial', 'Polvo para solución inyectable, vial', 'vial', 15),
  (13, 'MED-013', 'Diazepam', '10 mg/2 mL', 'Solución inyectable, ampolla de 2 mL', 'ampolla', 20),
  (14, 'MED-014', 'Hidrocortisona', '100 mg por vial', 'Polvo y disolvente para solución inyectable, vial', 'vial', 25),
  (15, 'MED-015', 'Furosemida', '40 mg', 'Tableta', 'tableta', 30);

INSERT INTO proveedores (proveedor_id, nombre, telefono, email) VALUES
  (3, 'Abastecedora Hospitalaria del Valle', '5543350366', 'ventas.abastecedora.hospitalaria.del.valle@example.com'),
  (4, 'Material Médico Alameda', '5552558257', 'ventas.material.medico.alameda@example.com');

INSERT INTO lotes_medicamento (lote_id, medicamento_id, proveedor_id, numero_lote, fecha_recepcion, fecha_caducidad, costo_unitario) VALUES
  (5, 4, 3, 'LT-2026-0005', '2026-09-01', '2028-12-31', 7.5),
  (6, 5, 4, 'LT-2026-0006', '2026-09-01', '2028-12-31', 8.5),
  (7, 6, 3, 'LT-2026-0007', '2026-09-01', '2028-12-31', 9.5),
  (8, 7, 4, 'LT-2026-0008', '2026-09-01', '2028-12-31', 10.5),
  (9, 8, 3, 'LT-2026-0009', '2026-09-01', '2028-12-31', 11.5),
  (10, 9, 4, 'LT-2026-0010', '2026-09-01', '2028-12-31', 12.5),
  (11, 10, 3, 'LT-2026-0011', '2026-09-01', '2028-12-31', 13.5),
  (12, 11, 4, 'LT-2026-0012', '2026-09-01', '2028-12-31', 14.5),
  (13, 12, 3, 'LT-2026-0013', '2026-09-01', '2028-12-31', 15.5),
  (14, 13, 4, 'LT-2026-0014', '2026-09-01', '2028-12-31', 16.5),
  (15, 14, 3, 'LT-2026-0015', '2026-09-01', '2028-12-31', 17.5),
  (16, 15, 4, 'LT-2026-0016', '2026-09-01', '2028-12-31', 18.5);

INSERT INTO movimientos_inventario (movimiento_id, lote_id, dispensacion_detalle_id, personal_id, fecha, tipo, cantidad, motivo) VALUES
  (7, 5, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 240, 'Recepción de mercancía y registro de lote en farmacia'),
  (8, 6, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 250, 'Recepción de mercancía y registro de lote en farmacia'),
  (9, 7, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 260, 'Recepción de mercancía y registro de lote en farmacia'),
  (10, 8, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 270, 'Recepción de mercancía y registro de lote en farmacia'),
  (11, 9, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 280, 'Recepción de mercancía y registro de lote en farmacia'),
  (12, 10, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 290, 'Recepción de mercancía y registro de lote en farmacia'),
  (13, 11, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 300, 'Recepción de mercancía y registro de lote en farmacia'),
  (14, 12, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 310, 'Recepción de mercancía y registro de lote en farmacia'),
  (15, 13, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 320, 'Recepción de mercancía y registro de lote en farmacia'),
  (16, 14, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 330, 'Recepción de mercancía y registro de lote en farmacia'),
  (17, 15, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 340, 'Recepción de mercancía y registro de lote en farmacia'),
  (18, 16, NULL, 6, '2026-09-01 12:00:00', 'ENTRADA', 350, 'Recepción de mercancía y registro de lote en farmacia');

INSERT INTO recetas (receta_id, consulta_id, fecha_prescripcion, observaciones) VALUES
  (4, 6, '2026-10-01 09:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (5, 7, '2026-10-01 10:05:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (6, 8, '2026-10-01 10:50:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (7, 9, '2026-10-01 11:35:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (8, 10, '2026-10-01 12:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (9, 11, '2026-10-02 09:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (10, 12, '2026-10-02 10:05:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (11, 13, '2026-10-02 10:50:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (12, 14, '2026-10-02 11:35:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (13, 15, '2026-10-02 12:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (14, 16, '2026-10-03 09:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (15, 17, '2026-10-03 10:05:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (16, 18, '2026-10-03 10:50:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (17, 19, '2026-10-03 11:35:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (18, 20, '2026-10-03 12:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (19, 21, '2026-10-04 09:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (20, 22, '2026-10-04 10:05:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (21, 23, '2026-10-04 10:50:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (22, 24, '2026-10-04 11:35:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (23, 25, '2026-10-04 12:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (24, 26, '2026-10-05 09:20:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.'),
  (25, 27, '2026-10-05 10:05:00', 'Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.');

INSERT INTO receta_detalle (receta_id, renglon, medicamento_id, dosis, frecuencia, duracion_dias, via_administracion, cantidad_prescrita) VALUES
  (4, 1, 4, '1 cápsula', 'Cada 8 horas', 3, 'Oral', 9),
  (4, 2, 8, '1 tableta', 'Cada 12 horas', 3, 'Oral', 6),
  (5, 1, 5, 'Según orden médica', 'Cada 12 horas', 4, 'Intravenosa', 8),
  (5, 2, 9, '1 tableta', 'Cada 24 horas', 4, 'Oral', 4),
  (6, 1, 6, '1 inhalación', 'Cada 24 horas', 5, 'Inhalatoria', 5),
  (6, 2, 10, '1 aplicación', 'Cada 6 horas', 5, 'Cutánea', 20),
  (7, 1, 7, '1 tableta', 'Cada 6 horas', 6, 'Oral', 24),
  (7, 2, 11, 'Según orden médica', 'Cada 8 horas', 6, 'Subcutánea', 18),
  (8, 1, 8, '1 tableta', 'Cada 8 horas', 7, 'Oral', 21),
  (8, 2, 12, 'Según orden médica', 'Cada 12 horas', 7, 'Intravenosa', 14),
  (9, 1, 9, '1 tableta', 'Cada 12 horas', 3, 'Oral', 6),
  (9, 2, 13, 'Según orden médica', 'Cada 24 horas', 3, 'Intramuscular', 3),
  (10, 1, 10, '1 aplicación', 'Cada 24 horas', 4, 'Cutánea', 4),
  (10, 2, 14, 'Según orden médica', 'Cada 6 horas', 4, 'Intravenosa', 16),
  (11, 1, 11, 'Según orden médica', 'Cada 6 horas', 5, 'Subcutánea', 20),
  (11, 2, 15, '1 tableta', 'Cada 8 horas', 5, 'Oral', 15),
  (12, 1, 12, 'Según orden médica', 'Cada 8 horas', 6, 'Intravenosa', 18),
  (12, 2, 4, '1 cápsula', 'Cada 12 horas', 6, 'Oral', 12),
  (13, 1, 13, 'Según orden médica', 'Cada 12 horas', 7, 'Intramuscular', 14),
  (13, 2, 5, 'Según orden médica', 'Cada 24 horas', 7, 'Intravenosa', 7),
  (14, 1, 14, 'Según orden médica', 'Cada 24 horas', 3, 'Intravenosa', 3),
  (14, 2, 6, '1 inhalación', 'Cada 6 horas', 3, 'Inhalatoria', 12),
  (15, 1, 15, '1 tableta', 'Cada 6 horas', 4, 'Oral', 16),
  (15, 2, 7, '1 tableta', 'Cada 8 horas', 4, 'Oral', 12),
  (16, 1, 4, '1 cápsula', 'Cada 8 horas', 5, 'Oral', 15),
  (16, 2, 8, '1 tableta', 'Cada 12 horas', 5, 'Oral', 10),
  (17, 1, 5, 'Según orden médica', 'Cada 12 horas', 6, 'Intravenosa', 12),
  (17, 2, 9, '1 tableta', 'Cada 24 horas', 6, 'Oral', 6),
  (18, 1, 6, '1 inhalación', 'Cada 24 horas', 7, 'Inhalatoria', 7),
  (18, 2, 10, '1 aplicación', 'Cada 6 horas', 7, 'Cutánea', 28),
  (19, 1, 7, '1 tableta', 'Cada 6 horas', 3, 'Oral', 12),
  (19, 2, 11, 'Según orden médica', 'Cada 8 horas', 3, 'Subcutánea', 9),
  (20, 1, 8, '1 tableta', 'Cada 8 horas', 4, 'Oral', 12),
  (20, 2, 12, 'Según orden médica', 'Cada 12 horas', 4, 'Intravenosa', 8),
  (21, 1, 9, '1 tableta', 'Cada 12 horas', 5, 'Oral', 10),
  (21, 2, 13, 'Según orden médica', 'Cada 24 horas', 5, 'Intramuscular', 5),
  (22, 1, 10, '1 aplicación', 'Cada 24 horas', 6, 'Cutánea', 6),
  (22, 2, 14, 'Según orden médica', 'Cada 6 horas', 6, 'Intravenosa', 24),
  (23, 1, 11, 'Según orden médica', 'Cada 6 horas', 7, 'Subcutánea', 28),
  (23, 2, 15, '1 tableta', 'Cada 8 horas', 7, 'Oral', 21),
  (24, 1, 12, 'Según orden médica', 'Cada 8 horas', 3, 'Intravenosa', 9),
  (24, 2, 4, '1 cápsula', 'Cada 12 horas', 3, 'Oral', 6),
  (25, 1, 13, 'Según orden médica', 'Cada 12 horas', 4, 'Intramuscular', 8),
  (25, 2, 5, 'Según orden médica', 'Cada 24 horas', 4, 'Intravenosa', 4);

INSERT INTO dispensaciones (dispensacion_id, receta_id, personal_id, fecha) VALUES
  (2, 4, 6, '2026-10-01 10:05:00'),
  (3, 5, 6, '2026-10-01 10:50:00'),
  (4, 6, 6, '2026-10-01 11:35:00'),
  (5, 7, 6, '2026-10-01 12:20:00'),
  (6, 8, 6, '2026-10-01 13:05:00'),
  (7, 9, 6, '2026-10-02 10:05:00'),
  (8, 10, 6, '2026-10-02 10:50:00'),
  (9, 11, 6, '2026-10-02 11:35:00'),
  (10, 12, 6, '2026-10-02 12:20:00'),
  (11, 13, 6, '2026-10-02 13:05:00');

INSERT INTO dispensacion_detalle (dispensacion_detalle_id, dispensacion_id, receta_id, renglon, medicamento_id, lote_id, cantidad) VALUES
  (3, 2, 4, 1, 4, 5, 9),
  (4, 2, 4, 2, 8, 9, 6),
  (5, 3, 5, 1, 5, 6, 8),
  (6, 3, 5, 2, 9, 10, 4),
  (7, 4, 6, 1, 6, 7, 5),
  (8, 4, 6, 2, 10, 11, 20),
  (9, 5, 7, 1, 7, 8, 24),
  (10, 5, 7, 2, 11, 12, 18),
  (11, 6, 8, 1, 8, 9, 21),
  (12, 6, 8, 2, 12, 13, 14),
  (13, 7, 9, 1, 9, 10, 3),
  (14, 7, 9, 2, 13, 14, 1),
  (15, 8, 10, 1, 10, 11, 2),
  (16, 8, 10, 2, 14, 15, 8),
  (17, 9, 11, 1, 11, 12, 10),
  (18, 9, 11, 2, 15, 16, 7),
  (19, 10, 12, 1, 12, 13, 9),
  (20, 10, 12, 2, 4, 5, 6),
  (21, 11, 13, 1, 13, 14, 7),
  (22, 11, 13, 2, 5, 6, 3);

INSERT INTO movimientos_inventario (movimiento_id, lote_id, dispensacion_detalle_id, personal_id, fecha, tipo, cantidad, motivo) VALUES
  (19, 5, 3, 6, '2026-10-01 10:05:00', 'SALIDA', -9, 'Entrega a paciente conforme al detalle de dispensación'),
  (20, 9, 4, 6, '2026-10-01 10:05:00', 'SALIDA', -6, 'Entrega a paciente conforme al detalle de dispensación'),
  (21, 6, 5, 6, '2026-10-01 10:50:00', 'SALIDA', -8, 'Entrega a paciente conforme al detalle de dispensación'),
  (22, 10, 6, 6, '2026-10-01 10:50:00', 'SALIDA', -4, 'Entrega a paciente conforme al detalle de dispensación'),
  (23, 7, 7, 6, '2026-10-01 11:35:00', 'SALIDA', -5, 'Entrega a paciente conforme al detalle de dispensación'),
  (24, 11, 8, 6, '2026-10-01 11:35:00', 'SALIDA', -20, 'Entrega a paciente conforme al detalle de dispensación'),
  (25, 8, 9, 6, '2026-10-01 12:20:00', 'SALIDA', -24, 'Entrega a paciente conforme al detalle de dispensación'),
  (26, 12, 10, 6, '2026-10-01 12:20:00', 'SALIDA', -18, 'Entrega a paciente conforme al detalle de dispensación'),
  (27, 9, 11, 6, '2026-10-01 13:05:00', 'SALIDA', -21, 'Entrega a paciente conforme al detalle de dispensación'),
  (28, 13, 12, 6, '2026-10-01 13:05:00', 'SALIDA', -14, 'Entrega a paciente conforme al detalle de dispensación'),
  (29, 10, 13, 6, '2026-10-02 10:05:00', 'SALIDA', -3, 'Entrega a paciente conforme al detalle de dispensación'),
  (30, 14, 14, 6, '2026-10-02 10:05:00', 'SALIDA', -1, 'Entrega a paciente conforme al detalle de dispensación'),
  (31, 11, 15, 6, '2026-10-02 10:50:00', 'SALIDA', -2, 'Entrega a paciente conforme al detalle de dispensación'),
  (32, 15, 16, 6, '2026-10-02 10:50:00', 'SALIDA', -8, 'Entrega a paciente conforme al detalle de dispensación'),
  (33, 12, 17, 6, '2026-10-02 11:35:00', 'SALIDA', -10, 'Entrega a paciente conforme al detalle de dispensación'),
  (34, 16, 18, 6, '2026-10-02 11:35:00', 'SALIDA', -7, 'Entrega a paciente conforme al detalle de dispensación'),
  (35, 13, 19, 6, '2026-10-02 12:20:00', 'SALIDA', -9, 'Entrega a paciente conforme al detalle de dispensación'),
  (36, 5, 20, 6, '2026-10-02 12:20:00', 'SALIDA', -6, 'Entrega a paciente conforme al detalle de dispensación'),
  (37, 14, 21, 6, '2026-10-02 13:05:00', 'SALIDA', -7, 'Entrega a paciente conforme al detalle de dispensación'),
  (38, 6, 22, 6, '2026-10-02 13:05:00', 'SALIDA', -3, 'Entrega a paciente conforme al detalle de dispensación');

INSERT INTO procedimientos (procedimiento_id, codigo, nombre, tipo, precio_referencia) VALUES
  (5, 'PROC-005', 'Química sanguínea', 'LABORATORIO', 125),
  (6, 'PROC-006', 'Ultrasonido abdominal', 'IMAGEN', 150),
  (7, 'PROC-007', 'Colecistectomía', 'CIRUGIA', 175),
  (8, 'PROC-008', 'Curación de herida', 'OTRO', 200);

INSERT INTO ordenes_procedimiento (orden_id, consulta_id, procedimiento_id, fecha_solicitud, fecha_programada, estado, indicaciones) VALUES
  (5, 6, 5, '2026-10-01 09:25:00', '2026-10-01 11:25:00', 'SOLICITADA', 'Realizar química sanguínea y anexar el informe al expediente.'),
  (6, 7, 6, '2026-10-01 10:10:00', '2026-10-01 12:10:00', 'SOLICITADA', 'Realizar ultrasonido abdominal y anexar el informe al expediente.'),
  (7, 8, 7, '2026-10-01 10:55:00', '2026-10-01 12:55:00', 'SOLICITADA', 'Realizar colecistectomía y anexar el informe al expediente.'),
  (8, 9, 8, '2026-10-01 11:40:00', '2026-10-01 13:40:00', 'SOLICITADA', 'Realizar curación de herida y anexar el informe al expediente.'),
  (9, 10, 5, '2026-10-01 12:25:00', '2026-10-01 14:25:00', 'SOLICITADA', 'Realizar química sanguínea y anexar el informe al expediente.'),
  (10, 11, 6, '2026-10-02 09:25:00', '2026-10-02 11:25:00', 'SOLICITADA', 'Realizar ultrasonido abdominal y anexar el informe al expediente.'),
  (11, 12, 7, '2026-10-02 10:10:00', '2026-10-02 12:10:00', 'SOLICITADA', 'Realizar colecistectomía y anexar el informe al expediente.'),
  (12, 13, 8, '2026-10-02 10:55:00', '2026-10-02 12:55:00', 'SOLICITADA', 'Realizar curación de herida y anexar el informe al expediente.'),
  (13, 14, 5, '2026-10-02 11:40:00', '2026-10-02 13:40:00', 'SOLICITADA', 'Realizar química sanguínea y anexar el informe al expediente.'),
  (14, 15, 6, '2026-10-02 12:25:00', '2026-10-02 14:25:00', 'SOLICITADA', 'Realizar ultrasonido abdominal y anexar el informe al expediente.'),
  (15, 16, 7, '2026-10-03 09:25:00', '2026-10-03 11:25:00', 'SOLICITADA', 'Realizar colecistectomía y anexar el informe al expediente.'),
  (16, 17, 8, '2026-10-03 10:10:00', '2026-10-03 12:10:00', 'SOLICITADA', 'Realizar curación de herida y anexar el informe al expediente.'),
  (17, 18, 5, '2026-10-03 10:55:00', '2026-10-03 12:55:00', 'SOLICITADA', 'Realizar química sanguínea y anexar el informe al expediente.'),
  (18, 19, 6, '2026-10-03 11:40:00', '2026-10-03 13:40:00', 'PROGRAMADA', 'Realizar ultrasonido abdominal y anexar el informe al expediente.'),
  (19, 20, 7, '2026-10-03 12:25:00', '2026-10-03 14:25:00', 'PROGRAMADA', 'Realizar colecistectomía y anexar el informe al expediente.'),
  (20, 21, 8, '2026-10-04 09:25:00', '2026-10-04 11:25:00', 'PROGRAMADA', 'Realizar curación de herida y anexar el informe al expediente.'),
  (21, 22, 5, '2026-10-04 10:10:00', '2026-10-04 12:10:00', 'PROGRAMADA', 'Realizar química sanguínea y anexar el informe al expediente.'),
  (22, 23, 6, '2026-10-04 10:55:00', '2026-10-04 12:55:00', 'PROGRAMADA', 'Realizar ultrasonido abdominal y anexar el informe al expediente.'),
  (23, 24, 7, '2026-10-04 11:40:00', '2026-10-04 13:40:00', 'PROGRAMADA', 'Realizar colecistectomía y anexar el informe al expediente.'),
  (24, 25, 8, '2026-10-04 12:25:00', '2026-10-04 14:25:00', 'PROGRAMADA', 'Realizar curación de herida y anexar el informe al expediente.'),
  (25, 26, 5, '2026-10-05 09:25:00', '2026-10-05 11:25:00', 'PROGRAMADA', 'Realizar química sanguínea y anexar el informe al expediente.'),
  (26, 27, 6, '2026-10-05 10:10:00', '2026-10-05 12:10:00', 'PROGRAMADA', 'Realizar ultrasonido abdominal y anexar el informe al expediente.'),
  (27, 28, 7, '2026-10-05 10:55:00', '2026-10-05 12:55:00', 'PROGRAMADA', 'Realizar colecistectomía y anexar el informe al expediente.'),
  (28, 29, 8, '2026-10-05 11:40:00', '2026-10-05 13:40:00', 'CANCELADA', 'Realizar curación de herida y anexar el informe al expediente.'),
  (29, 30, 5, '2026-10-05 12:25:00', '2026-10-05 14:25:00', 'PROGRAMADA', 'Realizar química sanguínea y anexar el informe al expediente.');

INSERT INTO resultados_procedimiento (resultado_id, orden_id, personal_id, fecha_resultado, informe) VALUES
  (3, 5, 8, '2026-10-01 12:25:00', 'Informe de química sanguínea. Documento recibido y registrado en el expediente EXP-2026-0006.'),
  (4, 6, 10, '2026-10-01 13:10:00', 'Informe de ultrasonido abdominal. Documento recibido y registrado en el expediente EXP-2026-0007.'),
  (5, 7, 11, '2026-10-01 13:55:00', 'Informe de colecistectomía. Documento recibido y registrado en el expediente EXP-2026-0008.'),
  (6, 8, 12, '2026-10-01 14:40:00', 'Informe de curación de herida. Documento recibido y registrado en el expediente EXP-2026-0009.'),
  (7, 9, 8, '2026-10-01 15:25:00', 'Informe de química sanguínea. Documento recibido y registrado en el expediente EXP-2026-0010.'),
  (8, 10, 14, '2026-10-02 12:25:00', 'Informe de ultrasonido abdominal. Documento recibido y registrado en el expediente EXP-2026-0011.'),
  (9, 11, 15, '2026-10-02 13:10:00', 'Informe de colecistectomía. Documento recibido y registrado en el expediente EXP-2026-0012.'),
  (10, 12, 16, '2026-10-02 13:55:00', 'Informe de curación de herida. Documento recibido y registrado en el expediente EXP-2026-0013.'),
  (11, 13, 8, '2026-10-02 14:40:00', 'Informe de química sanguínea. Documento recibido y registrado en el expediente EXP-2026-0014.'),
  (12, 14, 18, '2026-10-02 15:25:00', 'Informe de ultrasonido abdominal. Documento recibido y registrado en el expediente EXP-2026-0015.'),
  (13, 15, 19, '2026-10-03 12:25:00', 'Informe de colecistectomía. Documento recibido y registrado en el expediente EXP-2026-0016.'),
  (14, 16, 20, '2026-10-03 13:10:00', 'Informe de curación de herida. Documento recibido y registrado en el expediente EXP-2026-0017.'),
  (15, 17, 8, '2026-10-03 13:55:00', 'Informe de química sanguínea. Documento recibido y registrado en el expediente EXP-2026-0018.');

INSERT INTO facturas (factura_id, folio, paciente_id, poliza_id, fecha, estado) VALUES
  (5, 'FAC-2026-00005', 6, 4, '2026-10-01 13:05:00', 'ABIERTA'),
  (6, 'FAC-2026-00006', 7, 5, '2026-10-01 13:50:00', 'ABIERTA'),
  (7, 'FAC-2026-00007', 8, 6, '2026-10-01 14:35:00', 'ABIERTA'),
  (8, 'FAC-2026-00008', 9, 7, '2026-10-01 15:20:00', 'ABIERTA'),
  (9, 'FAC-2026-00009', 10, 8, '2026-10-01 16:05:00', 'ABIERTA'),
  (10, 'FAC-2026-00010', 11, 9, '2026-10-02 13:05:00', 'ABIERTA'),
  (11, 'FAC-2026-00011', 12, 10, '2026-10-02 13:50:00', 'ABIERTA'),
  (12, 'FAC-2026-00012', 13, 11, '2026-10-02 14:35:00', 'ABIERTA'),
  (13, 'FAC-2026-00013', 14, 12, '2026-10-02 15:20:00', 'ABIERTA'),
  (14, 'FAC-2026-00014', 15, 13, '2026-10-02 16:05:00', 'ABIERTA'),
  (15, 'FAC-2026-00015', 16, 14, '2026-10-03 13:05:00', 'ABIERTA'),
  (16, 'FAC-2026-00016', 17, 15, '2026-10-03 13:50:00', 'ABIERTA'),
  (17, 'FAC-2026-00017', 18, 16, '2026-10-03 14:35:00', 'ABIERTA'),
  (18, 'FAC-2026-00018', 19, 17, '2026-10-03 15:20:00', 'ABIERTA'),
  (19, 'FAC-2026-00019', 20, 18, '2026-10-03 16:05:00', 'ABIERTA'),
  (20, 'FAC-2026-00020', 21, NULL, '2026-10-04 13:05:00', 'ABIERTA'),
  (21, 'FAC-2026-00021', 22, NULL, '2026-10-04 13:50:00', 'ABIERTA'),
  (22, 'FAC-2026-00022', 23, NULL, '2026-10-04 14:35:00', 'ABIERTA'),
  (23, 'FAC-2026-00023', 24, NULL, '2026-10-04 15:20:00', 'ABIERTA'),
  (24, 'FAC-2026-00024', 25, NULL, '2026-10-04 16:05:00', 'ABIERTA'),
  (25, 'FAC-2026-00025', 26, NULL, '2026-10-05 13:05:00', 'ABIERTA'),
  (26, 'FAC-2026-00026', 27, NULL, '2026-10-05 13:50:00', 'ABIERTA'),
  (27, 'FAC-2026-00027', 28, NULL, '2026-10-05 14:35:00', 'ABIERTA'),
  (28, 'FAC-2026-00028', 29, NULL, '2026-10-05 15:20:00', 'ABIERTA'),
  (29, 'FAC-2026-00029', 30, NULL, '2026-10-05 16:05:00', 'ABIERTA');

INSERT INTO factura_detalle (factura_id, renglon, descripcion, cantidad, precio_unitario, descuento) VALUES
  (5, 1, 'Consulta médica de seguimiento', 1, 350, 0),
  (5, 2, 'Servicio de diagnóstico y procedimiento', 1, 125, 0),
  (6, 1, 'Consulta médica de seguimiento', 1, 400, 0),
  (6, 2, 'Servicio de diagnóstico y procedimiento', 1, 150, 0),
  (7, 1, 'Consulta médica de seguimiento', 1, 450, 0),
  (7, 2, 'Servicio de diagnóstico y procedimiento', 1, 175, 0),
  (8, 1, 'Consulta médica de seguimiento', 1, 500, 0),
  (8, 2, 'Servicio de diagnóstico y procedimiento', 1, 200, 0),
  (9, 1, 'Consulta médica de seguimiento', 1, 550, 0),
  (9, 2, 'Servicio de diagnóstico y procedimiento', 1, 125, 0),
  (10, 1, 'Consulta médica de seguimiento', 1, 600, 0),
  (10, 2, 'Servicio de diagnóstico y procedimiento', 1, 150, 0),
  (11, 1, 'Consulta médica de seguimiento', 1, 350, 0),
  (11, 2, 'Servicio de diagnóstico y procedimiento', 1, 175, 0),
  (12, 1, 'Consulta médica de seguimiento', 1, 400, 0),
  (12, 2, 'Servicio de diagnóstico y procedimiento', 1, 200, 0),
  (13, 1, 'Consulta médica de seguimiento', 1, 450, 0),
  (13, 2, 'Servicio de diagnóstico y procedimiento', 1, 125, 0),
  (14, 1, 'Consulta médica de seguimiento', 1, 500, 0),
  (14, 2, 'Servicio de diagnóstico y procedimiento', 1, 150, 0),
  (15, 1, 'Consulta médica de seguimiento', 1, 550, 0),
  (15, 2, 'Servicio de diagnóstico y procedimiento', 1, 175, 0),
  (16, 1, 'Consulta médica de seguimiento', 1, 600, 0),
  (16, 2, 'Servicio de diagnóstico y procedimiento', 1, 200, 0),
  (17, 1, 'Consulta médica de seguimiento', 1, 350, 0),
  (17, 2, 'Servicio de diagnóstico y procedimiento', 1, 125, 0),
  (18, 1, 'Consulta médica de seguimiento', 1, 400, 0),
  (18, 2, 'Servicio de diagnóstico y procedimiento', 1, 150, 0),
  (19, 1, 'Consulta médica de seguimiento', 1, 450, 0),
  (19, 2, 'Servicio de diagnóstico y procedimiento', 1, 175, 0),
  (20, 1, 'Consulta médica de seguimiento', 1, 500, 0),
  (20, 2, 'Servicio de diagnóstico y procedimiento', 1, 200, 0),
  (21, 1, 'Consulta médica de seguimiento', 1, 550, 0),
  (21, 2, 'Servicio de diagnóstico y procedimiento', 1, 125, 0),
  (22, 1, 'Consulta médica de seguimiento', 1, 600, 0),
  (22, 2, 'Servicio de diagnóstico y procedimiento', 1, 150, 0),
  (23, 1, 'Consulta médica de seguimiento', 1, 350, 0),
  (23, 2, 'Servicio de diagnóstico y procedimiento', 1, 175, 0),
  (24, 1, 'Consulta médica de seguimiento', 1, 400, 0),
  (24, 2, 'Servicio de diagnóstico y procedimiento', 1, 200, 0),
  (25, 1, 'Consulta médica de seguimiento', 1, 450, 0),
  (25, 2, 'Servicio de diagnóstico y procedimiento', 1, 125, 0),
  (26, 1, 'Consulta médica de seguimiento', 1, 500, 0),
  (26, 2, 'Servicio de diagnóstico y procedimiento', 1, 150, 0),
  (27, 1, 'Consulta médica de seguimiento', 1, 550, 0),
  (27, 2, 'Servicio de diagnóstico y procedimiento', 1, 175, 0),
  (28, 1, 'Consulta médica de seguimiento', 1, 600, 0),
  (28, 2, 'Servicio de diagnóstico y procedimiento', 1, 200, 0),
  (29, 1, 'Consulta médica de seguimiento', 1, 350, 0),
  (29, 2, 'Servicio de diagnóstico y procedimiento', 1, 125, 0);

UPDATE facturas SET estado = 'EMITIDA' WHERE factura_id BETWEEN 5 AND 24;

INSERT INTO pagos (pago_id, factura_id, fecha, monto, metodo, referencia) VALUES
  (5, 5, '2026-10-01 13:20:00', 475, 'EFECTIVO', 'EFE-202610-000005'),
  (6, 6, '2026-10-01 14:05:00', 550, 'TARJETA', 'TAR-202610-000006'),
  (7, 7, '2026-10-01 14:50:00', 625, 'TRANSFERENCIA', 'TRA-202610-000007'),
  (8, 8, '2026-10-01 15:35:00', 700, 'EFECTIVO', 'EFE-202610-000008'),
  (9, 9, '2026-10-01 16:20:00', 675, 'TARJETA', 'TAR-202610-000009'),
  (10, 10, '2026-10-02 13:20:00', 150, 'TRANSFERENCIA', 'TRA-202610-000010'),
  (11, 11, '2026-10-02 14:05:00', 150, 'EFECTIVO', 'EFE-202610-000011'),
  (12, 12, '2026-10-02 14:50:00', 150, 'TARJETA', 'TAR-202610-000012'),
  (13, 13, '2026-10-02 15:35:00', 150, 'TRANSFERENCIA', 'TRA-202610-000013'),
  (14, 14, '2026-10-02 16:20:00', 150, 'EFECTIVO', 'EFE-202610-000014'),
  (15, 15, '2026-10-03 13:20:00', 75, 'TARJETA', 'TAR-202610-000015'),
  (16, 15, '2026-10-03 13:50:00', 50, 'TARJETA', 'TAR-202610-000016'),
  (17, 16, '2026-10-03 14:05:00', 75, 'TRANSFERENCIA', 'TRA-202610-000017'),
  (18, 16, '2026-10-03 14:35:00', 50, 'TRANSFERENCIA', 'TRA-202610-000018'),
  (19, 17, '2026-10-03 14:50:00', 75, 'EFECTIVO', 'EFE-202610-000019'),
  (20, 17, '2026-10-03 15:20:00', 50, 'EFECTIVO', 'EFE-202610-000020'),
  (21, 18, '2026-10-03 15:35:00', 75, 'TARJETA', 'TAR-202610-000021'),
  (22, 18, '2026-10-03 16:05:00', 50, 'TARJETA', 'TAR-202610-000022'),
  (23, 19, '2026-10-03 16:20:00', 75, 'TRANSFERENCIA', 'TRA-202610-000023'),
  (24, 19, '2026-10-03 16:50:00', 50, 'TRANSFERENCIA', 'TRA-202610-000024');

INSERT INTO roles (rol_id, nombre, descripcion) VALUES
  (5, 'LABORATORIO', 'Registro de órdenes e informes de estudios.'),
  (6, 'ENFERMERIA', 'Registro de cuidados y seguimiento de hospitalización.');

INSERT INTO usuarios (usuario_id, personal_id, nombre_usuario, password_hash, activo) VALUES
  (4, 24, 'mariana.vega', 'pbkdf2_sha256$120000$4827187d29ff1a9a2e307811$Dm0eSqkySx1nY5dvolbdQrn39BYnploGHcmgX9Hv6Pg=', 0),
  (5, 25, 'daniel.leon', 'pbkdf2_sha256$120000$545a4a40771d2ffe4b316026$jhxzd47KJbdi4TstGP3fMPrL9/+SxD+7rSmg8PIsIyo=', 0),
  (6, 8, 'raquel.campos', 'pbkdf2_sha256$120000$8c6505c56518bf09e51988f5$22MufqgBYugwREKkvMNO2WsFsyyxvoCwSHUC5jgqn0o=', 0),
  (7, 9, 'carlos.mendoza', 'pbkdf2_sha256$120000$0c0f3f013e0de2c374fbfa4d$zHC3wc8p65fc+Qvgx865RhVSb7M493ohtKzcULlZ8aw=', 0);

INSERT INTO usuario_roles (usuario_id, rol_id) VALUES
  (4, 6),
  (5, 6),
  (6, 5),
  (7, 2);

INSERT INTO citas (cita_id, paciente_id, medico_id, inicio, fin, motivo, estado) VALUES
  (40, 6, 9, '2026-10-10 09:00:00', '2026-10-10 09:25:00', 'Valoración por gastritis', 'ATENDIDA'),
  (41, 7, 10, '2026-10-10 09:30:00', '2026-10-10 09:55:00', 'Valoración por rinitis alérgica', 'ATENDIDA'),
  (42, 8, 11, '2026-10-10 10:00:00', '2026-10-10 10:25:00', 'Valoración por control de hipertensión arterial', 'ATENDIDA'),
  (43, 9, 12, '2026-10-10 10:30:00', '2026-10-10 10:55:00', 'Valoración por dolor articular', 'ATENDIDA'),
  (44, 10, 13, '2026-10-10 11:00:00', '2026-10-10 11:25:00', 'Valoración por infección respiratoria de vías superiores', 'ATENDIDA'),
  (45, 11, 14, '2026-10-10 11:30:00', '2026-10-10 11:55:00', 'Valoración por gastritis', 'ATENDIDA'),
  (46, 12, 15, '2026-10-10 12:00:00', '2026-10-10 12:25:00', 'Valoración por rinitis alérgica', 'ATENDIDA'),
  (47, 13, 16, '2026-10-10 12:30:00', '2026-10-10 12:55:00', 'Valoración por control de hipertensión arterial', 'ATENDIDA'),
  (48, 14, 17, '2026-10-10 13:00:00', '2026-10-10 13:25:00', 'Valoración por dolor articular', 'ATENDIDA'),
  (49, 15, 18, '2026-10-10 13:30:00', '2026-10-10 13:55:00', 'Valoración por infección respiratoria de vías superiores', 'ATENDIDA'),
  (50, 16, 19, '2026-10-10 14:00:00', '2026-10-10 14:25:00', 'Valoración por gastritis', 'ATENDIDA'),
  (51, 17, 20, '2026-10-10 14:30:00', '2026-10-10 14:55:00', 'Valoración por rinitis alérgica', 'ATENDIDA'),
  (52, 18, 21, '2026-10-10 15:00:00', '2026-10-10 15:25:00', 'Valoración por control de hipertensión arterial', 'ATENDIDA'),
  (53, 19, 22, '2026-10-10 15:30:00', '2026-10-10 15:55:00', 'Valoración por dolor articular', 'ATENDIDA'),
  (54, 20, 23, '2026-10-10 16:00:00', '2026-10-10 16:25:00', 'Valoración por infección respiratoria de vías superiores', 'ATENDIDA');

INSERT INTO consultas (consulta_id, cita_id, paciente_id, medico_id, fecha, tipo, motivo, notas) VALUES
  (31, 40, 6, 9, '2026-10-10 09:05:00', 'PROGRAMADA', 'Valoración por gastritis', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (32, 41, 7, 10, '2026-10-10 09:35:00', 'PROGRAMADA', 'Valoración por rinitis alérgica', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (33, 42, 8, 11, '2026-10-10 10:05:00', 'PROGRAMADA', 'Valoración por control de hipertensión arterial', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (34, 43, 9, 12, '2026-10-10 10:35:00', 'PROGRAMADA', 'Valoración por dolor articular', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (35, 44, 10, 13, '2026-10-10 11:05:00', 'PROGRAMADA', 'Valoración por infección respiratoria de vías superiores', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (36, 45, 11, 14, '2026-10-10 11:35:00', 'PROGRAMADA', 'Valoración por gastritis', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (37, 46, 12, 15, '2026-10-10 12:05:00', 'PROGRAMADA', 'Valoración por rinitis alérgica', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (38, 47, 13, 16, '2026-10-10 12:35:00', 'PROGRAMADA', 'Valoración por control de hipertensión arterial', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (39, 48, 14, 17, '2026-10-10 13:05:00', 'PROGRAMADA', 'Valoración por dolor articular', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (40, 49, 15, 18, '2026-10-10 13:35:00', 'PROGRAMADA', 'Valoración por infección respiratoria de vías superiores', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (41, 50, 16, 19, '2026-10-10 14:05:00', 'PROGRAMADA', 'Valoración por gastritis', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (42, 51, 17, 20, '2026-10-10 14:35:00', 'PROGRAMADA', 'Valoración por rinitis alérgica', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (43, 52, 18, 21, '2026-10-10 15:05:00', 'PROGRAMADA', 'Valoración por control de hipertensión arterial', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (44, 53, 19, 22, '2026-10-10 15:35:00', 'PROGRAMADA', 'Valoración por dolor articular', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.'),
  (45, 54, 20, 23, '2026-10-10 16:05:00', 'PROGRAMADA', 'Valoración por infección respiratoria de vías superiores', 'Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.');

INSERT INTO recetas (receta_id, consulta_id, fecha_prescripcion, observaciones) VALUES
  (26, 31, '2026-10-10 09:10:00', 'Monitorear temperatura corporal.'),
  (27, 32, '2026-10-10 09:40:00', 'Administrar lentamente por vía IV.'),
  (28, 33, '2026-10-10 10:10:00', 'Tomar en ayunas por la mañana.'),
  (29, 34, '2026-10-10 10:40:00', 'Completar tratamiento de 7 días.'),
  (30, 35, '2026-10-10 11:10:00', 'Usar en caso de dolor agudo.'),
  (31, 36, '2026-10-10 11:40:00', 'Antes del primer alimento del día.'),
  (32, 37, '2026-10-10 12:10:00', 'Vigilar estado de conciencia.'),
  (33, 38, '2026-10-10 12:40:00', 'Indicado para cuadro alérgico.'),
  (34, 39, '2026-10-10 13:10:00', 'Acompañar con los alimentos principales.'),
  (35, 40, '2026-10-10 13:40:00', 'Usar espaciador en caso de disnea.'),
  (36, 41, '2026-10-10 14:10:00', 'Diluir en solución salina al 0.9%.'),
  (37, 42, '2026-10-10 14:40:00', 'Controlar niveles de glucosa.'),
  (38, 43, '2026-10-10 15:10:00', 'Vigilar gasto urinario y presión arterial.'),
  (39, 44, '2026-10-10 15:40:00', 'Rotar sitio de punción diariamente.'),
  (40, 45, '2026-10-10 16:10:00', 'Frotar suavemente sobre la zona afectada.');

INSERT INTO receta_detalle (receta_id, renglon, medicamento_id, dosis, frecuencia, duracion_dias, via_administracion, cantidad_prescrita) VALUES
  (26, 1, 1, '500 mg cada 8 horas', 'Cada 8 horas', 1, 'Oral', 1),
  (27, 1, 5, '30 mg cada 12 horas', 'Cada 12 horas', 1, 'Intravenosa', 1),
  (28, 1, 9, '50 mg cada 24 horas', 'Cada 24 horas', 1, 'Oral', 1),
  (29, 1, 3, '10 ml cada 8 horas', 'Cada 8 horas', 7, 'Oral', 1),
  (30, 1, 2, '400 mg cada 6 horas condicional', 'Cada 6 horas', 1, 'Oral', 1),
  (31, 1, 4, '20 mg cada 24 horas', 'Cada 24 horas', 1, 'Oral', 1),
  (32, 1, 13, '10 mg dosis única', 'Dosis única', 1, 'Intramuscular', 1),
  (33, 1, 7, '10 mg cada 24 horas', 'Cada 24 horas', 1, 'Oral', 1),
  (34, 1, 8, '850 mg cada 12 horas', 'Cada 12 horas', 1, 'Oral', 1),
  (35, 1, 6, '2 disparos cada 4 horas', 'Cada 4 horas', 1, 'Inhalatoria', 1),
  (36, 1, 12, '1 g cada 12 horas', 'Cada 12 horas', 1, 'Intravenosa', 1),
  (37, 1, 14, '100 mg cada 8 horas', 'Cada 8 horas', 1, 'Intravenosa', 1),
  (38, 1, 15, '40 mg cada 24 horas', 'Cada 24 horas', 1, 'Oral', 1),
  (39, 1, 11, '15 UI por la noche', 'Por la noche', 1, 'Subcutánea', 1),
  (40, 1, 10, 'Aplicar cantidad moderada', 'Según indicación registrada en la receta', 1, 'Tópico', 1);

COMMIT;
