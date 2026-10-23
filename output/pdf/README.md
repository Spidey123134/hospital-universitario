# Todas las tablas y sus relaciones

Abre [relaciones_y_tablas_hospital.pdf](relaciones_y_tablas_hospital.pdf). No necesitas Python ni MySQL para leerlo. Está preparado para imprimir en papel Carta; los ocho diagramas están en páginas horizontales.

El documento contiene:

- Explicación de PK, FK, UNIQUE, NULL y cardinalidades para principiantes.
- Índice navegable por nombre y número de página.
- Ocho diagramas por área, con las 48 relaciones identificadas F01 a F48.
- Una ficha para cada una de las 36 tablas: sus 205 campos, tipos SQL completos, valores predeterminados, columnas calculadas, claves y restricciones.
- Relaciones salientes y entrantes de cada tabla, con un catálogo central de las 48 FK, incluidas las siete compuestas.

Los diagramas repiten las tablas padre necesarias para entender cada hija sin cruzar líneas. Esa repetición visual no crea tablas ni relaciones adicionales. Los números 0..1 y 0..N expresan lo permitido por la estructura, no el número de registros actuales.

La estructura se obtuvo de [01_esquema.sql](../../01_esquema.sql) y se contrastó con los metadatos de MySQL el 23 de octubre de 2026, sin cambiar la base. [REVISION_RELACIONES_PDF.json](REVISION_RELACIONES_PDF.json) registra la cobertura y la revisión del documento.

Para regenerar el PDF se usa [generar_relaciones_pdf.py del repositorio](https://github.com/Spidey123134/hospital-universitario/blob/main/generar_relaciones_pdf.py), con Python 3, ReportLab y pypdf. El programa no se conecta a MySQL. Si cambia el esquema, vuelve a contrastar sus metadatos y a revisar todas las páginas renderizadas antes de presentar el PDF regenerado.
