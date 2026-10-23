# Hospital universitario

La entrega principal es una **base de datos MySQL con 36 tablas relacionadas y 789 registros ficticios**, incluidos 30 pacientes, 18 médicos, 15 medicamentos y 40 recetas. Está creada en un servidor local permanente y se incluye su respaldo exportado para instalar una copia en la computadora de cada integrante.

La revisión del **23 de octubre de 2026** corrige también el relleno que no usaba la palabra «ficticio»: notas repetidas, referencias vagas, dosis sin cantidad e informes sin resultados. Los textos se relacionan con su consulta, medicamento, estudio o factura. Se conservan **95 teléfonos de diez dígitos, 59 correos personalizados y los 15 médicos aportados por el compañero**. [Qué se corrigió y cómo actualizar una copia anterior](DATOS_DEL_PROYECTO.md).

El conjunto sigue siendo académico: las personas, contactos y operaciones no corresponden a un hospital real; las recetas no son indicaciones de tratamiento. La aclaración se mantiene aquí y en la documentación, en lugar de repetirse como relleno dentro de cada campo.

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
- [Datos completados y actualización de una copia anterior](DATOS_DEL_PROYECTO.md)
- [Respaldo exportado de la base](entrega_base/hospital_universitario_respaldo.sql)
- [Reporte del proyecto](reporte_hospital.pdf)
- [Modelo y relaciones](MODELO.md)
- [Diccionario de datos](DICCIONARIO.md)
- [Diagramas](diagramas/)
- [Guía completa del proyecto](GUIA_PROYECTO.md)
- [Cómo se integró el aporte del equipo](aporte_equipo/README.md)

Para el trabajo con MySQL se conservan el [tutorial de Workbench](tutorial/README.md), los [scripts del diseño y ejemplos](DATOS_DEMOSTRACION.md) y [hospital_practica.sql](tutorial/hospital_practica.sql).

## Aplicación de Python

La base y la aplicación son entregas separadas. La interfaz de escritorio de [app_hospital](app_hospital/README.md) permite trabajar con la base mediante botones y formularios: pacientes, citas, consultas, recetas, farmacia, hospitalización y cobros. Se conecta a MySQL; los registros siguen guardados en el servidor de cada integrante.

1. Extrae **todo** el proyecto y comprueba que MySQL Server esté iniciado.
2. Abre **ABRIR_HOSPITAL.bat**. Requiere Python 3.10 o posterior con Tkinter; la primera vez descarga las dependencias de `requirements.txt`.
3. Escribe los datos de tu MySQL y pulsa **Probar conexión**. La aplicación indica si encontró una base compatible, si la base falta o si su estructura necesita revisión.
4. Si ya tienes la base del proyecto, pulsa **Abrir hospital**. Si no existe, **Crear base con ejemplos** prepara una copia independiente con las 36 tablas y los 789 registros de la versión actual.
5. Para revisar una copia anterior, entra a **Inicio → Completar datos del proyecto**. La aplicación guarda un respaldo antes de actualizar los valores que reconoce; conserva los campos editados por el equipo e informa los que necesitan revisión manual. Lee el resultado aunque no haya actualizaciones automáticas pendientes.

El [tutorial paso a paso](tutorial_interfaz/TUTORIAL.md) y el [PDF actualizado](tutorial_interfaz/tutorial_interfaz_hospital.pdf) explican los formularios y un ejercicio completo. **Probar conexión solo revisa; no instala ni modifica la base.** La aplicación conserva las bases existentes.

Informes disponibles: [modelo de datos](VALIDACION.json), [tutorial SQL](tutorial/VALIDACION_TUTORIAL.json), [datos ampliados](VALIDACION_DATOS_AMPLIADOS.json), [servicio de la aplicación](VALIDACION_APP.json), [ventanas de Python](VALIDACION_INTERFAZ.json) y [validación de formularios](VALIDACION_FORMULARIOS.json). Cada informe registra sus comprobaciones y la versión de los archivos revisados.

Proyecto académico de Sistemas.
