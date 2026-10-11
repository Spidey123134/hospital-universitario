# Tutorial de la base de datos del hospital

## Guía desde cero para estudiantes y docentes

Aprende a abrir el proyecto, ver sus tablas, ejecutar consultas, practicar cambios, crear un diagrama y hacer un respaldo. No necesitas saber programar para comenzar.

Este manual corresponde al proyecto hospital_universitario: 36 tablas, 6 vistas, 6 procedimientos y 23 triggers. Usa datos ficticios y está pensado para una entrega universitaria.

## Qué necesitas

Una computadora con Windows, MySQL Server, MySQL Workbench y los archivos de la carpeta propuesta_hospital. Si ya puedes conectarte al servidor, ve a la página 4.

## Elige por dónde empezar

| Objetivo | Páginas |
| --- | --- |
| Ver el proyecto por primera vez | 2 y 4 a 8 |
| Instalar los programas | 3 |
| Practicar sin cambiar la entrega | 9 a 20 |
| Guardar un respaldo y recuperarlo | 21 y 22 |
| Presentar el proyecto al profesor | 23 |
| Editar un dato usando el ratón | 24 |
| Resolver errores y entender términos | 25 a 27 |

## Regla para todos los ejercicios

Lee primero el paso. Después selecciona y ejecuta solamente el bloque SQL indicado. Los cambios de los ejercicios se hacen en hospital_practica. Las instrucciones para crear las bases se ejecutan completas una sola vez.

Versión de servidor utilizada para validar el proyecto original: MySQL 8.0.45. Requisito del SQL: MySQL 8.0.16 o posterior. Esta guía muestra menús de Workbench 8.0; algunas etiquetas pueden variar.

Guarda la contraseña del servidor y la ubicación de tus archivos. No necesitas entregar tu contraseña al profesor.

# 1 Entender qué estás abriendo

Una base de datos organiza información en tablas. Imagina una tabla como una hoja con columnas y filas: cada fila de pacientes representa una persona ficticia; sus columnas guardan nombre, teléfono y otros datos.

| Elemento | Qué hace |
| --- | --- |
| MySQL Server | Guarda los datos y ejecuta las instrucciones SQL. Debe estar encendido. |
| MySQL Workbench | Es la interfaz que usas para conectarte, consultar y enviar cambios al servidor. |
| Archivo .sql | Es texto con instrucciones. Abrirlo no instala ni cambia la base. |
| Archivo .docx o .pdf | Es documentación para leer. No crea tablas. |
| Archivo .svg | Es un dibujo que puedes abrir en un navegador y ampliar. |
| Archivo .mwb | Es un modelo editable de Workbench, con diagramas. |

## Recorrido rápido para ver el proyecto

1. Extrae hospital_universitario.zip: clic derecho sobre el ZIP, Extraer todo y Extraer. Trabaja con los archivos extraídos.

2. Abre MySQL Workbench y entra a una conexión que funcione. La página 4 explica cómo crearla.

3. Si hospital_universitario todavía no existe, abre hospital_completo.sql y ejecútalo completo como se explica en la página 6.

4. En Schemas, refresca el panel y abre hospital_universitario → Tables → pacientes. Elige Select Rows – Limit… con clic derecho.

5. Abre diagramas/vision_modulos.svg para ubicar las áreas del hospital y diagramas/er_completo.svg para ver sus relaciones.

## Lo que se guarda en cada lugar

Los datos viven en el servidor. El archivo SQL contiene instrucciones y el Word explica cómo usarlas. Copiar la carpeta del proyecto a otra computadora no copia los cambios que ya hiciste en el servidor; para eso necesitas un respaldo.

# 2 Instalar MySQL y Workbench

Si ya tienes MySQL Server y Workbench funcionando, salta esta página. Workbench por sí solo no es el servidor.

## Ruta para seguir la versión 8 punto 0 del proyecto

1. Entra a https://dev.mysql.com/downloads/installer/ y descarga MySQL Installer Community para Windows. La serie de ese asistente es 8.0. No es la versión más nueva de MySQL.

2. Ejecuta el instalador. En Setup Type, elige Custom. En la selección de productos agrega MySQL Server 8.0 y MySQL Workbench. Si aparece una actualización de mantenimiento de la serie 8.0, anota la versión instalada.

3. En Check Requirements, resuelve los requisitos indicados por el asistente. Ejecuta la instalación y espera a que termine.

4. En la configuración del servidor, selecciona Development Computer o Development según la etiqueta. Usa TCP/IP y anota el puerto, normalmente 3306.

5. Define una contraseña para root. Guárdala. Sigue la configuración como servicio de Windows, aplica los cambios y comprueba que terminó correctamente.

6. Abre Workbench desde Inicio. Si no aparece, confirma que lo seleccionaste en el instalador.

## Si instalas MySQL 8 punto 4

Descarga Server 8.4 LTS desde https://dev.mysql.com/downloads/mysql/ y Workbench desde https://dev.mysql.com/downloads/workbench/. El MSI de Server 8.4 usa MySQL Configurator; Workbench se instala aparte. Configura Development, TCP/IP, contraseña de root y servicio de Windows; luego aplica la configuración.

Los scripts originales se probaron en Server 8.0.45. Workbench se desarrolló y probó con Server 8.0; su manual advierte que algunas funciones gráficas pueden fallar con 8.4 o versiones posteriores. No interpretes esa advertencia de conexión como prueba de que el SQL falló.

## Si ya existe un servidor

Usa el puerto y usuario de ese servidor. Si el puerto 3306 está ocupado, identifica qué instancia lo utiliza antes de crear otra. El puerto 33060 es de otro protocolo y no se usa en esta conexión Standard TCP/IP.

Fuentes oficiales de instalación y compatibilidad: página 27.

# 3 Crear y probar la conexión

Una conexión le dice a Workbench dónde está el servidor y con qué usuario entrar. El nombre de la conexión es solo una etiqueta.

1. En la pantalla inicial de Workbench, localiza MySQL Connections y pulsa el signo +.

2. Completa los campos usando los datos de tu instalación:

| Campo | Valor para un servidor local típico |
| --- | --- |
| Connection Name | Hospital local |
| Connection Method | Standard (TCP/IP) |
| Hostname | 127.0.0.1 o localhost |
| Port | 3306, o el puerto que anotaste |
| Username | root, o el usuario que te proporcionaron |
| Default Schema | Déjalo vacío en esta primera conexión |

