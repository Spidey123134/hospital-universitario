-- Estructura reconstruida de SDI; NO contiene registros de los .ibd.
-- No es una instruccion de IMPORT TABLESPACE ni una migracion.
-- Se conserva el diseno original para comparar con el proyecto mejorado.
CREATE DATABASE hospital_prototipo_recuperado CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE hospital_prototipo_recuperado;

CREATE TABLE `medicos` (
  `medico_id` int NOT NULL AUTO_INCREMENT,
  `cedula_profesional` varchar(50) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido_paterno` varchar(100) NOT NULL,
  `especialidad` varchar(100) NOT NULL,
  `horario_entrada` time NULL DEFAULT NULL,
  `horario_salida` time NULL DEFAULT NULL,
  PRIMARY KEY (`medico_id`),
  UNIQUE KEY `cedula_profesional` (`cedula_profesional`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `pacientes` (
  `paciente_id` int NOT NULL AUTO_INCREMENT,
  `expediente_clinico` varchar(50) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido_paterno` varchar(100) NOT NULL,
  `fecha_nacimiento` date NOT NULL,
  `medico_tratante_id` int NULL DEFAULT NULL,
  PRIMARY KEY (`paciente_id`),
  UNIQUE KEY `expediente_clinico` (`expediente_clinico`),
  KEY `fk_paciente_medico` (`medico_tratante_id`),
  CONSTRAINT `fk_paciente_medico` FOREIGN KEY (`medico_tratante_id`) REFERENCES `medicos` (`medico_id`) ON DELETE SET NULL ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `camillas` (
  `camilla_id` int NOT NULL AUTO_INCREMENT,
  `edificio` varchar(50) NOT NULL,
  `sala_ala` varchar(100) NOT NULL,
  `estado_operativo` varchar(30) NULL DEFAULT 'Disponible',
  PRIMARY KEY (`camilla_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `medicamentos` (
  `medicamento_id` int NOT NULL AUTO_INCREMENT,
  `principio_activo` varchar(100) NOT NULL,
  `presentacion` varchar(50) NOT NULL,
  `stock_disponible` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`medicamento_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `recetas` (
  `receta_id` int NOT NULL AUTO_INCREMENT,
  `paciente_id` int NOT NULL,
  `medico_id` int NOT NULL,
  `camilla_id` int NOT NULL,
  `medicamento_id` int NOT NULL,
  `fecha_prescripcion` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `dosis` varchar(100) NOT NULL,
  `via_administracion` varchar(50) NOT NULL,
  `observaciones` text NULL DEFAULT NULL,
  PRIMARY KEY (`receta_id`),
  KEY `fk_receta_paciente` (`paciente_id`),
  KEY `fk_receta_medico` (`medico_id`),
  KEY `fk_receta_camilla` (`camilla_id`),
  KEY `fk_receta_medicamento` (`medicamento_id`),
  CONSTRAINT `fk_receta_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`paciente_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_receta_medico` FOREIGN KEY (`medico_id`) REFERENCES `medicos` (`medico_id`) ON DELETE RESTRICT ON UPDATE NO ACTION,
  CONSTRAINT `fk_receta_camilla` FOREIGN KEY (`camilla_id`) REFERENCES `camillas` (`camilla_id`) ON DELETE RESTRICT ON UPDATE NO ACTION,
  CONSTRAINT `fk_receta_medicamento` FOREIGN KEY (`medicamento_id`) REFERENCES `medicamentos` (`medicamento_id`) ON DELETE RESTRICT ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

