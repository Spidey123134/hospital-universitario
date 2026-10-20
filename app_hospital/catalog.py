"""Catálogo cerrado de la interfaz. Ningún nombre SQL viene de un formulario."""

TABLE_GROUPS = {
    "Organización": ("departamentos", "especialidades", "personal", "medicos", "medico_especialidad"),
    "Pacientes": ("pacientes", "contactos_emergencia", "aseguradoras", "polizas"),
    "Instalaciones": ("habitaciones", "camillas"),
    "Atención médica": ("citas", "consultas", "diagnosticos", "consulta_diagnosticos", "alergias_paciente"),
    "Hospitalización": ("hospitalizaciones", "asignaciones_camilla", "notas_enfermeria"),
    "Farmacia": ("medicamentos", "proveedores", "lotes_medicamento", "recetas", "receta_detalle", "dispensaciones", "dispensacion_detalle", "movimientos_inventario"),
    "Estudios": ("procedimientos", "ordenes_procedimiento", "resultados_procedimiento"),
    "Cobros": ("facturas", "factura_detalle", "pagos"),
    "Acceso (consulta)": ("roles", "usuarios", "usuario_roles"),
}
TABLES = tuple(t for group in TABLE_GROUPS.values() for t in group)
LABELS = {
    "medicos": "Médicos", "medico_especialidad": "Especialidades de cada médico",
    "contactos_emergencia": "Contactos de emergencia", "polizas": "Pólizas",
    "diagnosticos": "Diagnósticos", "consulta_diagnosticos": "Diagnósticos de consultas",
    "alergias_paciente": "Alergias de pacientes", "asignaciones_camilla": "Historial de camillas",
    "notas_enfermeria": "Notas de enfermería", "lotes_medicamento": "Lotes de medicamentos",
    "receta_detalle": "Medicamentos de cada receta", "dispensaciones": "Entregas de farmacia",
    "dispensacion_detalle": "Detalle de entregas", "movimientos_inventario": "Movimientos de inventario",
    "ordenes_procedimiento": "Órdenes de estudios", "resultados_procedimiento": "Resultados de estudios",
    "factura_detalle": "Conceptos de facturas", "usuario_roles": "Roles de usuarios",
}
ROUTINE_ONLY = frozenset(("citas", "asignaciones_camilla", "movimientos_inventario", "dispensaciones", "dispensacion_detalle", "pagos"))
ACCESS_READONLY = frozenset(("roles", "usuarios", "usuario_roles"))
HISTORY_READONLY = frozenset(("hospitalizaciones", "consultas", "notas_enfermeria", "recetas", "resultados_procedimiento", "lotes_medicamento", "medico_especialidad", "consulta_diagnosticos"))
CREATE_READONLY = {
    "hospitalizaciones": {"fecha_alta", "resumen_alta"},
    "facturas": {"estado"},
}
UPDATE_READONLY = {
    "facturas": {"estado"},
    "receta_detalle": {"receta_id", "renglon", "medicamento_id"},
    "ordenes_procedimiento": {"consulta_id", "procedimiento_id", "estado"},
}
NOTES = {
    **{t: "Se registra desde Operaciones para comprobar las reglas del hospital." for t in ROUTINE_ONLY},
    **{t: "Catálogo de acceso del modelo académico; esta aplicación no implementa inicio de sesión de empleados." for t in ACCESS_READONLY},
    **{t: "Puede agregar registros. El historial existente se conserva sin edición desde la aplicación." for t in HISTORY_READONLY},
    "facturas": "Crear ABIERTA, agregar conceptos y después emitir desde Operaciones. El saldo se calcula automáticamente.",
    "factura_detalle": "Solo se agregan o corrigen conceptos mientras la factura está ABIERTA.",
    "receta_detalle": "Una línea ya entregada no se puede modificar. Recetar no descuenta inventario; entregar sí.",
    "personal": "Para registrar un médico, agregue primero personal con puesto MEDICO y después su cédula en Médicos.",
}

