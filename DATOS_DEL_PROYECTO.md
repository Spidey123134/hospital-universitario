# Datos completos para presentar el proyecto

La base conserva **36 tablas y 789 registros relacionados**. La revisión ya abarca los textos de **19 tablas**, incluidos los datos administrativos, las notas, los medicamentos, las recetas y los estudios. Se sustituyeron los valores que decían literalmente «ficticio», «simulado», «de prueba» o variantes equivalentes por contenido propio del campo. Los identificadores de los registros y sus relaciones siguen siendo los mismos.

## Qué se completó

- Nombres y apellidos del personal y de los pacientes que todavía tenían textos como «Ejemplo» o «Paciente Uno».
- **95 teléfonos de diez dígitos**, repartidos entre personal, pacientes, contactos de emergencia, aseguradoras y proveedores.
- **59 correos** derivados del nombre de la persona o empresa, como `elena.marquez.1@example.com`.
- Domicilios de pacientes y nombres de contactos de emergencia, aseguradoras y proveedores.
- Códigos de empleados, expedientes, departamentos, habitaciones, camillas, pólizas y lotes.
- Un catálogo de **15 medicamentos** con principio activo, concentración, presentación y unidad de inventario. Sus formulaciones se contrastaron con [fichas oficiales de CIMA](datos/REFERENCIAS_CATALOGO.md).
- Motivos de citas y consultas, observaciones de recetas, notas de enfermería y motivos o resúmenes de hospitalización.
- Textos de alergias, resultados de estudios, conceptos de factura y referencias de movimientos que antes describían la práctica en lugar del dato.

La comprobación recorre todos los campos de texto y todas las filas de las **36 tablas**, no solamente las primeras filas que muestra la aplicación. El informe identifica cuántas celdas se revisaron y si quedaron coincidencias; los valores de contraseñas y otros campos sensibles no se muestran.

Estos datos son **ficticios**. Los teléfonos tienen formato mexicano, pero no se comprobó si pertenecen a alguien; no se deben utilizar para contactar personas. Los correos usan `example.com`, un [dominio reservado para ejemplos por IANA](https://www.iana.org/help/example-domains), y no representan buzones del equipo. Ninguna cédula se presenta como una acreditación profesional verificada.

## Qué se conservó

Los **15 médicos que aportó el compañero conservan sus nombres y cédulas**. También se conservan las fechas, las cantidades, las relaciones entre tablas y los registros clínicos y contables. Completar sus descripciones no elimina recetas, movimientos, facturas, pagos ni resultados.

Los medicamentos, dosis y tratamientos del proyecto siguen siendo material académico. Los nombres de productos comprobados en fuentes oficiales no convierten las recetas del ejercicio en tratamientos válidos. Las cuentas de usuario del modelo permanecen inactivas; completar estos datos no crea un inicio de sesión para empleados ni sustituye las credenciales de MySQL.

## Si vas a instalar la base ahora

Usa [hospital_universitario_respaldo.sql](entrega_base/hospital_universitario_respaldo.sql) y sigue [BASE_DE_DATOS.md](BASE_DE_DATOS.md). **El respaldo ya contiene esta actualización**. Después de importarlo puedes abrir las tablas en MySQL Workbench y ver los datos completos. No necesitas Python para importar este respaldo.

Si instalas desde la interfaz de Python con **Crear base con ejemplos**, la copia también se crea directamente con los datos completos. El profesor o tus compañeros no tienen que ejecutar instrucciones SQL para llenar esas tablas.

## Si tu copia todavía muestra los textos anteriores

1. Descarga y extrae la versión actual del proyecto. Conserva tu base MySQL existente.
2. Abre `ABRIR_HOSPITAL.bat`, escribe los datos de tu servidor y pulsa **Abrir hospital**.
3. Entra a **Inicio** y pulsa **Completar datos del proyecto**.
4. Revisa el mensaje y el destino del respaldo. La aplicación debe guardar esa copia **antes** de modificar registros; si no puede crearla, no continúa con la actualización.
5. Espera a que termine y revisa el resumen. Después abre **Registros** y consulta, por ejemplo, `pacientes`, `medicamentos`, `notas_enfermeria` y `receta_detalle`.

La actualización cambia cada campo solamente cuando todavía coincide con un valor conocido de las versiones anteriores. Así conserva los campos que el equipo ya haya editado. No agrega filas, no borra datos y no reemplaza la base. En una copia modificada, el resultado puede combinar datos del equipo y datos completados por el proyecto.

Si el equipo escribió por su cuenta un texto parecido a los de relleno, revíselo después desde **Registros**: la actualización no debe sustituir automáticamente cualquier texto que encuentre. Los historiales que la interfaz protege se conservan protegidos para el trabajo diario.

## Si reconstruyes todo con los archivos de diseño

La ruta recomendada para una base nueva es importar el respaldo actual o utilizar **Crear base con ejemplos**. Ambas rutas incluyen esta revisión. Los archivos de diseño y la integración del aporte del equipo siguen incluidos para estudiar cómo se construyó el modelo.

El archivo [07_contactos_y_catalogos.sql](07_contactos_y_catalogos.sql) se conserva como registro histórico de la primera actualización de contactos. **No es la actualización completa actual** y no necesitas ejecutarlo después de instalar una copia nueva.

Si ya tienes una base con trabajo del equipo, utiliza **Completar datos del proyecto**; no reconstruyas la base ni importes otra encima de ella.

## Manuales que debes consultar

El [tutorial de texto](tutorial_interfaz/TUTORIAL.md) y su [PDF ilustrado](tutorial_interfaz/tutorial_interfaz_hospital.pdf) explican los botones y datos actuales. El Word de `tutorial_interfaz/` se conserva como versión anterior: sus ejemplos pueden contener textos antiguos y no es la guía recomendada para esta entrega.
