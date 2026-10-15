"""Servicio MySQL de la interfaz: parámetros, catálogo cerrado y reglas de negocio.

La contraseña solo vive en Settings durante la sesión. Las rutinas del proyecto
administran sus propias transacciones; las demás escrituras usan una transacción
por acción. No se ofrecen consultas libres ni eliminación de registros.
"""
from __future__ import annotations

import json
import re
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import date, datetime, time, timedelta
from decimal import Decimal, InvalidOperation
from pathlib import Path

from .catalog import (ACCESS_READONLY, CREATE_READONLY, HISTORY_READONLY, LABELS,
                      NOTES, OPTION_LABELS, REPORTS, ROUTINE_ONLY, TABLE_GROUPS,
                      TABLES, UPDATE_READONLY, WORKFLOWS)

try:
    import pymysql
except ImportError:
    pymysql = None

PROJECT = Path(__file__).resolve().parent.parent
IDENTIFIER = re.compile(r"^[A-Za-z][A-Za-z0-9_]{0,63}$")
SYSTEM_DATABASES = {"mysql", "sys", "information_schema", "performance_schema"}
BACKUP_FORMAT = "hospital-universitario-json-v1"


class ServiceError(Exception):
    """Mensaje apto para mostrar, sin SQL ni credenciales de conexión."""


@dataclass(frozen=True)
class Settings:
    host: str = "127.0.0.1"
    port: int = 3306
    user: str = "root"
    password: str = field(default="", repr=False)
    database: str = "hospital_universitario"

    def __post_init__(self):
        if not isinstance(self.host, str) or not self.host.strip():
            raise ServiceError("Escriba el servidor de MySQL; normalmente es 127.0.0.1.")
        if not isinstance(self.user, str) or not self.user.strip():
            raise ServiceError("Escriba el usuario de MySQL.")
        try:
            value = int(self.port)
        except (TypeError, ValueError):
            raise ServiceError("El puerto debe ser un número entre 1 y 65535.") from None
        if not 1 <= value <= 65535:
            raise ServiceError("El puerto debe estar entre 1 y 65535.")
        object.__setattr__(self, "port", value)
        validate_database_name(self.database)


def validate_database_name(name):
    if not isinstance(name, str) or not IDENTIFIER.fullmatch(name) or name.lower() in SYSTEM_DATABASES:
        raise ServiceError("El nombre de la base debe empezar con una letra y contener solo letras sin acentos, números o guion bajo (máximo 64). No use un nombre de sistema.")
    return name


def quote(name):
    if not isinstance(name, str) or not IDENTIFIER.fullmatch(name):
        raise ServiceError("Nombre de tabla o campo no permitido.")
    return "`" + name + "`"


def split_sql_script(source):
    """Lee nuestros instaladores con DELIMITER sin activar multi-statements.

    Respeta comillas, identificadores, comentarios y cuerpos de triggers. No se
    usa con texto del operador, únicamente con los archivos SQL del proyecto.
    """
    delimiter, buffer, i, state, line_start = ";", [], 0, None, True
    while i < len(source):
        if state is None and line_start:
            end = source.find("\n", i)
            end = len(source) if end < 0 else end
            match = re.fullmatch(r"\s*DELIMITER\s+(\S+)\s*", source[i:end], re.I)
            if match:
                if "".join(buffer).strip():
                    raise ServiceError("El archivo de instalación tiene un DELIMITER fuera de lugar.")
                delimiter = match.group(1)
                i = end + 1
                line_start = True
                continue
        char = source[i]
        if state == "line":
            if char == "\n":
                state = None
                buffer.append("\n")
                line_start = True
            i += 1
            continue
        if state == "block":
            if source.startswith("*/", i):
                state = None
                buffer.append(" ")
                i += 2
            else:
                line_start = char == "\n"
                i += 1
            continue
        if state in ("'", '"', "`"):
            buffer.append(char)
            if char == "\\" and i + 1 < len(source):
                buffer.append(source[i + 1])
                i += 2
                continue
            if char == state:
                if i + 1 < len(source) and source[i + 1] == state:
                    buffer.append(source[i + 1])
                    i += 2
                    continue
                state = None
            line_start = char == "\n"
            i += 1
            continue
        if source.startswith("--", i) and (i + 2 == len(source) or source[i + 2].isspace()):
            state = "line"
            i += 2
            continue
        if char == "#":
            state = "line"
            i += 1
            continue
        if source.startswith("/*", i):
            state = "block"
            i += 2
            continue
        if source.startswith(delimiter, i):
            statement = "".join(buffer).strip()
            if statement:
                yield statement
            buffer = []
            i += len(delimiter)
            line_start = False
            continue
        if char in ("'", '"', "`"):
            state = char
        buffer.append(char)
        line_start = char == "\n"
        i += 1
    if state in ("'", '"', "`", "block"):
        raise ServiceError("El archivo de instalación contiene texto incompleto.")
    remaining = "".join(buffer).strip()
    if remaining:
        yield remaining