3. Pulsa Test Connection. Escribe la contraseña que definiste al instalar el servidor.

4. Si la prueba funciona, pulsa OK. Luego abre la conexión desde la pantalla inicial.

5. En una pestaña SQL nueva, pega y ejecuta esta consulta:

```sql
SELECT VERSION() AS version_servidor,
       @@version_comment AS descripcion;
```

Resultado esperado: una fila con la versión y descripción del servidor. Si aparece MariaDB, no es el motor MySQL validado en este proyecto; la etiqueta MySQL de XAMPP no basta para identificarlo.

## Si no puedes entrar

Connection refused o error 2003: comprueba que el servicio del servidor está iniciado y que el puerto sea correcto. Access denied o error 1045: revisa usuario y contraseña. Workbench debe conectarse antes de que puedas ejecutar SQL.

No hay una contraseña universal del proyecto. Los registros ficticios de la tabla usuarios tampoco son cuentas para conectarse a MySQL.

# 4 Ubicar los botones y ejecutar SQL

Una vez conectada la sesión, identifica estas zonas de Workbench:

| Zona | Para qué sirve |
| --- | --- |
| Schemas a la izquierda | Muestra bases, tablas, vistas y rutinas. |
| Pestaña SQL en el centro | Aquí escribes o pegas instrucciones. |
| Barra con botones de rayo | Envía SQL al servidor. |
| Result Grid debajo del editor | Muestra filas devueltas por una consulta. |
| Action Output en la parte inferior | Muestra éxito, errores y mensajes de ejecución. |

## Para cada bloque de este manual

1. Abre una pestaña de consulta con el botón SQL + o File → New Query Tab. Pega el bloque sin las marcas de formato del documento.

2. Selecciona con el ratón todas las líneas del bloque que quieres ejecutar. Incluye los puntos y coma.

3. Usa Query → Execute (All or Selection), o Ctrl + Shift + Enter. El primer botón de rayo hace esta misma operación: si no hay texto seleccionado, ejecuta toda la pestaña.

4. Revisa Result Grid y Action Output. Si un paso da error, resuélvelo antes de continuar con el siguiente.

Activa Query → Stop Script Execution On Errors para que un error detenga el bloque. Si se detiene dentro de una transacción de práctica, ejecuta ROLLBACK antes de continuar.

## Instrucción actual frente a bloque completo

Ctrl + Enter ejecuta la instrucción donde está el cursor. Es útil para una consulta aislada. Los ejemplos con SET y SELECT o con START TRANSACTION y ROLLBACK necesitan que selecciones el bloque completo.

## Guardar y ejecutar son acciones diferentes

Ctrl + S guarda el texto en un archivo .sql. No ejecuta ese texto ni modifica el servidor. Ejecutar SQL envía las instrucciones al servidor; el resultado depende de cada instrucción y de la transacción.

No ejecutes todo este tutorial como si fuera un instalador. Incluye lecturas, cambios, operaciones que solo deben hacerse una vez y errores intencionales.

# 5 Crear la base del proyecto

Haz esto una sola vez por servidor cuando hospital_universitario todavía no exista. Si ya aparece, pasa a la siguiente página.

1. En Workbench conectado, abre File → Open SQL Script, o Ctrl + Shift + O.

2. Selecciona propuesta_hospital/hospital_completo.sql de la carpeta extraída.

3. Comprueba que la pestaña corresponde a ese archivo. No selecciones un fragmento: necesitas ejecutar el archivo completo.

4. Usa Query → Execute (All or Selection). Espera a que termine y revisa Action Output. Las instrucciones DELIMITER pertenecen al script de las rutinas; no las borres.

5. En Schemas, haz clic derecho y elige Refresh All. Despliega hospital_universitario.

6. En una pestaña nueva, ejecuta:

```sql
USE hospital_universitario;
SELECT DATABASE() AS base_actual;
SELECT COUNT(*) AS pacientes_iniciales
FROM pacientes;
```

Resultado inicial esperado: hospital_universitario y 5 pacientes ficticios. Si ya modificaste datos, el conteo puede ser diferente.

## Elige una forma de instalación

hospital_completo.sql reúne estructura, reglas y datos. También existen 01_esquema.sql, 02_reglas.sql y 03_datos_demo.sql para instalarlos por separado en ese orden. Usa una sola opción; ejecutar ambas vuelve a intentar crear los mismos objetos y datos.

## Si aparece un error

Error 1007: esa base ya existe. Detente; volver a ejecutar el archivo no actualiza ni guarda una instalación existente. Error 1050: una tabla ya existe, posiblemente por instalación parcial. Conserva la base y revisa el primer error de Action Output antes de decidir cómo corregirla.

Este instalador no borra una base anterior. Los cinco archivos .ibd del prototipo son evidencia; no se abren como scripts ni se cargan automáticamente.

# 6 Ver las tablas y comprobar la instalación

## Ver datos usando el ratón

1. En Schemas, abre hospital_universitario → Tables. Si no lo ves, usa Refresh All.

2. Haz clic derecho en pacientes y elige Select Rows – Limit… El número del límite depende de la versión y preferencias de Workbench.

3. Mira los nombres de las columnas y las filas ficticias de Result Grid. La pestaña SQL muestra la consulta que produjo ese resultado.

## Ver datos usando SQL

```sql
USE hospital_universitario;
SELECT paciente_id, expediente_clinico, nombre,
       apellido_paterno, fecha_nacimiento, telefono
FROM pacientes
ORDER BY paciente_id;
```

Esperas 5 filas en la carga inicial. ORDER BY ordena el resultado; no cambia el orden físico ni los datos guardados.

## Contar tablas y vistas

```sql
SELECT table_type AS tipo, COUNT(*) AS cantidad
FROM information_schema.tables
WHERE table_schema = DATABASE()
GROUP BY table_type;
```

Esperas BASE TABLE = 36 y VIEW = 6, es decir, 42 objetos entre ambos tipos. Una vista es una consulta guardada; no cuenta como tabla física del proyecto.

## Ver las columnas y la definición

```sql
DESCRIBE pacientes;
SHOW CREATE TABLE pacientes;
```

