# Diccionario de datos

Fuente de verdad: `01_esquema.sql`. Generado del DDL, no de capturas. MySQL 8.0.16 o posterior; InnoDB y utf8mb4.

PK = clave primaria; FK = clave foránea; UK* = participa en una restricción UNIQUE, que puede ser compuesta; AI = AUTO_INCREMENT; G = columna generada STORED. La columna NULL indica si se admite NULL. BOOLEAN equivale a un entero lógico; los CHECK limitan valores a 0/1. No se incluyen columnas internas de InnoDB.

Las claves compuestas completas se enumeran bajo cada tabla. El símbolo UK* por columna no afirma unicidad individual. Sin una cláusula ON DELETE/ON UPDATE explícita, InnoDB restringe cambios del padre con hijos asociados [Manual MySQL](https://dev.mysql.com/doc/refman/8.0/en/create-table-foreign-keys.html).

## Organización y personas

### 01. departamentos

Catálogo de áreas organizativas del hospital.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `departamento_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `codigo` | `VARCHAR(20)` | No | UK* | `-` |
| `nombre` | `VARCHAR(100)` | No | UK* | `-` |

**PK:** `departamento_id`.
**UNIQUE:** `(codigo)`; `(nombre)`.

### 02. especialidades

Catálogo de especialidades profesionales.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `especialidad_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `nombre` | `VARCHAR(100)` | No | UK* | `-` |

**PK:** `especialidad_id`.
**UNIQUE:** `(nombre)`.

### 03. personal

Identidad laboral común de médicos y otros trabajadores.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `personal_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `numero_empleado` | `VARCHAR(25)` | No | UK* | `-` |
| `departamento_id` | `INT UNSIGNED` | No | FK | `-` |
| `nombre` | `VARCHAR(100)` | No | - | `-` |
| `apellido_paterno` | `VARCHAR(100)` | No | - | `-` |
| `apellido_materno` | `VARCHAR(100)` | Sí | - | `-` |
| `puesto` | `ENUM('MEDICO','ENFERMERIA','FARMACIA','RECEPCION','ADMINISTRACION','LABORATORIO')` | No | - | `-` |
| `telefono` | `VARCHAR(25)` | Sí | - | `-` |
| `email` | `VARCHAR(150)` | Sí | - | `-` |
| `activo` | `BOOLEAN` | No | - | `TRUE` |

**PK:** `personal_id`.
**UNIQUE:** `(numero_empleado)`.
- **fk_personal_departamento:** `(departamento_id)` → `departamentos(departamento_id)`.

**CHECK:**
- `ck_personal_activo`: `activo IN (0,1)`.

### 04. medicos

Subtipo de personal con cédula profesional única; comparte su identificador con personal.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `medico_id` | `INT UNSIGNED` | No | PK, FK | `-` |
| `cedula_profesional` | `VARCHAR(50)` | No | UK* | `-` |

**PK:** `medico_id`.
**UNIQUE:** `(cedula_profesional)`.
- **fk_medico_personal:** `(medico_id)` → `personal(personal_id)`.

### 05. medico_especialidad

Relación de muchos a muchos entre médicos y especialidades.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `medico_id` | `INT UNSIGNED` | No | PK, FK | `-` |
| `especialidad_id` | `INT UNSIGNED` | No | PK, FK | `-` |

**PK:** `medico_id, especialidad_id`.
- **fk_me_medico:** `(medico_id)` → `medicos(medico_id)`.
- **fk_me_especialidad:** `(especialidad_id)` → `especialidades(especialidad_id)`.

### 06. pacientes

Identidad del paciente, expediente y datos de contacto básicos.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `paciente_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `expediente_clinico` | `VARCHAR(30)` | No | UK* | `-` |
| `nombre` | `VARCHAR(100)` | No | - | `-` |
| `apellido_paterno` | `VARCHAR(100)` | No | - | `-` |
| `apellido_materno` | `VARCHAR(100)` | Sí | - | `-` |
| `fecha_nacimiento` | `DATE` | No | - | `-` |
| `sexo` | `ENUM('F','M','NO_ESPECIFICADO')` | No | - | `'NO_ESPECIFICADO'` |
| `telefono` | `VARCHAR(25)` | Sí | - | `-` |
| `email` | `VARCHAR(150)` | Sí | - | `-` |
| `domicilio` | `VARCHAR(250)` | Sí | - | `-` |
| `fecha_registro` | `DATETIME` | No | - | `CURRENT_TIMESTAMP` |
| `activo` | `BOOLEAN` | No | - | `TRUE` |

**PK:** `paciente_id`.
**UNIQUE:** `(expediente_clinico)`.

**CHECK:**
- `ck_paciente_activo`: `activo IN (0,1)`.
- `ck_paciente_nacimiento`: `fecha_nacimiento <= DATE(fecha_registro)`.

### 07. contactos_emergencia

Contactos ordenados por prioridad para un paciente.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `contacto_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `paciente_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `nombre` | `VARCHAR(200)` | No | - | `-` |
| `parentesco` | `VARCHAR(50)` | No | - | `-` |
| `telefono` | `VARCHAR(25)` | No | - | `-` |
| `prioridad` | `TINYINT UNSIGNED` | No | UK* | `1` |

**PK:** `contacto_id`.
**UNIQUE:** `(paciente_id, prioridad)`.
- **fk_contacto_paciente:** `(paciente_id)` → `pacientes(paciente_id)`.

**CHECK:**
- `ck_contacto_prioridad`: `prioridad > 0`.

### 08. aseguradoras

Catálogo de entidades aseguradoras.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `aseguradora_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `nombre` | `VARCHAR(150)` | No | UK* | `-` |
| `telefono` | `VARCHAR(25)` | Sí | - | `-` |

**PK:** `aseguradora_id`.
**UNIQUE:** `(nombre)`.

### 09. polizas

Cobertura básica de un paciente con vigencia; no liquida reclamaciones.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `poliza_id` | `INT UNSIGNED` | No | PK, UK*, AI | `Secuencia automática` |
| `paciente_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `aseguradora_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `numero_poliza` | `VARCHAR(60)` | No | UK* | `-` |
| `fecha_inicio` | `DATE` | No | - | `-` |
| `fecha_fin` | `DATE` | No | - | `-` |

**PK:** `poliza_id`.
**UNIQUE:** `(aseguradora_id, numero_poliza, paciente_id)`; `(poliza_id, paciente_id)`.
- **fk_poliza_paciente:** `(paciente_id)` → `pacientes(paciente_id)`.
- **fk_poliza_aseguradora:** `(aseguradora_id)` → `aseguradoras(aseguradora_id)`.

**CHECK:**
- `ck_poliza_fechas`: `fecha_fin >= fecha_inicio`.

## Infraestructura

### 10. habitaciones

Ubicación física por departamento, edificio, piso y tipo.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `habitacion_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `departamento_id` | `INT UNSIGNED` | No | FK | `-` |
| `codigo` | `VARCHAR(30)` | No | UK* | `-` |
| `edificio` | `VARCHAR(50)` | No | - | `-` |
| `piso` | `SMALLINT` | No | - | `-` |
| `tipo` | `ENUM('GENERAL','PRIVADA','UCI','URGENCIAS')` | No | - | `-` |

**PK:** `habitacion_id`.
**UNIQUE:** `(codigo)`.
- **fk_habitacion_departamento:** `(departamento_id)` → `departamentos(departamento_id)`.

### 11. camillas

Camilla física y condición operativa; la ocupación se obtiene de asignaciones.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `camilla_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `habitacion_id` | `INT UNSIGNED` | No | FK | `-` |
| `codigo` | `VARCHAR(30)` | No | UK* | `-` |
| `estado_operativo` | `ENUM('OPERATIVA','MANTENIMIENTO','FUERA_SERVICIO')` | No | - | `'OPERATIVA'` |

**PK:** `camilla_id`.
**UNIQUE:** `(codigo)`.
- **fk_camilla_habitacion:** `(habitacion_id)` → `habitaciones(habitacion_id)`.

## Atención clínica

### 12. citas

Intervalo planeado entre un paciente y un médico; permite cancelación.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `cita_id` | `INT UNSIGNED` | No | PK, UK*, AI | `Secuencia automática` |
| `paciente_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `medico_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `inicio` | `DATETIME` | No | UK* | `-` |
| `fin` | `DATETIME` | No | - | `-` |
| `motivo` | `VARCHAR(250)` | No | - | `-` |
| `estado` | `ENUM('PROGRAMADA','CONFIRMADA','ATENDIDA','CANCELADA','NO_ASISTIO')` | No | - | `'PROGRAMADA'` |
| `medico_agenda` | `INT UNSIGNED` | Sí | UK*, G | `Generado: CASE WHEN estado <> 'CANCELADA' THEN medico_id END` |
| `paciente_agenda` | `INT UNSIGNED` | Sí | UK*, G | `Generado: CASE WHEN estado <> 'CANCELADA' THEN paciente_id END` |

**PK:** `cita_id`.
**UNIQUE:** `(medico_agenda, inicio)`; `(paciente_agenda, inicio)`; `(cita_id, paciente_id, medico_id)`.
- **fk_cita_paciente:** `(paciente_id)` → `pacientes(paciente_id)`.
- **fk_cita_medico:** `(medico_id)` → `medicos(medico_id)`.

**CHECK:**
- `ck_cita_intervalo`: `fin > inicio`.

**Índices adicionales:** `KEY ix_cita_paciente_fecha (paciente_id, inicio)`; `KEY ix_cita_medico_intervalo (medico_id, inicio, fin)`.

### 13. consultas

Evento de atención clínica, con o sin cita, que determina paciente y médico.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `consulta_id` | `INT UNSIGNED` | No | PK, UK*, AI | `Secuencia automática` |
| `cita_id` | `INT UNSIGNED` | Sí | FK, UK* | `-` |
| `paciente_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `medico_id` | `INT UNSIGNED` | No | FK | `-` |
| `fecha` | `DATETIME` | No | - | `CURRENT_TIMESTAMP` |
| `tipo` | `ENUM('PROGRAMADA','URGENCIA','SEGUIMIENTO')` | No | - | `-` |
| `motivo` | `VARCHAR(250)` | No | - | `-` |
| `notas` | `TEXT` | Sí | - | `-` |
| `peso_kg` | `DECIMAL(6,2)` | Sí | - | `-` |
| `talla_cm` | `DECIMAL(5,2)` | Sí | - | `-` |
| `temperatura_c` | `DECIMAL(4,1)` | Sí | - | `-` |

**PK:** `consulta_id`.
**UNIQUE:** `(cita_id)`; `(consulta_id, paciente_id)`.
- **fk_consulta_cita:** `(cita_id, paciente_id, medico_id)` → `citas(cita_id, paciente_id, medico_id)`.
- **fk_consulta_paciente:** `(paciente_id)` → `pacientes(paciente_id)`.
- **fk_consulta_medico:** `(medico_id)` → `medicos(medico_id)`.

**CHECK:**
- `ck_consulta_peso`: `peso_kg IS NULL OR peso_kg > 0`.
- `ck_consulta_talla`: `talla_cm IS NULL OR talla_cm > 0`.

**Índices adicionales:** `KEY ix_consulta_paciente_fecha (paciente_id, fecha)`.

### 14. diagnosticos

Catálogo de diagnósticos; los códigos de demostración no constituyen un catálogo clínico oficial.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `diagnostico_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `codigo` | `VARCHAR(20)` | No | UK* | `-` |
| `descripcion` | `VARCHAR(250)` | No | - | `-` |

**PK:** `diagnostico_id`.
**UNIQUE:** `(codigo)`.

### 15. consulta_diagnosticos

Diagnósticos de una consulta y marca de principal; máximo un principal por consulta.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `consulta_id` | `INT UNSIGNED` | No | PK, FK | `-` |
| `diagnostico_id` | `INT UNSIGNED` | No | PK, FK | `-` |
| `es_principal` | `BOOLEAN` | No | - | `FALSE` |
| `diagnostico_principal` | `INT UNSIGNED` | Sí | UK*, G | `Generado: CASE WHEN es_principal = 1 THEN consulta_id END` |
| `observaciones` | `VARCHAR(250)` | Sí | - | `-` |

**PK:** `consulta_id, diagnostico_id`.
**UNIQUE:** `(diagnostico_principal)`.
- **fk_cd_consulta:** `(consulta_id)` → `consultas(consulta_id)`.
- **fk_cd_diagnostico:** `(diagnostico_id)` → `diagnosticos(diagnostico_id)`.

**CHECK:**
- `ck_cd_principal`: `es_principal IN (0,1)`.

### 16. alergias_paciente

Registro básico de sustancia y reacción informada por paciente.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `alergia_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `paciente_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `sustancia` | `VARCHAR(150)` | No | UK* | `-` |
| `reaccion` | `VARCHAR(250)` | No | - | `-` |
| `fecha_registro` | `DATE` | No | - | `-` |

**PK:** `alergia_id`.
**UNIQUE:** `(paciente_id, sustancia)`.
- **fk_alergia_paciente:** `(paciente_id)` → `pacientes(paciente_id)`.

## Hospitalización

### 17. hospitalizaciones

Estancia derivada de una consulta de ingreso, con responsable, ingreso y alta.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `hospitalizacion_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `consulta_ingreso_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `paciente_id` | `INT UNSIGNED` | No | FK | `-` |
| `medico_responsable_id` | `INT UNSIGNED` | No | FK | `-` |
| `fecha_ingreso` | `DATETIME` | No | - | `-` |
| `fecha_alta` | `DATETIME` | Sí | - | `-` |
| `motivo` | `VARCHAR(250)` | No | - | `-` |
| `resumen_alta` | `TEXT` | Sí | - | `-` |
| `paciente_internado` | `INT UNSIGNED` | Sí | UK*, G | `Generado: CASE WHEN fecha_alta IS NULL THEN paciente_id END` |

**PK:** `hospitalizacion_id`.
**UNIQUE:** `(consulta_ingreso_id)`; `(paciente_internado)`.
- **fk_hosp_consulta:** `(consulta_ingreso_id, paciente_id)` → `consultas(consulta_id, paciente_id)`.
- **fk_hosp_paciente:** `(paciente_id)` → `pacientes(paciente_id)`.
- **fk_hosp_medico:** `(medico_responsable_id)` → `medicos(medico_id)`.

**CHECK:**
- `ck_hosp_fechas`: `fecha_alta IS NULL OR fecha_alta >= fecha_ingreso`.

### 18. asignaciones_camilla

Historial temporal de ocupación y traslados de una hospitalización.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `asignacion_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `hospitalizacion_id` | `INT UNSIGNED` | No | FK | `-` |
| `camilla_id` | `INT UNSIGNED` | No | FK | `-` |
| `inicio` | `DATETIME` | No | - | `-` |
| `fin` | `DATETIME` | Sí | - | `-` |
| `camilla_ocupada` | `INT UNSIGNED` | Sí | UK*, G | `Generado: CASE WHEN fin IS NULL THEN camilla_id END` |
| `hospitalizacion_asignada` | `INT UNSIGNED` | Sí | UK*, G | `Generado: CASE WHEN fin IS NULL THEN hospitalizacion_id END` |

**PK:** `asignacion_id`.
**UNIQUE:** `(camilla_ocupada)`; `(hospitalizacion_asignada)`.
- **fk_asignacion_hosp:** `(hospitalizacion_id)` → `hospitalizaciones(hospitalizacion_id)`.
- **fk_asignacion_camilla:** `(camilla_id)` → `camillas(camilla_id)`.

**CHECK:**
- `ck_asignacion_fechas`: `fin IS NULL OR fin > inicio`.

**Índices adicionales:** `KEY ix_asignacion_historial (camilla_id, inicio, fin)`.

### 19. notas_enfermeria

Observaciones de personal de enfermería durante una estancia.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `nota_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `hospitalizacion_id` | `INT UNSIGNED` | No | FK | `-` |
| `personal_id` | `INT UNSIGNED` | No | FK | `-` |
| `fecha` | `DATETIME` | No | - | `CURRENT_TIMESTAMP` |
| `observacion` | `TEXT` | No | - | `-` |

**PK:** `nota_id`.
- **fk_nota_hosp:** `(hospitalizacion_id)` → `hospitalizaciones(hospitalizacion_id)`.
- **fk_nota_personal:** `(personal_id)` → `personal(personal_id)`.

## Farmacia e inventario

### 20. medicamentos

Catálogo de productos con concentración, presentación y unidad de inventario.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `medicamento_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `codigo` | `VARCHAR(30)` | No | UK* | `-` |
| `principio_activo` | `VARCHAR(150)` | No | - | `-` |
| `concentracion` | `VARCHAR(60)` | No | - | `-` |
| `presentacion` | `VARCHAR(100)` | No | - | `-` |
| `unidad_inventario` | `VARCHAR(40)` | No | - | `-` |
| `stock_minimo` | `INT UNSIGNED` | No | - | `0` |

**PK:** `medicamento_id`.
**UNIQUE:** `(codigo)`.

### 21. proveedores

Catálogo de proveedores de medicamentos.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `proveedor_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `nombre` | `VARCHAR(150)` | No | UK* | `-` |
| `telefono` | `VARCHAR(25)` | Sí | - | `-` |
| `email` | `VARCHAR(150)` | Sí | - | `-` |

**PK:** `proveedor_id`.
**UNIQUE:** `(nombre)`.

### 22. lotes_medicamento

Lote de un producto recibido de un proveedor, con caducidad y costo histórico.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `lote_id` | `INT UNSIGNED` | No | PK, UK*, AI | `Secuencia automática` |
| `medicamento_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `proveedor_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `numero_lote` | `VARCHAR(50)` | No | UK* | `-` |
| `fecha_recepcion` | `DATE` | No | - | `-` |
| `fecha_caducidad` | `DATE` | No | - | `-` |
| `costo_unitario` | `DECIMAL(12,2)` | No | - | `-` |

**PK:** `lote_id`.
**UNIQUE:** `(medicamento_id, proveedor_id, numero_lote)`; `(lote_id, medicamento_id)`.
- **fk_lote_medicamento:** `(medicamento_id)` → `medicamentos(medicamento_id)`.
- **fk_lote_proveedor:** `(proveedor_id)` → `proveedores(proveedor_id)`.

**CHECK:**
- `ck_lote_fechas`: `fecha_caducidad >= fecha_recepcion`.
- `ck_lote_costo`: `costo_unitario >= 0`.

### 23. recetas

Encabezado de prescripción asociado a una consulta.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `receta_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `consulta_id` | `INT UNSIGNED` | No | FK | `-` |
| `fecha_prescripcion` | `DATETIME` | No | - | `CURRENT_TIMESTAMP` |
| `observaciones` | `TEXT` | Sí | - | `-` |

**PK:** `receta_id`.
- **fk_receta_consulta:** `(consulta_id)` → `consultas(consulta_id)`.

### 24. receta_detalle

Indicaciones y cantidad prescrita por renglón; permite varios medicamentos por receta.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `receta_id` | `INT UNSIGNED` | No | PK, FK, UK* | `-` |
| `renglon` | `SMALLINT UNSIGNED` | No | PK, UK* | `-` |
| `medicamento_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `dosis` | `VARCHAR(100)` | No | - | `-` |
| `frecuencia` | `VARCHAR(100)` | No | - | `-` |
| `duracion_dias` | `SMALLINT UNSIGNED` | No | - | `-` |
| `via_administracion` | `VARCHAR(50)` | No | - | `-` |
| `cantidad_prescrita` | `INT UNSIGNED` | No | - | `-` |

**PK:** `receta_id, renglon`.
**UNIQUE:** `(receta_id, renglon, medicamento_id)`.
- **fk_rd_receta:** `(receta_id)` → `recetas(receta_id)`.
- **fk_rd_medicamento:** `(medicamento_id)` → `medicamentos(medicamento_id)`.

**CHECK:**
- `ck_rd_renglon`: `renglon > 0`.
- `ck_rd_cantidad`: `cantidad_prescrita > 0`.
- `ck_rd_duracion`: `duracion_dias > 0`.

### 25. dispensaciones

Evento de entrega de una receta por personal de farmacia; admite entregas parciales.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `dispensacion_id` | `INT UNSIGNED` | No | PK, UK*, AI | `Secuencia automática` |
| `receta_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `personal_id` | `INT UNSIGNED` | No | FK | `-` |
| `fecha` | `DATETIME` | No | - | `CURRENT_TIMESTAMP` |

**PK:** `dispensacion_id`.
**UNIQUE:** `(dispensacion_id, receta_id)`.
- **fk_disp_receta:** `(receta_id)` → `recetas(receta_id)`.
- **fk_disp_personal:** `(personal_id)` → `personal(personal_id)`.

### 26. dispensacion_detalle

Cantidad de un renglón prescrito entregada desde un lote compatible.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `dispensacion_detalle_id` | `INT UNSIGNED` | No | PK, UK*, AI | `Secuencia automática` |
| `dispensacion_id` | `INT UNSIGNED` | No | FK | `-` |
| `receta_id` | `INT UNSIGNED` | No | FK | `-` |
| `renglon` | `SMALLINT UNSIGNED` | No | FK | `-` |
| `medicamento_id` | `INT UNSIGNED` | No | FK | `-` |
| `lote_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `cantidad` | `INT UNSIGNED` | No | - | `-` |

**PK:** `dispensacion_detalle_id`.
**UNIQUE:** `(dispensacion_detalle_id, lote_id)`.
- **fk_dd_dispensacion:** `(dispensacion_id, receta_id)` → `dispensaciones(dispensacion_id, receta_id)`.
- **fk_dd_receta_detalle:** `(receta_id, renglon, medicamento_id)` → `receta_detalle(receta_id, renglon, medicamento_id)`.
- **fk_dd_lote:** `(lote_id, medicamento_id)` → `lotes_medicamento(lote_id, medicamento_id)`.

**CHECK:**
- `ck_dd_cantidad`: `cantidad > 0`.

**Índices adicionales:** `KEY ix_dd_prescrito (receta_id, renglon)`.

### 27. movimientos_inventario

Libro de entradas, salidas y ajustes firmados; existencia = suma de cantidades por lote.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `movimiento_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `lote_id` | `INT UNSIGNED` | No | FK | `-` |
| `dispensacion_detalle_id` | `INT UNSIGNED` | Sí | FK, UK* | `-` |
| `personal_id` | `INT UNSIGNED` | No | FK | `-` |
| `fecha` | `DATETIME` | No | - | `CURRENT_TIMESTAMP` |
| `tipo` | `ENUM('ENTRADA','SALIDA','AJUSTE')` | No | - | `-` |
| `cantidad` | `INT` | No | - | `-` |
| `motivo` | `VARCHAR(250)` | No | - | `-` |

**PK:** `movimiento_id`.
**UNIQUE:** `(dispensacion_detalle_id)`.
- **fk_mov_lote:** `(lote_id)` → `lotes_medicamento(lote_id)`.
- **fk_mov_personal:** `(personal_id)` → `personal(personal_id)`.
- **fk_mov_disp:** `(dispensacion_detalle_id, lote_id)` → `dispensacion_detalle(dispensacion_detalle_id, lote_id)`.

**CHECK:**
- `ck_mov_signo`: `(tipo = 'ENTRADA' AND cantidad > 0) OR (tipo = 'SALIDA' AND cantidad < 0) OR (tipo = 'AJUSTE' AND cantidad <> 0)`.
- `ck_mov_disp_tipo`: `dispensacion_detalle_id IS NULL OR tipo = 'SALIDA'`.

**Índices adicionales:** `KEY ix_mov_lote (lote_id, movimiento_id)`.

## Estudios y procedimientos

### 28. procedimientos

Catálogo común de estudios de laboratorio, imagen, cirugía y otros procedimientos.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `procedimiento_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `codigo` | `VARCHAR(30)` | No | UK* | `-` |
| `nombre` | `VARCHAR(150)` | No | - | `-` |
| `tipo` | `ENUM('LABORATORIO','IMAGEN','CIRUGIA','OTRO')` | No | - | `-` |
| `precio_referencia` | `DECIMAL(12,2)` | No | - | `-` |

**PK:** `procedimiento_id`.
**UNIQUE:** `(codigo)`.

**CHECK:**
- `ck_procedimiento_precio`: `precio_referencia >= 0`.

### 29. ordenes_procedimiento

Solicitud de un único procedimiento a partir de una consulta.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `orden_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `consulta_id` | `INT UNSIGNED` | No | FK | `-` |
| `procedimiento_id` | `INT UNSIGNED` | No | FK | `-` |
| `fecha_solicitud` | `DATETIME` | No | - | `CURRENT_TIMESTAMP` |
| `fecha_programada` | `DATETIME` | Sí | - | `-` |
| `estado` | `ENUM('SOLICITADA','PROGRAMADA','REALIZADA','CANCELADA')` | No | - | `'SOLICITADA'` |
| `indicaciones` | `TEXT` | Sí | - | `-` |

**PK:** `orden_id`.
- **fk_orden_consulta:** `(consulta_id)` → `consultas(consulta_id)`.
- **fk_orden_procedimiento:** `(procedimiento_id)` → `procedimientos(procedimiento_id)`.

### 30. resultados_procedimiento

Un informe final por orden; no implementa versiones de resultados.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `resultado_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `orden_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `personal_id` | `INT UNSIGNED` | No | FK | `-` |
| `fecha_resultado` | `DATETIME` | No | - | `-` |
| `informe` | `TEXT` | No | - | `-` |

**PK:** `resultado_id`.
**UNIQUE:** `(orden_id)`.
- **fk_resultado_orden:** `(orden_id)` → `ordenes_procedimiento(orden_id)`.
- **fk_resultado_personal:** `(personal_id)` → `personal(personal_id)`.

## Cobros

### 31. facturas

Cuenta académica del paciente, con póliza opcional del mismo paciente.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `factura_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `folio` | `VARCHAR(40)` | No | UK* | `-` |
| `paciente_id` | `INT UNSIGNED` | No | FK | `-` |
| `poliza_id` | `INT UNSIGNED` | Sí | FK | `-` |
| `fecha` | `DATETIME` | No | - | `CURRENT_TIMESTAMP` |
| `estado` | `ENUM('ABIERTA','EMITIDA','ANULADA')` | No | - | `'ABIERTA'` |

**PK:** `factura_id`.
**UNIQUE:** `(folio)`.
- **fk_factura_paciente:** `(paciente_id)` → `pacientes(paciente_id)`.
- **fk_factura_poliza:** `(poliza_id, paciente_id)` → `polizas(poliza_id, paciente_id)`.

### 32. factura_detalle

Cargos con descripción y precio históricos; importe generado por renglón.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `factura_id` | `INT UNSIGNED` | No | PK, FK | `-` |
| `renglon` | `SMALLINT UNSIGNED` | No | PK | `-` |
| `descripcion` | `VARCHAR(250)` | No | - | `-` |
| `cantidad` | `DECIMAL(10,2)` | No | - | `-` |
| `precio_unitario` | `DECIMAL(12,2)` | No | - | `-` |
| `descuento` | `DECIMAL(12,2)` | No | - | `0` |
| `importe` | `DECIMAL(14,2)` | Sí | G | `Generado: ROUND(cantidad * precio_unitario - descuento, 2)` |

**PK:** `factura_id, renglon`.
- **fk_fd_factura:** `(factura_id)` → `facturas(factura_id)`.

**CHECK:**
- `ck_fd_renglon`: `renglon > 0`.
- `ck_fd_cantidad`: `cantidad > 0`.
- `ck_fd_precio`: `precio_unitario >= 0`.
- `ck_fd_descuento`: `descuento >= 0 AND descuento <= cantidad * precio_unitario`.

### 33. pagos

Pagos parciales positivos asociados a una factura.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `pago_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `factura_id` | `INT UNSIGNED` | No | FK | `-` |
| `fecha` | `DATETIME` | No | - | `CURRENT_TIMESTAMP` |
| `monto` | `DECIMAL(14,2)` | No | - | `-` |
| `metodo` | `ENUM('EFECTIVO','TARJETA','TRANSFERENCIA','ASEGURADORA')` | No | - | `-` |
| `referencia` | `VARCHAR(100)` | Sí | - | `-` |

**PK:** `pago_id`.
- **fk_pago_factura:** `(factura_id)` → `facturas(factura_id)`.

**CHECK:**
- `ck_pago_monto`: `monto > 0`.

## Acceso de la aplicación

### 34. roles

Roles conceptuales de la futura aplicación; no son roles del servidor MySQL.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `rol_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `nombre` | `VARCHAR(50)` | No | UK* | `-` |
| `descripcion` | `VARCHAR(250)` | No | - | `-` |

**PK:** `rol_id`.
**UNIQUE:** `(nombre)`.

### 35. usuarios

Cuenta vinculada a un trabajador; campo para hash, sin motor de autenticación.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `usuario_id` | `INT UNSIGNED` | No | PK, AI | `Secuencia automática` |
| `personal_id` | `INT UNSIGNED` | No | FK, UK* | `-` |
| `nombre_usuario` | `VARCHAR(80)` | No | UK* | `-` |
| `password_hash` | `VARCHAR(255)` | No | - | `-` |
| `activo` | `BOOLEAN` | No | - | `TRUE` |

**PK:** `usuario_id`.
**UNIQUE:** `(personal_id)`; `(nombre_usuario)`.
- **fk_usuario_personal:** `(personal_id)` → `personal(personal_id)`.

**CHECK:**
- `ck_usuario_activo`: `activo IN (0,1)`.

### 36. usuario_roles

Relación de muchos a muchos entre cuentas de aplicación y roles.

| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |
| --- | --- | --- | --- | --- |
| `usuario_id` | `INT UNSIGNED` | No | PK, FK | `-` |
| `rol_id` | `INT UNSIGNED` | No | PK, FK | `-` |

**PK:** `usuario_id, rol_id`.
- **fk_ur_usuario:** `(usuario_id)` → `usuarios(usuario_id)`.
- **fk_ur_rol:** `(rol_id)` → `roles(rol_id)`.

## Campos y valores calculados

- Edad: calcular desde `pacientes.fecha_nacimiento` para la fecha consultada; no se almacena.
- Existencia por lote: `SUM(movimientos_inventario.cantidad)`. Entradas positivas, salidas negativas y ajustes con signo.
- Total de factura: suma de `factura_detalle.importe`. Saldo: total menos suma de pagos. No existe un total editable independiente.
- Disponibilidad de camilla: condición operativa habilitada y ausencia de asignación activa; también deben respetarse los períodos consultados.
- `medico_agenda`, `paciente_agenda`, `diagnostico_principal`, `paciente_internado`, `camilla_ocupada` y `hospitalizacion_asignada` son auxiliares generados de restricciones, sin significado clínico nuevo.
- `factura_detalle.importe` es un cálculo determinista generado; descripción y precio_unitario son instantáneas históricas deliberadas.

## Unidad y dominio

Una sola moneda académica: pesos mexicanos (MXN), sin conversión. Los importes usan DECIMAL con dos decimales. Las cantidades de inventario son enteras y se expresan en unidad_inventario; las cantidades cobradas permiten fracciones. Las fechas de calendario usan DATE y eventos DATETIME; el proyecto asume una zona local común, America/Mexico_City. SQL no incorpora automáticamente esa política de zona horaria.

No debe ingresarse una contraseña en texto claro en password_hash. El sistema de ejemplo no autentica personas ni concede permisos del servidor MySQL.
