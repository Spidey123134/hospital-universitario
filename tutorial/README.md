# Tutorial desde cero

Abre **tutorial_hospital_principiantes.pdf** para leer o imprimir, o **tutorial_hospital_principiantes.docx** para editar el documento. Ambos contienen la misma guía de 27 páginas para estudiantes y docentes sin experiencia previa.

Empieza en la página 2 para ver el proyecto. La página 3 explica instalación y la 4 conexión. Para practicar cambios, sigue desde la página 9 con **hospital_practica.sql**, que crea una instalación ficticia independiente una sola vez. No es un respaldo de una base modificada.

Ejecuta únicamente cada bloque indicado por el manual; no todos los ejercicios juntos. El instalador de práctica sí se ejecuta completo una vez.

## Archivos

- tutorial_hospital_principiantes.docx: documento editable.
- tutorial_hospital_principiantes.pdf: documento para lectura e impresión.
- hospital_practica.sql: estructura, reglas y datos ficticios de la base nueva hospital_practica.
- TUTORIAL.md: texto de la guía con bloques SQL copiables.
- VALIDACION_TUTORIAL.json: evidencia de 28 comprobaciones aprobadas en MySQL 8.0.45. Distingue pruebas del SQL de instrucciones de interfaz.
- validar_tutorial.py: ejecutor reproducible de las comprobaciones en una base temporal UUID propia; requiere un servidor de pruebas y cliente mysql.
- generar_tutorial.py: fuente del Word y Markdown; requiere Python y python-docx. El PDF se exporta del Word.

Los procedimientos de negocio confirman sus propias transacciones. No envuelvas CALL en otra transacción esperando deshacerlo con ROLLBACK. Los ejemplos de citas, entregas y pagos se ejecutan una sola vez para obtener los resultados descritos.

La carpeta superior incluye los scripts del proyecto, diagramas, diccionario e informe académico. Guarda un respaldo antes de modificar una base con datos que quieras conservar.
