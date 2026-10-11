# Hospital universitario

Proyecto de una base de datos hospitalaria en **MySQL**, con 36 tablas, consultas y documentación. La demostración reúne el aporte del equipo y ejemplos ficticios: **30 pacientes, 18 médicos, 15 medicamentos y 40 recetas**.

## Uso

1. Conéctate a MySQL desde Workbench.
2. Para una instalación nueva, ejecuta [hospital_demostracion.sql](hospital_demostracion.sql) completo una sola vez: crea `hospital_universitario` con la muestra ampliada.
3. Abre [06_ver_datos.sql](06_ver_datos.sql) y ejecuta sus consultas para ver los registros.

Si ya cargaste la muestra inicial de `hospital_completo.sql`, ejecuta solamente [05_datos_demo_ampliados.sql](05_datos_demo_ampliados.sql) una vez. Los dos instaladores crean la misma base: elige uno. [Instrucciones y conteos](DATOS_DEMOSTRACION.md).

Requiere MySQL 8.0.16 o posterior. Probado en MySQL 8.0.45.

## Documentación

- [Tutorial desde cero en PDF](tutorial/tutorial_hospital_principiantes.pdf)
- [Tutorial editable en Word](tutorial/tutorial_hospital_principiantes.docx)
- [Reporte del proyecto](reporte_hospital.pdf)
- [Modelo y relaciones](MODELO.md)
- [Diccionario de datos](DICCIONARIO.md)
- [Diagramas](diagramas/)
- [Guía completa del proyecto](GUIA_PROYECTO.md)
- [Cómo se integró el aporte del equipo](aporte_equipo/README.md)

Para los ejercicios, usa [hospital_practica.sql](tutorial/hospital_practica.sql): crea una base nueva de práctica con datos ficticios. Ejecuta cada ejercicio según el tutorial.

Validación: [82 del proyecto inicial](VALIDACION.json), [28 del tutorial](tutorial/VALIDACION_TUTORIAL.json) y [122 de la ampliación y fusión](VALIDACION_DATOS_AMPLIADOS.json), todas aprobadas. [04_consultas.sql](04_consultas.sql) contiene las consultas del reporte.

Proyecto académico de Sistemas.
