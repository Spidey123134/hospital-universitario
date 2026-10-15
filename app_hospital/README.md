# Aplicación de escritorio del hospital

La interfaz está programada en Python con Tkinter. MySQL conserva la información; PyMySQL conecta las ventanas con el servidor. No se necesita Workbench para utilizar el programa ni hay una caja para ejecutar SQL.

## Uso en Windows

Extrae toda la carpeta y abre **ABRIR_HOSPITAL.bat** desde la carpeta principal. Requiere Python 3.10 o posterior con Tkinter y MySQL Server 8.0.16 o posterior iniciado. El iniciador crea `.venv_app` e instala `requirements.txt`; la primera vez necesita Internet. No instala ni configura el servidor MySQL.

La [guía ilustrada](../tutorial_interfaz/tutorial_interfaz_hospital.pdf) explica la instalación y cada ejercicio. Servidor, puerto, usuario y contraseña son los de tu servidor MySQL. La contraseña no se guarda al recordar la conexión.

## Funciones

- **Inicio:** conteos de las 36 tablas, pacientes, médicos, medicamentos, recetas y total; creación de respaldo completo y restauración en una base nueva.
- **Registros:** consultar las 36 tablas, buscar, agregar y editar los registros permitidos, seleccionar relaciones por nombre y exportar las filas mostradas a CSV. Identificadores y campos calculados se protegen.
- **Operaciones:** agendar, confirmar y cancelar citas; asignar o trasladar camillas; dar altas; registrar entradas y ajustes; entregar medicamentos; emitir y anular facturas; registrar pagos. Las seis operaciones principales usan los procedimientos transaccionales de la base.
- **Consultas:** ocho reportes con nombres, especialidades, recetas, disponibilidad, existencias y saldos.
- **Guía:** ayuda breve y botones para abrir el tutorial PDF o Word.

La instalación desde la ventana crea una base inexistente con 789 registros en las 36 tablas. No carga ejemplos encima de una base existente. Si tu versión antigua tiene menos registros, puedes crear otra demostración con un nombre nuevo sin perder la anterior.

El historial tiene restricciones: los pagos, movimientos y entregas se consultan desde Registros y se agregan mediante Operaciones. Las consultas y notas existentes se conservan; puedes agregar las nuevas. Los conceptos de facturas se modifican mientras la factura está ABIERTA. No se ofrece eliminación de registros. Los catálogos de usuarios y roles se muestran como parte del modelo académico; la aplicación utiliza una cuenta de MySQL y no implementa inicio de sesión de empleados.

## Respaldos

**Crear respaldo completo** genera un archivo `.hospital.json` con todas las filas y columnas originales de las 36 tablas; los campos calculados se reconstruyen. La lectura usa una instantánea consistente. No incluye la conexión ni su contraseña. Si hay hashes de cuentas en los datos, se conservan para poder restaurarlos: protege el archivo como proteges tu base.

**Restaurar respaldo en base nueva** lee solo el formato JSON del proyecto. Crea el esquema del proyecto, carga las filas con parámetros y restablece sus vistas, procedimientos y triggers. El destino debe ser inexistente; no ejecuta instrucciones SQL recibidas desde el JSON. Límite académico: 50 MB y 100 000 filas. Si se interrumpe una instalación o restauración, la base nueva puede quedar incompleta; el programa explica ese estado y no la borra automáticamente.

El CSV contiene solo la página visible: hasta 200 filas en Registros o 500 en Consultas. No sirve como respaldo completo. Los textos que podrían interpretarse como fórmulas de hoja de cálculo se exportan como texto.

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

Se puede consultar y agregar información en los módulos del hospital. Algunas relaciones dependen de más de un campo: una consulta vinculada a una cita debe usar el mismo paciente y médico; un lote debe coincidir con el medicamento de la receta. Las listas ayudan a elegir y la base valida esas relaciones al guardar. No se afirma que la aplicación cubra todos los procesos de un hospital real.

## Repetir las pruebas

Usa una instancia de pruebas con una cuenta que pueda crear y eliminar bases. Estos programas generan nombres UUID propios y no aceptan una base existente como objetivo de borrado. La contraseña se obtiene de `MYSQL_PWD`; no debe aparecer en los comandos ni en la evidencia.

```text
.venv_app\Scripts\python.exe app_hospital/tests/integration_mysql.py --user root --port 3306
.venv_app\Scripts\python.exe -m app_hospital.tests.gui_smoke --user root --port 3306
```

El segundo recorrido necesita escritorio Windows y Pillow para capturar exclusivamente las ventanas de esta aplicación. Pillow es una dependencia opcional de las pruebas, no de la aplicación. Los reportes están en [VALIDACION_APP.json](../VALIDACION_APP.json) y [VALIDACION_INTERFAZ.json](../VALIDACION_INTERFAZ.json). Cambiar código o datos requiere volver a verificar la evidencia correspondiente.

Referencias de programación: [Tkinter](https://docs.python.org/3/library/tkinter.html), [PyMySQL y su extra de autenticación](https://pypi.org/project/PyMySQL/), [instalación de MySQL en Windows](https://dev.mysql.com/doc/refman/8.0/en/windows-installation.html).
