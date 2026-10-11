# Modelo hospitalario y justificación

## Objetivo y alcance

Diseñar una base relacional de un hospital para un proyecto universitario de sistemas en MySQL. El modelo conecta identidad, atención, hospitalización, farmacia, estudios y cobros, y aporta un soporte conceptual para el acceso de una aplicación. Son 36 tablas distribuidas en 8 módulos. El diseño parte de cinco tablas entregadas como prototipo; ampliar el alcance no supone que ese prototipo cubriera todos estos procesos.

La propuesta es una base académica amplia. La consigna del profesor sigue pendiente: ajustar cantidad de registros, diagramas o formato final conforme a la rúbrica. No se inventan institución, autor, grupo ni matrícula.

## Evidencia del prototipo

Se recuperaron metadatos SDI de camillas.ibd, medicamentos.ibd, medicos.ibd, pacientes.ibd y recetas.ibd. El manifiesto registra huellas SHA-256 y versión 80029 (MySQL 8.0.29). Esta versión corresponde a los archivos revisados, no certifica la instalación local actual. Se conservan las estructuras JSON en evidencia_original; los registros originales todavía no se han recuperado ni validado.

Aspectos aprovechables: claves primarias enteras, expediente y cédula únicos, separación de médicos/pacientes/medicamentos/camillas y relaciones con receta. Limitaciones estructurales detectadas:

| Prototipo | Efecto permitido | Cambio del modelo |
| --- | --- | --- |
| Una receta tiene un medicamento_id | Varios medicamentos requieren repetir encabezados | recetas + receta_detalle |
| camilla_id obligatorio en recetas | La receta ambulatoria exige camilla | Ocupación en hospitalizaciones/asignaciones_camilla |
| Cinco tablas sin estancia ni traslados | No representa ingreso, alta e historial de ocupación | Hospitalización y asignaciones temporales |
| Fecha de receta admite NULL | Puede quedar una prescripción sin fecha | Fecha NOT NULL con valor predeterminado |
| FK receta-paciente con borrado cascada | Borrar paciente puede borrar recetas | Restricción de borrado e inactivación de entidades |
| Estado de camilla libre y nullable | Mezcla funcionamiento con ocupación | ENUM operativo y ocupación calculada |

Estos son comportamientos posibles del esquema; no se afirma que existan filas inválidas. Cambiar de estructura requiere una migración explícita. Los scripts propuestos no importan los .ibd y no modifican los originales.

## Modelo conceptual

El paciente es la identidad común de la atención. La cita es un plan; la consulta es el evento realizado y puede registrar urgencias sin cita. La consulta vincula diagnósticos y origina recetas, órdenes o una estancia. La hospitalización conserva su responsable y las asignaciones permiten traslados sin reescribir el historial.

Personal almacena datos laborales comunes; medicos es un subtipo con el mismo identificador y su cédula. Medico_especialidad resuelve la relación de muchos a muchos. Contactos y pólizas dependen del paciente. Departamentos y habitaciones organizan recursos físicos, y camillas conserva su estado operativo.

En farmacia, medicamentos describe el producto y lotes_medicamento identifica recepciones, proveedor y caducidad. Recetar no reduce existencias: dispensaciones registra entregas y movimientos_inventario registra su impacto. La cantidad disponible se calcula con el libro de movimientos. Una receta puede entregarse parcialmente y desde varios lotes compatibles, sin superar la cantidad prescrita.

Procedimientos agrupa laboratorio, imagen, cirugía y otros. Cada orden solicita un procedimiento, y puede tener cero o un resultado final. Solicitar varios procedimientos genera varias órdenes; el modelo no guarda versiones de informes.

Facturas es una cuenta académica, no un comprobante fiscal CFDI. Sus detalles conservan descripción y precio al emitir el cargo; pagos almacena eventos parciales. La póliza, si existe, pertenece al mismo paciente de la cuenta. Usuarios y roles describen autorización futura de una aplicación; no implementan autenticación ni GRANT del servidor.

## Cardinalidades y opcionalidad

- Un paciente puede tener cero o muchas citas, consultas, pólizas, alergias y contactos. Cada una de esas filas pertenece a un paciente.
- Un trabajador puede tener cero o una fila en medicos y cero o una cuenta en usuarios. Un médico puede tener varias especialidades y una especialidad varios médicos.
- Una cita puede tener cero o una consulta; la referencia a cita es opcional en consulta. Cuando existe, paciente y médico coinciden por FK compuesta.
- Una consulta puede tener muchas recetas, órdenes y diagnósticos, y cero o una hospitalización de ingreso. La receta pertenece a una consulta; cada detalle pertenece a una receta y medicamento.
- Una hospitalización tiene cero o muchas asignaciones y notas; la operación de ingreso debe crear una asignación si el caso lo requiere. El DDL por sí solo no exige que un padre tenga hijos.
- Una receta admite varias dispensaciones; cada entrega contiene detalles que apuntan a su renglón y lote. Un detalle de entrega puede tener cero o un movimiento asociado por UNIQUE; el procedimiento debe producir su salida en la misma transacción.
- Una orden tiene cero o un resultado, una factura varios detalles y pagos, y una cuenta varios roles por la tabla puente.