DESCRIBE muestra campos, tipos y claves. SHOW CREATE TABLE muestra el SQL completo de esa tabla. Si el texto se corta en la cuadrícula, usa clic derecho sobre la celda → Open Value in Editor para leerlo.

# 7 Abrir y crear los diagramas

## Ver el dibujo ya entregado

1. En el Explorador de archivos abre propuesta_hospital/diagramas.

2. Abre vision_modulos.svg con Edge, Chrome u otro navegador para ubicar las áreas del hospital. Abre er_completo.svg para ver tablas, campos y relaciones; usa zoom. Los archivos er_ por módulo permiten leer áreas más pequeñas.

3. Una línea conecta campos relacionados. El identificador de un paciente permite asociar citas, consultas y hospitalizaciones sin repetir toda su información en cada tabla.

## Crear tu propio diagrama editable en Workbench

1. En Workbench conectado, abre Database → Reverse Engineer.

2. Selecciona tu conexión y avanza con Next. Proporciona la contraseña si la pide.

3. Selecciona solamente hospital_universitario. No agregues otras bases del servidor.

4. Avanza hasta Select Objects to Reverse Engineer. Mantén las tablas y la opción Place imported objects on a diagram.

5. Pulsa Execute, revisa el resultado y termina con Finish. Si hay varias páginas del modelo, abre la pestaña EER Diagram.

6. Ordena las cajas para leerlas. Guarda el modelo con File → Save como hospital_modelo.mwb.

## Qué archivo consultar según la duda

| Archivo del proyecto | Qué explica |
| --- | --- |
| MODELO.md | Alcance, relaciones, reglas y normalización. |
| DICCIONARIO.md | Campos, tipos y claves de cada tabla. |
| REVISION.md | Problemas del prototipo y mejoras realizadas. |
| reporte_hospital.pdf | Informe académico completo. |
| 04_consultas.sql | 20 consultas para mostrar el funcionamiento. |

Guardar o mover cajas en el modelo .mwb no cambia automáticamente el servidor. Cuando cambies la estructura mediante SQL, genera de nuevo el modelo para que el dibujo corresponda a la base actual.

# 8 Crear una base para practicar

Antes de modificar datos, crea hospital_practica. Es una instalación nueva con los mismos datos ficticios iniciales; no es un respaldo de los cambios que hiciste en hospital_universitario.

1. Abre File → Open SQL Script y selecciona tutorial/hospital_practica.sql.

2. Ejecuta ese archivo completo una sola vez. No selecciones solo una parte.

3. Revisa Action Output y refresca Schemas. Ahora deben aparecer hospital_universitario y hospital_practica si instalaste ambas.

4. Abre una pestaña SQL nueva para los ejercicios y ejecuta:

```sql
USE hospital_practica;
SELECT DATABASE() AS base_actual,
       VERSION() AS version_mysql;
SHOW FULL TABLES;
```

Esperas base_actual = hospital_practica y 42 objetos de tabla o vista. Los siguientes ejercicios parten de la carga inicial y se realizan en orden.

## Comprueba la base antes de cada cambio

USE selecciona la base de esta sesión. Si abres otra conexión, vuelve a escribir USE hospital_practica. Como verificación rápida, ejecuta SELECT DATABASE(); y lee el nombre.

## Si hospital_practica ya existe

No vuelvas a ejecutar su instalador para reiniciarla. Puedes continuar con ella teniendo en cuenta los cambios que ya hiciste. Para otro inicio limpio, copia el archivo y reemplaza todas las apariciones del nombre hospital_practica por uno nuevo, por ejemplo hospital_practica_2, usando Find and Replace del editor. Comprueba el texto antes de ejecutar y usa ese nuevo nombre en tus consultas.

No cambies solo el nombre en CREATE DATABASE: las instrucciones USE del mismo archivo también deben apuntar al nombre nuevo. Conserva intactos los archivos originales del proyecto.

# 9 Consultar datos sin modificarlos

SELECT lee filas. Puedes ejecutar estas consultas varias veces: no cambian registros. Selecciona un bloque a la vez y revisa sus resultados.

## Mostrar columnas y ordenar

```sql
USE hospital_practica;
SELECT paciente_id, nombre, apellido_paterno, telefono
FROM pacientes
ORDER BY paciente_id;
```

SELECT indica qué columnas mostrar, FROM dice de qué tabla y ORDER BY ordena la lista. El punto y coma termina la instrucción.

## Filtrar con una condición

```sql
SELECT paciente_id, nombre, sexo, activo
FROM pacientes
WHERE activo = 1 AND sexo = 'F'
ORDER BY paciente_id;
```

En los datos iniciales aparecen las pacientes con IDs 1 y 4. AND pide que se cumplan las dos condiciones. El texto va entre comillas simples.

## Buscar parte de un texto

```sql
SELECT paciente_id, nombre
FROM pacientes
WHERE nombre LIKE '%Tres%';
```

Esperas al paciente con ID 3. El símbolo % permite que haya más caracteres antes o después de Tres.

## Contar en lugar de listar

```sql
SELECT COUNT(*) AS total_pacientes
FROM pacientes;
```

Esperas 5 antes de agregar otro paciente. COUNT(*) cuenta filas. AS da un nombre fácil de leer a una columna del resultado.

Una consulta sin resultados puede ser correcta: significa que ninguna fila cumplió la condición. Una fila de resultado con 0 en un conteo no es lo mismo que un error.

# 10 Consultar dos tablas relacionadas

Los datos de un paciente y los de sus contactos de emergencia viven en tablas distintas. JOIN permite mostrarlos juntos.

```sql
USE hospital_practica;
SELECT p.paciente_id, p.nombre AS paciente,
       ce.nombre AS contacto,
       ce.telefono AS telefono_contacto
FROM pacientes AS p
LEFT JOIN contactos_emergencia AS ce
  ON ce.paciente_id = p.paciente_id
 AND ce.prioridad = 1
ORDER BY p.paciente_id;
```

Resultado inicial: 5 filas, una por paciente, con su contacto de prioridad 1 cuando existe.

## Cómo leer esta consulta

p es un nombre corto para pacientes y ce para contactos_emergencia. p.nombre significa la columna nombre de pacientes.