# Fragments below are trusted constants, not SQL supplied by an operator.
OPTION_LABELS = {
    "departamentos": ("codigo", "nombre"), "especialidades": ("nombre",),
    "personal": ("numero_empleado", "nombre", "apellido_paterno", "puesto"),
    "medicos": ("cedula_profesional",), "pacientes": ("expediente_clinico", "nombre", "apellido_paterno"),
    "aseguradoras": ("nombre",), "polizas": ("numero_poliza", "paciente_id"),
    "habitaciones": ("codigo", "edificio"), "camillas": ("codigo", "estado_operativo"),
    "citas": ("paciente_id", "medico_id", "inicio", "estado"),
    "consultas": ("paciente_id", "medico_id", "fecha", "motivo"),
    "diagnosticos": ("codigo", "descripcion"), "hospitalizaciones": ("paciente_id", "fecha_ingreso", "fecha_alta"),
    "medicamentos": ("codigo", "principio_activo", "concentracion"), "proveedores": ("nombre",),
    "lotes_medicamento": ("medicamento_id", "numero_lote", "fecha_caducidad"),
    "recetas": ("consulta_id", "fecha_prescripcion"), "procedimientos": ("codigo", "nombre"),
    "ordenes_procedimiento": ("consulta_id", "procedimiento_id", "estado"),
    "facturas": ("folio", "paciente_id", "estado"), "roles": ("nombre",),
    "usuarios": ("nombre_usuario",),
}

# Consultas fijas para que las relaciones se elijan por nombres y contexto.
# El servicio solo agrega filtros sobre columnas verificadas del alias «t».
REFERENCE_QUERIES = {
    "citas": ("cita_id", """SELECT t.cita_id AS value,
        CONCAT_WS(' | ',CONCAT('Cita ',t.cita_id),CONCAT_WS(' ',p.nombre,p.apellido_paterno,p.apellido_materno),
        CONCAT('Médico: ',CONCAT_WS(' ',pe.nombre,pe.apellido_paterno)),CAST(t.inicio AS CHAR),t.estado) AS label
        FROM citas t JOIN pacientes p ON p.paciente_id=t.paciente_id JOIN personal pe ON pe.personal_id=t.medico_id"""),
    "consultas": ("consulta_id", """SELECT t.consulta_id AS value,
        CONCAT_WS(' | ',CONCAT('Consulta ',t.consulta_id),CONCAT_WS(' ',p.nombre,p.apellido_paterno,p.apellido_materno),
        CONCAT('Médico: ',CONCAT_WS(' ',pe.nombre,pe.apellido_paterno)),CAST(t.fecha AS CHAR),t.tipo) AS label
        FROM consultas t JOIN pacientes p ON p.paciente_id=t.paciente_id JOIN personal pe ON pe.personal_id=t.medico_id"""),
    "recetas": ("receta_id", """SELECT t.receta_id AS value,
        CONCAT_WS(' | ',CONCAT('Receta ',t.receta_id),CONCAT_WS(' ',p.nombre,p.apellido_paterno,p.apellido_materno),
        CONCAT('Médico: ',CONCAT_WS(' ',pe.nombre,pe.apellido_paterno)),CAST(t.fecha_prescripcion AS CHAR)) AS label
        FROM recetas t JOIN consultas c ON c.consulta_id=t.consulta_id JOIN pacientes p ON p.paciente_id=c.paciente_id
        JOIN personal pe ON pe.personal_id=c.medico_id"""),
    "hospitalizaciones": ("hospitalizacion_id", """SELECT t.hospitalizacion_id AS value,
        CONCAT_WS(' | ',CONCAT('Estancia ',t.hospitalizacion_id),CONCAT_WS(' ',p.nombre,p.apellido_paterno,p.apellido_materno),
        CAST(t.fecha_ingreso AS CHAR),IF(t.fecha_alta IS NULL,'ABIERTA','CERRADA')) AS label
        FROM hospitalizaciones t JOIN pacientes p ON p.paciente_id=t.paciente_id"""),
    "lotes_medicamento": ("lote_id", """SELECT t.lote_id AS value,
        CONCAT_WS(' | ',t.numero_lote,m.principio_activo,m.concentracion,CONCAT('Caduca ',t.fecha_caducidad)) AS label
        FROM lotes_medicamento t JOIN medicamentos m ON m.medicamento_id=t.medicamento_id"""),
    "facturas": ("factura_id", """SELECT t.factura_id AS value,
        CONCAT_WS(' | ',t.folio,CONCAT_WS(' ',p.nombre,p.apellido_paterno,p.apellido_materno),t.estado) AS label
        FROM facturas t JOIN pacientes p ON p.paciente_id=t.paciente_id"""),
    "camillas": ("camilla_id", """SELECT t.camilla_id AS value,
        CONCAT_WS(' | ',t.codigo,CONCAT('Habitación ',h.codigo),h.edificio,t.estado_operativo) AS label
        FROM camillas t JOIN habitaciones h ON h.habitacion_id=t.habitacion_id"""),
}

