# Hospital universitario en MySQL

Propuesta académica integral con **36 tablas**, diagramas físicos, diccionario, reporte y scripts separados. La estructura original de cinco tablas se conserva como evidencia; los datos de esos archivos no se migran automáticamente.

## Empieza aquí

**Uso con ventanas:** abre `ABRIR_HOSPITAL.bat` y sigue [el tutorial nuevo de la interfaz](tutorial_interfaz/TUTORIAL.md). La aplicación permite crear la base con ejemplos, consultar las 36 tablas y registrar información sin escribir SQL. Esta guía y el tutorial anterior conservan el material técnico del diseño.

**Demostración ampliada y aporte del equipo:** para una instalación nueva con más registros, usa `hospital_demostracion.sql`. Si ya cargaste la muestra inicial, agrega `05_datos_demo_ampliados.sql` una vez. [DATOS_DEMOSTRACION.md](DATOS_DEMOSTRACION.md) explica la carga y sus conteos; [aporte_equipo/README.md](aporte_equipo/README.md) documenta la fusión de las capturas. Los diagramas y el diccionario describen la misma estructura de 36 tablas. Los números del reporte y del tutorial corresponden a la muestra inicial; las 122 comprobaciones de la ampliación están en `VALIDACION_DATOS_AMPLIADOS.json`.

Para estudiar el uso técnico de SQL en Workbench se conserva `tutorial/tutorial_hospital_principiantes.docx` y su PDF de 27 páginas. `tutorial/hospital_practica.sql` crea una base ficticia independiente para esos ejercicios. Su SQL pasó 28 de 28 comprobaciones. Para operar el hospital mediante formularios, usa el tutorial nuevo de `tutorial_interfaz`.

1. Lee `REVISION.md` para entender qué había y qué se corrigió.
2. Abre `diagramas/vision_modulos.svg` y `diagramas/er_completo.svg` en un navegador; usa zoom para el ER completo. Los SVG son vectoriales.
3. Usa `MODELO.md` para alcance, cardinalidades, reglas y normalización; `DICCIONARIO.md` enumera todos los campos y claves.
4. Consulta `reporte_hospital.pdf` para una presentación formal del mismo diseño.

## Archivos

