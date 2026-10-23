# Respaldo de la base creada

`hospital_universitario_respaldo.sql` fue exportado con mysqldump de una base real MySQL 8.0.45 creada y poblada. Incluye 36 tablas, 789 filas, seis vistas, seis procedimientos y 23 triggers.

Este respaldo incluye la revisión del 23 de octubre de 2026: notas individuales, informes de estudios con contenido, dosis explícitas y conceptos de cobro identificados. También conserva los 95 teléfonos de diez dígitos y 59 correos `example.com` del conjunto académico. No requiere aplicar actualizaciones después de importarlo. [Datos del proyecto](../DATOS_DEL_PROYECTO.md) explica los cambios y [REVISION_CALIDAD_DATOS.json](REVISION_CALIDAD_DATOS.json) documenta las comprobaciones actuales.

Cada integrante importa este archivo en su propio MySQL Server mediante MySQL Workbench: **Server → Data Import → Import from Self-Contained File → Start Import**. La base de destino `hospital_universitario` no debe existir con trabajo anterior. El archivo incluye la creación del esquema; no requiere Python.

[BASE_DE_DATOS.md](../BASE_DE_DATOS.md) explica la diferencia entre la base funcionando, su respaldo y GitHub. [INFORME_BASE_CREADA.json](INFORME_BASE_CREADA.json) documenta la persistencia tras reiniciar el servidor y la restauración de una copia con todas las filas idénticas. El respaldo no incluye la contraseña del servidor original.
