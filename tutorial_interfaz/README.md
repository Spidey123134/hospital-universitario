# Tutorial de la aplicación del hospital

Esta es la guía recomendada para usar el proyecto mediante ventanas, botones y formularios de Python. No hace falta escribir SQL para ver los datos, registrar pacientes ni realizar las operaciones disponibles.

- [Tutorial en PDF](tutorial_interfaz_hospital.pdf): versión ilustrada para leer y compartir.
- [Tutorial en texto](TUTORIAL.md).
- [Generador del PDF](generar_pdf.py): usa el texto y las capturas del manual.
- [Generador del Word](generar_tutorial.py): fuente para regenerar una versión editable.

El archivo `tutorial_interfaz_hospital.docx` se conserva como **versión anterior**. Para seguir los botones de la aplicación actual utiliza el PDF o el texto de esta carpeta. La versión Word nueva requiere conversión y revisión visual antes de publicarse como actualizada.

Empieza por extraer **toda** la carpeta del proyecto y abrir `ABRIR_HOSPITAL.bat`, situado en la carpeta principal. La primera puesta en marcha requiere Python, MySQL Server e internet para descargar la dependencia de conexión.

Si la base del proyecto ya está instalada, primero prueba la conexión y después pulsa **Abrir hospital**. El botón **Crear base con ejemplos** se usa únicamente cuando el nombre elegido todavía no existe. La comprobación de conexión no carga ni cambia registros.

Para revisar una copia anterior, entra a **Inicio → Completar datos del proyecto**. La aplicación guarda un respaldo antes de actualizar los valores reconocidos y conserva los campos que el equipo ya editó. También informa los marcadores o valores distintos que requieren revisión manual, aunque no haya cambios automáticos pendientes. Las copias nuevas incluyen la revisión del 23 de octubre de 2026, que corrige notas repetidas, dosis vagas y descripciones sin contenido del registro.

Cada integrante trabaja con su propio MySQL. El servidor local preparado en la laptop del proyecto usa el puerto **3307**; una instalación normal suele usar **3306**. El tutorial explica esta diferencia y cómo trasladar los datos mediante un respaldo completo.

El tutorial de la carpeta `tutorial/` explica el uso técnico de MySQL Workbench. Se conserva como material para desarrolladores; para la demostración de la aplicación utiliza esta guía.

La [revisión de esta guía](REVISION_TUTORIAL.json) registra las páginas inspeccionadas, los recursos gráficos y las huellas de los archivos finales. Los ejercicios de paciente, cita, consulta, receta, cobro y hospitalización se verifican con MySQL mediante las pruebas de la aplicación.

Para mantener el manual, edita primero `TUTORIAL.md`. `generar_pdf.py` requiere ReportLab y genera el PDF desde ese texto y las seis capturas de `imagenes/`; después hay que renderizar y revisar todas sus páginas. `generar_tutorial.py` requiere python-docx y genera un Word editable, cuya revisión visual necesita un conversor de documentos. Estas herramientas son para editar la documentación y no se necesitan para utilizar el hospital.