ON une el contacto con el paciente que tiene el mismo paciente_id. La condición prioridad = 1 elige el contacto principal.

LEFT JOIN mantiene al paciente aunque no tenga ese contacto. En ese caso, las columnas del contacto aparecerán como NULL.

## Por qué importan las claves

paciente_id es la clave primaria de pacientes: identifica una fila sin ambigüedad. En contactos_emergencia es una clave foránea: señala a un paciente existente.

Dos personas pueden tener el mismo nombre. Por eso la relación usa un identificador y no el nombre de la persona. Tampoco debes escribir listas de contactos en una sola celda.

## Practica una consulta del proyecto

Abre 04_consultas.sql y busca una pregunta que te interese. Su instrucción USE apunta a hospital_universitario. Para probarla en tu copia, abre otra pestaña, escribe USE hospital_practica y pega solamente la consulta elegida, sin copiar el USE anterior.

Los ejercicios de transacción comentados al final de ese archivo son ejemplos adicionales. No necesitas ejecutarlos para ver sus 20 consultas de lectura.

# 11 Agregar un paciente ficticio

INSERT agrega una fila. Usaremos un expediente exclusivo del tutorial para reconocer el registro después.

1. Comprueba que la base es hospital_practica. Ejecuta este bloque una sola vez en la misma conexión que usarás en las dos páginas siguientes:

```sql
USE hospital_practica;
INSERT INTO pacientes (
  expediente_clinico, nombre, apellido_paterno,
  apellido_materno, fecha_nacimiento, sexo, telefono
)
VALUES (
  'EXP-TUTORIAL-001', 'Paciente Tutorial', 'Prueba',
  'Ficticio', '2000-01-15', 'NO_ESPECIFICADO',
  'TEL-TUTORIAL-001'
);
```

2. Comprueba en Action Output que INSERT terminó sin error. Solo si tuvo éxito, ejecuta este segundo bloque en la misma conexión:

```sql
SET @paciente_tutorial = LAST_INSERT_ID();
SELECT paciente_id, expediente_clinico, nombre, telefono
FROM pacientes
WHERE paciente_id = @paciente_tutorial;
```

3. Anota el paciente_id devuelto. Debe aparecer Paciente Tutorial con su expediente y teléfono ficticios.

## Lo que hizo el bloque

AUTO_INCREMENT genera el identificador. LAST_INSERT_ID() recupera el que acaba de generarse en esta conexión; no supongas que siempre será 6. La variable @paciente_tutorial guarda ese ID durante la sesión.

Las columnas que omitimos usan su valor predeterminado o permiten NULL según la definición de la tabla. Las fechas se escriben año-mes-día.

## Si sale el error 1062

El expediente ya existe. Detente: no ejecutes el SET ni las modificaciones siguientes basándote en un INSERT que falló. Para repetir el ejercicio, elige otro expediente exclusivo, cambia también los filtros posteriores y vuelve a insertar.

Si cerraste la conexión, la variable se pierde. Puedes recuperar el registro con SELECT paciente_id FROM pacientes WHERE expediente_clinico = 'EXP-TUTORIAL-001'; y establecer SET @paciente_tutorial = el_numero_real; reemplazando el_numero_real por el ID que leíste.

# 12 Cambiar un dato y deshacerlo

UPDATE cambia filas. Una transacción permite revisar un cambio antes de confirmarlo. Este ejercicio usa el paciente agregado en la página anterior.

1. En la misma conexión, selecciona y ejecuta el bloque completo:

```sql
USE hospital_practica;
START TRANSACTION;

SELECT paciente_id, telefono AS antes
FROM pacientes
WHERE paciente_id = @paciente_tutorial;

UPDATE pacientes
SET telefono = 'TEL-CAMBIADO-TUTORIAL'
WHERE paciente_id = @paciente_tutorial;

SELECT paciente_id, telefono AS durante
FROM pacientes
WHERE paciente_id = @paciente_tutorial;

ROLLBACK;

SELECT paciente_id, telefono AS despues
FROM pacientes
WHERE paciente_id = @paciente_tutorial;
```

2. Revisa las tres cuadrículas: antes y después deben mostrar TEL-TUTORIAL-001; durante debe mostrar TEL-CAMBIADO-TUTORIAL.

## Cómo guardar un cambio

START TRANSACTION abre una transacción. ROLLBACK deshace sus cambios pendientes; COMMIT los confirma. Si quieres guardar el teléfono nuevo en este ejercicio, repite el bloque sustituyendo ROLLBACK por COMMIT.

Con autocommit activo, una instrucción de modificación fuera de una transacción se confirma automáticamente. No confíes en Ctrl + Z para deshacer un cambio del servidor: ese atajo solo afecta al editor.

## Evita cambiar todas las filas

Antes de UPDATE, usa SELECT con el mismo WHERE y confirma qué fila apunta. Aquí WHERE usa una clave primaria. Sin WHERE, el cambio podría afectar a todos los pacientes.

No uses este patrón para los procedimientos de negocio ni para CREATE o ALTER. Esos casos tienen reglas diferentes que se explican más adelante.

# 13 Eliminar solo el registro de práctica

DELETE elimina filas. Este ejemplo borra únicamente el paciente que acabas de crear; todavía no tiene citas, consultas u otros registros asociados.

1. Ejecuta primero esta lectura y confirma que muestra Paciente Tutorial:

```sql
USE hospital_practica;
SELECT paciente_id, expediente_clinico, nombre
FROM pacientes
WHERE paciente_id = @paciente_tutorial
  AND expediente_clinico = 'EXP-TUTORIAL-001';
```

2. Si aparece exactamente el registro correcto, ejecuta el bloque siguiente:

```sql
DELETE FROM pacientes
WHERE paciente_id = @paciente_tutorial
  AND expediente_clinico = 'EXP-TUTORIAL-001';

SELECT ROW_COUNT() AS filas_eliminadas;

SELECT paciente_id, nombre
FROM pacientes
WHERE paciente_id = @paciente_tutorial;
```

Resultado esperado: filas_eliminadas = 1 y una última cuadrícula sin filas. Si aparece 0, revisa el ID, el expediente y si el registro ya se eliminó.

## Por qué se agrega el expediente al filtro

