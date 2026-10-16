-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: hospital_universitario
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `hospital_universitario`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `hospital_universitario` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `hospital_universitario`;

--
-- Table structure for table `alergias_paciente`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alergias_paciente` (
  `alergia_id` int unsigned NOT NULL AUTO_INCREMENT,
  `paciente_id` int unsigned NOT NULL,
  `sustancia` varchar(150) NOT NULL,
  `reaccion` varchar(250) NOT NULL,
  `fecha_registro` date NOT NULL,
  PRIMARY KEY (`alergia_id`),
  UNIQUE KEY `paciente_id` (`paciente_id`,`sustancia`),
  CONSTRAINT `fk_alergia_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`paciente_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alergias_paciente`
--

LOCK TABLES `alergias_paciente` WRITE;
/*!40000 ALTER TABLE `alergias_paciente` DISABLE KEYS */;
INSERT INTO `alergias_paciente` VALUES (1,1,'Sustancia ficticia X','Descripcion simulada A','2026-09-01'),(2,3,'Sustancia ficticia Y','Descripcion simulada B','2026-09-02'),(3,6,'Compuesto de prueba 1','Reaccion simulada para comprobar el expediente','2026-09-15'),(4,10,'Compuesto de prueba 2','Reaccion simulada para comprobar el expediente','2026-09-15'),(5,14,'Compuesto de prueba 3','Reaccion simulada para comprobar el expediente','2026-09-15'),(6,18,'Compuesto de prueba 4','Reaccion simulada para comprobar el expediente','2026-09-15'),(7,22,'Compuesto de prueba 5','Reaccion simulada para comprobar el expediente','2026-09-15'),(8,26,'Compuesto de prueba 6','Reaccion simulada para comprobar el expediente','2026-09-15'),(9,30,'Compuesto de prueba 7','Reaccion simulada para comprobar el expediente','2026-09-15');
/*!40000 ALTER TABLE `alergias_paciente` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `aseguradoras`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `aseguradoras` (
  `aseguradora_id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) NOT NULL,
  `telefono` varchar(25) DEFAULT NULL,
  PRIMARY KEY (`aseguradora_id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `aseguradoras`
--

LOCK TABLES `aseguradoras` WRITE;
/*!40000 ALTER TABLE `aseguradoras` DISABLE KEYS */;
INSERT INTO `aseguradoras` VALUES (1,'Aseguradora ficticia Alfa','TEL-ASEG-DEMO-001'),(2,'Aseguradora ficticia Beta','TEL-ASEG-DEMO-002'),(3,'Aseguradora ficticia Gamma','TEL-ASEG-DEMO-003'),(4,'Aseguradora ficticia Delta','TEL-ASEG-DEMO-004'),(5,'Aseguradora ficticia Epsilon','TEL-ASEG-DEMO-005');
/*!40000 ALTER TABLE `aseguradoras` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `asignaciones_camilla`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `asignaciones_camilla` (
  `asignacion_id` int unsigned NOT NULL AUTO_INCREMENT,
  `hospitalizacion_id` int unsigned NOT NULL,
  `camilla_id` int unsigned NOT NULL,
  `inicio` datetime NOT NULL,
  `fin` datetime DEFAULT NULL,
  `camilla_ocupada` int unsigned GENERATED ALWAYS AS ((case when (`fin` is null) then `camilla_id` end)) STORED,
  `hospitalizacion_asignada` int unsigned GENERATED ALWAYS AS ((case when (`fin` is null) then `hospitalizacion_id` end)) STORED,
  PRIMARY KEY (`asignacion_id`),
  UNIQUE KEY `camilla_ocupada` (`camilla_ocupada`),
  UNIQUE KEY `hospitalizacion_asignada` (`hospitalizacion_asignada`),
  KEY `ix_asignacion_historial` (`camilla_id`,`inicio`,`fin`),
  KEY `fk_asignacion_hosp` (`hospitalizacion_id`),
  CONSTRAINT `fk_asignacion_camilla` FOREIGN KEY (`camilla_id`) REFERENCES `camillas` (`camilla_id`),
  CONSTRAINT `fk_asignacion_hosp` FOREIGN KEY (`hospitalizacion_id`) REFERENCES `hospitalizaciones` (`hospitalizacion_id`),
  CONSTRAINT `ck_asignacion_fechas` CHECK (((`fin` is null) or (`fin` > `inicio`)))
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `asignaciones_camilla`
--

LOCK TABLES `asignaciones_camilla` WRITE;
/*!40000 ALTER TABLE `asignaciones_camilla` DISABLE KEYS */;
INSERT INTO `asignaciones_camilla` (`asignacion_id`, `hospitalizacion_id`, `camilla_id`, `inicio`, `fin`) VALUES (1,1,1,'2026-10-08 12:00:00','2026-10-08 18:00:00'),(2,1,3,'2026-10-08 18:00:00','2026-10-09 12:00:00'),(3,2,2,'2026-10-09 15:00:00',NULL),(4,3,7,'2026-10-01 10:05:00',NULL),(5,4,8,'2026-10-01 10:50:00',NULL),(6,5,9,'2026-10-01 11:35:00',NULL),(7,6,10,'2026-10-01 12:20:00',NULL),(8,7,11,'2026-10-01 13:05:00',NULL),(9,8,12,'2026-10-02 10:05:00',NULL),(10,9,13,'2026-10-02 10:50:00','2026-10-03 10:50:00'),(11,10,14,'2026-10-02 11:35:00','2026-10-03 11:35:00'),(12,11,3,'2026-10-02 12:20:00','2026-10-03 12:20:00');
/*!40000 ALTER TABLE `asignaciones_camilla` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `camillas`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `camillas` (
  `camilla_id` int unsigned NOT NULL AUTO_INCREMENT,
  `habitacion_id` int unsigned NOT NULL,
  `codigo` varchar(30) NOT NULL,
  `estado_operativo` enum('OPERATIVA','MANTENIMIENTO','FUERA_SERVICIO') NOT NULL DEFAULT 'OPERATIVA',
  PRIMARY KEY (`camilla_id`),
  UNIQUE KEY `codigo` (`codigo`),
  KEY `fk_camilla_habitacion` (`habitacion_id`),
  CONSTRAINT `fk_camilla_habitacion` FOREIGN KEY (`habitacion_id`) REFERENCES `habitaciones` (`habitacion_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `camillas`
--

LOCK TABLES `camillas` WRITE;
/*!40000 ALTER TABLE `camillas` DISABLE KEYS */;
INSERT INTO `camillas` VALUES (1,1,'CAM-DEMO-01','OPERATIVA'),(2,1,'CAM-DEMO-02','OPERATIVA'),(3,2,'CAM-DEMO-03','OPERATIVA'),(4,3,'CAM-DEMO-04','OPERATIVA'),(5,4,'CAM-DEMO-05','OPERATIVA'),(6,4,'CAM-DEMO-06','MANTENIMIENTO'),(7,5,'CAM-DEMO-07','OPERATIVA'),(8,5,'CAM-DEMO-08','OPERATIVA'),(9,6,'CAM-DEMO-09','OPERATIVA'),(10,6,'CAM-DEMO-10','OPERATIVA'),(11,7,'CAM-DEMO-11','OPERATIVA'),(12,7,'CAM-DEMO-12','OPERATIVA'),(13,8,'CAM-DEMO-13','OPERATIVA'),(14,8,'CAM-DEMO-14','OPERATIVA'),(15,9,'CAM-DEMO-15','MANTENIMIENTO');
/*!40000 ALTER TABLE `camillas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `citas`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `citas` (
  `cita_id` int unsigned NOT NULL AUTO_INCREMENT,
  `paciente_id` int unsigned NOT NULL,
  `medico_id` int unsigned NOT NULL,
  `inicio` datetime NOT NULL,
  `fin` datetime NOT NULL,
  `motivo` varchar(250) NOT NULL,
  `estado` enum('PROGRAMADA','CONFIRMADA','ATENDIDA','CANCELADA','NO_ASISTIO') NOT NULL DEFAULT 'PROGRAMADA',
  `medico_agenda` int unsigned GENERATED ALWAYS AS ((case when (`estado` <> _utf8mb4'CANCELADA') then `medico_id` end)) STORED,
  `paciente_agenda` int unsigned GENERATED ALWAYS AS ((case when (`estado` <> _utf8mb4'CANCELADA') then `paciente_id` end)) STORED,
  PRIMARY KEY (`cita_id`),
  UNIQUE KEY `cita_id` (`cita_id`,`paciente_id`,`medico_id`),
  UNIQUE KEY `medico_agenda` (`medico_agenda`,`inicio`),
  UNIQUE KEY `paciente_agenda` (`paciente_agenda`,`inicio`),
  KEY `ix_cita_paciente_fecha` (`paciente_id`,`inicio`),
  KEY `ix_cita_medico_intervalo` (`medico_id`,`inicio`,`fin`),
  CONSTRAINT `fk_cita_medico` FOREIGN KEY (`medico_id`) REFERENCES `medicos` (`medico_id`),
  CONSTRAINT `fk_cita_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`paciente_id`),
  CONSTRAINT `ck_cita_intervalo` CHECK ((`fin` > `inicio`))
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `citas`
--

LOCK TABLES `citas` WRITE;
/*!40000 ALTER TABLE `citas` DISABLE KEYS */;
INSERT INTO `citas` (`cita_id`, `paciente_id`, `medico_id`, `inicio`, `fin`, `motivo`, `estado`) VALUES (1,1,1,'2026-10-06 09:00:00','2026-10-06 09:30:00','Caso academico A','ATENDIDA'),(2,2,2,'2026-10-07 10:00:00','2026-10-07 10:30:00','Caso academico B','ATENDIDA'),(3,4,1,'2026-10-08 09:00:00','2026-10-08 09:30:00','Caso academico C','ATENDIDA'),(4,1,1,'2026-10-12 09:00:00','2026-10-12 09:30:00','Seguimiento ficticio A','PROGRAMADA'),(5,2,2,'2026-10-12 10:00:00','2026-10-12 10:30:00','Seguimiento ficticio B','CONFIRMADA'),(6,3,3,'2026-10-09 11:00:00','2026-10-09 11:30:00','Ejemplo de cancelacion','CANCELADA'),(7,6,9,'2026-10-01 09:00:00','2026-10-01 09:30:00','Consulta programada del caso ficticio 6','ATENDIDA'),(8,7,10,'2026-10-01 09:45:00','2026-10-01 10:15:00','Consulta programada del caso ficticio 7','ATENDIDA'),(9,8,11,'2026-10-01 10:30:00','2026-10-01 11:00:00','Consulta programada del caso ficticio 8','ATENDIDA'),(10,9,12,'2026-10-01 11:15:00','2026-10-01 11:45:00','Consulta programada del caso ficticio 9','ATENDIDA'),(11,10,13,'2026-10-01 12:00:00','2026-10-01 12:30:00','Consulta programada del caso ficticio 10','ATENDIDA'),(12,11,14,'2026-10-02 09:00:00','2026-10-02 09:30:00','Consulta programada del caso ficticio 11','ATENDIDA'),(13,12,15,'2026-10-02 09:45:00','2026-10-02 10:15:00','Consulta programada del caso ficticio 12','ATENDIDA'),(14,13,16,'2026-10-02 10:30:00','2026-10-02 11:00:00','Consulta programada del caso ficticio 13','ATENDIDA'),(15,14,17,'2026-10-02 11:15:00','2026-10-02 11:45:00','Consulta programada del caso ficticio 14','ATENDIDA'),(16,15,18,'2026-10-02 12:00:00','2026-10-02 12:30:00','Consulta programada del caso ficticio 15','ATENDIDA'),(17,16,19,'2026-10-03 09:00:00','2026-10-03 09:30:00','Consulta programada del caso ficticio 16','ATENDIDA'),(18,17,20,'2026-10-03 09:45:00','2026-10-03 10:15:00','Consulta programada del caso ficticio 17','ATENDIDA'),(19,18,21,'2026-10-03 10:30:00','2026-10-03 11:00:00','Consulta programada del caso ficticio 18','ATENDIDA'),(20,19,22,'2026-10-03 11:15:00','2026-10-03 11:45:00','Consulta programada del caso ficticio 19','ATENDIDA'),(21,20,23,'2026-10-03 12:00:00','2026-10-03 12:30:00','Consulta programada del caso ficticio 20','ATENDIDA'),(22,21,9,'2026-10-04 09:00:00','2026-10-04 09:30:00','Consulta programada del caso ficticio 21','ATENDIDA'),(23,22,10,'2026-10-04 09:45:00','2026-10-04 10:15:00','Consulta programada del caso ficticio 22','ATENDIDA'),(24,23,11,'2026-10-04 10:30:00','2026-10-04 11:00:00','Consulta programada del caso ficticio 23','ATENDIDA'),(25,24,12,'2026-10-04 11:15:00','2026-10-04 11:45:00','Consulta programada del caso ficticio 24','ATENDIDA'),(26,25,13,'2026-10-04 12:00:00','2026-10-04 12:30:00','Consulta programada del caso ficticio 25','ATENDIDA'),(27,26,14,'2026-10-05 09:00:00','2026-10-05 09:30:00','Consulta programada del caso ficticio 26','ATENDIDA'),(28,27,15,'2026-10-05 09:45:00','2026-10-05 10:15:00','Consulta programada del caso ficticio 27','ATENDIDA'),(29,28,16,'2026-10-05 10:30:00','2026-10-05 11:00:00','Consulta programada del caso ficticio 28','ATENDIDA'),(30,29,17,'2026-10-05 11:15:00','2026-10-05 11:45:00','Consulta programada del caso ficticio 29','ATENDIDA'),(31,30,18,'2026-10-05 12:00:00','2026-10-05 12:30:00','Consulta programada del caso ficticio 30','ATENDIDA'),(32,6,9,'2026-10-20 09:00:00','2026-10-20 09:30:00','Seguimiento de demostracion','PROGRAMADA'),(33,7,10,'2026-10-20 10:00:00','2026-10-20 10:30:00','Seguimiento de demostracion','CONFIRMADA'),(34,8,11,'2026-10-20 11:00:00','2026-10-20 11:30:00','Seguimiento de demostracion','PROGRAMADA'),(35,9,12,'2026-10-20 12:00:00','2026-10-20 12:30:00','Seguimiento de demostracion','CONFIRMADA'),(36,10,13,'2026-10-21 09:00:00','2026-10-21 09:30:00','Seguimiento de demostracion','PROGRAMADA'),(37,11,14,'2026-10-21 10:00:00','2026-10-21 10:30:00','Seguimiento de demostracion','CONFIRMADA'),(38,12,15,'2026-10-21 11:00:00','2026-10-21 11:30:00','Seguimiento de demostracion','PROGRAMADA'),(39,13,16,'2026-10-21 12:00:00','2026-10-21 12:30:00','Seguimiento de demostracion','CONFIRMADA'),(40,6,9,'2026-10-10 09:00:00','2026-10-10 09:25:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(41,7,10,'2026-10-10 09:30:00','2026-10-10 09:55:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(42,8,11,'2026-10-10 10:00:00','2026-10-10 10:25:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(43,9,12,'2026-10-10 10:30:00','2026-10-10 10:55:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(44,10,13,'2026-10-10 11:00:00','2026-10-10 11:25:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(45,11,14,'2026-10-10 11:30:00','2026-10-10 11:55:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(46,12,15,'2026-10-10 12:00:00','2026-10-10 12:25:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(47,13,16,'2026-10-10 12:30:00','2026-10-10 12:55:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(48,14,17,'2026-10-10 13:00:00','2026-10-10 13:25:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(49,15,18,'2026-10-10 13:30:00','2026-10-10 13:55:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(50,16,19,'2026-10-10 14:00:00','2026-10-10 14:25:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(51,17,20,'2026-10-10 14:30:00','2026-10-10 14:55:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(52,18,21,'2026-10-10 15:00:00','2026-10-10 15:25:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(53,19,22,'2026-10-10 15:30:00','2026-10-10 15:55:00','Caso docente adaptado de la captura del equipo','ATENDIDA'),(54,20,23,'2026-10-10 16:00:00','2026-10-10 16:25:00','Caso docente adaptado de la captura del equipo','ATENDIDA');
/*!40000 ALTER TABLE `citas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `consulta_diagnosticos`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `consulta_diagnosticos` (
  `consulta_id` int unsigned NOT NULL,
  `diagnostico_id` int unsigned NOT NULL,
  `es_principal` tinyint(1) NOT NULL DEFAULT '0',
  `diagnostico_principal` int unsigned GENERATED ALWAYS AS ((case when (`es_principal` = 1) then `consulta_id` end)) STORED,
  `observaciones` varchar(250) DEFAULT NULL,
  PRIMARY KEY (`consulta_id`,`diagnostico_id`),
  UNIQUE KEY `diagnostico_principal` (`diagnostico_principal`),
  KEY `fk_cd_diagnostico` (`diagnostico_id`),
  CONSTRAINT `fk_cd_consulta` FOREIGN KEY (`consulta_id`) REFERENCES `consultas` (`consulta_id`),
  CONSTRAINT `fk_cd_diagnostico` FOREIGN KEY (`diagnostico_id`) REFERENCES `diagnosticos` (`diagnostico_id`),
  CONSTRAINT `ck_cd_principal` CHECK ((`es_principal` in (0,1)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `consulta_diagnosticos`
--

LOCK TABLES `consulta_diagnosticos` WRITE;
/*!40000 ALTER TABLE `consulta_diagnosticos` DISABLE KEYS */;
INSERT INTO `consulta_diagnosticos` (`consulta_id`, `diagnostico_id`, `es_principal`, `observaciones`) VALUES (1,1,1,'Registro principal de prueba'),(1,2,0,'Registro secundario de prueba'),(2,2,1,'Registro principal de prueba'),(3,3,1,'Registro principal de prueba'),(4,1,1,'Registro principal de prueba'),(5,3,1,'Registro principal de prueba'),(6,2,0,'Diagnostico secundario simulado'),(6,4,1,'Diagnostico principal simulado'),(7,5,1,'Diagnostico principal simulado'),(8,6,1,'Diagnostico principal simulado'),(9,2,0,'Diagnostico secundario simulado'),(9,7,1,'Diagnostico principal simulado'),(10,8,1,'Diagnostico principal simulado'),(11,4,1,'Diagnostico principal simulado'),(12,2,0,'Diagnostico secundario simulado'),(12,5,1,'Diagnostico principal simulado'),(13,6,1,'Diagnostico principal simulado'),(14,7,1,'Diagnostico principal simulado'),(15,2,0,'Diagnostico secundario simulado'),(15,8,1,'Diagnostico principal simulado'),(16,4,1,'Diagnostico principal simulado'),(17,5,1,'Diagnostico principal simulado'),(18,2,0,'Diagnostico secundario simulado'),(18,6,1,'Diagnostico principal simulado'),(19,7,1,'Diagnostico principal simulado'),(20,8,1,'Diagnostico principal simulado'),(21,2,0,'Diagnostico secundario simulado'),(21,4,1,'Diagnostico principal simulado'),(22,5,1,'Diagnostico principal simulado'),(23,6,1,'Diagnostico principal simulado'),(24,2,0,'Diagnostico secundario simulado'),(24,7,1,'Diagnostico principal simulado'),(25,8,1,'Diagnostico principal simulado'),(26,4,1,'Diagnostico principal simulado'),(27,2,0,'Diagnostico secundario simulado'),(27,5,1,'Diagnostico principal simulado'),(28,6,1,'Diagnostico principal simulado'),(29,7,1,'Diagnostico principal simulado'),(30,2,0,'Diagnostico secundario simulado'),(30,8,1,'Diagnostico principal simulado');
/*!40000 ALTER TABLE `consulta_diagnosticos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `consultas`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `consultas` (
  `consulta_id` int unsigned NOT NULL AUTO_INCREMENT,
  `cita_id` int unsigned DEFAULT NULL,
  `paciente_id` int unsigned NOT NULL,
  `medico_id` int unsigned NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tipo` enum('PROGRAMADA','URGENCIA','SEGUIMIENTO') NOT NULL,
  `motivo` varchar(250) NOT NULL,
  `notas` text,
  `peso_kg` decimal(6,2) DEFAULT NULL,
  `talla_cm` decimal(5,2) DEFAULT NULL,
  `temperatura_c` decimal(4,1) DEFAULT NULL,
  PRIMARY KEY (`consulta_id`),
  UNIQUE KEY `consulta_id` (`consulta_id`,`paciente_id`),
  UNIQUE KEY `cita_id` (`cita_id`),
  KEY `ix_consulta_paciente_fecha` (`paciente_id`,`fecha`),
  KEY `fk_consulta_cita` (`cita_id`,`paciente_id`,`medico_id`),
  KEY `fk_consulta_medico` (`medico_id`),
  CONSTRAINT `fk_consulta_cita` FOREIGN KEY (`cita_id`, `paciente_id`, `medico_id`) REFERENCES `citas` (`cita_id`, `paciente_id`, `medico_id`),
  CONSTRAINT `fk_consulta_medico` FOREIGN KEY (`medico_id`) REFERENCES `medicos` (`medico_id`),
  CONSTRAINT `fk_consulta_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`paciente_id`),
  CONSTRAINT `ck_consulta_peso` CHECK (((`peso_kg` is null) or (`peso_kg` > 0))),
  CONSTRAINT `ck_consulta_talla` CHECK (((`talla_cm` is null) or (`talla_cm` > 0)))
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `consultas`
--

LOCK TABLES `consultas` WRITE;
/*!40000 ALTER TABLE `consultas` DISABLE KEYS */;
INSERT INTO `consultas` VALUES (1,1,1,1,'2026-10-06 09:05:00','PROGRAMADA','Caso academico A','Nota simulada para practicar el expediente; sin contenido clinico real.',60.00,160.00,36.5),(2,2,2,2,'2026-10-07 10:05:00','PROGRAMADA','Caso academico B','Nota simulada para practicar relaciones entre tablas.',75.00,175.00,36.6),(3,NULL,3,3,'2026-10-08 11:00:00','URGENCIA','Ingreso ficticio A','Caso inventado con hospitalizacion cerrada y traslado.',65.00,168.00,36.7),(4,3,4,1,'2026-10-08 09:05:00','PROGRAMADA','Caso academico C','Nota simulada; valores numericos unicamente para probar tipos de datos.',40.00,145.00,36.5),(5,NULL,5,2,'2026-10-09 14:00:00','URGENCIA','Ingreso ficticio B','Caso inventado con hospitalizacion abierta.',80.00,172.00,36.8),(6,7,6,9,'2026-10-01 09:05:00','PROGRAMADA','Revision del caso ficticio 6','Registro inventado para probar relaciones y consultas; sin uso clinico.',55.00,155.00,36.5),(7,8,7,10,'2026-10-01 09:50:00','PROGRAMADA','Revision del caso ficticio 7','Registro inventado para probar relaciones y consultas; sin uso clinico.',56.00,156.00,36.6),(8,9,8,11,'2026-10-01 10:35:00','PROGRAMADA','Revision del caso ficticio 8','Registro inventado para probar relaciones y consultas; sin uso clinico.',57.00,157.00,36.7),(9,10,9,12,'2026-10-01 11:20:00','PROGRAMADA','Revision del caso ficticio 9','Registro inventado para probar relaciones y consultas; sin uso clinico.',58.00,158.00,36.5),(10,11,10,13,'2026-10-01 12:05:00','PROGRAMADA','Revision del caso ficticio 10','Registro inventado para probar relaciones y consultas; sin uso clinico.',59.00,159.00,36.6),(11,12,11,14,'2026-10-02 09:05:00','PROGRAMADA','Revision del caso ficticio 11','Registro inventado para probar relaciones y consultas; sin uso clinico.',60.00,160.00,36.7),(12,13,12,15,'2026-10-02 09:50:00','PROGRAMADA','Revision del caso ficticio 12','Registro inventado para probar relaciones y consultas; sin uso clinico.',61.00,161.00,36.5),(13,14,13,16,'2026-10-02 10:35:00','PROGRAMADA','Revision del caso ficticio 13','Registro inventado para probar relaciones y consultas; sin uso clinico.',62.00,162.00,36.6),(14,15,14,17,'2026-10-02 11:20:00','PROGRAMADA','Revision del caso ficticio 14','Registro inventado para probar relaciones y consultas; sin uso clinico.',63.00,163.00,36.7),(15,16,15,18,'2026-10-02 12:05:00','PROGRAMADA','Revision del caso ficticio 15','Registro inventado para probar relaciones y consultas; sin uso clinico.',64.00,164.00,36.5),(16,17,16,19,'2026-10-03 09:05:00','PROGRAMADA','Revision del caso ficticio 16','Registro inventado para probar relaciones y consultas; sin uso clinico.',65.00,165.00,36.6),(17,18,17,20,'2026-10-03 09:50:00','PROGRAMADA','Revision del caso ficticio 17','Registro inventado para probar relaciones y consultas; sin uso clinico.',66.00,166.00,36.7),(18,19,18,21,'2026-10-03 10:35:00','PROGRAMADA','Revision del caso ficticio 18','Registro inventado para probar relaciones y consultas; sin uso clinico.',67.00,167.00,36.5),(19,20,19,22,'2026-10-03 11:20:00','PROGRAMADA','Revision del caso ficticio 19','Registro inventado para probar relaciones y consultas; sin uso clinico.',68.00,168.00,36.6),(20,21,20,23,'2026-10-03 12:05:00','PROGRAMADA','Revision del caso ficticio 20','Registro inventado para probar relaciones y consultas; sin uso clinico.',69.00,169.00,36.7),(21,22,21,9,'2026-10-04 09:05:00','PROGRAMADA','Revision del caso ficticio 21','Registro inventado para probar relaciones y consultas; sin uso clinico.',70.00,170.00,36.5),(22,23,22,10,'2026-10-04 09:50:00','PROGRAMADA','Revision del caso ficticio 22','Registro inventado para probar relaciones y consultas; sin uso clinico.',71.00,171.00,36.6),(23,24,23,11,'2026-10-04 10:35:00','PROGRAMADA','Revision del caso ficticio 23','Registro inventado para probar relaciones y consultas; sin uso clinico.',72.00,172.00,36.7),(24,25,24,12,'2026-10-04 11:20:00','PROGRAMADA','Revision del caso ficticio 24','Registro inventado para probar relaciones y consultas; sin uso clinico.',73.00,173.00,36.5),(25,26,25,13,'2026-10-04 12:05:00','PROGRAMADA','Revision del caso ficticio 25','Registro inventado para probar relaciones y consultas; sin uso clinico.',74.00,174.00,36.6),(26,27,26,14,'2026-10-05 09:05:00','PROGRAMADA','Revision del caso ficticio 26','Registro inventado para probar relaciones y consultas; sin uso clinico.',75.00,175.00,36.7),(27,28,27,15,'2026-10-05 09:50:00','PROGRAMADA','Revision del caso ficticio 27','Registro inventado para probar relaciones y consultas; sin uso clinico.',76.00,176.00,36.5),(28,29,28,16,'2026-10-05 10:35:00','PROGRAMADA','Revision del caso ficticio 28','Registro inventado para probar relaciones y consultas; sin uso clinico.',77.00,177.00,36.6),(29,30,29,17,'2026-10-05 11:20:00','PROGRAMADA','Revision del caso ficticio 29','Registro inventado para probar relaciones y consultas; sin uso clinico.',78.00,178.00,36.7),(30,31,30,18,'2026-10-05 12:05:00','PROGRAMADA','Revision del caso ficticio 30','Registro inventado para probar relaciones y consultas; sin uso clinico.',79.00,179.00,36.5),(31,40,6,9,'2026-10-10 09:05:00','PROGRAMADA','Caso docente adaptado de la receta 1','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(32,41,7,10,'2026-10-10 09:35:00','PROGRAMADA','Caso docente adaptado de la receta 2','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(33,42,8,11,'2026-10-10 10:05:00','PROGRAMADA','Caso docente adaptado de la receta 3','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(34,43,9,12,'2026-10-10 10:35:00','PROGRAMADA','Caso docente adaptado de la receta 4','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(35,44,10,13,'2026-10-10 11:05:00','PROGRAMADA','Caso docente adaptado de la receta 5','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(36,45,11,14,'2026-10-10 11:35:00','PROGRAMADA','Caso docente adaptado de la receta 6','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(37,46,12,15,'2026-10-10 12:05:00','PROGRAMADA','Caso docente adaptado de la receta 7','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(38,47,13,16,'2026-10-10 12:35:00','PROGRAMADA','Caso docente adaptado de la receta 8','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(39,48,14,17,'2026-10-10 13:05:00','PROGRAMADA','Caso docente adaptado de la receta 9','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(40,49,15,18,'2026-10-10 13:35:00','PROGRAMADA','Caso docente adaptado de la receta 10','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(41,50,16,19,'2026-10-10 14:05:00','PROGRAMADA','Caso docente adaptado de la receta 11','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(42,51,17,20,'2026-10-10 14:35:00','PROGRAMADA','Caso docente adaptado de la receta 12','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(43,52,18,21,'2026-10-10 15:05:00','PROGRAMADA','Caso docente adaptado de la receta 13','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(44,53,19,22,'2026-10-10 15:35:00','PROGRAMADA','Caso docente adaptado de la receta 14','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL),(45,54,20,23,'2026-10-10 16:05:00','PROGRAMADA','Caso docente adaptado de la receta 15','Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.',NULL,NULL,NULL);
/*!40000 ALTER TABLE `consultas` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_consulta_identidad` BEFORE UPDATE ON `consultas` FOR EACH ROW BEGIN
  IF NEW.paciente_id <> OLD.paciente_id OR NEW.medico_id <> OLD.medico_id OR NOT (NEW.cita_id <=> OLD.cita_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La identidad de una consulta registrada es inmutable';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `contactos_emergencia`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `contactos_emergencia` (
  `contacto_id` int unsigned NOT NULL AUTO_INCREMENT,
  `paciente_id` int unsigned NOT NULL,
  `nombre` varchar(200) NOT NULL,
  `parentesco` varchar(50) NOT NULL,
  `telefono` varchar(25) NOT NULL,
  `prioridad` tinyint unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`contacto_id`),
  UNIQUE KEY `paciente_id` (`paciente_id`,`prioridad`),
  CONSTRAINT `fk_contacto_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`paciente_id`),
  CONSTRAINT `ck_contacto_prioridad` CHECK ((`prioridad` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contactos_emergencia`
--

LOCK TABLES `contactos_emergencia` WRITE;
/*!40000 ALTER TABLE `contactos_emergencia` DISABLE KEYS */;
INSERT INTO `contactos_emergencia` VALUES (1,1,'Contacto ficticio Uno A','Familiar de prueba','TEL-CON-DEMO-001',1),(2,1,'Contacto ficticio Uno B','Contacto de prueba','TEL-CON-DEMO-002',2),(3,2,'Contacto ficticio Dos','Familiar de prueba','TEL-CON-DEMO-003',1),(4,3,'Contacto ficticio Tres','Familiar de prueba','TEL-CON-DEMO-004',1),(5,4,'Contacto ficticio Cuatro','Tutor de prueba','TEL-CON-DEMO-005',1),(6,5,'Contacto ficticio Cinco','Familiar de prueba','TEL-CON-DEMO-006',1),(7,6,'Contacto simulado de Andrea','Familiar ficticio','TEL-CON-DEMO-007',1),(8,7,'Contacto simulado de Diego','Familiar ficticio','TEL-CON-DEMO-008',1),(9,8,'Contacto simulado de Valeria','Familiar ficticio','TEL-CON-DEMO-009',1),(10,9,'Contacto simulado de Mateo','Familiar ficticio','TEL-CON-DEMO-010',1),(11,10,'Contacto simulado de Camila','Familiar ficticio','TEL-CON-DEMO-011',1),(12,11,'Contacto simulado de Sebastian','Familiar ficticio','TEL-CON-DEMO-012',1),(13,12,'Contacto simulado de Renata','Familiar ficticio','TEL-CON-DEMO-013',1),(14,13,'Contacto simulado de Emiliano','Familiar ficticio','TEL-CON-DEMO-014',1),(15,14,'Contacto simulado de Paula','Familiar ficticio','TEL-CON-DEMO-015',1),(16,15,'Contacto simulado de Nicolas','Familiar ficticio','TEL-CON-DEMO-016',1),(17,16,'Contacto simulado de Fernanda','Familiar ficticio','TEL-CON-DEMO-017',1),(18,17,'Contacto simulado de Alejandro','Familiar ficticio','TEL-CON-DEMO-018',1),(19,18,'Contacto simulado de Regina','Familiar ficticio','TEL-CON-DEMO-019',1),(20,19,'Contacto simulado de Leonardo','Familiar ficticio','TEL-CON-DEMO-020',1),(21,20,'Contacto simulado de Daniela','Familiar ficticio','TEL-CON-DEMO-021',1),(22,21,'Contacto simulado de Santiago','Familiar ficticio','TEL-CON-DEMO-022',1),(23,22,'Contacto simulado de Isabella','Familiar ficticio','TEL-CON-DEMO-023',1),(24,23,'Contacto simulado de Gabriel','Familiar ficticio','TEL-CON-DEMO-024',1),(25,24,'Contacto simulado de Ximena','Familiar ficticio','TEL-CON-DEMO-025',1),(26,25,'Contacto simulado de Rodrigo','Familiar ficticio','TEL-CON-DEMO-026',1),(27,26,'Contacto simulado de Natalia','Familiar ficticio','TEL-CON-DEMO-027',1),(28,27,'Contacto simulado de Mauricio','Familiar ficticio','TEL-CON-DEMO-028',1),(29,28,'Contacto simulado de Carolina','Familiar ficticio','TEL-CON-DEMO-029',1),(30,29,'Contacto simulado de Joaquin','Familiar ficticio','TEL-CON-DEMO-030',1),(31,30,'Contacto simulado de Adriana','Familiar ficticio','TEL-CON-DEMO-031',1);
/*!40000 ALTER TABLE `contactos_emergencia` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `departamentos`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `departamentos` (
  `departamento_id` int unsigned NOT NULL AUTO_INCREMENT,
  `codigo` varchar(20) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  PRIMARY KEY (`departamento_id`),
  UNIQUE KEY `codigo` (`codigo`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `departamentos`
--

LOCK TABLES `departamentos` WRITE;
/*!40000 ALTER TABLE `departamentos` DISABLE KEYS */;
INSERT INTO `departamentos` VALUES (1,'DEP-DEMO-01','Consulta externa de demostracion'),(2,'DEP-DEMO-02','Hospitalizacion de demostracion'),(3,'DEP-DEMO-03','Farmacia de demostracion'),(4,'DEP-DEMO-04','Recepcion de demostracion'),(5,'DEP-DEMO-05','Laboratorio de demostracion'),(6,'DEP-DEMO-06','Imagenologia de demostracion'),(7,'DEP-DEMO-07','Cuidados intensivos de demostracion'),(8,'DEP-DEMO-08','Urgencias de demostracion');
/*!40000 ALTER TABLE `departamentos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `diagnosticos`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `diagnosticos` (
  `diagnostico_id` int unsigned NOT NULL AUTO_INCREMENT,
  `codigo` varchar(20) NOT NULL,
  `descripcion` varchar(250) NOT NULL,
  PRIMARY KEY (`diagnostico_id`),
  UNIQUE KEY `codigo` (`codigo`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `diagnosticos`
--

LOCK TABLES `diagnosticos` WRITE;
/*!40000 ALTER TABLE `diagnosticos` DISABLE KEYS */;
INSERT INTO `diagnosticos` VALUES (1,'DEMO-A','Diagnostico ficticio A; no es un codigo CIE'),(2,'DEMO-B','Diagnostico ficticio B; no es un codigo CIE'),(3,'DEMO-C','Diagnostico ficticio C; no es un codigo CIE'),(4,'DEMO-04','Diagnostico ficticio del caso 4; codigo de prueba, no CIE'),(5,'DEMO-05','Diagnostico ficticio del caso 5; codigo de prueba, no CIE'),(6,'DEMO-06','Diagnostico ficticio del caso 6; codigo de prueba, no CIE'),(7,'DEMO-07','Diagnostico ficticio del caso 7; codigo de prueba, no CIE'),(8,'DEMO-08','Diagnostico ficticio del caso 8; codigo de prueba, no CIE');
/*!40000 ALTER TABLE `diagnosticos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dispensacion_detalle`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dispensacion_detalle` (
  `dispensacion_detalle_id` int unsigned NOT NULL AUTO_INCREMENT,
  `dispensacion_id` int unsigned NOT NULL,
  `receta_id` int unsigned NOT NULL,
  `renglon` smallint unsigned NOT NULL,
  `medicamento_id` int unsigned NOT NULL,
  `lote_id` int unsigned NOT NULL,
  `cantidad` int unsigned NOT NULL,
  PRIMARY KEY (`dispensacion_detalle_id`),
  UNIQUE KEY `dispensacion_detalle_id` (`dispensacion_detalle_id`,`lote_id`),
  KEY `ix_dd_prescrito` (`receta_id`,`renglon`),
  KEY `fk_dd_dispensacion` (`dispensacion_id`,`receta_id`),
  KEY `fk_dd_receta_detalle` (`receta_id`,`renglon`,`medicamento_id`),
  KEY `fk_dd_lote` (`lote_id`,`medicamento_id`),
  CONSTRAINT `fk_dd_dispensacion` FOREIGN KEY (`dispensacion_id`, `receta_id`) REFERENCES `dispensaciones` (`dispensacion_id`, `receta_id`),
  CONSTRAINT `fk_dd_lote` FOREIGN KEY (`lote_id`, `medicamento_id`) REFERENCES `lotes_medicamento` (`lote_id`, `medicamento_id`),
  CONSTRAINT `fk_dd_receta_detalle` FOREIGN KEY (`receta_id`, `renglon`, `medicamento_id`) REFERENCES `receta_detalle` (`receta_id`, `renglon`, `medicamento_id`),
  CONSTRAINT `ck_dd_cantidad` CHECK ((`cantidad` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dispensacion_detalle`
--

LOCK TABLES `dispensacion_detalle` WRITE;
/*!40000 ALTER TABLE `dispensacion_detalle` DISABLE KEYS */;
INSERT INTO `dispensacion_detalle` VALUES (1,1,1,1,1,1,8),(2,1,1,2,2,2,3),(3,2,4,1,4,5,9),(4,2,4,2,8,9,6),(5,3,5,1,5,6,8),(6,3,5,2,9,10,4),(7,4,6,1,6,7,5),(8,4,6,2,10,11,20),(9,5,7,1,7,8,24),(10,5,7,2,11,12,18),(11,6,8,1,8,9,21),(12,6,8,2,12,13,14),(13,7,9,1,9,10,3),(14,7,9,2,13,14,1),(15,8,10,1,10,11,2),(16,8,10,2,14,15,8),(17,9,11,1,11,12,10),(18,9,11,2,15,16,7),(19,10,12,1,12,13,9),(20,10,12,2,4,5,6),(21,11,13,1,13,14,7),(22,11,13,2,5,6,3);
/*!40000 ALTER TABLE `dispensacion_detalle` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_disp_detalle_update` BEFORE UPDATE ON `dispensacion_detalle` FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una entrega registrada es inmutable';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_disp_detalle_delete` BEFORE DELETE ON `dispensacion_detalle` FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una entrega registrada es inmutable';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `dispensaciones`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dispensaciones` (
  `dispensacion_id` int unsigned NOT NULL AUTO_INCREMENT,
  `receta_id` int unsigned NOT NULL,
  `personal_id` int unsigned NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`dispensacion_id`),
  UNIQUE KEY `dispensacion_id` (`dispensacion_id`,`receta_id`),
  KEY `fk_disp_receta` (`receta_id`),
  KEY `fk_disp_personal` (`personal_id`),
  CONSTRAINT `fk_disp_personal` FOREIGN KEY (`personal_id`) REFERENCES `personal` (`personal_id`),
  CONSTRAINT `fk_disp_receta` FOREIGN KEY (`receta_id`) REFERENCES `recetas` (`receta_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dispensaciones`
--

LOCK TABLES `dispensaciones` WRITE;
/*!40000 ALTER TABLE `dispensaciones` DISABLE KEYS */;
INSERT INTO `dispensaciones` VALUES (1,1,6,'2026-10-06 10:00:00'),(2,4,6,'2026-10-01 10:05:00'),(3,5,6,'2026-10-01 10:50:00'),(4,6,6,'2026-10-01 11:35:00'),(5,7,6,'2026-10-01 12:20:00'),(6,8,6,'2026-10-01 13:05:00'),(7,9,6,'2026-10-02 10:05:00'),(8,10,6,'2026-10-02 10:50:00'),(9,11,6,'2026-10-02 11:35:00'),(10,12,6,'2026-10-02 12:20:00'),(11,13,6,'2026-10-02 13:05:00');
/*!40000 ALTER TABLE `dispensaciones` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_disp_insert` BEFORE INSERT ON `dispensaciones` FOR EACH ROW BEGIN
  IF NOT EXISTS (SELECT 1 FROM personal WHERE personal_id = NEW.personal_id AND puesto = 'FARMACIA' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La entrega requiere personal de FARMACIA activo';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `especialidades`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `especialidades` (
  `especialidad_id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  PRIMARY KEY (`especialidad_id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `especialidades`
--

LOCK TABLES `especialidades` WRITE;
/*!40000 ALTER TABLE `especialidades` DISABLE KEYS */;
INSERT INTO `especialidades` VALUES (4,'Cardiologia'),(8,'Dermatologia'),(14,'Endocrinologia'),(6,'Ginecologia'),(1,'Medicina general'),(2,'Medicina interna'),(13,'Nefrologia'),(7,'Neurologia'),(9,'Oftalmologia'),(11,'Oncologia'),(10,'Otorrinolaringologia'),(3,'Pediatria'),(12,'Psiquiatria'),(5,'Traumatologia'),(16,'Urgencias'),(15,'Urologia');
/*!40000 ALTER TABLE `especialidades` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `factura_detalle`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `factura_detalle` (
  `factura_id` int unsigned NOT NULL,
  `renglon` smallint unsigned NOT NULL,
  `descripcion` varchar(250) NOT NULL,
  `cantidad` decimal(10,2) NOT NULL,
  `precio_unitario` decimal(12,2) NOT NULL,
  `descuento` decimal(12,2) NOT NULL DEFAULT '0.00',
  `importe` decimal(14,2) GENERATED ALWAYS AS (round(((`cantidad` * `precio_unitario`) - `descuento`),2)) STORED,
  PRIMARY KEY (`factura_id`,`renglon`),
  CONSTRAINT `fk_fd_factura` FOREIGN KEY (`factura_id`) REFERENCES `facturas` (`factura_id`),
  CONSTRAINT `ck_fd_cantidad` CHECK ((`cantidad` > 0)),
  CONSTRAINT `ck_fd_descuento` CHECK (((`descuento` >= 0) and (`descuento` <= (`cantidad` * `precio_unitario`)))),
  CONSTRAINT `ck_fd_precio` CHECK ((`precio_unitario` >= 0)),
  CONSTRAINT `ck_fd_renglon` CHECK ((`renglon` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `factura_detalle`
--

LOCK TABLES `factura_detalle` WRITE;
/*!40000 ALTER TABLE `factura_detalle` DISABLE KEYS */;
INSERT INTO `factura_detalle` (`factura_id`, `renglon`, `descripcion`, `cantidad`, `precio_unitario`, `descuento`) VALUES (1,1,'Consulta ficticia A',1.00,500.00,50.00),(1,2,'Estudio ficticio de laboratorio A',1.00,300.00,0.00),(1,3,'Unidades ficticias A',8.00,12.50,0.00),(2,1,'Consulta ficticia B',1.00,600.00,0.00),(2,2,'Servicio ficticio de imagen programado',1.00,200.00,0.00),(3,1,'Consulta ficticia de ingreso A',1.00,450.00,0.00),(3,2,'Dos unidades ficticias de estancia',2.00,300.00,0.00),(3,3,'Procedimiento ficticio C',1.00,150.00,0.00),(4,1,'Consulta ficticia de ingreso B',1.00,450.00,0.00),(4,2,'Unidad ficticia de estancia',1.00,300.00,0.00),(5,1,'Consulta de demostracion 6',1.00,350.00,0.00),(5,2,'Servicio ficticio de procedimiento',1.00,125.00,0.00),(6,1,'Consulta de demostracion 7',1.00,400.00,0.00),(6,2,'Servicio ficticio de procedimiento',1.00,150.00,0.00),(7,1,'Consulta de demostracion 8',1.00,450.00,0.00),(7,2,'Servicio ficticio de procedimiento',1.00,175.00,0.00),(8,1,'Consulta de demostracion 9',1.00,500.00,0.00),(8,2,'Servicio ficticio de procedimiento',1.00,200.00,0.00),(9,1,'Consulta de demostracion 10',1.00,550.00,0.00),(9,2,'Servicio ficticio de procedimiento',1.00,125.00,0.00),(10,1,'Consulta de demostracion 11',1.00,600.00,0.00),(10,2,'Servicio ficticio de procedimiento',1.00,150.00,0.00),(11,1,'Consulta de demostracion 12',1.00,350.00,0.00),(11,2,'Servicio ficticio de procedimiento',1.00,175.00,0.00),(12,1,'Consulta de demostracion 13',1.00,400.00,0.00),(12,2,'Servicio ficticio de procedimiento',1.00,200.00,0.00),(13,1,'Consulta de demostracion 14',1.00,450.00,0.00),(13,2,'Servicio ficticio de procedimiento',1.00,125.00,0.00),(14,1,'Consulta de demostracion 15',1.00,500.00,0.00),(14,2,'Servicio ficticio de procedimiento',1.00,150.00,0.00),(15,1,'Consulta de demostracion 16',1.00,550.00,0.00),(15,2,'Servicio ficticio de procedimiento',1.00,175.00,0.00),(16,1,'Consulta de demostracion 17',1.00,600.00,0.00),(16,2,'Servicio ficticio de procedimiento',1.00,200.00,0.00),(17,1,'Consulta de demostracion 18',1.00,350.00,0.00),(17,2,'Servicio ficticio de procedimiento',1.00,125.00,0.00),(18,1,'Consulta de demostracion 19',1.00,400.00,0.00),(18,2,'Servicio ficticio de procedimiento',1.00,150.00,0.00),(19,1,'Consulta de demostracion 20',1.00,450.00,0.00),(19,2,'Servicio ficticio de procedimiento',1.00,175.00,0.00),(20,1,'Consulta de demostracion 21',1.00,500.00,0.00),(20,2,'Servicio ficticio de procedimiento',1.00,200.00,0.00),(21,1,'Consulta de demostracion 22',1.00,550.00,0.00),(21,2,'Servicio ficticio de procedimiento',1.00,125.00,0.00),(22,1,'Consulta de demostracion 23',1.00,600.00,0.00),(22,2,'Servicio ficticio de procedimiento',1.00,150.00,0.00),(23,1,'Consulta de demostracion 24',1.00,350.00,0.00),(23,2,'Servicio ficticio de procedimiento',1.00,175.00,0.00),(24,1,'Consulta de demostracion 25',1.00,400.00,0.00),(24,2,'Servicio ficticio de procedimiento',1.00,200.00,0.00),(25,1,'Consulta de demostracion 26',1.00,450.00,0.00),(25,2,'Servicio ficticio de procedimiento',1.00,125.00,0.00),(26,1,'Consulta de demostracion 27',1.00,500.00,0.00),(26,2,'Servicio ficticio de procedimiento',1.00,150.00,0.00),(27,1,'Consulta de demostracion 28',1.00,550.00,0.00),(27,2,'Servicio ficticio de procedimiento',1.00,175.00,0.00),(28,1,'Consulta de demostracion 29',1.00,600.00,0.00),(28,2,'Servicio ficticio de procedimiento',1.00,200.00,0.00),(29,1,'Consulta de demostracion 30',1.00,350.00,0.00),(29,2,'Servicio ficticio de procedimiento',1.00,125.00,0.00);
/*!40000 ALTER TABLE `factura_detalle` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_factura_detalle_insert` BEFORE INSERT ON `factura_detalle` FOR EACH ROW BEGIN
  IF NOT EXISTS (SELECT 1 FROM facturas WHERE factura_id = NEW.factura_id AND estado = 'ABIERTA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo puede agregar conceptos a una factura ABIERTA';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_factura_detalle_update` BEFORE UPDATE ON `factura_detalle` FOR EACH ROW BEGIN
  IF NOT EXISTS (SELECT 1 FROM facturas WHERE factura_id = OLD.factura_id AND estado = 'ABIERTA')
     OR NOT EXISTS (SELECT 1 FROM facturas WHERE factura_id = NEW.factura_id AND estado = 'ABIERTA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los conceptos de una factura emitida son inmutables';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_factura_detalle_delete` BEFORE DELETE ON `factura_detalle` FOR EACH ROW BEGIN
  IF NOT EXISTS (SELECT 1 FROM facturas WHERE factura_id = OLD.factura_id AND estado = 'ABIERTA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los conceptos de una factura emitida son inmutables';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `facturas`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `facturas` (
  `factura_id` int unsigned NOT NULL AUTO_INCREMENT,
  `folio` varchar(40) NOT NULL,
  `paciente_id` int unsigned NOT NULL,
  `poliza_id` int unsigned DEFAULT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `estado` enum('ABIERTA','EMITIDA','ANULADA') NOT NULL DEFAULT 'ABIERTA',
  PRIMARY KEY (`factura_id`),
  UNIQUE KEY `folio` (`folio`),
  KEY `fk_factura_paciente` (`paciente_id`),
  KEY `fk_factura_poliza` (`poliza_id`,`paciente_id`),
  CONSTRAINT `fk_factura_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`paciente_id`),
  CONSTRAINT `fk_factura_poliza` FOREIGN KEY (`poliza_id`, `paciente_id`) REFERENCES `polizas` (`poliza_id`, `paciente_id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `facturas`
--

LOCK TABLES `facturas` WRITE;
/*!40000 ALTER TABLE `facturas` DISABLE KEYS */;
INSERT INTO `facturas` VALUES (1,'FAC-DEMO-001',1,1,'2026-10-06 13:00:00','EMITIDA'),(2,'FAC-DEMO-002',2,2,'2026-10-07 12:00:00','EMITIDA'),(3,'FAC-DEMO-003',3,NULL,'2026-10-09 12:30:00','EMITIDA'),(4,'FAC-DEMO-004',5,3,'2026-10-10 09:00:00','ABIERTA'),(5,'FAC-DEMO-005',6,4,'2026-10-01 13:05:00','EMITIDA'),(6,'FAC-DEMO-006',7,5,'2026-10-01 13:50:00','EMITIDA'),(7,'FAC-DEMO-007',8,6,'2026-10-01 14:35:00','EMITIDA'),(8,'FAC-DEMO-008',9,7,'2026-10-01 15:20:00','EMITIDA'),(9,'FAC-DEMO-009',10,8,'2026-10-01 16:05:00','EMITIDA'),(10,'FAC-DEMO-010',11,9,'2026-10-02 13:05:00','EMITIDA'),(11,'FAC-DEMO-011',12,10,'2026-10-02 13:50:00','EMITIDA'),(12,'FAC-DEMO-012',13,11,'2026-10-02 14:35:00','EMITIDA'),(13,'FAC-DEMO-013',14,12,'2026-10-02 15:20:00','EMITIDA'),(14,'FAC-DEMO-014',15,13,'2026-10-02 16:05:00','EMITIDA'),(15,'FAC-DEMO-015',16,14,'2026-10-03 13:05:00','EMITIDA'),(16,'FAC-DEMO-016',17,15,'2026-10-03 13:50:00','EMITIDA'),(17,'FAC-DEMO-017',18,16,'2026-10-03 14:35:00','EMITIDA'),(18,'FAC-DEMO-018',19,17,'2026-10-03 15:20:00','EMITIDA'),(19,'FAC-DEMO-019',20,18,'2026-10-03 16:05:00','EMITIDA'),(20,'FAC-DEMO-020',21,NULL,'2026-10-04 13:05:00','EMITIDA'),(21,'FAC-DEMO-021',22,NULL,'2026-10-04 13:50:00','EMITIDA'),(22,'FAC-DEMO-022',23,NULL,'2026-10-04 14:35:00','EMITIDA'),(23,'FAC-DEMO-023',24,NULL,'2026-10-04 15:20:00','EMITIDA'),(24,'FAC-DEMO-024',25,NULL,'2026-10-04 16:05:00','EMITIDA'),(25,'FAC-DEMO-025',26,NULL,'2026-10-05 13:05:00','ABIERTA'),(26,'FAC-DEMO-026',27,NULL,'2026-10-05 13:50:00','ABIERTA'),(27,'FAC-DEMO-027',28,NULL,'2026-10-05 14:35:00','ABIERTA'),(28,'FAC-DEMO-028',29,NULL,'2026-10-05 15:20:00','ABIERTA'),(29,'FAC-DEMO-029',30,NULL,'2026-10-05 16:05:00','ABIERTA');
/*!40000 ALTER TABLE `facturas` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_factura_insert` BEFORE INSERT ON `facturas` FOR EACH ROW BEGIN
  IF NEW.estado <> 'ABIERTA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Toda factura debe crearse ABIERTA y emitirse despues de sus conceptos';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_factura_estado` BEFORE UPDATE ON `facturas` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `habitaciones`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `habitaciones` (
  `habitacion_id` int unsigned NOT NULL AUTO_INCREMENT,
  `departamento_id` int unsigned NOT NULL,
  `codigo` varchar(30) NOT NULL,
  `edificio` varchar(50) NOT NULL,
  `piso` smallint NOT NULL,
  `tipo` enum('GENERAL','PRIVADA','UCI','URGENCIAS') NOT NULL,
  PRIMARY KEY (`habitacion_id`),
  UNIQUE KEY `codigo` (`codigo`),
  KEY `fk_habitacion_departamento` (`departamento_id`),
  CONSTRAINT `fk_habitacion_departamento` FOREIGN KEY (`departamento_id`) REFERENCES `departamentos` (`departamento_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `habitaciones`
--

LOCK TABLES `habitaciones` WRITE;
/*!40000 ALTER TABLE `habitaciones` DISABLE KEYS */;
INSERT INTO `habitaciones` VALUES (1,2,'HAB-DEMO-101','Edificio de prueba A',1,'GENERAL'),(2,2,'HAB-DEMO-102','Edificio de prueba A',1,'PRIVADA'),(3,2,'HAB-DEMO-201','Edificio de prueba A',2,'UCI'),(4,2,'HAB-DEMO-001','Edificio de prueba B',0,'URGENCIAS'),(5,2,'HAB-DEMO-005','Edificio de prueba C',2,'GENERAL'),(6,2,'HAB-DEMO-006','Edificio de prueba C',2,'PRIVADA'),(7,2,'HAB-DEMO-007','Edificio de prueba C',2,'UCI'),(8,2,'HAB-DEMO-008','Edificio de prueba C',3,'GENERAL'),(9,2,'HAB-DEMO-009','Edificio de prueba C',3,'URGENCIAS');
/*!40000 ALTER TABLE `habitaciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hospitalizaciones`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hospitalizaciones` (
  `hospitalizacion_id` int unsigned NOT NULL AUTO_INCREMENT,
  `consulta_ingreso_id` int unsigned NOT NULL,
  `paciente_id` int unsigned NOT NULL,
  `medico_responsable_id` int unsigned NOT NULL,
  `fecha_ingreso` datetime NOT NULL,
  `fecha_alta` datetime DEFAULT NULL,
  `motivo` varchar(250) NOT NULL,
  `resumen_alta` text,
  `paciente_internado` int unsigned GENERATED ALWAYS AS ((case when (`fecha_alta` is null) then `paciente_id` end)) STORED,
  PRIMARY KEY (`hospitalizacion_id`),
  UNIQUE KEY `consulta_ingreso_id` (`consulta_ingreso_id`),
  UNIQUE KEY `paciente_internado` (`paciente_internado`),
  KEY `fk_hosp_consulta` (`consulta_ingreso_id`,`paciente_id`),
  KEY `fk_hosp_paciente` (`paciente_id`),
  KEY `fk_hosp_medico` (`medico_responsable_id`),
  CONSTRAINT `fk_hosp_consulta` FOREIGN KEY (`consulta_ingreso_id`, `paciente_id`) REFERENCES `consultas` (`consulta_id`, `paciente_id`),
  CONSTRAINT `fk_hosp_medico` FOREIGN KEY (`medico_responsable_id`) REFERENCES `medicos` (`medico_id`),
  CONSTRAINT `fk_hosp_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`paciente_id`),
  CONSTRAINT `ck_hosp_fechas` CHECK (((`fecha_alta` is null) or (`fecha_alta` >= `fecha_ingreso`)))
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hospitalizaciones`
--

LOCK TABLES `hospitalizaciones` WRITE;
/*!40000 ALTER TABLE `hospitalizaciones` DISABLE KEYS */;
INSERT INTO `hospitalizaciones` (`hospitalizacion_id`, `consulta_ingreso_id`, `paciente_id`, `medico_responsable_id`, `fecha_ingreso`, `fecha_alta`, `motivo`, `resumen_alta`) VALUES (1,3,3,3,'2026-10-08 12:00:00','2026-10-09 12:00:00','Hospitalizacion ficticia A','Cierre de caso academico sin indicaciones clinicas.'),(2,5,5,2,'2026-10-09 15:00:00',NULL,'Hospitalizacion ficticia B',NULL),(3,6,6,9,'2026-10-01 10:05:00',NULL,'Estancia del caso ficticio 6',NULL),(4,7,7,10,'2026-10-01 10:50:00',NULL,'Estancia del caso ficticio 7',NULL),(5,8,8,11,'2026-10-01 11:35:00',NULL,'Estancia del caso ficticio 8',NULL),(6,9,9,12,'2026-10-01 12:20:00',NULL,'Estancia del caso ficticio 9',NULL),(7,10,10,13,'2026-10-01 13:05:00',NULL,'Estancia del caso ficticio 10',NULL),(8,11,11,14,'2026-10-02 10:05:00',NULL,'Estancia del caso ficticio 11',NULL),(9,12,12,15,'2026-10-02 10:50:00','2026-10-03 10:50:00','Estancia del caso ficticio 12','Cierre simulado del caso'),(10,13,13,16,'2026-10-02 11:35:00','2026-10-03 11:35:00','Estancia del caso ficticio 13','Cierre simulado del caso'),(11,14,14,17,'2026-10-02 12:20:00','2026-10-03 12:20:00','Estancia del caso ficticio 14','Cierre simulado del caso');
/*!40000 ALTER TABLE `hospitalizaciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lotes_medicamento`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lotes_medicamento` (
  `lote_id` int unsigned NOT NULL AUTO_INCREMENT,
  `medicamento_id` int unsigned NOT NULL,
  `proveedor_id` int unsigned NOT NULL,
  `numero_lote` varchar(50) NOT NULL,
  `fecha_recepcion` date NOT NULL,
  `fecha_caducidad` date NOT NULL,
  `costo_unitario` decimal(12,2) NOT NULL,
  PRIMARY KEY (`lote_id`),
  UNIQUE KEY `medicamento_id` (`medicamento_id`,`proveedor_id`,`numero_lote`),
  UNIQUE KEY `lote_id` (`lote_id`,`medicamento_id`),
  KEY `fk_lote_proveedor` (`proveedor_id`),
  CONSTRAINT `fk_lote_medicamento` FOREIGN KEY (`medicamento_id`) REFERENCES `medicamentos` (`medicamento_id`),
  CONSTRAINT `fk_lote_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedores` (`proveedor_id`),
  CONSTRAINT `ck_lote_costo` CHECK ((`costo_unitario` >= 0)),
  CONSTRAINT `ck_lote_fechas` CHECK ((`fecha_caducidad` >= `fecha_recepcion`))
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lotes_medicamento`
--

LOCK TABLES `lotes_medicamento` WRITE;
/*!40000 ALTER TABLE `lotes_medicamento` DISABLE KEYS */;
INSERT INTO `lotes_medicamento` VALUES (1,1,1,'LOTE-DEMO-A1','2026-09-30','2027-06-30',12.50),(2,2,1,'LOTE-DEMO-B1','2026-09-30','2027-09-30',20.00),(3,3,2,'LOTE-DEMO-C1','2026-09-30','2028-01-31',5.00),(4,1,2,'LOTE-DEMO-A2','2026-10-01','2027-12-31',13.00),(5,4,3,'LOTE-DEMO-04','2026-09-01','2028-12-31',7.50),(6,5,4,'LOTE-DEMO-05','2026-09-01','2028-12-31',8.50),(7,6,3,'LOTE-DEMO-06','2026-09-01','2028-12-31',9.50),(8,7,4,'LOTE-DEMO-07','2026-09-01','2028-12-31',10.50),(9,8,3,'LOTE-DEMO-08','2026-09-01','2028-12-31',11.50),(10,9,4,'LOTE-DEMO-09','2026-09-01','2028-12-31',12.50),(11,10,3,'LOTE-DEMO-10','2026-09-01','2028-12-31',13.50),(12,11,4,'LOTE-DEMO-11','2026-09-01','2028-12-31',14.50),(13,12,3,'LOTE-DEMO-12','2026-09-01','2028-12-31',15.50),(14,13,4,'LOTE-DEMO-13','2026-09-01','2028-12-31',16.50),(15,14,3,'LOTE-DEMO-14','2026-09-01','2028-12-31',17.50),(16,15,4,'LOTE-DEMO-15','2026-09-01','2028-12-31',18.50);
/*!40000 ALTER TABLE `lotes_medicamento` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `medicamentos`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `medicamentos` (
  `medicamento_id` int unsigned NOT NULL AUTO_INCREMENT,
  `codigo` varchar(30) NOT NULL,
  `principio_activo` varchar(150) NOT NULL,
  `concentracion` varchar(60) NOT NULL,
  `presentacion` varchar(100) NOT NULL,
  `unidad_inventario` varchar(40) NOT NULL,
  `stock_minimo` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`medicamento_id`),
  UNIQUE KEY `codigo` (`codigo`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `medicamentos`
--

LOCK TABLES `medicamentos` WRITE;
/*!40000 ALTER TABLE `medicamentos` DISABLE KEYS */;
INSERT INTO `medicamentos` VALUES (1,'MED-DEMO-A','Sustancia de prueba A','Valor didactico','Envase ficticio A','unidad de prueba',20),(2,'MED-DEMO-B','Sustancia de prueba B','Valor didactico','Envase ficticio B','unidad de prueba',15),(3,'MED-DEMO-C','Sustancia de prueba C','Valor didactico','Envase ficticio C','unidad de prueba',50),(4,'MED-DEMO-04','Compuesto simulado 04','5 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',15),(5,'MED-DEMO-05','Compuesto simulado 05','10 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',20),(6,'MED-DEMO-06','Compuesto simulado 06','20 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',25),(7,'MED-DEMO-07','Compuesto simulado 07','25 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',30),(8,'MED-DEMO-08','Compuesto simulado 08','5 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',15),(9,'MED-DEMO-09','Compuesto simulado 09','10 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',20),(10,'MED-DEMO-10','Compuesto simulado 10','20 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',25),(11,'MED-DEMO-11','Compuesto simulado 11','25 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',30),(12,'MED-DEMO-12','Compuesto simulado 12','5 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',15),(13,'MED-DEMO-13','Compuesto simulado 13','10 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',20),(14,'MED-DEMO-14','Compuesto simulado 14','20 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',25),(15,'MED-DEMO-15','Compuesto simulado 15','25 mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',30);
/*!40000 ALTER TABLE `medicamentos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `medico_especialidad`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `medico_especialidad` (
  `medico_id` int unsigned NOT NULL,
  `especialidad_id` int unsigned NOT NULL,
  PRIMARY KEY (`medico_id`,`especialidad_id`),
  KEY `fk_me_especialidad` (`especialidad_id`),
  CONSTRAINT `fk_me_especialidad` FOREIGN KEY (`especialidad_id`) REFERENCES `especialidades` (`especialidad_id`),
  CONSTRAINT `fk_me_medico` FOREIGN KEY (`medico_id`) REFERENCES `medicos` (`medico_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `medico_especialidad`
--

LOCK TABLES `medico_especialidad` WRITE;
/*!40000 ALTER TABLE `medico_especialidad` DISABLE KEYS */;
INSERT INTO `medico_especialidad` VALUES (1,1),(3,1),(9,1),(2,2),(1,3),(12,3),(11,4),(13,5),(14,6),(15,7),(16,8),(17,9),(18,10),(19,11),(20,12),(21,13),(22,14),(23,15),(10,16);
/*!40000 ALTER TABLE `medico_especialidad` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `medicos`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `medicos` (
  `medico_id` int unsigned NOT NULL,
  `cedula_profesional` varchar(50) NOT NULL,
  PRIMARY KEY (`medico_id`),
  UNIQUE KEY `cedula_profesional` (`cedula_profesional`),
  CONSTRAINT `fk_medico_personal` FOREIGN KEY (`medico_id`) REFERENCES `personal` (`personal_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `medicos`
--

LOCK TABLES `medicos` WRITE;
/*!40000 ALTER TABLE `medicos` DISABLE KEYS */;
INSERT INTO `medicos` VALUES (1,'CEDULA-FICTICIA-001'),(2,'CEDULA-FICTICIA-002'),(3,'CEDULA-FICTICIA-003'),(9,'CP-1001'),(10,'CP-1002'),(11,'CP-1003'),(12,'CP-1004'),(13,'CP-1005'),(14,'CP-1006'),(15,'CP-1007'),(16,'CP-1008'),(17,'CP-1009'),(18,'CP-1010'),(19,'CP-1011'),(20,'CP-1012'),(21,'CP-1013'),(22,'CP-1014'),(23,'CP-1015');
/*!40000 ALTER TABLE `medicos` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_medico_insert` BEFORE INSERT ON `medicos` FOR EACH ROW BEGIN
  IF NOT EXISTS (SELECT 1 FROM personal WHERE personal_id = NEW.medico_id AND puesto = 'MEDICO' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El medico debe ser personal MEDICO activo';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `movimientos_inventario`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `movimientos_inventario` (
  `movimiento_id` int unsigned NOT NULL AUTO_INCREMENT,
  `lote_id` int unsigned NOT NULL,
  `dispensacion_detalle_id` int unsigned DEFAULT NULL,
  `personal_id` int unsigned NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tipo` enum('ENTRADA','SALIDA','AJUSTE') NOT NULL,
  `cantidad` int NOT NULL,
  `motivo` varchar(250) NOT NULL,
  PRIMARY KEY (`movimiento_id`),
  UNIQUE KEY `dispensacion_detalle_id` (`dispensacion_detalle_id`),
  KEY `ix_mov_lote` (`lote_id`,`movimiento_id`),
  KEY `fk_mov_personal` (`personal_id`),
  KEY `fk_mov_disp` (`dispensacion_detalle_id`,`lote_id`),
  CONSTRAINT `fk_mov_disp` FOREIGN KEY (`dispensacion_detalle_id`, `lote_id`) REFERENCES `dispensacion_detalle` (`dispensacion_detalle_id`, `lote_id`),
  CONSTRAINT `fk_mov_lote` FOREIGN KEY (`lote_id`) REFERENCES `lotes_medicamento` (`lote_id`),
  CONSTRAINT `fk_mov_personal` FOREIGN KEY (`personal_id`) REFERENCES `personal` (`personal_id`),
  CONSTRAINT `ck_mov_disp_tipo` CHECK (((`dispensacion_detalle_id` is null) or (`tipo` = _utf8mb4'SALIDA'))),
  CONSTRAINT `ck_mov_signo` CHECK ((((`tipo` = _utf8mb4'ENTRADA') and (`cantidad` > 0)) or ((`tipo` = _utf8mb4'SALIDA') and (`cantidad` < 0)) or ((`tipo` = _utf8mb4'AJUSTE') and (`cantidad` <> 0))))
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `movimientos_inventario`
--

LOCK TABLES `movimientos_inventario` WRITE;
/*!40000 ALTER TABLE `movimientos_inventario` DISABLE KEYS */;
INSERT INTO `movimientos_inventario` VALUES (1,1,NULL,6,'2026-09-30 12:00:00','ENTRADA',100,'Recepcion ficticia A1'),(2,2,NULL,6,'2026-09-30 12:05:00','ENTRADA',60,'Recepcion ficticia B1'),(3,3,NULL,6,'2026-09-30 12:10:00','ENTRADA',40,'Recepcion ficticia C1'),(4,4,NULL,6,'2026-10-01 12:00:00','ENTRADA',50,'Recepcion ficticia A2'),(5,1,1,6,'2026-10-06 10:00:00','SALIDA',-8,'Entrega ficticia de receta 1, renglon 1'),(6,2,2,6,'2026-10-06 10:00:00','SALIDA',-3,'Entrega ficticia de receta 1, renglon 2'),(7,5,NULL,6,'2026-09-01 12:00:00','ENTRADA',240,'Recepcion del lote ficticio 4'),(8,6,NULL,6,'2026-09-01 12:00:00','ENTRADA',250,'Recepcion del lote ficticio 5'),(9,7,NULL,6,'2026-09-01 12:00:00','ENTRADA',260,'Recepcion del lote ficticio 6'),(10,8,NULL,6,'2026-09-01 12:00:00','ENTRADA',270,'Recepcion del lote ficticio 7'),(11,9,NULL,6,'2026-09-01 12:00:00','ENTRADA',280,'Recepcion del lote ficticio 8'),(12,10,NULL,6,'2026-09-01 12:00:00','ENTRADA',290,'Recepcion del lote ficticio 9'),(13,11,NULL,6,'2026-09-01 12:00:00','ENTRADA',300,'Recepcion del lote ficticio 10'),(14,12,NULL,6,'2026-09-01 12:00:00','ENTRADA',310,'Recepcion del lote ficticio 11'),(15,13,NULL,6,'2026-09-01 12:00:00','ENTRADA',320,'Recepcion del lote ficticio 12'),(16,14,NULL,6,'2026-09-01 12:00:00','ENTRADA',330,'Recepcion del lote ficticio 13'),(17,15,NULL,6,'2026-09-01 12:00:00','ENTRADA',340,'Recepcion del lote ficticio 14'),(18,16,NULL,6,'2026-09-01 12:00:00','ENTRADA',350,'Recepcion del lote ficticio 15'),(19,5,3,6,'2026-10-01 10:05:00','SALIDA',-9,'Entrega simulada de receta 4, renglon 1'),(20,9,4,6,'2026-10-01 10:05:00','SALIDA',-6,'Entrega simulada de receta 4, renglon 2'),(21,6,5,6,'2026-10-01 10:50:00','SALIDA',-8,'Entrega simulada de receta 5, renglon 1'),(22,10,6,6,'2026-10-01 10:50:00','SALIDA',-4,'Entrega simulada de receta 5, renglon 2'),(23,7,7,6,'2026-10-01 11:35:00','SALIDA',-5,'Entrega simulada de receta 6, renglon 1'),(24,11,8,6,'2026-10-01 11:35:00','SALIDA',-20,'Entrega simulada de receta 6, renglon 2'),(25,8,9,6,'2026-10-01 12:20:00','SALIDA',-24,'Entrega simulada de receta 7, renglon 1'),(26,12,10,6,'2026-10-01 12:20:00','SALIDA',-18,'Entrega simulada de receta 7, renglon 2'),(27,9,11,6,'2026-10-01 13:05:00','SALIDA',-21,'Entrega simulada de receta 8, renglon 1'),(28,13,12,6,'2026-10-01 13:05:00','SALIDA',-14,'Entrega simulada de receta 8, renglon 2'),(29,10,13,6,'2026-10-02 10:05:00','SALIDA',-3,'Entrega simulada de receta 9, renglon 1'),(30,14,14,6,'2026-10-02 10:05:00','SALIDA',-1,'Entrega simulada de receta 9, renglon 2'),(31,11,15,6,'2026-10-02 10:50:00','SALIDA',-2,'Entrega simulada de receta 10, renglon 1'),(32,15,16,6,'2026-10-02 10:50:00','SALIDA',-8,'Entrega simulada de receta 10, renglon 2'),(33,12,17,6,'2026-10-02 11:35:00','SALIDA',-10,'Entrega simulada de receta 11, renglon 1'),(34,16,18,6,'2026-10-02 11:35:00','SALIDA',-7,'Entrega simulada de receta 11, renglon 2'),(35,13,19,6,'2026-10-02 12:20:00','SALIDA',-9,'Entrega simulada de receta 12, renglon 1'),(36,5,20,6,'2026-10-02 12:20:00','SALIDA',-6,'Entrega simulada de receta 12, renglon 2'),(37,14,21,6,'2026-10-02 13:05:00','SALIDA',-7,'Entrega simulada de receta 13, renglon 1'),(38,6,22,6,'2026-10-02 13:05:00','SALIDA',-3,'Entrega simulada de receta 13, renglon 2');
/*!40000 ALTER TABLE `movimientos_inventario` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_mov_insert` BEFORE INSERT ON `movimientos_inventario` FOR EACH ROW BEGIN
  IF NOT EXISTS (SELECT 1 FROM personal WHERE personal_id = NEW.personal_id AND puesto = 'FARMACIA' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El movimiento requiere personal de FARMACIA activo';
  END IF;
  IF NEW.dispensacion_detalle_id IS NOT NULL AND NOT EXISTS
    (SELECT 1 FROM dispensacion_detalle WHERE dispensacion_detalle_id = NEW.dispensacion_detalle_id
     AND lote_id = NEW.lote_id AND NEW.cantidad = -CAST(cantidad AS SIGNED)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La salida debe coincidir con la cantidad entregada';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_mov_update` BEFORE UPDATE ON `movimientos_inventario` FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inventario es inmutable: registre un movimiento de ajuste';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_mov_delete` BEFORE DELETE ON `movimientos_inventario` FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inventario es inmutable: registre un movimiento de ajuste';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `notas_enfermeria`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notas_enfermeria` (
  `nota_id` int unsigned NOT NULL AUTO_INCREMENT,
  `hospitalizacion_id` int unsigned NOT NULL,
  `personal_id` int unsigned NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `observacion` text NOT NULL,
  PRIMARY KEY (`nota_id`),
  KEY `fk_nota_hosp` (`hospitalizacion_id`),
  KEY `fk_nota_personal` (`personal_id`),
  CONSTRAINT `fk_nota_hosp` FOREIGN KEY (`hospitalizacion_id`) REFERENCES `hospitalizaciones` (`hospitalizacion_id`),
  CONSTRAINT `fk_nota_personal` FOREIGN KEY (`personal_id`) REFERENCES `personal` (`personal_id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notas_enfermeria`
--

LOCK TABLES `notas_enfermeria` WRITE;
/*!40000 ALTER TABLE `notas_enfermeria` DISABLE KEYS */;
INSERT INTO `notas_enfermeria` VALUES (1,1,4,'2026-10-08 12:30:00','Observacion ficticia de ingreso para prueba de registro.'),(2,1,5,'2026-10-08 18:30:00','Observacion ficticia posterior al traslado.'),(3,2,4,'2026-10-09 15:30:00','Observacion ficticia de un caso abierto.'),(4,3,24,'2026-10-01 10:35:00','Nota simulada 1 de la estancia 3; dato de demostracion.'),(5,3,25,'2026-10-01 12:35:00','Nota simulada 2 de la estancia 3; dato de demostracion.'),(6,4,24,'2026-10-01 11:20:00','Nota simulada 1 de la estancia 4; dato de demostracion.'),(7,4,25,'2026-10-01 13:20:00','Nota simulada 2 de la estancia 4; dato de demostracion.'),(8,5,24,'2026-10-01 12:05:00','Nota simulada 1 de la estancia 5; dato de demostracion.'),(9,5,25,'2026-10-01 14:05:00','Nota simulada 2 de la estancia 5; dato de demostracion.'),(10,6,24,'2026-10-01 12:50:00','Nota simulada 1 de la estancia 6; dato de demostracion.'),(11,6,25,'2026-10-01 14:50:00','Nota simulada 2 de la estancia 6; dato de demostracion.'),(12,7,24,'2026-10-01 13:35:00','Nota simulada 1 de la estancia 7; dato de demostracion.'),(13,7,25,'2026-10-01 15:35:00','Nota simulada 2 de la estancia 7; dato de demostracion.'),(14,8,24,'2026-10-02 10:35:00','Nota simulada 1 de la estancia 8; dato de demostracion.'),(15,8,25,'2026-10-02 12:35:00','Nota simulada 2 de la estancia 8; dato de demostracion.'),(16,9,24,'2026-10-02 11:20:00','Nota simulada 1 de la estancia 9; dato de demostracion.'),(17,9,25,'2026-10-02 13:20:00','Nota simulada 2 de la estancia 9; dato de demostracion.'),(18,10,24,'2026-10-02 12:05:00','Nota simulada 1 de la estancia 10; dato de demostracion.'),(19,10,25,'2026-10-02 14:05:00','Nota simulada 2 de la estancia 10; dato de demostracion.'),(20,11,24,'2026-10-02 12:50:00','Nota simulada 1 de la estancia 11; dato de demostracion.'),(21,11,25,'2026-10-02 14:50:00','Nota simulada 2 de la estancia 11; dato de demostracion.');
/*!40000 ALTER TABLE `notas_enfermeria` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_nota_insert` BEFORE INSERT ON `notas_enfermeria` FOR EACH ROW BEGIN
  IF NOT EXISTS (SELECT 1 FROM personal WHERE personal_id = NEW.personal_id AND puesto = 'ENFERMERIA' AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La nota requiere personal de ENFERMERIA activo';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM hospitalizaciones WHERE hospitalizacion_id = NEW.hospitalizacion_id
                 AND NEW.fecha >= fecha_ingreso AND (fecha_alta IS NULL OR NEW.fecha <= fecha_alta)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La nota debe estar dentro de la hospitalizacion';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `ordenes_procedimiento`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ordenes_procedimiento` (
  `orden_id` int unsigned NOT NULL AUTO_INCREMENT,
  `consulta_id` int unsigned NOT NULL,
  `procedimiento_id` int unsigned NOT NULL,
  `fecha_solicitud` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_programada` datetime DEFAULT NULL,
  `estado` enum('SOLICITADA','PROGRAMADA','REALIZADA','CANCELADA') NOT NULL DEFAULT 'SOLICITADA',
  `indicaciones` text,
  PRIMARY KEY (`orden_id`),
  KEY `fk_orden_consulta` (`consulta_id`),
  KEY `fk_orden_procedimiento` (`procedimiento_id`),
  CONSTRAINT `fk_orden_consulta` FOREIGN KEY (`consulta_id`) REFERENCES `consultas` (`consulta_id`),
  CONSTRAINT `fk_orden_procedimiento` FOREIGN KEY (`procedimiento_id`) REFERENCES `procedimientos` (`procedimiento_id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ordenes_procedimiento`
--

LOCK TABLES `ordenes_procedimiento` WRITE;
/*!40000 ALTER TABLE `ordenes_procedimiento` DISABLE KEYS */;
INSERT INTO `ordenes_procedimiento` VALUES (1,1,1,'2026-10-06 09:20:00','2026-10-06 11:00:00','REALIZADA','Indicacion ficticia sin uso clinico.'),(2,2,2,'2026-10-07 10:20:00','2026-10-13 11:00:00','PROGRAMADA','Indicacion ficticia sin uso clinico.'),(3,3,3,'2026-10-08 11:30:00','2026-10-08 13:00:00','REALIZADA','Indicacion ficticia sin uso clinico.'),(4,5,4,'2026-10-09 14:30:00',NULL,'SOLICITADA','Indicacion ficticia sin uso clinico.'),(5,6,5,'2026-10-01 09:25:00','2026-10-01 11:25:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(6,7,6,'2026-10-01 10:10:00','2026-10-01 12:10:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(7,8,7,'2026-10-01 10:55:00','2026-10-01 12:55:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(8,9,8,'2026-10-01 11:40:00','2026-10-01 13:40:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(9,10,5,'2026-10-01 12:25:00','2026-10-01 14:25:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(10,11,6,'2026-10-02 09:25:00','2026-10-02 11:25:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(11,12,7,'2026-10-02 10:10:00','2026-10-02 12:10:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(12,13,8,'2026-10-02 10:55:00','2026-10-02 12:55:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(13,14,5,'2026-10-02 11:40:00','2026-10-02 13:40:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(14,15,6,'2026-10-02 12:25:00','2026-10-02 14:25:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(15,16,7,'2026-10-03 09:25:00','2026-10-03 11:25:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(16,17,8,'2026-10-03 10:10:00','2026-10-03 12:10:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(17,18,5,'2026-10-03 10:55:00','2026-10-03 12:55:00','REALIZADA','Indicacion inventada para probar el flujo del sistema.'),(18,19,6,'2026-10-03 11:40:00','2026-10-03 13:40:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.'),(19,20,7,'2026-10-03 12:25:00','2026-10-03 14:25:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.'),(20,21,8,'2026-10-04 09:25:00','2026-10-04 11:25:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.'),(21,22,5,'2026-10-04 10:10:00','2026-10-04 12:10:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.'),(22,23,6,'2026-10-04 10:55:00','2026-10-04 12:55:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.'),(23,24,7,'2026-10-04 11:40:00','2026-10-04 13:40:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.'),(24,25,8,'2026-10-04 12:25:00','2026-10-04 14:25:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.'),(25,26,5,'2026-10-05 09:25:00','2026-10-05 11:25:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.'),(26,27,6,'2026-10-05 10:10:00','2026-10-05 12:10:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.'),(27,28,7,'2026-10-05 10:55:00','2026-10-05 12:55:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.'),(28,29,8,'2026-10-05 11:40:00','2026-10-05 13:40:00','CANCELADA','Indicacion inventada para probar el flujo del sistema.'),(29,30,5,'2026-10-05 12:25:00','2026-10-05 14:25:00','PROGRAMADA','Indicacion inventada para probar el flujo del sistema.');
/*!40000 ALTER TABLE `ordenes_procedimiento` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_orden_update` BEFORE UPDATE ON `ordenes_procedimiento` FOR EACH ROW BEGIN
  IF NEW.consulta_id <> OLD.consulta_id OR NEW.procedimiento_id <> OLD.procedimiento_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La identidad de una orden registrada es inmutable';
  END IF;
  IF NEW.estado <> 'REALIZADA' AND EXISTS (SELECT 1 FROM resultados_procedimiento WHERE orden_id = OLD.orden_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una orden con resultado debe permanecer REALIZADA';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `pacientes`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pacientes` (
  `paciente_id` int unsigned NOT NULL AUTO_INCREMENT,
  `expediente_clinico` varchar(30) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido_paterno` varchar(100) NOT NULL,
  `apellido_materno` varchar(100) DEFAULT NULL,
  `fecha_nacimiento` date NOT NULL,
  `sexo` enum('F','M','NO_ESPECIFICADO') NOT NULL DEFAULT 'NO_ESPECIFICADO',
  `telefono` varchar(25) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `domicilio` varchar(250) DEFAULT NULL,
  `fecha_registro` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`paciente_id`),
  UNIQUE KEY `expediente_clinico` (`expediente_clinico`),
  CONSTRAINT `ck_paciente_activo` CHECK ((`activo` in (0,1))),
  CONSTRAINT `ck_paciente_nacimiento` CHECK ((`fecha_nacimiento` <= cast(`fecha_registro` as date)))
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pacientes`
--

LOCK TABLES `pacientes` WRITE;
/*!40000 ALTER TABLE `pacientes` DISABLE KEYS */;
INSERT INTO `pacientes` VALUES (1,'EXP-DEMO-001','Paciente Uno','Ejemplo','Ficticio','1998-02-15','F','TEL-PAC-DEMO-001','paciente.uno@example.invalid','Domicilio ficticio 1','2026-09-01 09:00:00',1),(2,'EXP-DEMO-002','Paciente Dos','Ejemplo','Ficticio','1980-06-10','M','TEL-PAC-DEMO-002','paciente.dos@example.invalid','Domicilio ficticio 2','2026-09-01 09:10:00',1),(3,'EXP-DEMO-003','Paciente Tres','Ejemplo','Ficticio','2001-11-20','NO_ESPECIFICADO','TEL-PAC-DEMO-003','paciente.tres@example.invalid','Domicilio ficticio 3','2026-09-02 09:00:00',1),(4,'EXP-DEMO-004','Paciente Cuatro','Ejemplo','Ficticio','2014-03-12','F','TEL-PAC-DEMO-004','paciente.cuatro@example.invalid','Domicilio ficticio 4','2026-09-02 09:10:00',1),(5,'EXP-DEMO-005','Paciente Cinco','Ejemplo','Ficticio','1972-12-05','M','TEL-PAC-DEMO-005','paciente.cinco@example.invalid','Domicilio ficticio 5','2026-09-03 09:00:00',1),(6,'EXP-DEMO-006','Andrea','Perez','Simulado','1970-01-01','F','TEL-PAC-DEMO-006','paciente.6@example.invalid','Domicilio ficticio 6','2026-09-15 09:00:00',1),(7,'EXP-DEMO-007','Diego','Sanchez','Simulado','1973-02-02','M','TEL-PAC-DEMO-007','paciente.7@example.invalid','Domicilio ficticio 7','2026-09-15 09:00:00',1),(8,'EXP-DEMO-008','Valeria','Romero','Simulado','1976-03-03','F','TEL-PAC-DEMO-008','paciente.8@example.invalid','Domicilio ficticio 8','2026-09-15 09:00:00',1),(9,'EXP-DEMO-009','Mateo','Ortiz','Simulado','1979-04-04','M','TEL-PAC-DEMO-009','paciente.9@example.invalid','Domicilio ficticio 9','2026-09-15 09:00:00',1),(10,'EXP-DEMO-010','Camila','Reyes','Simulado','1982-05-05','F','TEL-PAC-DEMO-010','paciente.10@example.invalid','Domicilio ficticio 10','2026-09-15 09:00:00',1),(11,'EXP-DEMO-011','Sebastian','Cruz','Simulado','1985-06-06','M','TEL-PAC-DEMO-011','paciente.11@example.invalid','Domicilio ficticio 11','2026-09-15 09:00:00',1),(12,'EXP-DEMO-012','Renata','Aguilar','Simulado','1988-07-07','F','TEL-PAC-DEMO-012','paciente.12@example.invalid','Domicilio ficticio 12','2026-09-15 09:00:00',1),(13,'EXP-DEMO-013','Emiliano','Jimenez','Simulado','1991-08-08','M','TEL-PAC-DEMO-013','paciente.13@example.invalid','Domicilio ficticio 13','2026-09-15 09:00:00',1),(14,'EXP-DEMO-014','Paula','Rojas','Simulado','1994-09-09','F','TEL-PAC-DEMO-014','paciente.14@example.invalid','Domicilio ficticio 14','2026-09-15 09:00:00',1),(15,'EXP-DEMO-015','Nicolas','Chavez','Simulado','1997-10-10','M','TEL-PAC-DEMO-015','paciente.15@example.invalid','Domicilio ficticio 15','2026-09-15 09:00:00',1),(16,'EXP-DEMO-016','Fernanda','Molina','Simulado','2000-11-11','F','TEL-PAC-DEMO-016','paciente.16@example.invalid','Domicilio ficticio 16','2026-09-15 09:00:00',1),(17,'EXP-DEMO-017','Alejandro','Silva','Simulado','2003-12-12','M','TEL-PAC-DEMO-017','paciente.17@example.invalid','Domicilio ficticio 17','2026-09-15 09:00:00',1),(18,'EXP-DEMO-018','Regina','Castillo','Simulado','2006-01-13','F','TEL-PAC-DEMO-018','paciente.18@example.invalid','Domicilio ficticio 18','2026-09-15 09:00:00',1),(19,'EXP-DEMO-019','Leonardo','Herrera','Simulado','2009-02-14','M','TEL-PAC-DEMO-019','paciente.19@example.invalid','Domicilio ficticio 19','2026-09-15 09:00:00',1),(20,'EXP-DEMO-020','Daniela','Vazquez','Simulado','2012-03-15','F','TEL-PAC-DEMO-020','paciente.20@example.invalid','Domicilio ficticio 20','2026-09-15 09:00:00',1),(21,'EXP-DEMO-021','Santiago','Navarro','Simulado','1970-04-16','M','TEL-PAC-DEMO-021','paciente.21@example.invalid','Domicilio ficticio 21','2026-09-15 09:00:00',1),(22,'EXP-DEMO-022','Isabella','Acosta','Simulado','1973-05-17','F','TEL-PAC-DEMO-022','paciente.22@example.invalid','Domicilio ficticio 22','2026-09-15 09:00:00',1),(23,'EXP-DEMO-023','Gabriel','Luna','Simulado','1976-06-18','M','TEL-PAC-DEMO-023','paciente.23@example.invalid','Domicilio ficticio 23','2026-09-15 09:00:00',1),(24,'EXP-DEMO-024','Ximena','Salazar','Simulado','1979-07-19','F','TEL-PAC-DEMO-024','paciente.24@example.invalid','Domicilio ficticio 24','2026-09-15 09:00:00',1),(25,'EXP-DEMO-025','Rodrigo','Guerrero','Simulado','1982-08-20','M','TEL-PAC-DEMO-025','paciente.25@example.invalid','Domicilio ficticio 25','2026-09-15 09:00:00',1),(26,'EXP-DEMO-026','Natalia','Campos','Simulado','1985-09-21','F','TEL-PAC-DEMO-026','paciente.26@example.invalid','Domicilio ficticio 26','2026-09-15 09:00:00',1),(27,'EXP-DEMO-027','Mauricio','Delgado','Simulado','1988-10-22','M','TEL-PAC-DEMO-027','paciente.27@example.invalid','Domicilio ficticio 27','2026-09-15 09:00:00',1),(28,'EXP-DEMO-028','Carolina','Paredes','Simulado','1991-11-23','F','TEL-PAC-DEMO-028','paciente.28@example.invalid','Domicilio ficticio 28','2026-09-15 09:00:00',1),(29,'EXP-DEMO-029','Joaquin','Fuentes','Simulado','1994-12-24','M','TEL-PAC-DEMO-029','paciente.29@example.invalid','Domicilio ficticio 29','2026-09-15 09:00:00',1),(30,'EXP-DEMO-030','Adriana','Mejia','Simulado','1997-01-25','F','TEL-PAC-DEMO-030','paciente.30@example.invalid','Domicilio ficticio 30','2026-09-15 09:00:00',1);
/*!40000 ALTER TABLE `pacientes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pagos`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pagos` (
  `pago_id` int unsigned NOT NULL AUTO_INCREMENT,
  `factura_id` int unsigned NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `monto` decimal(14,2) NOT NULL,
  `metodo` enum('EFECTIVO','TARJETA','TRANSFERENCIA','ASEGURADORA') NOT NULL,
  `referencia` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`pago_id`),
  KEY `fk_pago_factura` (`factura_id`),
  CONSTRAINT `fk_pago_factura` FOREIGN KEY (`factura_id`) REFERENCES `facturas` (`factura_id`),
  CONSTRAINT `ck_pago_monto` CHECK ((`monto` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pagos`
--

LOCK TABLES `pagos` WRITE;
/*!40000 ALTER TABLE `pagos` DISABLE KEYS */;
INSERT INTO `pagos` VALUES (1,1,'2026-10-06 13:15:00',200.00,'EFECTIVO','ABONO-DEMO-001'),(2,1,'2026-10-07 09:00:00',300.00,'TRANSFERENCIA','ABONO-DEMO-002'),(3,2,'2026-10-07 12:15:00',800.00,'TARJETA','PAGO-DEMO-003'),(4,3,'2026-10-09 13:00:00',400.00,'EFECTIVO','ABONO-DEMO-004'),(5,5,'2026-10-01 13:20:00',475.00,'EFECTIVO','PAGO-DEMO-005'),(6,6,'2026-10-01 14:05:00',550.00,'TARJETA','PAGO-DEMO-006'),(7,7,'2026-10-01 14:50:00',625.00,'TRANSFERENCIA','PAGO-DEMO-007'),(8,8,'2026-10-01 15:35:00',700.00,'EFECTIVO','PAGO-DEMO-008'),(9,9,'2026-10-01 16:20:00',675.00,'TARJETA','PAGO-DEMO-009'),(10,10,'2026-10-02 13:20:00',150.00,'TRANSFERENCIA','PAGO-DEMO-010'),(11,11,'2026-10-02 14:05:00',150.00,'EFECTIVO','PAGO-DEMO-011'),(12,12,'2026-10-02 14:50:00',150.00,'TARJETA','PAGO-DEMO-012'),(13,13,'2026-10-02 15:35:00',150.00,'TRANSFERENCIA','PAGO-DEMO-013'),(14,14,'2026-10-02 16:20:00',150.00,'EFECTIVO','PAGO-DEMO-014'),(15,15,'2026-10-03 13:20:00',75.00,'TARJETA','PAGO-DEMO-015'),(16,15,'2026-10-03 13:50:00',50.00,'TARJETA','PAGO-DEMO-016'),(17,16,'2026-10-03 14:05:00',75.00,'TRANSFERENCIA','PAGO-DEMO-017'),(18,16,'2026-10-03 14:35:00',50.00,'TRANSFERENCIA','PAGO-DEMO-018'),(19,17,'2026-10-03 14:50:00',75.00,'EFECTIVO','PAGO-DEMO-019'),(20,17,'2026-10-03 15:20:00',50.00,'EFECTIVO','PAGO-DEMO-020'),(21,18,'2026-10-03 15:35:00',75.00,'TARJETA','PAGO-DEMO-021'),(22,18,'2026-10-03 16:05:00',50.00,'TARJETA','PAGO-DEMO-022'),(23,19,'2026-10-03 16:20:00',75.00,'TRANSFERENCIA','PAGO-DEMO-023'),(24,19,'2026-10-03 16:50:00',50.00,'TRANSFERENCIA','PAGO-DEMO-024');
/*!40000 ALTER TABLE `pagos` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_pago_update` BEFORE UPDATE ON `pagos` FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un pago registrado es inmutable en este modelo academico';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_pago_delete` BEFORE DELETE ON `pagos` FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un pago registrado es inmutable en este modelo academico';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `personal`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `personal` (
  `personal_id` int unsigned NOT NULL AUTO_INCREMENT,
  `numero_empleado` varchar(25) NOT NULL,
  `departamento_id` int unsigned NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido_paterno` varchar(100) NOT NULL,
  `apellido_materno` varchar(100) DEFAULT NULL,
  `puesto` enum('MEDICO','ENFERMERIA','FARMACIA','RECEPCION','ADMINISTRACION','LABORATORIO') NOT NULL,
  `telefono` varchar(25) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`personal_id`),
  UNIQUE KEY `numero_empleado` (`numero_empleado`),
  KEY `fk_personal_departamento` (`departamento_id`),
  CONSTRAINT `fk_personal_departamento` FOREIGN KEY (`departamento_id`) REFERENCES `departamentos` (`departamento_id`),
  CONSTRAINT `ck_personal_activo` CHECK ((`activo` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personal`
--

LOCK TABLES `personal` WRITE;
/*!40000 ALTER TABLE `personal` DISABLE KEYS */;
INSERT INTO `personal` VALUES (1,'EMP-DEMO-001',1,'Medica Uno','Ejemplo','Ficticio','MEDICO','TEL-DEMO-001','medica.uno@example.invalid',1),(2,'EMP-DEMO-002',1,'Medico Dos','Ejemplo','Ficticio','MEDICO','TEL-DEMO-002','medico.dos@example.invalid',1),(3,'EMP-DEMO-003',2,'Medica Tres','Ejemplo','Ficticio','MEDICO','TEL-DEMO-003','medica.tres@example.invalid',1),(4,'EMP-DEMO-004',2,'Enfermeria Uno','Ejemplo','Ficticio','ENFERMERIA','TEL-DEMO-004','enfermeria.uno@example.invalid',1),(5,'EMP-DEMO-005',2,'Enfermeria Dos','Ejemplo','Ficticio','ENFERMERIA','TEL-DEMO-005','enfermeria.dos@example.invalid',1),(6,'EMP-DEMO-006',3,'Farmacia Uno','Ejemplo','Ficticio','FARMACIA','TEL-DEMO-006','farmacia.uno@example.invalid',1),(7,'EMP-DEMO-007',4,'Recepcion Uno','Ejemplo','Ficticio','RECEPCION','TEL-DEMO-007','recepcion.uno@example.invalid',1),(8,'EMP-DEMO-008',5,'Laboratorio Uno','Ejemplo','Ficticio','LABORATORIO','TEL-DEMO-008','laboratorio.uno@example.invalid',1),(9,'EMP-DEMO-009',1,'Carlos','Mendoza','Simulado','MEDICO','TEL-DEMO-009','medico.9@example.invalid',1),(10,'EMP-DEMO-010',8,'Ana','Gómez','Simulado','MEDICO','TEL-DEMO-010','medico.10@example.invalid',1),(11,'EMP-DEMO-011',2,'Luis','Hernández','Simulado','MEDICO','TEL-DEMO-011','medico.11@example.invalid',1),(12,'EMP-DEMO-012',6,'María','López','Simulado','MEDICO','TEL-DEMO-012','medico.12@example.invalid',1),(13,'EMP-DEMO-013',1,'Jorge','Martínez','Simulado','MEDICO','TEL-DEMO-013','medico.13@example.invalid',1),(14,'EMP-DEMO-014',8,'Sofía','Ramírez','Simulado','MEDICO','TEL-DEMO-014','medico.14@example.invalid',1),(15,'EMP-DEMO-015',2,'Miguel','Torres','Simulado','MEDICO','TEL-DEMO-015','medico.15@example.invalid',1),(16,'EMP-DEMO-016',6,'Lucía','Flores','Simulado','MEDICO','TEL-DEMO-016','medico.16@example.invalid',1),(17,'EMP-DEMO-017',1,'David','Rivera','Simulado','MEDICO','TEL-DEMO-017','medico.17@example.invalid',1),(18,'EMP-DEMO-018',8,'Elena','Vargas','Simulado','MEDICO','TEL-DEMO-018','medico.18@example.invalid',1),(19,'EMP-DEMO-019',2,'Fernando','Castro','Simulado','MEDICO','TEL-DEMO-019','medico.19@example.invalid',1),(20,'EMP-DEMO-020',6,'Carmen','Morales','Simulado','MEDICO','TEL-DEMO-020','medico.20@example.invalid',1),(21,'EMP-DEMO-021',1,'Javier','Jiménez','Simulado','MEDICO','TEL-DEMO-021','medico.21@example.invalid',1),(22,'EMP-DEMO-022',8,'Patricia','Ruiz','Simulado','MEDICO','TEL-DEMO-022','medico.22@example.invalid',1),(23,'EMP-DEMO-023',2,'Roberto','Díaz','Simulado','MEDICO','TEL-DEMO-023','medico.23@example.invalid',1),(24,'EMP-DEMO-024',2,'Mariana','Vega','Simulado','ENFERMERIA','TEL-DEMO-024','enfermeria.24@example.invalid',1),(25,'EMP-DEMO-025',2,'Daniel','Leon','Simulado','ENFERMERIA','TEL-DEMO-025','enfermeria.25@example.invalid',1);
/*!40000 ALTER TABLE `personal` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_personal_puesto` BEFORE UPDATE ON `personal` FOR EACH ROW BEGIN
  IF NEW.puesto <> 'MEDICO' AND EXISTS (SELECT 1 FROM medicos WHERE medico_id = OLD.personal_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puede cambiar el puesto de un medico registrado';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `polizas`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `polizas` (
  `poliza_id` int unsigned NOT NULL AUTO_INCREMENT,
  `paciente_id` int unsigned NOT NULL,
  `aseguradora_id` int unsigned NOT NULL,
  `numero_poliza` varchar(60) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  PRIMARY KEY (`poliza_id`),
  UNIQUE KEY `aseguradora_id` (`aseguradora_id`,`numero_poliza`,`paciente_id`),
  UNIQUE KEY `poliza_id` (`poliza_id`,`paciente_id`),
  KEY `fk_poliza_paciente` (`paciente_id`),
  CONSTRAINT `fk_poliza_aseguradora` FOREIGN KEY (`aseguradora_id`) REFERENCES `aseguradoras` (`aseguradora_id`),
  CONSTRAINT `fk_poliza_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`paciente_id`),
  CONSTRAINT `ck_poliza_fechas` CHECK ((`fecha_fin` >= `fecha_inicio`))
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `polizas`
--

LOCK TABLES `polizas` WRITE;
/*!40000 ALTER TABLE `polizas` DISABLE KEYS */;
INSERT INTO `polizas` VALUES (1,1,1,'POLIZA-DEMO-001','2026-01-01','2026-12-31'),(2,2,2,'POLIZA-DEMO-002','2026-01-01','2027-06-30'),(3,5,1,'POLIZA-DEMO-003','2026-09-01','2027-08-31'),(4,6,3,'POLIZA-DEMO-004','2026-01-01','2027-12-31'),(5,7,4,'POLIZA-DEMO-005','2026-01-01','2027-12-31'),(6,8,5,'POLIZA-DEMO-006','2026-01-01','2027-12-31'),(7,9,3,'POLIZA-DEMO-007','2026-01-01','2027-12-31'),(8,10,4,'POLIZA-DEMO-008','2026-01-01','2027-12-31'),(9,11,5,'POLIZA-DEMO-009','2026-01-01','2027-12-31'),(10,12,3,'POLIZA-DEMO-010','2026-01-01','2027-12-31'),(11,13,4,'POLIZA-DEMO-011','2026-01-01','2027-12-31'),(12,14,5,'POLIZA-DEMO-012','2026-01-01','2027-12-31'),(13,15,3,'POLIZA-DEMO-013','2026-01-01','2027-12-31'),(14,16,4,'POLIZA-DEMO-014','2026-01-01','2027-12-31'),(15,17,5,'POLIZA-DEMO-015','2026-01-01','2027-12-31'),(16,18,3,'POLIZA-DEMO-016','2026-01-01','2027-12-31'),(17,19,4,'POLIZA-DEMO-017','2026-01-01','2027-12-31'),(18,20,5,'POLIZA-DEMO-018','2026-01-01','2027-12-31');
/*!40000 ALTER TABLE `polizas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `procedimientos`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `procedimientos` (
  `procedimiento_id` int unsigned NOT NULL AUTO_INCREMENT,
  `codigo` varchar(30) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `tipo` enum('LABORATORIO','IMAGEN','CIRUGIA','OTRO') NOT NULL,
  `precio_referencia` decimal(12,2) NOT NULL,
  PRIMARY KEY (`procedimiento_id`),
  UNIQUE KEY `codigo` (`codigo`),
  CONSTRAINT `ck_procedimiento_precio` CHECK ((`precio_referencia` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `procedimientos`
--

LOCK TABLES `procedimientos` WRITE;
/*!40000 ALTER TABLE `procedimientos` DISABLE KEYS */;
INSERT INTO `procedimientos` VALUES (1,'PROC-DEMO-LAB','Estudio ficticio de laboratorio A','LABORATORIO',300.00),(2,'PROC-DEMO-IMG','Estudio ficticio de imagen B','IMAGEN',200.00),(3,'PROC-DEMO-OTR','Procedimiento ficticio C','OTRO',150.00),(4,'PROC-DEMO-CIR','Procedimiento ficticio de cirugia D','CIRUGIA',800.00),(5,'PROC-DEMO-05','Estudio docente de laboratorio B','LABORATORIO',125.00),(6,'PROC-DEMO-06','Estudio docente de imagen C','IMAGEN',150.00),(7,'PROC-DEMO-07','Procedimiento docente de cirugia E','CIRUGIA',175.00),(8,'PROC-DEMO-08','Procedimiento docente ambulatorio F','OTRO',200.00);
/*!40000 ALTER TABLE `procedimientos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proveedores`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `proveedores` (
  `proveedor_id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) NOT NULL,
  `telefono` varchar(25) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`proveedor_id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedores`
--

LOCK TABLES `proveedores` WRITE;
/*!40000 ALTER TABLE `proveedores` DISABLE KEYS */;
INSERT INTO `proveedores` VALUES (1,'Proveedor ficticio Alfa','TEL-PROV-DEMO-001','proveedor.alfa@example.invalid'),(2,'Proveedor ficticio Beta','TEL-PROV-DEMO-002','proveedor.beta@example.invalid'),(3,'Proveedor ficticio Gamma','TEL-PROV-DEMO-003','proveedor.gamma@example.invalid'),(4,'Proveedor ficticio Delta','TEL-PROV-DEMO-004','proveedor.delta@example.invalid');
/*!40000 ALTER TABLE `proveedores` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `receta_detalle`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `receta_detalle` (
  `receta_id` int unsigned NOT NULL,
  `renglon` smallint unsigned NOT NULL,
  `medicamento_id` int unsigned NOT NULL,
  `dosis` varchar(100) NOT NULL,
  `frecuencia` varchar(100) NOT NULL,
  `duracion_dias` smallint unsigned NOT NULL,
  `via_administracion` varchar(50) NOT NULL,
  `cantidad_prescrita` int unsigned NOT NULL,
  PRIMARY KEY (`receta_id`,`renglon`),
  UNIQUE KEY `receta_id` (`receta_id`,`renglon`,`medicamento_id`),
  KEY `fk_rd_medicamento` (`medicamento_id`),
  CONSTRAINT `fk_rd_medicamento` FOREIGN KEY (`medicamento_id`) REFERENCES `medicamentos` (`medicamento_id`),
  CONSTRAINT `fk_rd_receta` FOREIGN KEY (`receta_id`) REFERENCES `recetas` (`receta_id`),
  CONSTRAINT `ck_rd_cantidad` CHECK ((`cantidad_prescrita` > 0)),
  CONSTRAINT `ck_rd_duracion` CHECK ((`duracion_dias` > 0)),
  CONSTRAINT `ck_rd_renglon` CHECK ((`renglon` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `receta_detalle`
--

LOCK TABLES `receta_detalle` WRITE;
/*!40000 ALTER TABLE `receta_detalle` DISABLE KEYS */;
INSERT INTO `receta_detalle` VALUES (1,1,1,'Valor didactico','Texto de prueba sin uso clinico',1,'Campo de prueba',8),(1,2,2,'Valor didactico','Texto de prueba sin uso clinico',1,'Campo de prueba',3),(2,1,3,'Valor didactico','Texto de prueba sin uso clinico',1,'Campo de prueba',4),(2,2,1,'Valor didactico','Texto de prueba sin uso clinico',1,'Campo de prueba',2),(3,1,2,'Valor didactico','Texto de prueba sin uso clinico',1,'Campo de prueba',2),(4,1,4,'5 mg (dato simulado)','Cada 8 horas (simulado)',3,'Oral (simulada)',9),(4,2,8,'5 mg (dato simulado)','Cada 12 horas (simulado)',3,'Oral (simulada)',6),(5,1,5,'10 mg (dato simulado)','Cada 12 horas (simulado)',4,'Oral (simulada)',8),(5,2,9,'10 mg (dato simulado)','Cada 24 horas (simulado)',4,'Oral (simulada)',4),(6,1,6,'20 mg (dato simulado)','Cada 24 horas (simulado)',5,'Oral (simulada)',5),(6,2,10,'20 mg (dato simulado)','Cada 6 horas (simulado)',5,'Oral (simulada)',20),(7,1,7,'25 mg (dato simulado)','Cada 6 horas (simulado)',6,'Oral (simulada)',24),(7,2,11,'25 mg (dato simulado)','Cada 8 horas (simulado)',6,'Oral (simulada)',18),(8,1,8,'5 mg (dato simulado)','Cada 8 horas (simulado)',7,'Oral (simulada)',21),(8,2,12,'5 mg (dato simulado)','Cada 12 horas (simulado)',7,'Oral (simulada)',14),(9,1,9,'10 mg (dato simulado)','Cada 12 horas (simulado)',3,'Oral (simulada)',6),(9,2,13,'10 mg (dato simulado)','Cada 24 horas (simulado)',3,'Oral (simulada)',3),(10,1,10,'20 mg (dato simulado)','Cada 24 horas (simulado)',4,'Oral (simulada)',4),(10,2,14,'20 mg (dato simulado)','Cada 6 horas (simulado)',4,'Oral (simulada)',16),(11,1,11,'25 mg (dato simulado)','Cada 6 horas (simulado)',5,'Oral (simulada)',20),(11,2,15,'25 mg (dato simulado)','Cada 8 horas (simulado)',5,'Oral (simulada)',15),(12,1,12,'5 mg (dato simulado)','Cada 8 horas (simulado)',6,'Oral (simulada)',18),(12,2,4,'5 mg (dato simulado)','Cada 12 horas (simulado)',6,'Oral (simulada)',12),(13,1,13,'10 mg (dato simulado)','Cada 12 horas (simulado)',7,'Oral (simulada)',14),(13,2,5,'10 mg (dato simulado)','Cada 24 horas (simulado)',7,'Oral (simulada)',7),(14,1,14,'20 mg (dato simulado)','Cada 24 horas (simulado)',3,'Oral (simulada)',3),(14,2,6,'20 mg (dato simulado)','Cada 6 horas (simulado)',3,'Oral (simulada)',12),(15,1,15,'25 mg (dato simulado)','Cada 6 horas (simulado)',4,'Oral (simulada)',16),(15,2,7,'25 mg (dato simulado)','Cada 8 horas (simulado)',4,'Oral (simulada)',12),(16,1,4,'5 mg (dato simulado)','Cada 8 horas (simulado)',5,'Oral (simulada)',15),(16,2,8,'5 mg (dato simulado)','Cada 12 horas (simulado)',5,'Oral (simulada)',10),(17,1,5,'10 mg (dato simulado)','Cada 12 horas (simulado)',6,'Oral (simulada)',12),(17,2,9,'10 mg (dato simulado)','Cada 24 horas (simulado)',6,'Oral (simulada)',6),(18,1,6,'20 mg (dato simulado)','Cada 24 horas (simulado)',7,'Oral (simulada)',7),(18,2,10,'20 mg (dato simulado)','Cada 6 horas (simulado)',7,'Oral (simulada)',28),(19,1,7,'25 mg (dato simulado)','Cada 6 horas (simulado)',3,'Oral (simulada)',12),(19,2,11,'25 mg (dato simulado)','Cada 8 horas (simulado)',3,'Oral (simulada)',9),(20,1,8,'5 mg (dato simulado)','Cada 8 horas (simulado)',4,'Oral (simulada)',12),(20,2,12,'5 mg (dato simulado)','Cada 12 horas (simulado)',4,'Oral (simulada)',8),(21,1,9,'10 mg (dato simulado)','Cada 12 horas (simulado)',5,'Oral (simulada)',10),(21,2,13,'10 mg (dato simulado)','Cada 24 horas (simulado)',5,'Oral (simulada)',5),(22,1,10,'20 mg (dato simulado)','Cada 24 horas (simulado)',6,'Oral (simulada)',6),(22,2,14,'20 mg (dato simulado)','Cada 6 horas (simulado)',6,'Oral (simulada)',24),(23,1,11,'25 mg (dato simulado)','Cada 6 horas (simulado)',7,'Oral (simulada)',28),(23,2,15,'25 mg (dato simulado)','Cada 8 horas (simulado)',7,'Oral (simulada)',21),(24,1,12,'5 mg (dato simulado)','Cada 8 horas (simulado)',3,'Oral (simulada)',9),(24,2,4,'5 mg (dato simulado)','Cada 12 horas (simulado)',3,'Oral (simulada)',6),(25,1,13,'10 mg (dato simulado)','Cada 12 horas (simulado)',4,'Oral (simulada)',8),(25,2,5,'10 mg (dato simulado)','Cada 24 horas (simulado)',4,'Oral (simulada)',4),(26,1,1,'500 mg cada 8 horas','Ver texto de dosis de la captura',1,'Oral',1),(27,1,5,'30 mg cada 12 horas','Ver texto de dosis de la captura',1,'Intravenosa',1),(28,1,9,'50 mg cada 24 horas','Ver texto de dosis de la captura',1,'Oral',1),(29,1,3,'10 ml cada 8 horas','Ver texto de dosis de la captura',7,'Oral',1),(30,1,2,'400 mg cada 6 horas condicional','Ver texto de dosis de la captura',1,'Oral',1),(31,1,4,'20 mg cada 24 horas','Ver texto de dosis de la captura',1,'Oral',1),(32,1,13,'10 mg dosis única','Ver texto de dosis de la captura',1,'Intramuscular',1),(33,1,7,'10 mg cada 24 horas','Ver texto de dosis de la captura',1,'Oral',1),(34,1,8,'850 mg cada 12 horas','Ver texto de dosis de la captura',1,'Oral',1),(35,1,6,'2 disparos cada 4 horas','Ver texto de dosis de la captura',1,'Inhalatoria',1),(36,1,12,'1 g cada 12 horas','Ver texto de dosis de la captura',1,'Intravenosa',1),(37,1,14,'100 mg cada 8 horas','Ver texto de dosis de la captura',1,'Intravenosa',1),(38,1,15,'40 mg cada 24 horas','Ver texto de dosis de la captura',1,'Oral',1),(39,1,11,'15 UI por la noche','Ver texto de dosis de la captura',1,'Subcutánea',1),(40,1,10,'Aplicar cantidad moderada','Ver texto de dosis de la captura',1,'Tópico',1);
/*!40000 ALTER TABLE `receta_detalle` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_receta_detalle_update` BEFORE UPDATE ON `receta_detalle` FOR EACH ROW BEGIN
  IF EXISTS (SELECT 1 FROM dispensacion_detalle WHERE receta_id = OLD.receta_id AND renglon = OLD.renglon) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puede modificar una linea de receta ya dispensada';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `recetas`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recetas` (
  `receta_id` int unsigned NOT NULL AUTO_INCREMENT,
  `consulta_id` int unsigned NOT NULL,
  `fecha_prescripcion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `observaciones` text,
  PRIMARY KEY (`receta_id`),
  KEY `fk_receta_consulta` (`consulta_id`),
  CONSTRAINT `fk_receta_consulta` FOREIGN KEY (`consulta_id`) REFERENCES `consultas` (`consulta_id`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recetas`
--

LOCK TABLES `recetas` WRITE;
/*!40000 ALTER TABLE `recetas` DISABLE KEYS */;
INSERT INTO `recetas` VALUES (1,1,'2026-10-06 09:20:00','Receta simulada. Ningun dato constituye una prescripcion real.'),(2,3,'2026-10-08 11:30:00','Receta simulada pendiente de entrega.'),(3,4,'2026-10-08 09:20:00','Receta simulada pendiente de entrega.'),(4,6,'2026-10-01 09:20:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(5,7,'2026-10-01 10:05:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(6,8,'2026-10-01 10:50:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(7,9,'2026-10-01 11:35:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(8,10,'2026-10-01 12:20:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(9,11,'2026-10-02 09:20:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(10,12,'2026-10-02 10:05:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(11,13,'2026-10-02 10:50:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(12,14,'2026-10-02 11:35:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(13,15,'2026-10-02 12:20:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(14,16,'2026-10-03 09:20:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(15,17,'2026-10-03 10:05:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(16,18,'2026-10-03 10:50:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(17,19,'2026-10-03 11:35:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(18,20,'2026-10-03 12:20:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(19,21,'2026-10-04 09:20:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(20,22,'2026-10-04 10:05:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(21,23,'2026-10-04 10:50:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(22,24,'2026-10-04 11:35:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(23,25,'2026-10-04 12:20:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(24,26,'2026-10-05 09:20:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(25,27,'2026-10-05 10:05:00','Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'),(26,31,'2026-10-10 09:10:00','[APORTE EQUIPO receta 1; paciente fuente 101; camilla fuente 1; medicamento fuente 1]. Monitorear temperatura corporal. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(27,32,'2026-10-10 09:40:00','[APORTE EQUIPO receta 2; paciente fuente 102; camilla fuente 3; medicamento fuente 5]. Administrar lentamente por vía IV. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(28,33,'2026-10-10 10:10:00','[APORTE EQUIPO receta 3; paciente fuente 103; camilla fuente 9; medicamento fuente 9]. Tomar en ayunas por la mañana. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(29,34,'2026-10-10 10:40:00','[APORTE EQUIPO receta 4; paciente fuente 104; camilla fuente 5; medicamento fuente 3]. Completar tratamiento de 7 días. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(30,35,'2026-10-10 11:10:00','[APORTE EQUIPO receta 5; paciente fuente 105; camilla fuente 13; medicamento fuente 2]. Usar en caso de dolor agudo. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(31,36,'2026-10-10 11:40:00','[APORTE EQUIPO receta 6; paciente fuente 106; camilla fuente 11; medicamento fuente 4]. Antes del primer alimento del día. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(32,37,'2026-10-10 12:10:00','[APORTE EQUIPO receta 7; paciente fuente 107; camilla fuente 7; medicamento fuente 13]. Vigilar estado de conciencia. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(33,38,'2026-10-10 12:40:00','[APORTE EQUIPO receta 8; paciente fuente 108; camilla fuente 2; medicamento fuente 7]. Indicado para cuadro alérgico. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(34,39,'2026-10-10 13:10:00','[APORTE EQUIPO receta 9; paciente fuente 109; camilla fuente 10; medicamento fuente 8]. Acompañar con los alimentos principales. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(35,40,'2026-10-10 13:40:00','[APORTE EQUIPO receta 10; paciente fuente 110; camilla fuente 8; medicamento fuente 6]. Usar espaciador en caso de disnea. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(36,41,'2026-10-10 14:10:00','[APORTE EQUIPO receta 11; paciente fuente 111; camilla fuente 4; medicamento fuente 12]. Diluir en solución salina al 0.9%. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(37,42,'2026-10-10 14:40:00','[APORTE EQUIPO receta 12; paciente fuente 112; camilla fuente 6; medicamento fuente 14]. Controlar niveles de glucosa. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(38,43,'2026-10-10 15:10:00','[APORTE EQUIPO receta 13; paciente fuente 113; camilla fuente 12; medicamento fuente 15]. Vigilar gasto urinario y presión arterial. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(39,44,'2026-10-10 15:40:00','[APORTE EQUIPO receta 14; paciente fuente 114; camilla fuente 14; medicamento fuente 11]. Rotar sitio de punción diariamente. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'),(40,45,'2026-10-10 16:10:00','[APORTE EQUIPO receta 15; paciente fuente 115; camilla fuente 15; medicamento fuente 10]. Frotar suavemente sobre la zona afectada. Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.');
/*!40000 ALTER TABLE `recetas` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_receta_identidad` BEFORE UPDATE ON `recetas` FOR EACH ROW BEGIN
  IF NEW.consulta_id <> OLD.consulta_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una receta no puede reasignarse a otra consulta';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `resultados_procedimiento`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resultados_procedimiento` (
  `resultado_id` int unsigned NOT NULL AUTO_INCREMENT,
  `orden_id` int unsigned NOT NULL,
  `personal_id` int unsigned NOT NULL,
  `fecha_resultado` datetime NOT NULL,
  `informe` text NOT NULL,
  PRIMARY KEY (`resultado_id`),
  UNIQUE KEY `orden_id` (`orden_id`),
  KEY `fk_resultado_personal` (`personal_id`),
  CONSTRAINT `fk_resultado_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes_procedimiento` (`orden_id`),
  CONSTRAINT `fk_resultado_personal` FOREIGN KEY (`personal_id`) REFERENCES `personal` (`personal_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resultados_procedimiento`
--

LOCK TABLES `resultados_procedimiento` WRITE;
/*!40000 ALTER TABLE `resultados_procedimiento` DISABLE KEYS */;
INSERT INTO `resultados_procedimiento` VALUES (1,1,8,'2026-10-06 12:00:00','Resultado simulado A: texto de prueba sin interpretacion medica.'),(2,3,3,'2026-10-08 14:00:00','Resultado simulado C: procedimiento de demostracion registrado.'),(3,5,8,'2026-10-01 12:25:00','Informe simulado del estudio 5; no contiene resultados clinicos reales.'),(4,6,10,'2026-10-01 13:10:00','Informe simulado del estudio 6; no contiene resultados clinicos reales.'),(5,7,11,'2026-10-01 13:55:00','Informe simulado del estudio 7; no contiene resultados clinicos reales.'),(6,8,12,'2026-10-01 14:40:00','Informe simulado del estudio 8; no contiene resultados clinicos reales.'),(7,9,8,'2026-10-01 15:25:00','Informe simulado del estudio 9; no contiene resultados clinicos reales.'),(8,10,14,'2026-10-02 12:25:00','Informe simulado del estudio 10; no contiene resultados clinicos reales.'),(9,11,15,'2026-10-02 13:10:00','Informe simulado del estudio 11; no contiene resultados clinicos reales.'),(10,12,16,'2026-10-02 13:55:00','Informe simulado del estudio 12; no contiene resultados clinicos reales.'),(11,13,8,'2026-10-02 14:40:00','Informe simulado del estudio 13; no contiene resultados clinicos reales.'),(12,14,18,'2026-10-02 15:25:00','Informe simulado del estudio 14; no contiene resultados clinicos reales.'),(13,15,19,'2026-10-03 12:25:00','Informe simulado del estudio 15; no contiene resultados clinicos reales.'),(14,16,20,'2026-10-03 13:10:00','Informe simulado del estudio 16; no contiene resultados clinicos reales.'),(15,17,8,'2026-10-03 13:55:00','Informe simulado del estudio 17; no contiene resultados clinicos reales.');
/*!40000 ALTER TABLE `resultados_procedimiento` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_resultado_insert` BEFORE INSERT ON `resultados_procedimiento` FOR EACH ROW BEGIN
  IF NOT EXISTS (SELECT 1 FROM ordenes_procedimiento WHERE orden_id = NEW.orden_id
                 AND estado <> 'CANCELADA' AND NEW.fecha_resultado >= fecha_solicitud) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Orden cancelada, inexistente o fecha de resultado invalida';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_resultado_estado` AFTER INSERT ON `resultados_procedimiento` FOR EACH ROW BEGIN
  UPDATE ordenes_procedimiento SET estado = 'REALIZADA' WHERE orden_id = NEW.orden_id;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_resultado_update` BEFORE UPDATE ON `resultados_procedimiento` FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El informe registrado es inmutable en este modelo academico';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `roles`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `rol_id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) NOT NULL,
  `descripcion` varchar(250) NOT NULL,
  PRIMARY KEY (`rol_id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'ADMINISTRACION','Rol de prueba para administrar configuracion de la futura aplicacion.'),(2,'MEDICO','Rol de prueba para acceder a atencion clinica.'),(3,'FARMACIA','Rol de prueba para manejar recetas, entregas e inventario.'),(4,'RECEPCION','Rol de prueba para registrar pacientes y citas.'),(5,'LABORATORIO','Rol simulado de la futura aplicacion.'),(6,'ENFERMERIA','Rol simulado de la futura aplicacion.');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuario_roles`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuario_roles` (
  `usuario_id` int unsigned NOT NULL,
  `rol_id` int unsigned NOT NULL,
  PRIMARY KEY (`usuario_id`,`rol_id`),
  KEY `fk_ur_rol` (`rol_id`),
  CONSTRAINT `fk_ur_rol` FOREIGN KEY (`rol_id`) REFERENCES `roles` (`rol_id`),
  CONSTRAINT `fk_ur_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`usuario_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuario_roles`
--

LOCK TABLES `usuario_roles` WRITE;
/*!40000 ALTER TABLE `usuario_roles` DISABLE KEYS */;
INSERT INTO `usuario_roles` VALUES (1,2),(7,2),(2,3),(3,4),(6,5),(4,6),(5,6);
/*!40000 ALTER TABLE `usuario_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `usuario_id` int unsigned NOT NULL AUTO_INCREMENT,
  `personal_id` int unsigned NOT NULL,
  `nombre_usuario` varchar(80) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`usuario_id`),
  UNIQUE KEY `personal_id` (`personal_id`),
  UNIQUE KEY `nombre_usuario` (`nombre_usuario`),
  CONSTRAINT `fk_usuario_personal` FOREIGN KEY (`personal_id`) REFERENCES `personal` (`personal_id`),
  CONSTRAINT `ck_usuario_activo` CHECK ((`activo` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,1,'demo.medica.uno','MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION',0),(2,6,'demo.farmacia.uno','MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION',0),(3,7,'demo.recepcion.uno','MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION',0),(4,24,'demo.personal.24','MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION',0),(5,25,'demo.personal.25','MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION',0),(6,8,'demo.personal.8','MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION',0),(7,9,'demo.personal.9','MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION',0);
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_camillas_estado`
--

SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_camillas_estado` AS SELECT 
 1 AS `camilla_id`,
 1 AS `codigo`,
 1 AS `habitacion_id`,
 1 AS `estado_operativo`,
 1 AS `hospitalizacion_id`,
 1 AS `disponibilidad`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_expediente_consultas`
--

SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_expediente_consultas` AS SELECT 
 1 AS `paciente_id`,
 1 AS `expediente_clinico`,
 1 AS `paciente`,
 1 AS `consulta_id`,
 1 AS `fecha`,
 1 AS `tipo`,
 1 AS `motivo`,
 1 AS `medico_id`,
 1 AS `medico`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_facturas_saldo`
--

SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_facturas_saldo` AS SELECT 
 1 AS `factura_id`,
 1 AS `folio`,
 1 AS `paciente_id`,
 1 AS `estado`,
 1 AS `total`,
 1 AS `pagado`,
 1 AS `saldo`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_recetas_pendientes`
--

SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_recetas_pendientes` AS SELECT 
 1 AS `receta_id`,
 1 AS `renglon`,
 1 AS `medicamento_id`,
 1 AS `cantidad_prescrita`,
 1 AS `cantidad_entregada`,
 1 AS `cantidad_pendiente`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_stock_lotes`
--

SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_stock_lotes` AS SELECT 
 1 AS `lote_id`,
 1 AS `medicamento_id`,
 1 AS `numero_lote`,
 1 AS `fecha_caducidad`,
 1 AS `stock`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_stock_medicamentos`
--

SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_stock_medicamentos` AS SELECT 
 1 AS `medicamento_id`,
 1 AS `codigo`,
 1 AS `principio_activo`,
 1 AS `unidad_inventario`,
 1 AS `stock_minimo`,
 1 AS `stock_total`,
 1 AS `stock_vigente`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'hospital_universitario'
--

--
-- Dumping routines for database 'hospital_universitario'
--
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_agendar_cita`(IN p_paciente INT UNSIGNED, IN p_medico INT UNSIGNED,
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_alta_hospitalaria`(IN p_hosp INT UNSIGNED, IN p_fecha DATETIME, IN p_resumen TEXT)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_asignar_camilla`(IN p_hosp INT UNSIGNED, IN p_camilla INT UNSIGNED,
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dispensar`(IN p_receta INT UNSIGNED, IN p_renglon SMALLINT UNSIGNED,
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_movimiento`(IN p_lote INT UNSIGNED, IN p_personal INT UNSIGNED,
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_pago`(IN p_factura INT UNSIGNED, IN p_fecha DATETIME,
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Current Database: `hospital_universitario`
--

USE `hospital_universitario`;

--
-- Final view structure for view `v_camillas_estado`
--

/*!50001 DROP VIEW IF EXISTS `v_camillas_estado`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_camillas_estado` AS select `c`.`camilla_id` AS `camilla_id`,`c`.`codigo` AS `codigo`,`c`.`habitacion_id` AS `habitacion_id`,`c`.`estado_operativo` AS `estado_operativo`,`a`.`hospitalizacion_id` AS `hospitalizacion_id`,(case when (`a`.`asignacion_id` is not null) then 'OCUPADA' when (`c`.`estado_operativo` = 'OPERATIVA') then 'DISPONIBLE' else `c`.`estado_operativo` end) AS `disponibilidad` from (`camillas` `c` left join `asignaciones_camilla` `a` on(((`a`.`camilla_id` = `c`.`camilla_id`) and (`a`.`fin` is null)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_expediente_consultas`
--

/*!50001 DROP VIEW IF EXISTS `v_expediente_consultas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_expediente_consultas` AS select `p`.`paciente_id` AS `paciente_id`,`p`.`expediente_clinico` AS `expediente_clinico`,concat_ws(' ',`p`.`nombre`,`p`.`apellido_paterno`,`p`.`apellido_materno`) AS `paciente`,`c`.`consulta_id` AS `consulta_id`,`c`.`fecha` AS `fecha`,`c`.`tipo` AS `tipo`,`c`.`motivo` AS `motivo`,`c`.`medico_id` AS `medico_id`,concat_ws(' ',`pe`.`nombre`,`pe`.`apellido_paterno`,`pe`.`apellido_materno`) AS `medico` from ((`consultas` `c` join `pacientes` `p` on((`p`.`paciente_id` = `c`.`paciente_id`))) join `personal` `pe` on((`pe`.`personal_id` = `c`.`medico_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_facturas_saldo`
--

/*!50001 DROP VIEW IF EXISTS `v_facturas_saldo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_facturas_saldo` AS select `f`.`factura_id` AS `factura_id`,`f`.`folio` AS `folio`,`f`.`paciente_id` AS `paciente_id`,`f`.`estado` AS `estado`,coalesce(`d`.`total`,0) AS `total`,coalesce(`p`.`pagado`,0) AS `pagado`,(coalesce(`d`.`total`,0) - coalesce(`p`.`pagado`,0)) AS `saldo` from ((`facturas` `f` left join (select `factura_detalle`.`factura_id` AS `factura_id`,sum(`factura_detalle`.`importe`) AS `total` from `factura_detalle` group by `factura_detalle`.`factura_id`) `d` on((`d`.`factura_id` = `f`.`factura_id`))) left join (select `pagos`.`factura_id` AS `factura_id`,sum(`pagos`.`monto`) AS `pagado` from `pagos` group by `pagos`.`factura_id`) `p` on((`p`.`factura_id` = `f`.`factura_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_recetas_pendientes`
--

/*!50001 DROP VIEW IF EXISTS `v_recetas_pendientes`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_recetas_pendientes` AS select `rd`.`receta_id` AS `receta_id`,`rd`.`renglon` AS `renglon`,`rd`.`medicamento_id` AS `medicamento_id`,`rd`.`cantidad_prescrita` AS `cantidad_prescrita`,coalesce(`dd`.`entregada`,0) AS `cantidad_entregada`,(`rd`.`cantidad_prescrita` - coalesce(`dd`.`entregada`,0)) AS `cantidad_pendiente` from (`receta_detalle` `rd` left join (select `dispensacion_detalle`.`receta_id` AS `receta_id`,`dispensacion_detalle`.`renglon` AS `renglon`,sum(`dispensacion_detalle`.`cantidad`) AS `entregada` from `dispensacion_detalle` group by `dispensacion_detalle`.`receta_id`,`dispensacion_detalle`.`renglon`) `dd` on(((`dd`.`receta_id` = `rd`.`receta_id`) and (`dd`.`renglon` = `rd`.`renglon`)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_stock_lotes`
--

/*!50001 DROP VIEW IF EXISTS `v_stock_lotes`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_stock_lotes` AS select `l`.`lote_id` AS `lote_id`,`l`.`medicamento_id` AS `medicamento_id`,`l`.`numero_lote` AS `numero_lote`,`l`.`fecha_caducidad` AS `fecha_caducidad`,coalesce(sum(`m`.`cantidad`),0) AS `stock` from (`lotes_medicamento` `l` left join `movimientos_inventario` `m` on((`m`.`lote_id` = `l`.`lote_id`))) group by `l`.`lote_id`,`l`.`medicamento_id`,`l`.`numero_lote`,`l`.`fecha_caducidad` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_stock_medicamentos`
--

/*!50001 DROP VIEW IF EXISTS `v_stock_medicamentos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_stock_medicamentos` AS select `m`.`medicamento_id` AS `medicamento_id`,`m`.`codigo` AS `codigo`,`m`.`principio_activo` AS `principio_activo`,`m`.`unidad_inventario` AS `unidad_inventario`,`m`.`stock_minimo` AS `stock_minimo`,coalesce(sum(`s`.`stock`),0) AS `stock_total`,coalesce(sum((case when (`s`.`fecha_caducidad` >= curdate()) then `s`.`stock` else 0 end)),0) AS `stock_vigente` from (`medicamentos` `m` left join `v_stock_lotes` `s` on((`s`.`medicamento_id` = `m`.`medicamento_id`))) group by `m`.`medicamento_id`,`m`.`codigo`,`m`.`principio_activo`,`m`.`unidad_inventario`,`m`.`stock_minimo` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-15 22:00:37
