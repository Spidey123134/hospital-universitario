# Aplicación de escritorio del hospital

La interfaz está programada en Python con Tkinter. MySQL conserva la información; PyMySQL conecta las ventanas con el servidor. No se necesita Workbench para utilizar el programa ni hay una caja para ejecutar SQL.

## Uso en Windows

Extrae toda la carpeta y abre **ABRIR_HOSPITAL.bat** desde la carpeta principal. Requiere Python 3.10 o posterior con Tkinter y MySQL Server 8.0.16 o posterior iniciado. El iniciador crea `.venv_app` e instala `requirements.txt`; la primera vez necesita Internet. No instala ni configura el servidor MySQL.

La [guía ilustrada actualizada](../tutorial_interfaz/tutorial_interfaz_hospital.pdf) explica la instalación y cada ejercicio; también está [en texto](../tutorial_interfaz/TUTORIAL.md). Servidor, puerto, usuario y contraseña son los de tu servidor MySQL. La contraseña no se guarda al recordar la conexión.

En la laptop donde se preparó la base local del proyecto, el servidor se inicia con `F:\Base de Datos\mysql_local\INICIAR_BASE_LOCAL.bat`, escucha en `127.0.0.1:3307` y sus datos privados están en `F:\Base de Datos\mysql_local\CONEXION_PRIVADA.txt`. Esos archivos pertenecen a esa laptop y no se distribuyen en GitHub. En las computadoras del equipo se utiliza el servidor y la contraseña elegidos por cada integrante; el puerto habitual es `3306`.

## Primera conexión

1. Inicia tu MySQL Server y abre `ABRIR_HOSPITAL.bat`.
2. Completa servidor, puerto, usuario, contraseña y base `hospital_universitario`.
3. Pulsa **Probar conexión**. La comprobación distingue servidor accesible con base compatible, base todavía inexistente y base con estructura incompatible. No crea ni carga datos.
4. Si la base del proyecto ya existe y es compatible, pulsa **Abrir hospital**.
5. Si no existe, pulsa **Crear base con ejemplos**, confirma y espera. Después abre el hospital.

La creación carga 789 registros repartidos en las 36 tablas e incluye `07_contactos_y_catalogos.sql`: nombres completos, 95 teléfonos de diez dígitos y 59 correos de ejemplo personalizados. Conserva los aportes del equipo. Una base existente no se sustituye ni recibe esta carga otra vez. Para actualizar una copia anterior, consulta [Datos del proyecto](../DATOS_DEL_PROYECTO.md) y respáldala primero.

## Funciones

- **Inicio:** conteos de las 36 tablas, pacientes, médicos, medicamentos, recetas y total; creación de respaldo completo y restauración en una base nueva.
- **Registros:** filtrar las 36 tablas por área del hospital, buscar, abrir **Ver registro**, agregar y editar donde corresponde, seleccionar relaciones por nombre y exportar la página mostrada a CSV. Identificadores y campos calculados se protegen. Los valores lógicos se eligen como **Sí** o **No**; las fechas, números y longitudes de los campos se revisan al guardar.
- **Operaciones:** agendar, confirmar y cancelar citas; asignar o trasladar camillas; dar altas; registrar entradas y ajustes; entregar medicamentos; emitir y anular facturas; registrar pagos. Las seis operaciones principales usan los procedimientos transaccionales de la base.
- **Consultas:** ocho reportes con nombres, especialidades, recetas, disponibilidad, existencias y saldos.
- **Guía:** ayuda breve y botones para abrir el tutorial PDF o el texto actualizado.

Si quieres una práctica aparte, crea otra base con un nombre nuevo. Cada computadora del equipo mantiene su propia copia; los cambios hechos en una no aparecen automáticamente en las otras.

El historial tiene restricciones: los pagos, movimientos y entregas se consultan desde Registros con **Ver registro** y se agregan mediante Operaciones. Las consultas y notas existentes se conservan; puedes agregar las nuevas. Los conceptos de facturas se modifican mientras la factura está ABIERTA. No se ofrece eliminación de registros. Los catálogos de usuarios y roles se muestran como parte del modelo académico; la aplicación utiliza una cuenta de MySQL y no implementa inicio de sesión de empleados.

Si la cuenta MySQL tiene permisos de consulta, la aplicación permite abrir la base, buscar y leer sus registros, y deshabilita las acciones de escritura. Para registrar o modificar datos se necesita una cuenta MySQL con los permisos correspondientes.

