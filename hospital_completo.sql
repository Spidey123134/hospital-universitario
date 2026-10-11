-- INSTALACION COMPLETA: esquema + reglas + datos ficticios.
-- Ejecutar UNA VEZ en una base nueva. No ejecutar tambien 01/02/03.
-- No elimina ni importa bases existentes. Consultas: 04_consultas.sql.

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