| Archivo | Uso |
| --- | --- |
| 01_esquema.sql | Crea hospital_universitario, sus 36 tablas, claves, CHECK e índices |
| hospital_completo.sql | Opción sencilla: estructura, reglas y datos ficticios en un archivo |
| 02_reglas.sql | 6 vistas, 6 procedimientos y 23 triggers de validación |
| 03_datos_demo.sql | Carga datos ficticios coherentes |
| 04_consultas.sql | Consultas de atención, ocupación, farmacia, resultados y cobros |
| REVISION.md | Hallazgos sobre las cinco tablas originales |
| MODELO.md | Justificación, normalización, supuestos y límites |
| DICCIONARIO.md | Campos, tipos, NULL, PK, FK, UNIQUE, CHECK y derivados |
| reporte_hospital.pdf | Reporte académico legible e imprimible |
| diagramas/*.svg | ER completo, ER por módulos y visión funcional |
| diagramas/*.mmd | Fuentes Mermaid consistentes con el DDL |
| diagramas/*_relaciones.md | Correspondencia Fxx del SVG con cada FK exacta |
| evidencia_original/*.sdi.json | Metadatos recuperados, no registros de pacientes |
| evidencia_original/manifest.json | Tamaños, versiones y huellas de los originales |
| validar_proyecto.py / VALIDACION.json | Ejecutor y evidencia real de las pruebas de servidor |
| generar_documentacion.py | Regenera diccionario, diagramas y PDF desde 01_esquema.sql; lee evidencia histórica en VALIDACION.json |

## Requisitos y ejecución en MySQL Workbench

MySQL **8.0.16 o posterior** (no MariaDB). InnoDB, utf8mb4 y permisos para crear un esquema nuevo, tablas, vistas, procedimientos y triggers. La propuesta usa CHECK aplicados y columnas generadas; no ejecutar en una versión anterior suponiendo la misma protección. Versión utilizada en la validación de esta entrega: MySQL 8.0.45, instancia temporal de pruebas en modo estricto.

1. Conéctate a un servidor de pruebas en MySQL Workbench.
2. Elige UNA forma de instalación: ejecuta hospital_completo.sql completo una vez; o ejecuta por separado 01_esquema.sql → 02_reglas.sql → 03_datos_demo.sql, en ese orden. No ejecutes ambas opciones: contienen la misma instalación y datos.
3. La instalación crea un esquema NUEVO llamado hospital_universitario; si ya existe, detente y decide otro nombre antes de ejecutar. No elimina bases anteriores. DELIMITER es una instrucción del cliente: ejecuta las reglas como script completo.
4. Ejecuta 04_consultas.sql y revisa sus 20 consultas junto con las preguntas que responde cada una.
5. Consulta VALIDACION.json para los resultados verificables. validar_proyecto.py crea su propia base hospital_prueba_UUID, carga y verifica los scripts, y la elimina al finalizar. Usa sus argumentos --mysql, --user, --port y --output en un servidor de pruebas; no se acepta un nombre de base existente para eliminar. La contraseña, si se necesita, se lee de MYSQL_PWD y no debe escribirse en argumentos públicos.

También puedes usar el cliente mysql: desde su consola, SOURCE ruta/01_esquema.sql y luego los archivos en el orden anterior; usa una ruta real de tu equipo. En PowerShell evita reutilizar comandos de redirección de Bash sin adaptación. No pongas una contraseña en el historial de comandos.

## Estado de verificación

La ejecución documentada en VALIDACION.json está APROBADO: 82 de 82 comprobaciones correctas y 0 fallidas. Incluye carga del proyecto, consistencia del modelo y datos, ejecución de las 20 consultas, rechazos esperados y dos pruebas con sesiones concurrentes (agenda e inventario). La base temporal de pruebas se eliminó correctamente.

El diccionario y Mermaid se generan del mismo DDL y comprueban 36 tablas, PK presentes y referencias a columnas existentes. La inspección estática no sustituye ejecutar SQL en un servidor. La validación funcional/concurrente se documenta por separado y solo se afirma cuando existe evidencia.

La evidencia adjunta corresponde a los scripts entregados. Al cambiar SQL o datos, vuelve a ejecutar el validador y actualiza el JSON antes de presentar esos resultados como validación del nuevo contenido. Las dos pruebas concurrentes comprueban los casos incluidos; no constituyen una certificación de todos los escenarios de concurrencia posibles.

Los seis procedimientos de negocio gestionan sus propias transacciones. Invócalos con CALL como operaciones autónomas, fuera de otra transacción abierta: agendar cita, asignar/trasladar camilla, dar alta, registrar movimiento, dispensar medicamento y registrar pago. Consulta los parámetros exactos en 02_reglas.sql; los parámetros de fecha permiten casos de prueba y no implican que el servidor los obtenga todos de su reloj.

En inventario, captura movimientos por orden cronológico de cada lote; las rutinas rechazan fechas anteriores al último movimiento. Las correcciones se hacen con un nuevo AJUSTE y su motivo. No modifiques ni borres movimientos históricos. En cobros, crea la factura ABIERTA, agrega sus detalles y luego actualízala a EMITIDA; los pagos registrados son inmutables y no hay flujo de devolución en este alcance.

Los usuarios ficticios se cargan inactivos y con hashes marcadores sin credenciales funcionales. La aplicación de escritorio utiliza la conexión MySQL y no implementa autenticación de empleados. Invoca los procedimientos para agenda, camas, inventario, entregas y pagos, y restringe las escrituras directas de esos historiales desde sus formularios.

## Guion para defender el proyecto

- Explica el caso: cita o urgencia → consulta → diagnóstico → receta/orden → dispensación/resultado → factura → pago.
- Muestra cómo una receta admite varios renglones y la entrega parcial no modifica la prescripción.
- Explica la diferencia entre operación de una camilla y ocupación; conserva traslados con intervalos.
- Justifica las tablas puente para relaciones M:N y muestra ejemplos de 1FN, 2FN y 3FN en MODELO.md.
- Señala las excepciones controladas: FKs compuestas, precios históricos y columnas generadas. No afirmes 3FN estricta de todas las columnas físicas.
- Distingue una regla CHECK por fila de reglas entre filas que necesitan transacciones y bloqueos.
- Consulta existencia por lote y saldo de factura para mostrar una fuente única de valores calculados.
- Reconoce límites académicos: factura no fiscal, resultados sin versiones, cirugías simplificadas y acceso sin autenticación.

## Datos originales y alcance

Los .ibd originales permanecen intactos. Este proyecto usa una base nueva y datos ficticios; no es una recuperación de filas ni una migración de los registros originales. Para migrar, solicita un respaldo SQL del prototipo o realiza una recuperación compatible y valida sus datos antes de transformarlos.

La consigna detallada del profesor está pendiente. El diseño cubre procesos principales de un hospital con fines académicos y puede ajustarse a la rúbrica sin prometer que cubre literalmente todos los sistemas de un hospital real.