El identificador y el expediente exclusivo permiten comprobar juntos que estamos borrando el registro de este ejercicio. Si usaste otro expediente, cambia ambos filtros para que coincidan con el que insertaste.

## Por qué puede fallar eliminar un paciente

La base protege las relaciones. Un paciente con consultas o citas asociadas normalmente no se puede borrar directamente: el error 1451 indica que hay registros que dependen de él.

No borres registros relacionados para saltarte esa protección. Para conservar historia, muchas entidades permiten marcar activo = 0 mediante el flujo que corresponda. Este tutorial usa DELETE solo sobre el registro ficticio recién creado y sin dependencias.

Si Workbench devuelve 1175, consulta la página 25. Conserva un filtro con la clave primaria en lugar de desactivar globalmente Safe Updates.

# 14 Agendar una cita con un procedimiento

Un procedimiento agrupa instrucciones para una operación. sp_agendar_cita revisa el intervalo y evita solapamientos del médico o del paciente.

## Antes de empezar

Termina cualquier transacción pendiente con COMMIT para confirmar o ROLLBACK para deshacer lo que corresponda. Los seis procedimientos de negocio de este proyecto abren y confirman sus propias transacciones. No los envuelvas en otra transacción esperando deshacerlos después.

1. En hospital_practica con sus datos iniciales, ejecuta una sola vez:

```sql
USE hospital_practica;
SET @cita_tutorial = NULL;
CALL sp_agendar_cita(
  4, 1,
  '2026-10-15 15:00:00',
  '2026-10-15 15:30:00',
  'Cita ficticia del tutorial',
  @cita_tutorial
);
SELECT @cita_tutorial AS cita_creada;
SELECT cita_id, paciente_id, medico_id,
       inicio, fin, estado
FROM citas
WHERE cita_id = @cita_tutorial;
```

2. Esperas una cita para el paciente 4, médico 1 y el intervalo indicado. El último parámetro devuelve su identificador.

## Cómo interpretar los argumentos

4 es paciente_id y 1 es medico_id. Las dos fechas son inicio y fin. El texto es el motivo y @cita_tutorial recibe el resultado de salida. No reemplaces números sin verificar primero que existen en sus tablas.

Las fechas fijas permiten reproducir la demostración; no representan el día actual. Al repetir exactamente esta llamada, debe rechazarse el solapamiento de la cita ya creada. Eso demuestra una regla, no una falla de instalación.

Los parámetros y reglas de los seis procedimientos están en 02_reglas.sql. Esta guía muestra tres operaciones completas.

# 15 Consultar hospitalizaciones y camillas

Una camilla puede estar operativa y, al mismo tiempo, ocupada. Su disponibilidad combina el estado operativo con una asignación abierta.

```sql
USE hospital_practica;
SELECT camilla_id, codigo, estado_operativo,
       disponibilidad
FROM v_camillas_estado
ORDER BY camilla_id;

SELECT disponibilidad, COUNT(*) AS cantidad
FROM v_camillas_estado
GROUP BY disponibilidad;

SELECT hospitalizacion_id, paciente_id,
       fecha_ingreso, fecha_alta
FROM hospitalizaciones
ORDER BY hospitalizacion_id;
```

En la carga inicial hay 1 camilla ocupada, 4 disponibles y 1 en mantenimiento. La hospitalización 1 tiene alta registrada y la 2 sigue abierta.

## Qué significa NULL

NULL indica que no hay un valor registrado. Cuando fecha_alta aparece como NULL, el alta todavía no está registrada; no es una fecha cero ni una cadena vacía. Para buscarlo usa IS NULL:

```sql
SELECT hospitalizacion_id, paciente_id, fecha_ingreso
FROM hospitalizaciones
WHERE fecha_alta IS NULL;
```

## Cómo se hacen los cambios de hospitalización

sp_asignar_camilla asigna una camilla y, cuando procede, cierra la asignación anterior para conservar el traslado. sp_alta_hospitalaria registra el alta y cierra la asignación abierta. Consulta sus argumentos en 02_reglas.sql antes de practicarlos.

No cambies manualmente un texto de ocupación para liberar una camilla. La ocupación se deriva de las asignaciones. v_camillas_estado refleja asignaciones con fin NULL; no reconstruye la ocupación de cualquier fecha histórica que escribas.

Una vista facilita leer valores calculados. En este proyecto, consulta las vistas y realiza los cambios mediante las tablas o los procedimientos adecuados.

# 16 Practicar una entrega de farmacia

Este ejercicio registra una entrega parcial ficticia. Hazlo una sola vez para comparar los resultados indicados. Mantén los registros de inventario en su orden cronológico.

## Leer antes de entregar

```sql
USE hospital_practica;
SELECT receta_id, renglon, cantidad_prescrita,
       cantidad_entregada, cantidad_pendiente
FROM v_recetas_pendientes
WHERE receta_id = 2 AND renglon = 1;
SELECT lote_id, stock
FROM v_stock_lotes WHERE lote_id = 3;
```

Valores iniciales: 4 pendientes en ese renglón y 40 unidades en el lote 3.

## Registrar la operación

```sql
SET @dispensacion_tutorial = NULL;
CALL sp_dispensar(
  2, 1, 3, 1, 6,
  '2026-10-10 10:00:00',
  @dispensacion_tutorial
);
SELECT @dispensacion_tutorial AS entrega_creada;
```

Argumentos: receta 2, renglón 1, lote 3, cantidad 1, personal de farmacia 6 y fecha. El procedimiento registra la entrega y el movimiento de inventario en una operación.

## Comprobar después

Repite solamente las dos consultas de lectura de arriba. Esperas 1 entregada, 3 pendientes y stock = 39.

Si vuelves a ejecutar CALL, puedes registrar otra entrega real de práctica y bajar otra vez el stock mientras haya cantidad pendiente. No es un botón para refrescar ni una operación que se pueda repetir sin consecuencias.

El stock se calcula sumando movimientos. No hagas UPDATE para escribir una existencia nueva. Los movimientos y detalles de entrega son inmutables; las correcciones de inventario usan un nuevo ajuste justificado. Los datos de sustancias y cantidades del proyecto son ficticios.

# 17 Practicar un pago parcial

El saldo de una factura se calcula a partir de sus conceptos y pagos. Usa una factura emitida y ejecuta la llamada una sola vez.

