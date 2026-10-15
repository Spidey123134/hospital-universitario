# Hospital universitario

Proyecto universitario de un hospital con **interfaz de escritorio en Python y base MySQL**. Se utiliza con ventanas, formularios y botones, sin escribir SQL. La demostración tiene **36 tablas y 789 registros ficticios**, incluidos 30 pacientes, 18 médicos y 40 recetas.

## Abrir el programa

1. Descarga el proyecto y **extrae toda la carpeta** del ZIP.
2. Necesitas Python 3.10 o posterior y MySQL Server instalado e iniciado.
3. En Windows, haz doble clic en **[ABRIR_HOSPITAL.bat](ABRIR_HOSPITAL.bat)**. La primera vez instala el conector y necesita Internet.
4. Escribe tu conexión MySQL y pulsa **Probar conexión**. Si es nueva, pulsa **Crear base con ejemplos** una sola vez; después **Abrir hospital**.
5. En **Registros**, elige una tabla y pulsa **Nuevo registro**. En **Operaciones**, agenda citas, entrega medicamentos o registra pagos.

**[Tutorial nuevo paso a paso con capturas](tutorial_interfaz/tutorial_interfaz_hospital.pdf)** · [Word editable](tutorial_interfaz/tutorial_interfaz_hospital.docx) · [Leer en GitHub](tutorial_interfaz/TUTORIAL.md).

Si la base ya existe, usa **Abrir hospital**. Para una demostración nueva con todos los ejemplos, escribe otro nombre de base antes de crearla. La aplicación nunca reemplaza una base existente. Incluye respaldo completo y restauración en una base nueva.

MySQL 8.0.16 o posterior; probado con MySQL 8.0.45. Tkinter viene con Python; el conector es PyMySQL. [Detalles del programa](app_hospital/README.md).

## Documentación

- [Tutorial de la interfaz para principiantes](tutorial_interfaz/tutorial_interfaz_hospital.pdf)
- [Reporte del proyecto](reporte_hospital.pdf)
- [Modelo y relaciones](MODELO.md)
- [Diccionario de datos](DICCIONARIO.md)
- [Diagramas](diagramas/)
- [Guía completa del proyecto](GUIA_PROYECTO.md)
- [Cómo se integró el aporte del equipo](aporte_equipo/README.md)

Para estudiar SQL se conserva [hospital_practica.sql](tutorial/hospital_practica.sql), que corresponde al tutorial anterior. Los ejercicios del tutorial nuevo se hacen desde las ventanas de la aplicación.

Validación de la aplicación: [200 comprobaciones en MySQL](VALIDACION_APP.json) y [23 del recorrido de ventanas](VALIDACION_INTERFAZ.json), todas aprobadas. Se verifican registros, relaciones, reglas, concurrencia y respaldo/restauración.

Los [scripts SQL y conteos](DATOS_DEMOSTRACION.md) y el [tutorial anterior de SQL](tutorial/README.md) quedan como material para estudiar la programación de la base. Para usar el hospital sigue el **tutorial nuevo de la interfaz**. También se conservan las evidencias anteriores: [82 del modelo](VALIDACION.json), [28 del tutorial SQL](tutorial/VALIDACION_TUTORIAL.json) y [122 de la ampliación](VALIDACION_DATOS_AMPLIADOS.json).

Proyecto académico de Sistemas.