def display_value(value):
    if value is None:
        return ""
    if isinstance(value, datetime):
        return value.isoformat(sep=" ", timespec="seconds")
    if isinstance(value, (date, time)):
        return value.isoformat()
    return str(value)


class HospitalService:
    def __init__(self, settings: Settings):
        self.settings = settings
        self._metadata = {}

    def _friendly_error(self, exc):
        if isinstance(exc, ServiceError):
            return exc
        code = exc.args[0] if exc.args and isinstance(exc.args[0], int) else None
        if code in (1044, 1045, 1698):
            return ServiceError("MySQL rechazó el acceso. Revise usuario, contraseña y permisos de esa cuenta.")
        if code in (2002, 2003, 2005, 2006, 2013):
            return ServiceError("No se pudo mantener la conexión con MySQL. Revise que el servidor esté encendido, la dirección y el puerto.")
        if code == 1049:
            return ServiceError("La base indicada todavía no existe. Puede crear la demostración o escribir el nombre de una base instalada.")
        if code == 1062:
            return ServiceError("Ya existe un registro con esa clave o dato único. Cambie el dato duplicado; no vuelva a insertar la misma fila.")
        if code in (1451, 1452):
            return ServiceError("El registro relacionado no existe o está en uso. Elija una opción de los desplegables y compruebe que corresponde al mismo paciente o medicamento.")
        if code == 1644:
            message = str(exc.args[1]) if len(exc.args) > 1 else "La regla del hospital rechazó esta operación."
            return ServiceError(message)
        if code in (3819, 4025):
            return ServiceError("Los valores no cumplen una regla de la tabla. Revise cantidades positivas, fechas, intervalos y descuentos.")
        if code in (1054, 1146, 1305):
            return ServiceError("La base no tiene la estructura completa de este proyecto. Seleccione la base correcta o cree una demostración con otro nombre.")
        if code in (1048, 1364, 1265, 1292, 1406, 1264):
            return ServiceError("Revise los campos obligatorios, su longitud y el formato de números o fechas.")
        if code in (1205, 1213):
            return ServiceError("Otra operación está usando estos registros. Espere un momento y vuelva a intentarlo.")
        return ServiceError("MySQL no pudo completar la operación" + (f" (código {code})." if code else ".") + " Revise la conexión y los datos indicados.")

    @contextmanager
    def _connection(self, database=True, transaction=False):
        if pymysql is None:
            raise ServiceError("Falta PyMySQL. Ejecute instalar_app.bat o instale las dependencias de requirements.txt.")
        conn = None
        try:
            kwargs = dict(host=self.settings.host, port=self.settings.port, user=self.settings.user,
                          password=self.settings.password, charset="utf8mb4", autocommit=True,
                          connect_timeout=8, read_timeout=60, write_timeout=60,
                          cursorclass=pymysql.cursors.DictCursor)
            if database:
                kwargs["database"] = self.settings.database
            conn = pymysql.connect(**kwargs)
            if transaction:
                conn.begin()
            yield conn
            if transaction:
                conn.commit()
        except Exception as exc:
            if conn is not None and transaction:
                conn.rollback()
            if isinstance(exc, (OSError, ValueError, TypeError)) and not (pymysql and isinstance(exc, pymysql.MySQLError)):
                if isinstance(exc, ServiceError):
                    raise
            raise self._friendly_error(exc) from None
        finally:
            if conn is not None:
                conn.close()

    def test_connection(self):
        with self._connection(database=False) as conn, conn.cursor() as cur:
            cur.execute("SELECT VERSION() AS version")
            result = cur.fetchone()
            cur.execute("SELECT COUNT(*) AS n FROM information_schema.SCHEMATA WHERE SCHEMA_NAME=%s", (self.settings.database,))
            result["database_exists"] = bool(cur.fetchone()["n"])
            cur.execute("SELECT TABLE_NAME AS name FROM information_schema.TABLES WHERE TABLE_SCHEMA=%s AND TABLE_TYPE='BASE TABLE'", (self.settings.database,))
            present = {r["name"] for r in cur.fetchall()}
            result["table_count"] = len(present)
            result["compatible"] = set(TABLES).issubset(present)
            result["missing_tables"] = sorted(set(TABLES) - present)
            return result

    connect = test_connection

    def validate_schema(self):
        result = self.test_connection()
        if not result["database_exists"]:
            raise ServiceError("Esta base todavía no existe. Cree la demostración o revise su nombre.")
        if not result["compatible"]:
            raise ServiceError("La base no contiene las 36 tablas del hospital. No se modificó. Cree una demostración con otro nombre.")
        return result

    def tables(self):
        return [{"name": table, "label": LABELS.get(table, table.replace("_", " ").capitalize()),
                 "module": module, "can_create": table not in ROUTINE_ONLY | ACCESS_READONLY,
                 "can_update": table not in ROUTINE_ONLY | ACCESS_READONLY | HISTORY_READONLY,
                 "note": NOTES.get(table, "Puede agregar y modificar registros. Los identificadores y campos calculados no se editan.")}
                for module, names in TABLE_GROUPS.items() for table in names]

    def _table(self, table):
        if table not in TABLES:
            raise ServiceError("Seleccione una tabla del catálogo del hospital.")
        return quote(table)

    def columns(self, table):
        self._table(table)
        if table not in self._metadata:
            with self._connection() as conn, conn.cursor() as cur:
                cur.execute("SELECT COLUMN_NAME AS name, DATA_TYPE AS data_type, COLUMN_TYPE AS column_type, IS_NULLABLE AS is_nullable, COLUMN_DEFAULT AS default_value, COLUMN_KEY AS column_key, EXTRA AS extra, CHARACTER_MAXIMUM_LENGTH AS max_length, GENERATION_EXPRESSION AS generation_expression FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=%s AND TABLE_NAME=%s ORDER BY ORDINAL_POSITION", (self.settings.database, table))
                rows = cur.fetchall()
                if not rows:
                    raise ServiceError("No se encontró la tabla en esta base. Revise que sea la base del hospital.")
                cur.execute("SELECT CONSTRAINT_NAME AS constraint_name, COLUMN_NAME AS col, REFERENCED_TABLE_NAME AS ref_table, REFERENCED_COLUMN_NAME AS ref_col FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=%s AND TABLE_NAME=%s AND REFERENCED_TABLE_NAME IS NOT NULL ORDER BY ORDINAL_POSITION", (self.settings.database, table))
                candidates = list(cur.fetchall())
                # Prefer a direct FK over one component of a composite FK. For
                # example consultas.paciente_id should offer pacientes, not a
                # repeated list of patient IDs extracted from appointments.
                sizes = {r["constraint_name"]: sum(c["constraint_name"] == r["constraint_name"] for c in candidates) for r in candidates}
                refs = {r["col"]: {"table": r["ref_table"], "column": r["ref_col"]} for r in sorted(candidates, key=lambda r: sizes[r["constraint_name"]], reverse=True)}
            metadata = []
            for r in rows:
                quote(r["name"])
                generated = bool(r["generation_expression"])  # DEFAULT_GENERATED is not a generated column.
                auto = "auto_increment" in r["extra"].lower()
                primary = r["column_key"] == "PRI"
                enum = re.findall(r"'((?:[^'\\]|\\.|'')*)'", r["column_type"]) if r["data_type"] == "enum" else []
                c = {"name": r["name"], "label": r["name"].replace("_", " ").capitalize(),
                     "data_type": r["data_type"], "column_type": r["column_type"],
                     "nullable": r["is_nullable"] == "YES", "default": r["default_value"],
                     "primary": primary, "generated": generated, "auto_increment": auto,
                     "max_length": r["max_length"], "enum_values": enum,
                     "reference": refs.get(r["name"]),
                     "editable_create": table not in ROUTINE_ONLY | ACCESS_READONLY and not generated and not auto and r["name"] not in CREATE_READONLY.get(table, set()),
                     "editable_update": table not in ROUTINE_ONLY | ACCESS_READONLY | HISTORY_READONLY and not generated and not primary and r["name"] not in UPDATE_READONLY.get(table, set())}
                if r["name"] == "password_hash":
                    c["editable_create"] = c["editable_update"] = False
                    c["sensitive"] = True
                metadata.append(c)
            self._metadata[table] = metadata
        return [dict(c) for c in self._metadata[table]]

    def counts(self):
        with self._connection() as conn, conn.cursor() as cur:
            result = {}
            for table in TABLES:
                cur.execute("SELECT COUNT(*) AS n FROM " + self._table(table))
                result[table] = cur.fetchone()["n"]
            return result

    @staticmethod
    def _page(limit, offset=0):
        try:
            limit, offset = int(limit), int(offset)
        except (TypeError, ValueError):
            raise ServiceError("La paginación debe usar números enteros.") from None
        if not 1 <= limit <= 1000 or offset < 0:
            raise ServiceError("Cada página permite de 1 a 1000 filas y un desplazamiento positivo.")
        return limit, offset

    def browse(self, table, search="", limit=200, offset=0):
        identifier = self._table(table)
        metadata = self.columns(table)
        limit, offset = self._page(limit, offset)
        visible = [c["name"] for c in metadata]
        terms, params = [], []
        if search:
            if len(str(search)) > 200:
                raise ServiceError("Use una búsqueda de hasta 200 caracteres.")
            # LOCATE treats % and _ as literal search text.
            terms = ["LOCATE(%s,CAST(" + quote(c["name"]) + " AS CHAR))>0" for c in metadata if not c.get("sensitive")]
            params = [str(search)] * len(terms)
        where = " WHERE (" + " OR ".join(terms) + ")" if terms else ""
        order = [quote(c["name"]) for c in metadata if c["primary"]]
        selected = ["'[OCULTO]' AS " + quote(c["name"]) if c.get("sensitive") else quote(c["name"]) for c in metadata]
        with self._connection() as conn, conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) AS n FROM " + identifier + where, params)
            total = cur.fetchone()["n"]
            cur.execute("SELECT " + ",".join(selected) + " FROM " + identifier + where + (" ORDER BY " + ",".join(order) if order else "") + " LIMIT %s OFFSET %s", params + [limit, offset])
            return {"columns": visible, "rows": list(cur.fetchall()), "total": total, "limit": limit, "offset": offset}

    def reference_options(self, table, column, search="", limit=500, filters=None):
        self._table(table)
        metadata = self.columns(table)
        cols = {c["name"] for c in metadata}
        if column not in cols:
            raise ServiceError("El campo relacionado no pertenece al catálogo.")
        limit, _ = self._page(limit)
        if table == "medicos" and column == "medico_id" and not filters:
            return self._doctor_options(search, limit)
        labels = OPTION_LABELS.get(table, tuple(c["name"] for c in metadata if c["name"] != column and c["data_type"] in ("varchar", "date", "datetime"))[:3])
        labels = tuple(c for c in labels if c in cols)
        where, params = [], []
        for name, value in (filters or {}).items():
            if name not in cols:
                raise ServiceError("Filtro relacionado no permitido.")
            where.append(quote(name) + (" IS NULL" if value is None else "=%s"))
            if value is not None:
                params.append(value)
        if search:
            if len(str(search)) > 200:
                raise ServiceError("La búsqueda es demasiado larga.")
            where.append("(" + " OR ".join("LOCATE(%s,CAST(" + quote(c) + " AS CHAR))>0" for c in (column,) + labels) + ")")
            params.extend([str(search)] * (len(labels) + 1))
        select = ",".join(quote(c) for c in dict.fromkeys((column,) + labels))
        with self._connection() as conn, conn.cursor() as cur:
            cur.execute("SELECT " + select + " FROM " + quote(table) + (" WHERE " + " AND ".join(where) if where else "") + " ORDER BY " + quote(column) + " LIMIT %s", params + [limit])
            rows = cur.fetchall()
        return [(r[column], " | ".join([str(r[column])] + [display_value(r[c]) for c in labels])) for r in rows]

    def _doctor_options(self, search="", limit=500, active_only=False):
        if len(str(search)) > 200:
            raise ServiceError("La búsqueda es demasiado larga.")
        clauses, params = [], []
        if active_only:
            clauses.append("p.activo=1")
        if search:
            clauses.append("LOCATE(%s,CONCAT_WS(' ',m.medico_id,m.cedula_profesional,p.nombre,p.apellido_paterno,p.apellido_materno))>0")
            params.append(str(search))
        with self._connection() as conn, conn.cursor() as cur:
            cur.execute("SELECT m.medico_id,m.cedula_profesional,p.nombre,p.apellido_paterno,p.apellido_materno FROM medicos m JOIN personal p ON p.personal_id=m.medico_id" + (" WHERE " + " AND ".join(clauses) if clauses else "") + " ORDER BY m.medico_id LIMIT %s", params + [limit])
            return [(r["medico_id"], " | ".join([str(r["medico_id"]), " ".join(str(r[n]) for n in ("nombre", "apellido_paterno", "apellido_materno") if r[n]), r["cedula_profesional"]])) for r in cur.fetchall()]

    def fk_options(self, table, column, search="", limit=500):
        fields = {c["name"]: c for c in self.columns(table)}
        if column not in fields or not fields[column]["reference"]:
            raise ServiceError("Este campo no es una relación de la tabla.")
        ref = fields[column]["reference"]
        filters = None
        if table == "medicos" and column == "medico_id":
            filters = {"puesto": "MEDICO", "activo": 1}
        elif table == "notas_enfermeria" and column == "personal_id":
            filters = {"puesto": "ENFERMERIA", "activo": 1}
        return self.reference_options(ref["table"], ref["column"], search, limit, filters)

    @staticmethod
    def _coerce(value, column):
        name, kind = column["name"], column["data_type"]
        if value is None or (isinstance(value, str) and not value.strip()):
            if column.get("nullable"):
                return None
            raise ServiceError("Complete el campo " + column.get("label", name) + ".")
        text = str(value).strip()
        try:
            if kind in ("tinyint", "smallint", "mediumint", "int", "bigint", "integer"):
                if not re.fullmatch(r"[+-]?\d+", text):
                    raise ValueError()
                result = int(text)
                if "unsigned" in column.get("column_type", "") and result < 0:
                    raise ValueError()
                return result
            if kind in ("decimal", "numeric", "float", "double"):
                result = Decimal(text)
                if not result.is_finite():
                    raise ValueError()
                return result
            if kind == "date":
                return date.fromisoformat(text)
            if kind in ("datetime", "timestamp"):
                result = datetime.fromisoformat(text)
                if result.tzinfo:
                    raise ValueError()
                return result
            if kind == "time":
                return time.fromisoformat(text)
            if kind == "enum" and text not in column.get("enum_values", []):
                raise ValueError()
            if column.get("max_length") and len(text) > column["max_length"]:
                raise ServiceError(f"{column.get('label', name)} permite hasta {column['max_length']} caracteres.")
            return text
        except (ValueError, TypeError, InvalidOperation):
            raise ServiceError("Formato inválido en " + column.get("label", name) + ". Fechas: AAAA-MM-DD. Fecha y hora: AAAA-MM-DD HH:MM. Decimales: use punto.") from None

    def _values(self, table, values, mode):
        if not isinstance(values, dict):
            raise ServiceError("Los valores deben corresponder al formulario.")
        columns = {c["name"]: c for c in self.columns(table)}
        clean = {}
        for name, value in values.items():
            if name not in columns or not columns[name]["editable_" + mode]:
                raise ServiceError("El campo no se puede editar desde este formulario: " + str(name))
            c = columns[name]
            if mode == "create" and isinstance(value, str) and not value.strip() and c["default"] is not None:
                continue
            clean[name] = self._coerce(value, c)
        if mode == "create":
            for c in columns.values():
                if c["editable_create"] and not c["nullable"] and c["default"] is None and c["name"] not in clean:
                    raise ServiceError("Complete el campo " + c["label"] + ".")
        if not clean:
            raise ServiceError("Complete al menos un campo editable.")
        return clean

    def _keys(self, table, keys):
        columns = [c for c in self.columns(table) if c["primary"]]
        if not isinstance(keys, dict) or set(keys) != {c["name"] for c in columns}:
            raise ServiceError("Seleccione exactamente un registro con su identificador completo.")
        return {c["name"]: self._coerce(keys[c["name"]], c) for c in columns}

    def create(self, table, values):
        self._table(table)
        if table in ROUTINE_ONLY | ACCESS_READONLY:
            raise ServiceError(NOTES[table])
        clean = self._values(table, values, "create")
        with self._connection(transaction=True) as conn, conn.cursor() as cur:
            self._validate_create(cur, table, clean)
            names = list(clean)
            cur.execute("INSERT INTO " + quote(table) + " (" + ",".join(map(quote, names)) + ") VALUES (" + ",".join(["%s"] * len(names)) + ")", [clean[n] for n in names])
            result = {"lastrowid": cur.lastrowid, "affected": cur.rowcount}
            if table == "consultas" and clean.get("cita_id"):
                cur.execute("UPDATE citas SET estado='ATENDIDA' WHERE cita_id=%s", (clean["cita_id"],))
            return result

    def _validate_create(self, cur, table, values):
        if table == "consultas" and values.get("cita_id"):
            cur.execute("SELECT * FROM citas WHERE cita_id=%s FOR UPDATE", (values["cita_id"],))
            row = cur.fetchone()
            if not row or row["estado"] not in ("PROGRAMADA", "CONFIRMADA") or row["paciente_id"] != values["paciente_id"] or row["medico_id"] != values["medico_id"]:
                raise ServiceError("Seleccione una cita pendiente del mismo paciente y médico.")
            if values.get("fecha", datetime.now()) < row["inicio"]:
                raise ServiceError("La consulta no puede registrarse antes del inicio de su cita.")
        if table == "consultas" and values.get("tipo") == "PROGRAMADA" and not values.get("cita_id"):
            raise ServiceError("Una consulta PROGRAMADA requiere una cita del mismo paciente y médico.")
        if table == "hospitalizaciones":
            cur.execute("SELECT fecha,paciente_id FROM consultas WHERE consulta_id=%s FOR UPDATE", (values["consulta_ingreso_id"],))
            row = cur.fetchone()
            if not row or row["paciente_id"] != values["paciente_id"] or values["fecha_ingreso"] < row["fecha"]:
                raise ServiceError("El ingreso debe corresponder a una consulta del paciente y ser posterior a ella.")
        if table == "recetas":
            cur.execute("SELECT fecha FROM consultas WHERE consulta_id=%s FOR UPDATE", (values["consulta_id"],))
            row = cur.fetchone()
            if not row or values.get("fecha_prescripcion", datetime.now()) < row["fecha"]:
                raise ServiceError("La receta debe ser posterior a su consulta.")
        if table == "ordenes_procedimiento" and values.get("estado", "SOLICITADA") not in ("SOLICITADA", "PROGRAMADA"):
            raise ServiceError("Cree la orden SOLICITADA o PROGRAMADA. Un resultado la marcará REALIZADA.")
        if table == "factura_detalle":
            self._lock_open_invoice(cur, values["factura_id"])

    def _lock_open_invoice(self, cur, factura):
        cur.execute("SELECT estado FROM facturas WHERE factura_id=%s FOR UPDATE", (factura,))
        row = cur.fetchone()
        if not row or row["estado"] != "ABIERTA":
            raise ServiceError("Solo se pueden modificar conceptos de una factura ABIERTA.")

    def update(self, table, keys, values):
        self._table(table)
        if table in ROUTINE_ONLY | ACCESS_READONLY | HISTORY_READONLY:
            raise ServiceError(NOTES.get(table, "Este historial es de solo lectura."))
        clean, identity = self._values(table, values, "update"), self._keys(table, keys)
        where = " AND ".join(quote(k) + "=%s" for k in identity)
        with self._connection(transaction=True) as conn, conn.cursor() as cur:
            if table == "factura_detalle":
                self._lock_open_invoice(cur, identity["factura_id"])
            if table == "facturas":
                self._lock_open_invoice(cur, identity["factura_id"])
            if table == "receta_detalle":
                cur.execute("SELECT receta_id FROM recetas WHERE receta_id=%s FOR UPDATE", (identity["receta_id"],))
                cur.execute("SELECT COUNT(*) AS n FROM dispensacion_detalle WHERE receta_id=%s AND renglon=%s", (identity["receta_id"], identity["renglon"]))
                if cur.fetchone()["n"]:
                    raise ServiceError("No puede modificar una línea de receta ya entregada.")
            cur.execute("SELECT 1 AS found FROM " + quote(table) + " WHERE " + where + " FOR UPDATE", list(identity.values()))
            if not cur.fetchone():
                raise ServiceError("El registro seleccionado ya no existe. Actualice la lista.")
            cur.execute("UPDATE " + quote(table) + " SET " + ",".join(quote(k) + "=%s" for k in clean) + " WHERE " + where, list(clean.values()) + list(identity.values()))
            return {"affected": cur.rowcount}

    def list_reports(self):
        return [{"name": n, "label": v[0], "description": v[1]} for n, v in REPORTS.items()]

    def report(self, name, limit=500):
        if name not in REPORTS:
            raise ServiceError("Seleccione un reporte del catálogo.")
        limit, _ = self._page(limit)
        with self._connection() as conn, conn.cursor() as cur:
            cur.execute(REPORTS[name][2] + " LIMIT %s", (limit,))
            return {"columns": [c[0] for c in cur.description], "rows": list(cur.fetchall()), "limit": limit}

    run_report = report

    def workflows(self):
        return [{"name": n, "label": w["label"], "description": w["description"], "fields": [dict(f) for f in w["fields"]]} for n, w in WORKFLOWS.items()]

    def workflow_options(self, name, field_name, search="", limit=500):
        if name not in WORKFLOWS:
            raise ServiceError("Operación no permitida.")
        f = next((f for f in WORKFLOWS[name]["fields"] if f["name"] == field_name), None)
        if not f or "reference" not in f:
            raise ServiceError("Este campo no usa una relación.")
        filters = None
        if field_name == "medico_id":
            limit, _ = self._page(limit)
            return self._doctor_options(search, limit, active_only=True)
        if field_name == "personal_id":
            filters = {"activo": 1, "puesto": "FARMACIA"}
        elif name == "agendar_cita" and field_name == "paciente_id":
            filters = {"activo": 1}
        elif field_name == "hospitalizacion_id":
            filters = {"fecha_alta": None}
        elif field_name == "camilla_id":
            filters = {"estado_operativo": "OPERATIVA"}
        elif field_name == "factura_id" and name == "emitir_factura":
            filters = {"estado": "ABIERTA"}
        elif field_name == "factura_id" and name == "registrar_pago":
            filters = {"estado": "EMITIDA"}
        return self.reference_options(f["reference"]["table"], f["reference"]["column"], search, limit, filters)

    def run_workflow(self, name, values):
        if name not in WORKFLOWS or not isinstance(values, dict):
            raise ServiceError("Seleccione una operación del hospital.")
        w = WORKFLOWS[name]
        fields = {f["name"]: f for f in w["fields"]}
        if set(values) - set(fields):
            raise ServiceError("La operación contiene campos no permitidos.")
        clean = {n: self._coerce(values.get(n), f) for n, f in fields.items()}
        if "procedure" in w:
            params = list(clean.values())
            with self._connection() as conn, conn.cursor() as cur:
                placeholders = ["%s"] * len(params) + (["@hospital_resultado"] if w["out"] else [])
                if w["out"]:
                    cur.execute("SET @hospital_resultado=NULL")
                cur.execute("CALL " + quote(w["procedure"]) + "(" + ",".join(placeholders) + ")", params)
                while cur.nextset():
                    pass
                result = {"success": True, "message": "Operación registrada."}
                if w["out"]:
                    cur.execute("SELECT @hospital_resultado AS id")
                    result["id"] = cur.fetchone()["id"]
                return result
        with self._connection(transaction=True) as conn, conn.cursor() as cur:
            if name in ("emitir_factura", "anular_factura"):
                cur.execute("SELECT estado FROM facturas WHERE factura_id=%s FOR UPDATE", (clean["factura_id"],))
                row = cur.fetchone()
                if not row or row["estado"] == "ANULADA":
                    raise ServiceError("La factura no existe o ya está anulada.")
                if name == "emitir_factura" and row["estado"] != "ABIERTA":
                    raise ServiceError("Solo se puede emitir una factura ABIERTA.")
                state = "EMITIDA" if name == "emitir_factura" else "ANULADA"
                cur.execute("UPDATE facturas SET estado=%s WHERE factura_id=%s", (state, clean["factura_id"]))
            elif name in ("confirmar_cita", "cancelar_cita"):
                cur.execute("SELECT estado FROM citas WHERE cita_id=%s FOR UPDATE", (clean["cita_id"],))
                row = cur.fetchone()
                permitted = ("PROGRAMADA",) if name == "confirmar_cita" else ("PROGRAMADA", "CONFIRMADA")
                if not row or row["estado"] not in permitted:
                    raise ServiceError("Esta cita ya no está pendiente para esa operación.")
                cur.execute("SELECT COUNT(*) AS n FROM consultas WHERE cita_id=%s", (clean["cita_id"],))
                if cur.fetchone()["n"]:
                    raise ServiceError("La cita ya tiene una consulta registrada; conserve su historial.")
                cur.execute("UPDATE citas SET estado=%s WHERE cita_id=%s", ("CONFIRMADA" if name == "confirmar_cita" else "CANCELADA", clean["cita_id"]))
            return {"success": True, "message": "Operación registrada."}

    def _script(self, filename):
        source = (PROJECT / filename).read_text(encoding="utf-8-sig")
        schema = quote(self.settings.database)
        source = re.sub(r"(?m)^(CREATE DATABASE|USE) hospital_universitario(?=[ ;])", lambda m: m[1] + " " + schema, source)
        return list(split_sql_script(source))

    def install_demo(self):
        statements = self._script("hospital_demostracion.sql")
        created, step = False, 0
        try:
            with self._connection(database=False) as conn, conn.cursor() as cur:
                self._require_absent(cur)
                for step, statement in enumerate(statements, 1):
                    cur.execute(statement)
                    while cur.nextset():
                        pass
                    if statement.upper().startswith("CREATE DATABASE"):
                        created = True
            self._metadata.clear()
            counts = self.counts()
            return {"success": True, "database": self.settings.database, "counts": counts, "total_rows": sum(counts.values()), "table_count": len(counts)}
        except ServiceError as exc:
            if created:
                raise ServiceError(f"La instalación se interrumpió en el paso {step}. La base nueva puede haber quedado incompleta; no se borró nada. Use otro nombre para reintentar o pida al responsable revisar esa base. Detalle: {exc}") from None
            raise

    def _require_absent(self, cur):
        validate_database_name(self.settings.database)
        cur.execute("SELECT COUNT(*) AS n FROM information_schema.SCHEMATA WHERE SCHEMA_NAME=%s", (self.settings.database,))
        if cur.fetchone()["n"]:
            raise ServiceError("Esa base ya existe. No se sobrescribió. Use Abrir hospital para verla o elija otro nombre para una instalación nueva.")

    @staticmethod
    def _json_value(value):
        if isinstance(value, datetime):
            return value.isoformat(sep=" ", timespec="seconds")
        if isinstance(value, (date, time)):
            return value.isoformat()
        if isinstance(value, (Decimal, timedelta)):
            return str(value)
        return value

    def export_backup(self, path):
        """Respaldo completo local. Incluye hashes de usuarios, nunca settings."""
        metadata = {t: [c for c in self.columns(t) if not c["generated"]] for t in TABLES}
        payload = {"format": BACKUP_FORMAT, "created_at": datetime.now().isoformat(timespec="seconds"), "tables": {}}
        with self._connection() as conn, conn.cursor() as cur:
            cur.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ")
            cur.execute("START TRANSACTION WITH CONSISTENT SNAPSHOT, READ ONLY")
            try:
                for table in TABLES:
                    names = [c["name"] for c in metadata[table]]
                    cur.execute("SELECT " + ",".join(map(quote, names)) + " FROM " + quote(table))
                    payload["tables"][table] = {"columns": names, "rows": [[self._json_value(r[n]) for n in names] for r in cur.fetchall()]}
                conn.commit()
            except Exception:
                conn.rollback()
                raise
        destination = Path(path)
        try:
            # Exclusive creation avoids silently replacing an earlier backup.
            with destination.open("x", encoding="utf-8", newline="\n") as output:
                json.dump(payload, output, ensure_ascii=False, indent=2)
        except FileExistsError:
            raise ServiceError("Ya existe un archivo con ese nombre. Guarde el respaldo con un nombre nuevo.") from None
        except OSError:
            raise ServiceError("No se pudo escribir el respaldo en esa carpeta.") from None
        return {"path": str(destination.resolve()), "tables": len(TABLES), "rows": sum(len(v["rows"]) for v in payload["tables"].values())}

    def restore_backup(self, path):
        """Restaura solo JSON propio en una base inexistente; nunca ejecuta SQL del JSON."""
        try:
            source = Path(path)
            if source.stat().st_size > 50 * 1024 * 1024:
                raise ServiceError("El respaldo supera el límite académico de 50 MB.")
            payload = json.loads(source.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError):
            raise ServiceError("No se pudo leer el respaldo JSON del hospital.") from None
        if not isinstance(payload, dict) or payload.get("format") != BACKUP_FORMAT or not isinstance(payload.get("tables"), dict) or set(payload["tables"]) != set(TABLES):
            raise ServiceError("El archivo no es un respaldo completo compatible del hospital.")
        total = 0
        for table, section in payload["tables"].items():
            if not isinstance(section, dict) or set(section) != {"columns", "rows"} or not isinstance(section["columns"], list) or not isinstance(section["rows"], list):
                raise ServiceError("El respaldo contiene una tabla con formato inválido.")
            if not all(isinstance(n, str) and IDENTIFIER.fullmatch(n) for n in section["columns"]) or len(set(section["columns"])) != len(section["columns"]):
                raise ServiceError("El respaldo contiene nombres de campos inválidos.")
            for row in section["rows"]:
                if not isinstance(row, list) or len(row) != len(section["columns"]) or any(v is not None and not isinstance(v, (str, int, float, bool)) for v in row):
                    raise ServiceError("El respaldo contiene un registro inválido.")
            total += len(section["rows"])
        if total > 100000:
            raise ServiceError("El respaldo supera el límite académico de 100000 registros.")
        created = False
        try:
            with self._connection(database=False) as conn, conn.cursor() as cur:
                self._require_absent(cur)
                for statement in self._script("01_esquema.sql"):
                    cur.execute(statement)
                    if statement.upper().startswith("CREATE DATABASE"):
                        created = True
            self._metadata.clear()
            # Validate column sets before any INSERT; generated values are rebuilt.
            for table in TABLES:
                names = [c["name"] for c in self.columns(table) if not c["generated"]]
                if payload["tables"][table]["columns"] != names:
                    raise ServiceError("Los campos del respaldo no coinciden con la versión del proyecto.")
            with self._connection(transaction=True) as conn, conn.cursor() as cur:
                for table in TABLES:
                    section = payload["tables"][table]
                    if section["rows"]:
                        names = section["columns"]
                        statement = "INSERT INTO " + quote(table) + " (" + ",".join(map(quote, names)) + ") VALUES (" + ",".join(["%s"] * len(names)) + ")"
                        cur.executemany(statement, section["rows"])
            with self._connection() as conn, conn.cursor() as cur:
                for statement in self._script("02_reglas.sql"):
                    cur.execute(statement)
                    while cur.nextset():
                        pass
            return {"success": True, "database": self.settings.database, "tables": len(TABLES), "rows": total, "counts": self.counts()}
        except ServiceError as exc:
            if created:
                raise ServiceError("La restauración se interrumpió. La base nueva puede haber quedado incompleta; no se eliminó nada. Reintente con otro nombre y revise que el archivo sea un respaldo original. Detalle: " + str(exc)) from None
            raise