## Leer el saldo inicial

```sql
USE hospital_practica;
SELECT factura_id, folio, estado, total, pagado, saldo
FROM v_facturas_saldo
WHERE factura_id = 1;
```

Valores iniciales de factura 1: total = 850.00, pagado = 500.00 y saldo = 350.00.

## Registrar un abono ficticio

```sql
SET @pago_tutorial = NULL;
CALL sp_registrar_pago(
  1, '2026-10-10 10:30:00', 25.00,
  'EFECTIVO', 'ABONO-TUTORIAL-001',
  @pago_tutorial
);
SELECT @pago_tutorial AS pago_creado;
```

## Leer de nuevo

```sql
SELECT factura_id, total, pagado, saldo
FROM v_facturas_saldo
WHERE factura_id = 1;
```

Esperas pagado = 525.00 y saldo = 325.00. El total permanece en 850.00.

## Qué recordar

Repetir CALL agrega otro pago; la referencia no funciona como un bloqueo contra duplicados. Ejecuta la operación solo cuando quieres registrar un abono nuevo.

Una factura ABIERTA admite conceptos; primero se emite para recibir pagos. La factura 4 del ejemplo todavía está ABIERTA. Los pagos registrados no se editan ni se eliminan en este alcance académico.

No escribas el saldo manualmente en una tabla: la vista lo calcula. Este módulo es una demostración de cobros y no un sistema de facturación fiscal.

# 18 Comprobar reglas con errores esperados

Ahora ejecutarás tres instrucciones incorrectas a propósito. Selecciona y ejecuta una sola instrucción a la vez. Debe aparecer un error y no debe agregarse la fila.

## Un código único repetido

```sql
USE hospital_practica;
INSERT INTO departamentos (codigo, nombre)
VALUES ('DEP-DEMO-01', 'Duplicado de prueba');
```

Esperas error 1062 Duplicate entry: ya existe ese código. UNIQUE protege valores que no deben repetirse.

## Un valor fuera de la regla

```sql
INSERT INTO contactos_emergencia (
  paciente_id, nombre, parentesco, telefono, prioridad
)
VALUES (1, 'Contacto ficticio', 'PRUEBA',
        'TEL-PRUEBA', 0);
```

Esperas error 3819 Check constraint: prioridad debe ser mayor que 0. CHECK valida una condición del registro.

## Una relación hacia un paciente inexistente

```sql
INSERT INTO contactos_emergencia (
  paciente_id, nombre, parentesco, telefono, prioridad
)
VALUES (999999, 'Contacto ficticio', 'PRUEBA',
        'TEL-PRUEBA', 1);
```

Esperas error 1452 Foreign key constraint: el paciente 999999 no existe en la carga inicial.

## Cómo explicarlo al profesor

Estos errores demuestran que el servidor protege reglas del modelo. No debes desactivar CHECK o claves foráneas para conseguir que entren datos incorrectos.

Las reglas entre filas, como citas que se solapan o entregas que superan una receta, también necesitan procedimientos y transacciones. Una futura aplicación debe usar esos procedimientos y restringir las escrituras directas que eludan sus comprobaciones.

# 19 Modificar la estructura de una tabla

Modificar datos cambia filas. Modificar estructura cambia columnas, tipos, índices o relaciones. Para aprender ALTER, usaremos una tabla nueva de prueba.

1. En hospital_practica ejecuta una sola vez:

```sql
USE hospital_practica;
CREATE TABLE prueba_estructura (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL
);
DESCRIBE prueba_estructura;
```

Esperas dos columnas: id y nombre. INT guarda números enteros; VARCHAR(100) admite texto de hasta 100 caracteres; NOT NULL exige un valor.

2. Ejecuta una sola vez:

```sql
ALTER TABLE prueba_estructura
  ADD COLUMN observaciones VARCHAR(200) NULL;
DESCRIBE prueba_estructura;
```

Esperas una tercera columna observaciones. NULL permite dejarla sin valor registrado. La copia de práctica ahora tiene 37 tablas físicas porque agregaste una tabla de ejercicio.

## Un cambio de estructura no se deshace igual

CREATE y ALTER producen confirmaciones implícitas en MySQL. No prometas recuperar un cambio de estructura con ROLLBACK. Haz respaldo y revisa qué se alterará antes de aplicarlo a una tabla del proyecto.

## Si cambias realmente el proyecto

Actualiza los scripts de creación y reglas afectados, el diccionario, el reporte y los diagramas. Repite la validación con los archivos nuevos. La evidencia 82 de 82 del proyecto original no prueba automáticamente una versión que tú modificaste.

Error 1050 al crear la tabla o 1060 al agregar la columna: probablemente ya ejecutaste ese paso. Usa DESCRIBE para comprobarlo antes de volver a intentarlo.

# 20 Respaldar la base con Workbench

Un respaldo SQL conserva estructura y datos del servidor en un archivo. Copiar hospital_completo.sql conserva la instalación inicial, pero no los cambios posteriores.

1. Conéctate al servidor donde está la base que quieres respaldar.

2. Abre Server → Data Export. Marca hospital_universitario, o hospital_practica si quieres guardar tus ejercicios.

3. Marca todas las tablas de esa base. Selecciona Dump Structure and Data.

4. En las opciones, activa Dump Stored Procedures and Functions y Dump Triggers. Mantén los eventos si existieran; este proyecto no necesita eventos. Revisa que las vistas queden incluidas en la exportación del esquema.

5. Selecciona Export to Self-Contained File: se generará un solo archivo SQL. Elige una carpeta que puedas encontrar.

6. Activa Include Create Schema si aparece. Así el archivo puede incluir la creación y selección de la base.

7. Usa un nombre que identifique la base y el momento, por ejemplo hospital_universitario_2026_10_10.sql. No reemplaces el único respaldo que tengas.

8. Pulsa Start Export. Revisa Export Progress y comprueba que terminó sin errores. Confirma en el Explorador que el archivo existe y no está vacío.

## Qué comprobar en el archivo

Ábrelo para revisar el texto sin ejecutarlo. Debes encontrar definiciones de tablas, datos, vistas y rutinas. La presencia de CREATE DATABASE, USE o DROP TABLE influye en dónde se restaurará y qué reemplazará.