Los diagramas físicos representan las FKs y lo que realmente permite el DDL. La obligatoriedad de un hijo no implica que un padre tenga al menos un hijo. Las reglas de negocio pueden exigir más condiciones que las cardinalidades físicas.

## Normalización: 1FN, 2FN y 3FN

### Primera forma normal

Cada celda guarda un valor del dominio y cada fila se identifica mediante PK. No se guardan listas de medicamentos, diagnósticos o especialidades separadas por comas: se usan receta_detalle, consulta_diagnosticos y medico_especialidad. Por ejemplo, una receta de tres medicamentos contiene un encabezado y tres renglones, sin columnas medicamento_1, medicamento_2 o medicamento_3. Dosis y frecuencia son indicaciones textuales del alcance académico; no constituyen listas relacionales de productos. Para reglas de dosificación estructuradas harían falta catálogos y unidades adicionales.

### Segunda forma normal

En tablas con PK compuesta, los atributos del evento dependen de toda la clave. En receta_detalle, (receta_id, renglon) identifica la indicación completa: medicamento, dosis, frecuencia, duración y cantidad. El nombre y concentración del medicamento dependen solo de medicamento_id y se guardan en medicamentos. En medico_especialidad y usuario_roles no hay atributos que dependan de una parte de la clave. En consulta_diagnosticos, es_principal y observaciones describen la asociación de ese diagnóstico con esa consulta, no el catálogo general.

### Tercera forma normal

Se separan dependencias entre atributos no clave: nombre de aseguradora en aseguradoras, nombre de departamento en departamentos, datos laborales en personal y descripciones de productos en medicamentos. Las recetas obtienen paciente y médico a través de consultas, evitando copias editables. Las órdenes obtienen el paciente de la misma consulta. La edad se calcula a la fecha consultada y no se almacena como dato que envejece.

No se afirma que todas las columnas físicas satisfagan estrictamente 3FN sin excepciones. El núcleo se organiza con criterio de 3FN y se aplican tres excepciones deliberadas:

1. FKs compuestas de coherencia. Consultas repite paciente_id/medico_id respecto de una cita opcional; hospitalizaciones conserva paciente_id junto a consulta_ingreso_id; dispensacion_detalle repite receta_id/medicamento_id para comprobar encabezado, renglón y lote; movimientos_inventario conserva lote_id para vincular la salida compatible; facturas conserva paciente_id aunque una póliza opcional ya identifica a su paciente. Las restricciones compuestas impiden que estos IDs se contradigan. Su finalidad es integridad verificable, y se documentan como redundancia controlada.
2. Instantáneas de cobro. Descripción y precio_unitario de factura_detalle corresponden al cargo histórico, no a la tarifa vigente del catálogo; costo_unitario es el costo histórico del lote. No son copias que se deban actualizar al cambiar precios. El detalle de factura no utiliza un id polimórfico sin FK ni pretende automatizar el origen de cada cargo.
3. Columnas derivadas. Importe y auxiliares de unicidad activa son GENERATED ALWAYS STORED, mantenidos por MySQL. No se editan manualmente. Existencia, edad, total y saldo se obtienen por consulta o vistas; no hay una segunda copia editable independiente.

Las PK enteras facilitan FKs y no convierten por sí solas una tabla en normalizada. Las claves de negocio se mantienen con UNIQUE (expediente, cédula, códigos, folios y combinaciones de lote/póliza).

## Reglas de negocio y mecanismos