## Respaldos

**Crear respaldo completo** genera un archivo `.hospital.json` con todas las filas y columnas originales de las 36 tablas; los campos calculados se reconstruyen. La lectura usa una instantánea consistente. No incluye la conexión ni su contraseña. Si hay hashes de cuentas en los datos, se conservan para poder restaurarlos: protege el archivo como proteges tu base.

**Restaurar respaldo en base nueva** pide el nombre de una base nueva en un diálogo; no hace falta cambiar el campo superior de conexión ni sobrescribir el original. Lee solo el formato JSON del proyecto. Crea el esquema, carga las filas con parámetros y restablece sus vistas, procedimientos y triggers. El destino debe ser inexistente; no ejecuta instrucciones SQL recibidas desde el JSON. Límite académico: 50 MB y 100 000 filas. Si se interrumpe una instalación o restauración, la base nueva puede quedar incompleta; el programa explica ese estado y no la borra automáticamente.

**Exportar página a CSV**, en Registros, y **Exportar filas mostradas a CSV**, en Consultas, guardan solo las filas mostradas: hasta 200 por página en Registros o 500 en Consultas. No sirven como respaldo completo. Los textos que podrían interpretarse como fórmulas de hoja de cálculo se exportan como texto.

## Para quienes programan el proyecto

```text
python -m venv .venv_app
.venv_app\Scripts\python.exe -m pip install -r requirements.txt
.venv_app\Scripts\python.exe -m app_hospital.main
```

En otros sistemas, usa el ejecutable Python del entorno correspondiente. La interfaz se probó en Windows con Python 3.12.14, Tk 8.6, PyMySQL 1.2.3 y MySQL 8.0.45. La instalación de Tkinter en Linux puede requerir el paquete de tu distribución.

| Archivo | Responsabilidad |
| --- | --- |
| `main.py` | Ventanas, formularios, acciones y exportación de CSV |
| `db.py` | Conexión, valores parametrizados, validación, carga y respaldo |
| `catalog.py` | Tablas permitidas, etiquetas, restricciones, operaciones y reportes |
| `tests/integration_mysql.py` | Pruebas reales del servicio, incluido el ejercicio del tutorial |
| `tests/gui_smoke.py` | Recorrido de las ventanas reales y capturas de la propia aplicación |
| `tests/test_forms.py` | Pruebas de validación de formularios con Tkinter, sin conexión a MySQL |

Se puede consultar y agregar información en los módulos del hospital. Algunas relaciones dependen de más de un campo: una consulta vinculada a una cita debe usar el mismo paciente y médico; un lote debe coincidir con el medicamento de la receta. Las listas ayudan a elegir y la base valida esas relaciones al guardar. No se afirma que la aplicación cubra todos los procesos de un hospital real.

## Repetir las pruebas

Usa una instancia de pruebas con una cuenta que pueda crear y eliminar bases. Estos programas generan nombres UUID propios y no aceptan una base existente como objetivo de borrado. La contraseña se obtiene de `MYSQL_PWD`; no debe aparecer en los comandos ni en la evidencia.

```text
.venv_app\Scripts\python.exe app_hospital/tests/integration_mysql.py --user root --port 3306
.venv_app\Scripts\python.exe -m app_hospital.tests.gui_smoke --user root --port 3306
.venv_app\Scripts\python.exe -m unittest app_hospital.tests.test_forms
```

El segundo recorrido necesita escritorio Windows y Pillow para capturar exclusivamente las ventanas de esta aplicación. Pillow es una dependencia opcional de las pruebas, no de la aplicación. Las pruebas de formularios también necesitan una pantalla con Tkinter y no usan MySQL. Los reportes están en [VALIDACION_APP.json](../VALIDACION_APP.json), [VALIDACION_INTERFAZ.json](../VALIDACION_INTERFAZ.json) y [VALIDACION_FORMULARIOS.json](../VALIDACION_FORMULARIOS.json). Cambiar código o datos requiere volver a verificar la evidencia correspondiente.

Referencias de programación: [Tkinter](https://docs.python.org/3/library/tkinter.html), [PyMySQL y su extra de autenticación](https://pypi.org/project/PyMySQL/), [instalación de MySQL en Windows](https://dev.mysql.com/doc/refman/8.0/en/windows-installation.html).
