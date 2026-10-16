# Hospital universitario

La entrega principal es una **base de datos MySQL con 36 tablas relacionadas y 789 registros ficticios**, incluidos 30 pacientes, 18 médicos, 15 medicamentos y 40 recetas. Está creada en un servidor local permanente y se incluye su respaldo exportado para instalar una copia en la computadora de cada integrante.

## La base para cada integrante

1. Cada integrante necesita **MySQL Server y MySQL Workbench** en su computadora.
2. Descarga [hospital_universitario_respaldo.sql](entrega_base/hospital_universitario_respaldo.sql), el respaldo de la base creada con estructura y registros.
3. En Workbench, entra a tu servidor y elige **Server → Data Import → Import from Self-Contained File**.
4. Selecciona el respaldo y pulsa **Start Import**. Importa en una instalación donde todavía no exista una base con ese nombre; conserva cualquier trabajo previo.
5. Actualiza **Schemas** y abre **hospital_universitario → Tables**. Tendrás la copia guardada en tu MySQL. **No necesitas Python para esta etapa.**

**[Explicación clara y pasos para el equipo](BASE_DE_DATOS.md)** · [Informe de la base creada y respaldo](entrega_base/INFORME_BASE_CREADA.json).

GitHub comparte los archivos del proyecto y el respaldo; **no hospeda un servidor MySQL**. Descargar el repositorio no instala una base automáticamente. Cada copia del equipo es independiente: sus cambios se guardan en su propio servidor.

MySQL 8.0.16 o posterior; servidor local y respaldo verificados en MySQL 8.0.45. Se incluyen seis vistas, seis procedimientos y 23 triggers. El respaldo se restauró como otra base y se compararon todas las filas.

## Documentación

- [Cómo tener la base en cada computadora](BASE_DE_DATOS.md)
- [Respaldo exportado de la base](entrega_base/hospital_universitario_respaldo.sql)
- [Reporte del proyecto](reporte_hospital.pdf)
- [Modelo y relaciones](MODELO.md)
- [Diccionario de datos](DICCIONARIO.md)
- [Diagramas](diagramas/)
- [Guía completa del proyecto](GUIA_PROYECTO.md)
- [Cómo se integró el aporte del equipo](aporte_equipo/README.md)

Para el trabajo con MySQL se conservan el [tutorial de Workbench](tutorial/README.md), los [scripts del diseño y ejemplos](DATOS_DEMOSTRACION.md) y [hospital_practica.sql](tutorial/hospital_practica.sql).

## Python queda para una etapa posterior

La interfaz está separada en [app_hospital](app_hospital/README.md). Se conecta a MySQL y no sustituye a la base. Para esa fase quedan [su tutorial PDF](tutorial_interfaz/tutorial_interfaz_hospital.pdf), [Word](tutorial_interfaz/tutorial_interfaz_hospital.docx) y `ABRIR_HOSPITAL.bat`.

Evidencias conservadas: [82 del modelo](VALIDACION.json), [28 del tutorial SQL](tutorial/VALIDACION_TUTORIAL.json), [122 de la ampliación](VALIDACION_DATOS_AMPLIADOS.json), [200 del servicio](VALIDACION_APP.json) y [23 de las ventanas](VALIDACION_INTERFAZ.json).

Proyecto académico de Sistemas.
