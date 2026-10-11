# Revisión de la base de datos del hospital

Esta revisión se basa en la estructura encontrada dentro de `camillas.ibd`, `medicamentos.ibd`, `medicos.ibd`, `pacientes.ibd` y `recetas.ibd`. Esas cinco tablas se consideran un prototipo inicial. El alcance solicitado es ahora una base de datos hospitalaria integral para un proyecto universitario de sistemas, con estructura, diagrama y material para explicar el diseño.

Todavía falta la consigna del profesor. Las reglas propuestas son supuestos que deben compararse con esa consigna antes de dar la entrega por definitiva.

## Qué se pudo comprobar

Los cinco archivos son espacios de tablas InnoDB. Se leyeron sus metadatos SDI comprimidos, que incluyen nombres de columnas, índices y relaciones. La versión registrada en esos metadatos es MySQL 8.0.29 y el esquema se llama `hospital`. Ese dato no confirma qué versión está instalada actualmente.

Se recuperó la **estructura**, pero aún no se han recuperado ni validado las filas originales. No se incluyeron registros ni datos personales en esta revisión. Los archivos `.ibd` originales permanecen intactos.

Según la [documentación oficial de SDI](https://dev.mysql.com/doc/refman/8.0/en/serialized-dictionary-information.html), InnoDB guarda metadatos JSON comprimidos dentro de los espacios de tablas y permite extraerlos incluso sin disponer del diccionario de datos del servidor.

## Qué está bien en el trabajo original

- Las cinco tablas tienen claves primarias enteras.
- `medicos.cedula_profesional` y `pacientes.expediente_clinico` tienen índices únicos, lo que ayuda a evitar duplicados.
- Las recetas cuentan con claves foráneas hacia pacientes, médicos, camillas y medicamentos.
- Los pacientes pueden tener un médico tratante asignado y ese vínculo es opcional.
- Se separaron los catálogos de médicos, pacientes, medicamentos y camillas, en lugar de repetir sus datos completos en cada receta.

## Problemas comprobados y correcciones propuestas

| Hallazgo en el original | Consecuencia | Corrección |
| --- | --- | --- |
| `recetas` contiene un solo `medicamento_id`, además de dosis y vía. | Una receta solo puede guardar un medicamento. Para varios, habría que generar recetas distintas o repetir el encabezado. | Mantener el encabezado en `recetas` y agregar `receta_detalle`, con una fila por medicamento indicado. |
| `recetas.camilla_id` es obligatorio. | No se puede registrar una receta de un paciente ambulatorio sin asignarle una camilla. | Quitar la camilla del encabezado y registrar las ocupaciones como asignaciones de camilla durante una hospitalización. |
| Solo están las cinco tablas mencionadas; no existe una entidad de hospitalización. | Una receta no permite conocer de forma fiable el ingreso, alta o historial de ocupación de una camilla. | Agregar hospitalizaciones y sus asignaciones de camilla, con fechas de ingreso, traslado y alta. |
| `fecha_prescripcion` admite `NULL`, aunque tiene valor predeterminado. | Una inserción explícita de `NULL` deja una receta sin fecha. | Hacer la fecha obligatoria y conservar un valor predeterminado. |
| La FK de recetas a pacientes tiene borrado en cascada. | Borrar un paciente puede borrar sus recetas. | Restringir el borrado cuando exista historial relacionado. |
| `camillas.estado_operativo` es texto libre, admite `NULL` y usa `Disponible` como valor predeterminado. | Se pueden registrar valores inconsistentes y confundir el funcionamiento de la camilla con su ocupación. | Usar un conjunto definido de estados operativos; calcular la disponibilidad a partir de la hospitalización activa. |

No se afirma que ya existan filas inválidas: estos son comportamientos permitidos o limitaciones de la estructura revisada.

## Alcance ampliado del diseño

El diseño debe conectar los procesos del hospital, no limitarse a agregar catálogos independientes. Un recorrido que debe poder explicarse con consultas SQL es: paciente → cita o ingreso → atención → diagnóstico → receta o estudio → entrega de medicamento o resultado → cargo → pago.

| Área | Tablas previstas | Separaciones necesarias |
| --- | --- | --- |
| Organización | `departamentos`, `especialidades`, `habitaciones`, `camillas`. | Ubicación física, estado operativo y ocupación son conceptos distintos. |
| Personal | `personal`, `medicos`, `medico_especialidad`. | El médico es un subtipo del personal; puede tener varias especialidades. |
| Pacientes y cobertura | `pacientes`, `contactos_emergencia`, `aseguradoras`, `polizas`, `alergias_paciente`. | Evitar duplicar la identidad y conservar la cobertura asociada al paciente correcto. |
| Atención | `citas`, `consultas`, `diagnosticos`, `consulta_diagnosticos`. | La cita planificada y la consulta realizada son eventos diferentes. |
| Hospitalización | `hospitalizaciones`, `asignaciones_camilla`, `notas_enfermeria`. | Una estancia puede tener varios traslados y varias notas. |
| Catálogo e inventario de farmacia | `medicamentos`, `proveedores`, `lotes_medicamento`, `movimientos_inventario`. | El medicamento es un catálogo; la existencia resulta de los movimientos por lote. |
| Prescripción y entrega | `recetas`, `receta_detalle`, `dispensaciones`, `dispensacion_detalle`. | Prescribir y entregar son operaciones distintas. |
| Procedimientos y estudios | `procedimientos`, `ordenes_procedimiento`, `resultados_procedimiento`. | Solicitar, realizar y obtener un resultado son eventos diferentes del catálogo. |
| Administración | `facturas`, `factura_detalle`, `pagos`. | Conservar precio histórico y permitir pagos parciales sin sobrescribir el total. |
| Acceso | `roles`, `usuarios`, `usuario_roles`. | El registro de un profesional y su cuenta de acceso tienen finalidades diferentes. |

Son **36 tablas previstas**. La estructura debe verificarse contra el script y el diagrama finales. Para una entrega universitaria se busca un modelo amplio y coherente; esta lista no representa literalmente todos los procesos posibles de un hospital real.

## Invariantes que debe respetar la estructura

### Identidad e historial clínico

- Cada tabla debe tener una clave primaria y las relaciones deben respaldarse con claves foráneas. Conservar las restricciones únicas sobre expediente y cédula.
- El paciente debe ser el mismo en todos los objetos de una atención. Si una receta u orden referencia una consulta, no debe poder indicar a otro paciente. Puede garantizarse con un episodio común, claves foráneas compuestas o validación transaccional explícita, según el esquema elegido.
- En el modelo previsto, la consulta proporciona el paciente y el médico de recetas y órdenes, evitando repetir estos IDs. La hospitalización debe conservar el mismo paciente que su consulta de ingreso mediante una FK compuesta.
- Si la consulta referencia una cita y ambas guardan paciente y médico, esos datos también deben coincidir. No basta con comprobar que el ID de la cita exista.
- Evitar relaciones basadas únicamente en una pareja `tipo_objeto` + `objeto_id`: una FK ordinaria no puede garantizar que el ID exista en varias tablas alternativas.
- `medico_tratante_id`, si se conserva, representa el responsable actual. El médico que firmó una receta o atendió una consulta debe quedar guardado en ese evento y puede ser diferente.
- Restringir borrados que eliminarían el historial. Un cambio en el catálogo o en el personal actual no debe reescribir la información histórica.

### Agenda y hospitalización

- Una cita debe tener inicio, fin y estado. Una restricción única sobre fecha y médico no detecta intervalos parcialmente superpuestos; documentar la validación adicional o utilizar horarios discretos definidos.
- Guardar ingreso y alta en la hospitalización; guardar inicio y fin de cada ocupación en las asignaciones de camilla. Así se conserva el historial de traslados.
- Impedir dos hospitalizaciones activas del mismo paciente y dos asignaciones activas de la misma camilla o de la misma hospitalización.
- En MySQL, columnas generadas con índices únicos pueden impedir duplicados activos usando IDs cuando la fecha de cierre es `NULL`. **No impiden por sí solas traslapes históricos de períodos cerrados**.
- Validar que una asignación esté dentro de la estancia, que la camilla esté habilitada y que una estancia cerrada no conserve ocupaciones abiertas. Las FKs simples no garantizan estas reglas entre filas.
- Las fechas de finalización no pueden anteceder a las de inicio. Los turnos nocturnos deben representarse con fechas o con una regla que permita atravesar la medianoche.

### Prescripción y farmacia

- La receta tiene encabezado y detalles. Cada detalle debe identificar el medicamento y sus indicaciones, con dosis y unidad, vía, frecuencia y duración cuando correspondan.
- Crear un encabezado y sus detalles en una misma transacción. Una FK ordinaria no obliga a que todo encabezado tenga al menos un detalle.
- Una dispensación debe señalar qué indicación satisface, el lote entregado y la cantidad. Verificar que ese lote pertenezca al medicamento prescrito.
- Elegir una fuente única para las existencias. Si el stock se calcula desde movimientos por lote, no mantener además otro stock que pueda modificarse de manera independiente.
- Las salidas deben impedir existencias negativas. La comprobación y el movimiento requieren una transacción y control de concurrencia, no solo una consulta previa de disponibilidad.
- Una receta por sí sola no descuenta existencias. Los movimientos y las entregas deben quedar vinculados para evitar descontar dos veces la misma operación.
- Definir si se permite entregar parcialmente una receta; si se permite, sumar las entregas antes de autorizar una nueva cantidad. Establecer además la regla sobre lotes caducados.

### Estudios y cobros

- El modelo previsto registra una orden por procedimiento o estudio; solicitar varios genera varias órdenes. Cada resultado debe corresponder a su orden. Definir si se conserva un único resultado final o versiones; no sobrescribir un historial que el proyecto necesite.
- Guardar precio unitario, cantidad y ajustes en cada detalle de cobro con tipos `DECIMAL`, no `FLOAT`. El cambio de tarifa del catálogo no debe alterar una cuenta emitida.
- Los totales deben coincidir con los detalles y el saldo con los pagos. Si se almacenan totales y estados, documentar cómo se evita que queden desactualizados.
- Los pagos deben conservarse como eventos independientes y positivos. Definir una sola moneda para el alcance inicial y una regla explícita para pagos mayores al saldo.

### Normalización y acceso

- No almacenar listas de medicamentos, diagnósticos o especialidades separadas por comas. Usar tablas de detalle o tablas puente en relaciones de muchos a muchos.
- Evitar repetir nombres de pacientes, médicos o servicios en eventos cuando una FK proporciona el dato. Los precios históricos sí son una copia deliberada del valor al emitir el cargo.
- No guardar edad como valor permanente: cambia con el tiempo y se calcula a partir del nacimiento.
- Usar estados definidos y documentar transiciones admitidas; texto libre permite variantes como `Alta`, `alta` o `Dado de alta` para el mismo significado.
- Una cuenta de acceso debe almacenar un hash de contraseña y su función o rol. El mecanismo de autenticación pertenece también a la aplicación; crear una tabla `usuarios` no lo implementa por sí solo.

## Supuestos y revisión de la entrega

El diseño se plantea como un sistema académico integral. Debe decir claramente qué áreas cubre y qué procesos quedan simplificados, por ejemplo facturación fiscal, seguros, nómina, compras o una historia clínica especializada. Esta delimitación permite defender el proyecto sin afirmar que es un sistema hospitalario listo para producción.

Entre los supuestos del modelo previsto: una consulta determina al médico prescriptor; si interviene otro médico, se registra otra atención. Los procedimientos agrupan estudios e intervenciones dentro de un catálogo, sin modelar todavía cada especialidad quirúrgica o un equipo de cirugía completo. La agenda no incluye por ahora una tabla específica de turnos. Las pólizas registran cobertura básica y no implementan la liquidación de reclamaciones ante aseguradoras.

La entrega debería incluir el esquema SQL, un diagrama que coincida con sus claves foráneas, un diccionario de datos, registros ficticios coherentes, consultas que recorran los procesos principales y pruebas de las restricciones importantes. Se debe indicar qué reglas cumple directamente la base y cuáles necesitan procedimientos, transacciones o lógica de aplicación.

El diagrama debe representar las cardinalidades y la opcionalidad reales: una receta pertenece a una consulta y tiene varios detalles; una hospitalización tiene varias asignaciones a lo largo del tiempo; cada orden señala un procedimiento; una cuenta puede recibir varios pagos.

## Revisión estática de `01_esquema.sql`

Se revisó el script de estructura sin modificarlo. Contiene las 36 tablas previstas. Las claves foráneas compuestas comprobadas mantienen la coherencia entre cita y consulta, consulta de ingreso y paciente, factura y póliza, detalle de receta y medicamento, dispensación y receta, lote y medicamento, y movimiento y lote entregado.

También incorpora cantidades positivas, signos de movimientos, intervalos básicos, importes calculados con `DECIMAL`, índices únicos de ocupación activa y un máximo de un diagnóstico principal por consulta. Ese último índice impide dos diagnósticos principales, pero no obliga a registrar uno.

No se detectaron errores de sintaxis evidentes en la lectura estática. Esto no sustituye ejecutar el esquema en MySQL ni realizar las pruebas funcionales.

El esquema por sí solo todavía necesita rutinas, transacciones o restricciones de escritura para validar los siguientes puntos:

- Una entrega debe producir exactamente una salida de inventario por detalle y con cantidad opuesta a lo entregado. La FK y el índice único existentes garantizan coherencia de lote y ausencia de duplicados, pero no obligan a crear la salida ni a que las cantidades coincidan.
- La suma de las dispensaciones no debe superar la cantidad prescrita. Una receta ya dispensada tampoco debe reducir su cantidad indicada por debajo de lo entregado.
- La agenda debe impedir solapamientos parciales; las asignaciones deben respetar el período de hospitalización, el historial de la camilla y el de la propia estancia.
- La factura debe tener detalles antes de emitirse. Después de emitirla, no debe poder reabrirse para alterar cargos ni cambiar de paciente o póliza; no debe anularse con pagos registrados sin un mecanismo explícito de devolución.
- Un resultado no debe registrarse antes de la solicitud ni para una orden cancelada. Los roles y la actividad del personal deben validarse al realizar cada operación que los requiera.
- Los vínculos de identidad clínica no deben reasignarse retroactivamente cuando ya existen recetas, resultados o entregas: cambiar el paciente de una consulta también cambia el paciente derivado de sus eventos.

Estas reglas se deben contrastar con el archivo de rutinas y las pruebas finales. La revisión estática no afirma que ya estén implementadas ni probadas.

## Recuperación y migración pendientes

Crear el esquema propuesto no importa automáticamente las filas de los `.ibd` y no constituye una migración. Para conservar los registros originales, primero hay que recuperar o conseguir un respaldo SQL del esquema anterior y revisar los datos antes de transformarlos.

La [documentación oficial de importación de tablas InnoDB](https://dev.mysql.com/doc/refman/8.0/en/innodb-table-import.html) describe requisitos de compatibilidad de versión, tamaño de página y estructura. También advierte que la importación del espacio de tablas no comprueba las relaciones de las filas importadas. Por eso no basta con copiar los `.ibd` a una carpeta de un servidor y asumir que la base ya funciona.

Antes de cerrar la entrega, falta confirmar la consigna, el gestor exigido, si deben conservarse los datos originales y los productos solicitados: script, diagrama, consultas, normalización o reporte.
