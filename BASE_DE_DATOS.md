# La base MySQL y las copias del equipo

La entrega principal es **hospital_universitario**, una base de MySQL con 36 tablas relacionadas y 789 registros ficticios. Python es una etapa aparte: no se necesita para importar, abrir ni consultar esta base en MySQL Workbench.

## Qué recibe cada integrante

El archivo [hospital_universitario_respaldo.sql](entrega_base/hospital_universitario_respaldo.sql) es un **respaldo exportado de una base que ya está creada y poblada en MySQL**. Incluye estructura, registros, vistas, procedimientos y triggers. Al importarlo en el servidor de cada integrante, se crea una copia real y permanente en esa computadora.

GitHub sirve para compartir este respaldo y los archivos del proyecto. Descargarlo no instala MySQL ni crea automáticamente una base en el servidor de quien lo descarga. El respaldo es la forma de trasladar la misma base entre computadoras; no es necesario copiar archivos internos `.ibd`.

El respaldo actual ya incluye los nombres, domicilios y contactos completados, además de las notas, informes y conceptos de cobro revisados el 23 de octubre. Conserva las mismas 36 tablas y 789 filas. Si lo importas, **no necesitas ejecutar `07_contactos_y_catalogos.sql` después**. [DATOS_DEL_PROYECTO.md](DATOS_DEL_PROYECTO.md) explica los datos académicos y cómo actualizar una copia anterior sin borrar el trabajo del equipo.

## En la computadora donde se preparó la entrega

En la computadora original se preparó un servidor local independiente en la carpeta `mysql_local`, junto a `propuesta_hospital`. Sus datos quedan guardados en `mysql_local/data`, fuera de las carpetas temporales y fuera del repositorio. Esa carpeta privada no viene en el ZIP ni se necesita para las copias de los demás: ellos siguen el apartado siguiente e importan el respaldo en su propio MySQL.

1. Abre `mysql_local/INICIAR_BASE_LOCAL.bat` para encender este servidor cuando lo necesites.
2. En MySQL Workbench, crea una conexión con servidor **127.0.0.1**, puerto **3307** y usuario **root**.
3. La contraseña particular de esta computadora está en `mysql_local/CONEXION_PRIVADA.txt`. Ese archivo no se sube a GitHub ni se comparte con el equipo.
4. Abre la conexión y actualiza **Schemas**. Debe aparecer **hospital_universitario**; expande **Tables** para ver sus 36 tablas.
5. Haz clic derecho en `pacientes` y elige **Select Rows Limit 1000** para ver sus 30 registros. No necesitas la interfaz de Python.

`COMPROBAR_BASE.bat` muestra si la base está disponible y sus conteos principales. `APAGAR_BASE_LOCAL.bat` apaga este servidor correctamente sin borrar datos. No es un servicio de Windows: después de reiniciar la computadora, abre el iniciador. No se modifican otros servidores que ya tengas instalados.

## En la laptop y en las computadoras de los compañeros

Cada integrante realiza esta instalación una vez en su propia computadora:

1. Instala **MySQL Server** y **MySQL Workbench**, o utiliza los que ya tenga funcionando. Workbench es la ventana para administrarlo; Server es el programa que guarda los datos.
2. Descarga del repositorio el archivo `entrega_base/hospital_universitario_respaldo.sql`. Si descargas el ZIP del proyecto, extrae toda la carpeta primero.
3. Abre Workbench y entra a su conexión local. Usa el puerto y la contraseña de **su instalación**; normalmente el puerto es 3306. El puerto 3307 corresponde al servidor separado que se preparó en esta computadora.
4. Revisa **Schemas**. Si ya existe una base llamada `hospital_universitario` con trabajo propio, **no importes encima**: conserva un respaldo y acuerda otro destino antes de continuar.
5. En el menú **Server**, elige **Data Import**.
6. Marca **Import from Self-Contained File** y selecciona `hospital_universitario_respaldo.sql`.
7. Abre **Import Progress** y pulsa **Start Import**. Espera a que termine sin errores. El respaldo incluye la creación de `hospital_universitario`.
8. Actualiza **Schemas** y abre `hospital_universitario` → **Tables**. Ya tiene su propia copia guardada en MySQL.
9. Abre `pacientes` con **Select Rows Limit 1000** y comprueba que aparecen 30 filas. También debe haber 18 médicos, 15 medicamentos y 40 recetas.

No se crea una cuenta de MySQL con una contraseña compartida al importar: cada computadora conserva sus propias credenciales de acceso. Para iniciar MySQL después, utiliza el servicio o el iniciador de su propia instalación.

## Cómo se comparte el trabajo después

Son **copias independientes**. Lo que agregue una persona no aparecerá automáticamente en las otras. Antes de intercambiar cambios, acuerden cuál será la versión de referencia; exporten un respaldo actualizado y conserven una copia del trabajo anterior antes de importar otra versión. El respaldo inicial de este repositorio no contiene los cambios que el equipo haga después.

## Qué se verificó

El [informe de la base creada](entrega_base/INFORME_BASE_CREADA.json) registra la versión del servidor, los conteos y la huella del respaldo. La entrega contiene 36 tablas, seis vistas, seis procedimientos y 23 triggers. Se comprueba que los datos siguen presentes después de apagar y reiniciar el servidor y que el respaldo puede crear otra copia con los mismos datos.

Los diagramas, el diccionario y el reporte académico siguen en el proyecto. La aplicación de `app_hospital` y su tutorial quedan separados para una etapa posterior.
