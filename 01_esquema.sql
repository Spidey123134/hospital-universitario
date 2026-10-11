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
