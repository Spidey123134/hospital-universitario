-- CONSULTAS DE LECTURA PARA VER REGISTROS COMO EN UNA CUADRICULA DE WORKBENCH.
-- Ejecutar despues de hospital_demostracion.sql o de la ampliacion 05.
-- Selecciona cada bloque por separado. No agrega ni modifica datos.
USE hospital_universitario;

-- 1. Medicos con sus nombres y especialidades: 18 filas tras la ampliacion.
-- En el modelo normalizado los nombres estan en personal.
SELECT m.medico_id, m.cedula_profesional, p.nombre,
       p.apellido_paterno,
       GROUP_CONCAT(e.nombre ORDER BY e.nombre SEPARATOR ', ')
         AS especialidades
FROM medicos m
JOIN personal p ON p.personal_id = m.medico_id
LEFT JOIN medico_especialidad me ON me.medico_id = m.medico_id
LEFT JOIN especialidades e ON e.especialidad_id = me.especialidad_id
GROUP BY m.medico_id, m.cedula_profesional, p.nombre, p.apellido_paterno
ORDER BY m.medico_id;

-- 2. Pacientes: 30 filas tras la ampliacion.
SELECT paciente_id, expediente_clinico, nombre, apellido_paterno,
       fecha_nacimiento, sexo, telefono
FROM pacientes ORDER BY paciente_id;

-- 3. Medicamentos y existencia calculada: 15 filas.
SELECT m.medicamento_id, m.codigo, m.principio_activo,
       m.concentracion, m.presentacion, s.stock_total AS stock_disponible
FROM medicamentos m
JOIN v_stock_medicamentos s ON s.medicamento_id = m.medicamento_id
ORDER BY m.medicamento_id;

-- 4. Recetas con datos completos: 64 renglones de 40 recetas.
-- Una receta puede contener varios medicamentos; por eso su ID se repite.
SELECT r.receta_id, rd.renglon, c.paciente_id,
       CONCAT_WS(' ', p.nombre, p.apellido_paterno) AS paciente,
       c.medico_id,
       CONCAT_WS(' ', pe.nombre, pe.apellido_paterno) AS medico,
       rd.medicamento_id, m.principio_activo AS medicamento,
       r.fecha_prescripcion, rd.dosis, rd.frecuencia,
       rd.duracion_dias, rd.via_administracion,
       rd.cantidad_prescrita, r.observaciones
FROM recetas r
JOIN consultas c ON c.consulta_id = r.consulta_id
JOIN pacientes p ON p.paciente_id = c.paciente_id
JOIN personal pe ON pe.personal_id = c.medico_id
JOIN receta_detalle rd ON rd.receta_id = r.receta_id
JOIN medicamentos m ON m.medicamento_id = rd.medicamento_id
ORDER BY r.receta_id, rd.renglon;

-- 5. Camillas y ubicacion: 15 filas.
SELECT c.camilla_id, c.codigo, h.edificio,
       h.codigo AS habitacion, c.estado_operativo, v.disponibilidad
FROM camillas c JOIN habitaciones h ON h.habitacion_id = c.habitacion_id
JOIN v_camillas_estado v ON v.camilla_id = c.camilla_id
ORDER BY c.camilla_id;

-- 6. Hospitalizaciones: 11 filas, incluidas 7 abiertas.
SELECT h.hospitalizacion_id,
       CONCAT_WS(' ', p.nombre, p.apellido_paterno) AS paciente,
       h.fecha_ingreso, h.fecha_alta,
       CASE WHEN h.fecha_alta IS NULL THEN 'ABIERTA' ELSE 'CERRADA' END AS estado
FROM hospitalizaciones h JOIN pacientes p ON p.paciente_id = h.paciente_id
ORDER BY h.hospitalizacion_id;

-- 7. Cobros: 29 facturas con casos pagados, parciales y sin pago.
SELECT f.factura_id, f.folio, p.nombre AS paciente,
       f.estado, v.total, v.pagado, v.saldo
FROM facturas f JOIN pacientes p ON p.paciente_id = f.paciente_id
JOIN v_facturas_saldo v ON v.factura_id = f.factura_id
ORDER BY f.factura_id;

-- 8. Conteos principales para comprobar que se cargo la ampliacion.
SELECT 'pacientes' AS tabla, COUNT(*) AS registros FROM pacientes
UNION ALL SELECT 'medicos', COUNT(*) FROM medicos
UNION ALL SELECT 'medicamentos', COUNT(*) FROM medicamentos
UNION ALL SELECT 'camillas', COUNT(*) FROM camillas
UNION ALL SELECT 'consultas', COUNT(*) FROM consultas
UNION ALL SELECT 'recetas', COUNT(*) FROM recetas
UNION ALL SELECT 'receta_detalle', COUNT(*) FROM receta_detalle
UNION ALL SELECT 'facturas', COUNT(*) FROM facturas;

-- 9. Solo los 15 medicos del aporte del equipo (los otros 3 son la muestra inicial).
SELECT m.medico_id, m.cedula_profesional, p.nombre, p.apellido_paterno,
       e.nombre AS especialidad
FROM medicos m JOIN personal p ON p.personal_id = m.medico_id
JOIN medico_especialidad me ON me.medico_id = m.medico_id
JOIN especialidades e ON e.especialidad_id = me.especialidad_id
WHERE m.cedula_profesional LIKE 'CP-10%'
ORDER BY m.medico_id;

-- 10. Solo las 15 recetas adaptadas de las capturas del equipo.
-- Las observaciones distinguen los datos transcritos de los agregados.
SELECT r.receta_id, c.paciente_id, c.medico_id,
       CONCAT_WS(' ', pe.nombre, pe.apellido_paterno) AS medico,
       rd.medicamento_id, m.principio_activo AS medicamento_de_ejemplo,
       r.fecha_prescripcion, rd.dosis, rd.via_administracion,
       r.observaciones
FROM recetas r JOIN consultas c ON c.consulta_id = r.consulta_id
JOIN personal pe ON pe.personal_id = c.medico_id
JOIN receta_detalle rd ON rd.receta_id = r.receta_id
JOIN medicamentos m ON m.medicamento_id = rd.medicamento_id
WHERE r.observaciones LIKE '[APORTE EQUIPO%'
ORDER BY r.receta_id;