| Regla | Mecanismo declarativo | Validación operativa adicional |
| --- | --- | --- |
| Identificadores válidos y relaciones existentes | PK, FK y UNIQUE | Inactivación de catálogos con historial |
| Consulta/cita, estancia/consulta, póliza/factura coherentes | FKs compuestas | No alterar identidades de eventos ya ligados |
| Fecha fin posterior a inicio | CHECK sobre fila | Agenda, estancia y asignación entre filas |
| Citas de duración válida y sin inicio duplicado | CHECK y UNIQUE generado | Impedir cualquier traslape de médico y paciente; bloquear recursos al validar |
| Un principal por consulta | UNIQUE sobre columna generada | Permite cero: exigir uno al cerrar atención si la rúbrica lo pide |
| Un ingreso activo por paciente y una ocupación activa | UNIQUE sobre columnas generadas | Traslapes históricos, pertenencia a estancia y camilla operativa |
| Lote del medicamento prescrito | FKs compuestas | Caducidad, existencia, saldo de receta y puesto de farmacia |
| Signo correcto de movimientos | CHECK; enlace único a salida | Evitar saldo negativo con transacción y bloqueo del lote |
| Cobro calculado y pago positivo | Importe generado y CHECK | No exceder saldo, estados y bloquear factura para pagos simultáneos |
| Médico y enfermería en el evento apropiado | FK a personal/medicos | Verificar puesto y activo, en rutinas/trigger según implementación |

Un índice único sobre el inicio de una cita no evita intervalos que empiezan a distinta hora y se superponen. Las columnas generadas de asignación solo restringen filas abiertas; no prueban ausencia de traslapes históricos. Estas reglas necesitan operaciones transaccionales adicionales, inspeccionables en 02_reglas.sql.

Las transacciones de negocio deben confirmar encabezado y detalles como una unidad. Validar un saldo con SELECT y después insertar sin bloquear el recurso permite carreras; las rutinas deben leer con bloqueo dentro de una transacción y deshacer todos los cambios ante error. También hace falta que una aplicación limite la escritura a operaciones autorizadas: conservar acceso de escritura directa puede saltarse reglas implementadas solo en procedimientos.

## Supuestos defendibles

- Se modela una sede lógica y una zona local común. No hay red multisede ni multimoneda.
- Una consulta identifica al médico que prescribe o solicita. Si atiende otro médico, registrar otro evento clínico para conservar su autoría.
- Una consulta de ingreso origina como máximo una estancia; un paciente puede tener varias estancias sucesivas, una activa a la vez.
- Los intervalos de citas y asignaciones usan [inicio, fin): terminar a las 10:00 permite comenzar otra a las 10:00. Una asignación sin fin es activa.
- Se permite entrega parcial y múltiples lotes, pero se bloquean entregas que excedan la prescripción o el inventario; se rechazan lotes caducados conforme a la fecha operativa.
- Los movimientos de inventario se capturan cronológicamente por lote: la fecha no puede anteceder al último movimiento. Correcciones de existencia se registran con un nuevo AJUSTE firmado, sin reescribir el libro histórico.
- La unidad de inventario debe permanecer consistente por producto. No hay conversión entre caja, tableta y mililitro.
- Un resultado final por orden y una orden por procedimiento. Cirugía es un tipo de catálogo y no una programación completa de quirófanos/equipo.
- Cobros en MXN, sin impuestos, CFDI, reembolsos, notas de crédito ni liquidación de aseguradoras.
- Los ejemplos contienen datos ficticios; no se han migrado registros del prototipo.

## Limitaciones y evolución

No se incluyen interoperabilidad HL7/FHIR, PACS/DICOM, expediente con firmas y versionado, consentimiento, auditoría completa de cambios, respaldo operativo, gestión de accesos real, nómina, compras con requisiciones/órdenes/recepciones, quirófanos detallados, turnos y guardias, emergencias con triaje completo, reclamaciones de seguros ni contabilidad fiscal. La presencia de usuarios/roles no resuelve estos procesos.

Una evolución razonable es agregar primero auditoría y permisos de aplicación, después agenda/turnos y catálogo estructurado de unidades; solo entonces ampliar módulos especializados. Estas extensiones requieren requisitos específicos y pruebas, no únicamente agregar tablas.

## Referencias técnicas

Las decisiones físicas de FK, CHECK, columnas generadas y bloqueos se apoyan en el manual oficial de MySQL 8.0. CHECK se exige a partir de MySQL 8.0.16. Los metadatos SDI son evidencia de estructura, y la importación de .ibd exige compatibilidad y revisión de datos; no sustituye una migración lógica.

- [Claves foráneas y acciones referenciales](https://dev.mysql.com/doc/refman/8.0/en/create-table-foreign-keys.html)
- [Restricciones CHECK y versión 8.0.16](https://dev.mysql.com/doc/refman/8.0/en/create-table-check-constraints.html)
- [Columnas generadas](https://dev.mysql.com/doc/refman/8.0/en/create-table-generated-columns.html)
- [Lecturas con bloqueo de InnoDB](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking-reads.html)
- [Metadatos SDI de InnoDB](https://dev.mysql.com/doc/refman/8.0/en/serialized-dictionary-information.html)
- [Importación de espacios de tablas](https://dev.mysql.com/doc/refman/8.0/en/innodb-table-import.html)