REPORTS = {
    "expedientes": ("Consultas y nombres de pacientes", "Expediente, paciente, médico, fecha y motivo.", "SELECT * FROM v_expediente_consultas ORDER BY fecha DESC, consulta_id DESC"),
    "medicos": ("Médicos y especialidades", "Une las cédulas, nombres y especialidades del equipo.", "SELECT m.medico_id,m.cedula_profesional,p.nombre,p.apellido_paterno,p.apellido_materno,GROUP_CONCAT(e.nombre ORDER BY e.nombre SEPARATOR ', ') AS especialidades FROM medicos m JOIN personal p ON p.personal_id=m.medico_id LEFT JOIN medico_especialidad me ON me.medico_id=m.medico_id LEFT JOIN especialidades e ON e.especialidad_id=me.especialidad_id GROUP BY m.medico_id,m.cedula_profesional,p.nombre,p.apellido_paterno,p.apellido_materno ORDER BY m.medico_id"),
    "recetas": ("Recetas con nombres y medicamentos", "Cada renglón es un medicamento de una receta.", "SELECT r.receta_id,c.paciente_id,CONCAT_WS(' ',p.nombre,p.apellido_paterno) AS paciente,c.medico_id,CONCAT_WS(' ',pe.nombre,pe.apellido_paterno) AS medico,r.fecha_prescripcion,rd.renglon,m.principio_activo,m.concentracion,rd.dosis,rd.frecuencia,rd.duracion_dias,rd.via_administracion,rd.cantidad_prescrita,r.observaciones FROM recetas r JOIN consultas c ON c.consulta_id=r.consulta_id JOIN pacientes p ON p.paciente_id=c.paciente_id JOIN personal pe ON pe.personal_id=c.medico_id JOIN receta_detalle rd ON rd.receta_id=r.receta_id JOIN medicamentos m ON m.medicamento_id=rd.medicamento_id ORDER BY r.receta_id,rd.renglon"),
    "camillas": ("Disponibilidad de camillas", "Disponible, ocupada o en mantenimiento.", "SELECT * FROM v_camillas_estado ORDER BY camilla_id"),
    "stock": ("Existencias de medicamentos", "Stock total y vigente calculado desde movimientos.", "SELECT * FROM v_stock_medicamentos ORDER BY medicamento_id"),
    "lotes": ("Existencias por lote", "Cantidad y fecha de caducidad de cada lote.", "SELECT * FROM v_stock_lotes ORDER BY lote_id"),
    "pendientes": ("Medicamentos pendientes de entregar", "Cantidades prescritas, entregadas y pendientes.", "SELECT * FROM v_recetas_pendientes ORDER BY receta_id,renglon"),
    "saldos": ("Facturas y saldos", "Total, pagos registrados y saldo pendiente.", "SELECT * FROM v_facturas_saldo ORDER BY factura_id"),
}

def field(name, label, kind="text", required=True, reference=None, options=None):
    result = {"name": name, "label": label, "type": kind, "required": required,
              "data_type": kind, "nullable": not required, "default": None}
    if reference:
        result["reference"] = {"table": reference[0], "column": reference[1]}
    if options:
        result["options"] = list(options)
        result["enum_values"] = list(options)
    return result