## Guardar el trabajo del equipo

Conserva el respaldo junto a una copia fechada de los scripts, documentos y modelo .mwb. Indica qué cambió y quién lo cambió. Si todos editan una base compartida, acuerden una sola versión antes de exportar.

Un respaldo se comprueba de verdad restaurándolo en otro entorno y consultando sus datos. Si la exportación marca un problema de compatibilidad de herramientas, revisa las versiones; no ignores el error ni entregues el archivo como respaldo exitoso.

Fuente oficial y opciones de exportación: página 27.

# 21 Recuperar un respaldo y compartir

## Restaurar en otra computadora o instancia

Para principiantes, utiliza una instancia donde no exista una base importante con el mismo nombre. No pruebes la restauración sobre la única copia de tu trabajo.

1. Guarda el archivo de respaldo SQL en la computadora destino. Instala y configura MySQL y Workbench si hace falta.

2. Conéctate al servidor destino y abre Server → Data Import.

3. Elige Import from Self-Contained File y selecciona el respaldo.

4. Antes de importar, abre el archivo como texto y revisa los nombres de CREATE DATABASE y USE, y si tiene DROP TABLE o DROP DATABASE. Si ya existe una base con ese nombre, detente y elige otro entorno para probar.

5. Si el respaldo incluye la creación del esquema, úsala. Si no la incluye, crea una base vacía con el nombre correcto y selecciona Default Target Schema según lo que contenga el archivo.

6. Pulsa Start Import y revisa Import Progress. Debe terminar sin errores.

7. Refresca Schemas. Comprueba tablas, vistas, rutinas y algunos datos de la base restaurada.

## El nombre destino requiere revisar el SQL

Elegir otra base en Default Target Schema no redirige necesariamente un archivo que ya contiene CREATE DATABASE o USE. Un respaldo con DROP TABLE puede reemplazar tablas existentes. No asumas que el asistente lo convertirá en una copia independiente.

## Qué entregar o pasar a un compañero

| Si necesita | Comparte |
| --- | --- |
| La instalación ficticia inicial | hospital_completo.sql y documentos del proyecto. |
| Tus datos y cambios actuales | Un respaldo SQL completo verificado. |
| Seguir los ejercicios | Este manual y tutorial/hospital_practica.sql. |
| Editar el dibujo | Tu modelo .mwb o las fuentes Mermaid .mmd. |

Cada compañero debe utilizar sus propias credenciales del servidor. No escriban contraseñas en el reporte o en archivos que vayan a entregar.

# 22 Mostrar el proyecto en cinco minutos

Este recorrido sirve para un estudiante que expone y para un docente que quiere revisar el resultado sin conocer Workbench. Solo usa lecturas.

1. Abre reporte_hospital.pdf y diagramas/vision_modulos.svg. Explica que el alcance es un sistema académico de atención, hospitalización, farmacia, procedimientos y cobros.

2. En Workbench entra a la conexión. Ejecuta:

```sql
USE hospital_universitario;
SELECT DATABASE() AS base;
SELECT COUNT(*) AS pacientes FROM pacientes;
SELECT table_type AS tipo, COUNT(*) AS cantidad
FROM information_schema.tables
WHERE table_schema = DATABASE()
GROUP BY table_type;
```

En la carga original muestra 5 pacientes, 36 tablas y 6 vistas. Si el equipo ya cambió datos, explícalo y muestra su respaldo actualizado.

3. Muestra atención clínica y ocupación:

```sql
SELECT * FROM v_expediente_consultas
ORDER BY paciente_id, fecha;
SELECT codigo, disponibilidad
FROM v_camillas_estado
ORDER BY camilla_id;
```

4. Muestra los valores calculados de farmacia y cobros:

```sql
SELECT lote_id, stock FROM v_stock_lotes;
SELECT folio, total, pagado, saldo
FROM v_facturas_saldo;
```

5. Abre el ER y señala una clave primaria y una foránea. Explica con pacientes y contactos por qué se relacionan mediante paciente_id.

## Explicar la evidencia con precisión

VALIDACION.json registra 82 de 82 comprobaciones aprobadas del proyecto original en MySQL 8.0.45. El tutorial pasó 28 de 28 comprobaciones de SQL en ese servidor; la evidencia está en tutorial/VALIDACION_TUTORIAL.json. Las pruebas SQL no son una prueba visual de la interfaz de Workbench.

Aclara que los datos son ficticios, la autenticación todavía no está implementada y la facturación es académica. Las tablas cubren los procesos incluidos en MODELO.md; no pretenden representar cada sistema de un hospital real.

# 23 Cambiar un dato usando el ratón

También puedes editar una celda de una tabla directamente en Result Grid. Practica solo en hospital_practica y con un dato sencillo, como el teléfono ficticio.

1. Ejecuta esta consulta para mostrar un único paciente con su clave primaria:

```sql
SELECT paciente_id, nombre, telefono
FROM hospital_practica.pacientes
WHERE paciente_id = 1;
```

2. Anota el teléfono que aparece antes de cambiarlo. Haz doble clic en la celda telefono y escribe TEL-VISUAL-001. No edites paciente_id.

3. Pulsa Apply en la zona de resultados. Workbench abre una ventana para revisar el SQL que enviará al servidor.

4. Lee el cambio antes de aprobarlo. Debe actualizar pacientes de hospital_practica, cambiar solo telefono y filtrar el paciente con ID 1. Si muestra otra tabla o varias filas, cancela y revisa el paso.

5. En la ventana de revisión pulsa Apply. Comprueba que terminó correctamente y pulsa Finish.

6. Vuelve a ejecutar la consulta de arriba o refresca la cuadrícula. El teléfono debe mostrar TEL-VISUAL-001.

7. Para devolver el dato al valor original, edita la misma celda con el valor que anotaste y repite Apply, revisión, Apply y Finish.

## Cuándo no se puede editar la cuadrícula

Si aparece Read Only, el resultado no es editable en ese contexto. Puede faltar la clave primaria, combinar varias tablas o no tener permisos de escritura. Usa una consulta de una sola tabla con su PK o el SQL del ejercicio correspondiente.

## Las reglas también se aplican aquí

Apply envía cambios reales al servidor; no es solo guardar el texto. Los triggers y restricciones pueden rechazarlos. Evita editar pagos, movimientos de inventario o entregas: este proyecto los protege para conservar su historia.

