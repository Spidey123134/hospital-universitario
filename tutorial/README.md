# Tutorial desde cero en MySQL Workbench

La guía actual es **[TUTORIAL.md](TUTORIAL.md)**. Sus instrucciones y bloques SQL corresponden a los datos actuales del proyecto y permiten copiar los ejercicios directamente a MySQL Workbench.

Para trabajar mediante **botones y formularios de Python**, sigue la [guía actual de la interfaz](../tutorial_interfaz/README.md), que enlaza su tutorial de texto y PDF actualizado.

Los archivos **tutorial_hospital_principiantes.pdf** y **tutorial_hospital_principiantes.docx** de esta carpeta son **versiones históricas del 10 de octubre de 2026**. No se regeneraron después de actualizar los datos el 22 de octubre: algunos códigos, ejemplos y resultados esperados ya no coinciden con la instalación actual. Se conservan como referencia; utiliza TUTORIAL.md para los ejercicios vigentes.

Empieza por el apartado **Elige por dónde empezar** de TUTORIAL.md. Para practicar cambios, usa **hospital_practica.sql**, que crea una instalación académica independiente una sola vez. No es un respaldo de una base modificada.

Ejecuta únicamente cada bloque indicado por el manual; no todos los ejercicios juntos. El instalador de práctica sí se ejecuta completo una vez.

## Archivos

- TUTORIAL.md: guía actual de Workbench, con bloques SQL copiables.
- tutorial_hospital_principiantes.docx: documento editable histórico; puede contener ejemplos anteriores.
- tutorial_hospital_principiantes.pdf: PDF histórico; puede contener ejemplos anteriores.
- hospital_practica.sql: estructura, reglas y datos ficticios de la base nueva hospital_practica.
- VALIDACION_TUTORIAL.json: evidencia de 28 comprobaciones aprobadas en MySQL 8.0.45. Distingue pruebas del SQL de instrucciones de interfaz.
- validar_tutorial.py: ejecutor reproducible de las comprobaciones en una base temporal UUID propia; requiere un servidor de pruebas y cliente mysql.
- generar_tutorial.py: fuente del Word y Markdown; requiere Python y python-docx. El PDF se exporta del Word. Los dos binarios históricos incluidos todavía no reflejan la última revisión de esta fuente.

Los procedimientos de negocio confirman sus propias transacciones. No envuelvas CALL en otra transacción esperando deshacerlo con ROLLBACK. Los ejemplos de citas, entregas y pagos se ejecutan una sola vez para obtener los resultados descritos.

La carpeta superior incluye los scripts del proyecto, diagramas, diccionario e informe académico. Guarda un respaldo antes de modificar una base con datos que quieras conservar.
