# Ver la base llena de datos

La estructura mantiene sus **36 tablas**. La demostración ampliada contiene **789 filas** repartidas entre ellas. Incluye los 15 médicos y 15 recetas adaptadas de las capturas del equipo, además de casos ficticios de citas, hospitalización, farmacia, estudios y cobros.

Para instalar la versión con nombres y contactos completados, utiliza el [respaldo actual](entrega_base/hospital_universitario_respaldo.sql) y sigue [BASE_DE_DATOS.md](BASE_DE_DATOS.md). Las instrucciones siguientes reconstruyen la muestra original usada en las comprobaciones del tutorial. Si eliges esa ruta, ejecuta también `07_contactos_y_catalogos.sql` después de la ampliación. [DATOS_DEL_PROYECTO.md](DATOS_DEL_PROYECTO.md) explica la actualización; no necesitas repetirla si importas el respaldo actual.

| Datos | Muestra inicial del tutorial | Demostración ampliada |
| --- | ---: | ---: |
| Pacientes | 5 | 30 |
| Médicos | 3 | 18 |
| Medicamentos | 3 | 15 |
| Camillas | 6 | 15 |
| Citas | 6 | 54 |
| Consultas | 5 | 45 |
| Recetas | 3 | 40 |
| Renglones de recetas | 5 | 64 |
| Hospitalizaciones | 2 | 11 |
| Facturas | 4 | 29 |

## Si empiezas desde cero

1. En MySQL Workbench, abre tu conexión al servidor.
2. Elige **File → Open SQL Script** y abre `hospital_demostracion.sql`.
3. Activa la opción para detener el script si ocurre un error. Ejecuta el archivo completo con el botón del rayo para ejecutar todo el script.
4. Debe crearse `hospital_universitario`. Actualiza el panel **Schemas** y abre **Tables**.
5. Abre `06_ver_datos.sql`, ejecuta `USE hospital_universitario;` y luego selecciona una consulta completa, desde `SELECT` hasta su punto y coma. Pulsa el rayo para ejecutarla y ver la cuadrícula de resultados.

El instalador crea una base nueva. Si `hospital_universitario` ya existe, no vuelvas a ejecutar ninguno de los instaladores. No hace falta borrar tu trabajo para agregar la ampliación.

## Si ya cargaste la versión inicial

Si tu base contiene exactamente la muestra original del proyecto, abre y ejecuta **solo `05_datos_demo_ampliados.sql`**, una vez. Agrega 646 filas y conserva los datos iniciales.

Si ya modificaste los datos o cargaste la ampliación, no la repitas. Los identificadores explícitos facilitan explicar las relaciones en clase, pero pueden chocar con registros que hayas agregado. Si un `INSERT` falla, detén el script y ejecuta `ROLLBACK;` en la misma conexión; no continúes hasta `COMMIT`. Conserva una copia antes de adaptar una base modificada.

`hospital_completo.sql` sigue disponible para instalar la muestra pequeña del tutorial. **Elige un instalador**: `hospital_completo.sql` o `hospital_demostracion.sql`. No ejecutes ambos en la misma base.

## Qué muestran las consultas

`06_ver_datos.sql` tiene diez consultas de lectura. Puedes ejecutar cada bloque por separado o todo el archivo y revisar las diferentes pestañas de resultados:

1. Los 18 médicos con nombres y especialidades.
2. Los 30 pacientes.
3. Los 15 medicamentos y sus existencias calculadas.
4. Las 40 recetas con sus 64 renglones de medicamentos.
5. Las 15 camillas y su disponibilidad.
6. Las 11 hospitalizaciones; siete están abiertas.
7. Las 29 facturas con total, pagos y saldo.
8. Un resumen de conteos.
9. Solamente los 15 médicos del compañero.
10. Solamente las 15 recetas adaptadas del compañero.

En este modelo, el nombre de un médico está en `personal`, su cédula en `medicos` y sus especialidades se relacionan mediante `medico_especialidad`. Una consulta con `JOIN` reúne estos datos para que se vean juntos en la cuadrícula. Por eso `SELECT * FROM medicos;` muestra menos columnas que la captura del prototipo.

Una receta tiene cabecera en `recetas` y medicamentos en `receta_detalle`. Si contiene dos medicamentos, la consulta devuelve dos filas con el mismo `receta_id`: es el resultado esperado. La camilla pertenece a una estancia y a su historial de asignaciones.

## Aporte del equipo y ejemplos agregados

La [explicación de la fusión](aporte_equipo/README.md) y sus dos CSV conservan los valores visibles de las capturas y la correspondencia de identificadores. Los horarios originales también se conservaron en el CSV; el esquema actual registra citas con fecha y hora, pero no administra jornadas laborales.

Las capturas no muestran los nombres de los pacientes ni de los medicamentos. Para completar relaciones se usaron pacientes y compuestos ficticios del proyecto. Las recetas adaptadas llevan una observación que identifica esa diferencia. Cantidad y duración no especificadas se completaron con valores de prueba; los textos de dosis y vías se conservaron como parte del ejercicio del equipo, sin validación clínica.

Los ejercicios del tutorial siguen usando `tutorial/hospital_practica.sql`, con la muestra pequeña y sus resultados esperados. La ampliación se usa para demostrar más registros y relaciones en `hospital_universitario`.

## Verificación y reproducción

[VALIDACION_DATOS_AMPLIADOS.json](VALIDACION_DATOS_AMPLIADOS.json) registra **122 comprobaciones correctas y cero fallidas en MySQL 8.0.45**. Comprueba los conteos, los datos transcritos, las diez consultas, citas y ocupaciones sin solapamientos, existencias y cobros consistentes. También compara todas las filas de una instalación nueva con las de una base inicial ampliada y verifica que repetir la ampliación rechaza duplicados sin modificar datos. Las dos bases temporales de prueba se eliminaron.

Para repetir estas pruebas, usa Python 3 y el cliente MySQL en un servidor de pruebas:

```text
python validar_datos_ampliados.py --mysql "C:/MySQL/bin/mysql.exe" --user root --port 3306 --output VALIDACION_DATOS_AMPLIADOS.json
```

Ajusta la ruta, usuario y puerto a tu equipo. La contraseña, si se necesita, se toma de la variable de entorno `MYSQL_PWD`; no va en los argumentos ni en el reporte. El programa crea sus propias bases `hospital_prueba_UUID` y no modifica `hospital_universitario`.

`generar_datos_ampliados.py` regenera los archivos 05 y `hospital_demostracion.sql` a partir de los CSV y ejemplos definidos en su código. Regenerar archivos no ejecuta ni modifica una base. Después de cambiar datos, vuelve a validar antes de presentar la evidencia.