La ruta se basa en el manual oficial Result Grid. Si tu versión muestra una ventana distinta, lee el SQL y sus mensajes antes de confirmar.

# 24 Resolver los errores más comunes

| Mensaje o situación | Qué revisar y hacer |
| --- | --- |
| No aparece la base en Schemas | Refresh All. Comprueba la conexión y que la instalación terminó. |
| 2003 o Connection refused | Servidor iniciado, host y puerto correctos. Revisa el servicio de Windows. |
| 1045 Access denied | Usuario y contraseña del servidor. No uses usuarios ficticios de la tabla usuarios. |
| 1046 No database selected | Ejecuta USE hospital_practica o la base que necesitas. |
| 1049 Unknown database | Nombre mal escrito o base no creada en esta instancia. |
| 1007 o 1050 Already exists | No reinstales encima. Revisa si el paso ya se ejecutó o hubo instalación parcial. |
| 1062 Duplicate entry | Código o expediente único repetido. Comprueba el registro existente. |
| 1064 Syntax error | Revisa comillas simples, comas, nombres y punto y coma. En reglas ejecuta el script completo con DELIMITER. |
| 1146 Table does not exist | Base seleccionada, nombre de tabla y ejecución de 01_esquema.sql. |
| 1175 Safe update mode | Usa WHERE con la clave primaria. Si la variable no se reconoce, usa el ID numérico leído y añade el expediente para confirmar. |
| 1451 Cannot delete parent row | Existen registros relacionados. Conserva la historia y revisa el flujo correspondiente. |
| 1452 Cannot add child row | La clave foránea apunta a un registro inexistente. Consulta primero el ID correcto. |
| 3819 Check constraint violated | Un valor incumple una regla. Revisa el campo y la definición CHECK. |
| 1644 o mensaje del proyecto | Una rutina o trigger rechazó la operación. Lee el mensaje: puede indicar solapamiento, saldo, stock o estado inválido. |
| No cambia nada o devuelve 0 filas | Revisa WHERE, variable, base, conexión y si el cambio ya se hizo. No siempre es un error. |

Action Output conserva el mensaje de la operación. Para pedir ayuda comparte el texto exacto del primer error, el bloque que ejecutaste y la versión del servidor. Oculta contraseñas y cualquier dato real.

# 25 Glosario para seguir la clase

| Palabra | Significado en este proyecto |
| --- | --- |
| Base o esquema | Contenedor de tablas y otros objetos; en MySQL estos nombres se usan como equivalentes. |
| Tabla | Conjunto de filas con las mismas columnas. |
| Fila o registro | Una instancia, como un paciente ficticio. |
| Columna o campo | Un atributo, como telefono. |
| Tipo de dato | Qué valores admite una columna: texto, número, fecha y otros. |
| SQL | Lenguaje para consultar y modificar bases relacionales. |
| PK o clave primaria | Identificador único y obligatorio de una fila. |
| FK o clave foránea | Referencia a una clave de otra tabla o de la misma tabla. |
| UNIQUE | Evita repetir un valor o combinación de valores. |
| CHECK | Exige que una condición del registro se cumpla. |
| NULL | Ausencia de valor registrado. Se consulta con IS NULL. |
| AUTO_INCREMENT | Genera identificadores numéricos al insertar. |
| Vista | Consulta guardada que se lee como una tabla. |
| Procedimiento | Rutina que se invoca con CALL y puede recibir y devolver parámetros. |
| Trigger | Regla que se ejecuta automáticamente ante una operación en una tabla. |
| Transacción | Grupo de cambios que se confirma con COMMIT o se deshace con ROLLBACK cuando sigue pendiente. |
| Autocommit | Modo que confirma automáticamente instrucciones fuera de una transacción explícita. |
| JOIN | Combina datos de tablas mediante una condición de relación. |
| ER o EER | Diagrama de entidades, atributos y relaciones. |
| Respaldo | Archivo que permite reconstruir estructura y datos de un momento. |

## Cuatro verbos que conviene distinguir

Abrir muestra un archivo. Guardar conserva el texto o modelo. Ejecutar envía SQL al servidor. Confirmar con COMMIT hace permanentes los cambios pendientes de una transacción.

# 26 Fuentes oficiales y comprobación final

Los menús de este manual se contrastaron con documentación oficial de MySQL. Las páginas de descarga pueden mostrar versiones nuevas; anota siempre la versión que realmente instalaste.

## Descargas e instalación

MySQL Installer 8.0: https://dev.mysql.com/downloads/installer/

Productos y modo Custom: https://dev.mysql.com/doc/refman/8.0/en/mysql-installer-setup.html

MySQL Server: https://dev.mysql.com/downloads/mysql/

MySQL Workbench: https://dev.mysql.com/downloads/workbench/

Server 8.4 en Windows: https://dev.mysql.com/doc/refman/8.4/en/windows-installation.html

## Uso de Workbench

Conexión: https://dev.mysql.com/doc/workbench/en/wb-mysql-connections-new.html

Barra SQL: https://dev.mysql.com/doc/workbench/en/wb-sql-editor-toolbar.html

Menú Query: https://dev.mysql.com/doc/workbench/en/wb-sql-editor-main-menu.html

Edición visual: https://dev.mysql.com/doc/workbench/en/wb-develop-sql-editor-results.html

Atajos: https://dev.mysql.com/doc/workbench/en/wb-keys.html

Schemas: https://dev.mysql.com/doc/workbench/en/wb-sql-editor-navigator.html

Diagrama: https://dev.mysql.com/doc/workbench/en/wb-reverse-engineer-live.html

Exportación e importación: https://dev.mysql.com/doc/workbench/en/wb-admin-export-import-management.html

Compatibilidad de Workbench: https://dev.mysql.com/doc/workbench/en/

## Antes de entregar

Comprueba que puedes conectarte, abrir las tablas y mostrar el diagrama. Exporta un respaldo con las rutinas y triggers. Entrega archivos que se correspondan con la misma versión del proyecto.

Las instrucciones y datos de ejemplo se validan por separado del formato del Word y PDF. Si cambias fechas, IDs, scripts o datos, los resultados esperados de los ejercicios pueden cambiar.