WORKFLOWS = {
    "agendar_cita": {"label": "Agendar cita", "description": "Comprueba que el paciente y el médico estén activos y no tengan otra cita en ese intervalo.", "procedure": "sp_agendar_cita", "out": True, "fields": [field("paciente_id","Paciente","int",reference=("pacientes","paciente_id")),field("medico_id","Médico","int",reference=("medicos","medico_id")),field("inicio","Inicio","datetime"),field("fin","Fin","datetime"),field("motivo","Motivo")]},
    "confirmar_cita": {"label": "Confirmar cita", "description": "Pasa una cita PROGRAMADA a CONFIRMADA.", "fields": [field("cita_id","Cita","int",reference=("citas","cita_id"))]},
    "cancelar_cita": {"label": "Cancelar cita", "description": "Cancela una cita pendiente y conserva su registro.", "fields": [field("cita_id","Cita","int",reference=("citas","cita_id"))]},
    "asignar_camilla": {"label": "Asignar o trasladar camilla", "description": "Asigna una camilla operativa y libre; cierra la asignación anterior si es un traslado.", "procedure": "sp_asignar_camilla", "out": True, "fields": [field("hospitalizacion_id","Hospitalización abierta","int",reference=("hospitalizaciones","hospitalizacion_id")),field("camilla_id","Camilla","int",reference=("camillas","camilla_id")),field("inicio","Inicio de asignación","datetime")]},
    "alta_hospitalaria": {"label": "Dar alta hospitalaria", "description": "Cierra la estancia y libera la camilla. La fecha debe ser posterior a sus notas y asignaciones.", "procedure": "sp_alta_hospitalaria", "out": False, "fields": [field("hospitalizacion_id","Hospitalización abierta","int",reference=("hospitalizaciones","hospitalizacion_id")),field("fecha","Fecha de alta","datetime"),field("resumen","Resumen de alta")]},
    "registrar_movimiento": {"label": "Registrar entrada o ajuste de inventario", "description": "ENTRADA: cantidad positiva. AJUSTE: positiva o negativa. SALIDA manual: negativa. Para una receta use Entregar medicamento.", "procedure": "sp_registrar_movimiento", "out": True, "fields": [field("lote_id","Lote","int",reference=("lotes_medicamento","lote_id")),field("personal_id","Empleado de farmacia","int",reference=("personal","personal_id")),field("fecha","Fecha","datetime"),field("tipo","Tipo","enum",options=("ENTRADA","AJUSTE","SALIDA")),field("cantidad","Cantidad con signo","int"),field("motivo","Motivo")]},
    "dispensar": {"label": "Entregar medicamento de receta", "description": "Una receta y renglón, un lote compatible y una cantidad. Descuenta existencias automáticamente.", "procedure": "sp_dispensar", "out": True, "fields": [field("receta_id","Receta","int",reference=("recetas","receta_id")),field("renglon","Renglón de la receta","int"),field("lote_id","Lote del mismo medicamento","int",reference=("lotes_medicamento","lote_id")),field("cantidad","Cantidad a entregar","int"),field("personal_id","Empleado de farmacia","int",reference=("personal","personal_id")),field("fecha","Fecha de entrega","datetime")]},
    "emitir_factura": {"label": "Emitir factura", "description": "Requiere una factura ABIERTA con al menos un concepto. Después los conceptos quedan cerrados.", "fields": [field("factura_id","Factura abierta","int",reference=("facturas","factura_id"))]},
    "anular_factura": {"label": "Anular factura sin pagos", "description": "Conserva la factura como ANULADA. No se pueden anular facturas con pagos.", "fields": [field("factura_id","Factura sin pagos","int",reference=("facturas","factura_id"))]},
    "registrar_pago": {"label": "Registrar pago de factura", "description": "Requiere una factura EMITIDA. Puede abonar parcialmente sin superar el saldo.", "procedure": "sp_registrar_pago", "out": True, "fields": [field("factura_id","Factura emitida","int",reference=("facturas","factura_id")),field("fecha","Fecha del pago","datetime"),field("monto","Monto","decimal"),field("metodo","Método","enum",options=("EFECTIVO","TARJETA","TRANSFERENCIA","ASEGURADORA")),field("referencia","Referencia (opcional)",required=False)]},
}
