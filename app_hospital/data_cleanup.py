"""Corrige únicamente valores iniciales reconocidos, conservando las reglas.

El plan del proyecto contiene claves primarias y SHA-256 de textos anteriores.
Una coincidencia parcial, una expresión regular o el nombre de una persona no
autorizan cambios. Los datos que el equipo ya personalizó se dejan intactos.

MySQL no permite suspender triggers dentro de una transacción. Esta operación
de mantenimiento conserva sus definiciones exactas antes de retirarlos, vuelve
a instalarlos en ``finally`` y deja un archivo local de recuperación. No cambia
el contrato de 02_reglas.sql ni añade excepciones permanentes a las reglas.
"""
from __future__ import annotations

import copy
import hashlib
import json
import os
import re
import uuid
from datetime import datetime
from pathlib import Path

from .catalog import TABLES
from .db import HospitalService, PROJECT, ServiceError, Settings, expected_structure, quote

PLAN_PATH = PROJECT / "datos" / "valores_completos.json"
TEXT_TYPES = frozenset(("char", "varchar", "tinytext", "text", "mediumtext", "longtext"))
PRIMARY_KEYS = {
    "departamentos": ("departamento_id",), "especialidades": ("especialidad_id",),
    "personal": ("personal_id",), "medicos": ("medico_id",),
    "medico_especialidad": ("medico_id", "especialidad_id"),
    "pacientes": ("paciente_id",), "contactos_emergencia": ("contacto_id",),
    "aseguradoras": ("aseguradora_id",), "polizas": ("poliza_id",),
    "habitaciones": ("habitacion_id",), "camillas": ("camilla_id",),
    "citas": ("cita_id",), "consultas": ("consulta_id",),
    "diagnosticos": ("diagnostico_id",),
    "consulta_diagnosticos": ("consulta_id", "diagnostico_id"),
    "alergias_paciente": ("alergia_id",), "hospitalizaciones": ("hospitalizacion_id",),
    "asignaciones_camilla": ("asignacion_id",), "notas_enfermeria": ("nota_id",),
    "medicamentos": ("medicamento_id",), "proveedores": ("proveedor_id",),
    "lotes_medicamento": ("lote_id",), "recetas": ("receta_id",),
    "receta_detalle": ("receta_id", "renglon"), "dispensaciones": ("dispensacion_id",),
    "dispensacion_detalle": ("dispensacion_detalle_id",),
    "movimientos_inventario": ("movimiento_id",),
    "procedimientos": ("procedimiento_id",), "ordenes_procedimiento": ("orden_id",),
    "resultados_procedimiento": ("resultado_id",), "facturas": ("factura_id",),
    "factura_detalle": ("factura_id", "renglon"), "pagos": ("pago_id",),
    "roles": ("rol_id",), "usuarios": ("usuario_id",),
    "usuario_roles": ("usuario_id", "rol_id"),
}
GUARD_TABLES = {
    "tr_receta_detalle_update": "receta_detalle",
    "tr_resultado_update": "resultados_procedimiento",
    "tr_mov_update": "movimientos_inventario",
    "tr_factura_detalle_update": "factura_detalle",
    "tr_factura_estado": "facturas",
    "tr_pago_update": "pagos",
}
HEX_DIGEST = re.compile(r"[a-f0-9]{64}\Z")


def _digest(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _load_plan():
    try:
        if PLAN_PATH.stat().st_size > 10 * 1024 * 1024:
            raise ServiceError("El archivo de actualización de datos supera el tamaño permitido.")
        plan = json.loads(PLAN_PATH.read_text(encoding="utf-8-sig"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        raise ServiceError("No se pudo leer datos/valores_completos.json. Extraiga la carpeta completa del proyecto.") from None
    if (not isinstance(plan, dict) or not isinstance(plan.get("version"), str)
            or not plan["version"] or len(plan["version"]) > 100
            or not isinstance(plan.get("changes"), list) or len(plan["changes"]) > 10000):
        raise ServiceError("El plan de actualización de datos tiene un formato incompatible.")
    seen = set()
    for change in plan["changes"]:
        if not isinstance(change, dict) or set(change) != {"table", "keys", "fields"}:
            raise ServiceError("El plan contiene un cambio incompleto.")
        table, keys, fields = change["table"], change["keys"], change["fields"]
        if (not isinstance(table, str) or table not in TABLES or table not in PRIMARY_KEYS
                or not isinstance(keys, dict) or set(keys) != set(PRIMARY_KEYS[table])
                or any(type(v) is not int or v <= 0 for v in keys.values())
                or not isinstance(fields, dict) or not fields):
            raise ServiceError("El plan contiene una tabla o clave que no pertenece al hospital.")
        identity = (table, tuple(keys[k] for k in PRIMARY_KEYS[table]))
        if identity in seen:
            raise ServiceError("El plan repite una clave primaria. No se modificó ningún dato.")
        seen.add(identity)
        for column, spec in fields.items():
            quote(column)
            if (not isinstance(spec, dict) or set(spec) != {"value", "source_sha256"}
                    or not isinstance(spec["value"], str) or not spec["value"]
                    or "\x00" in spec["value"] or not isinstance(spec["source_sha256"], list)
                    or not spec["source_sha256"] or len(spec["source_sha256"]) > 100
                    or any(not isinstance(h, str) or not HEX_DIGEST.fullmatch(h)
                           for h in spec["source_sha256"])):
                raise ServiceError("El plan contiene un texto o huella de origen incompatible.")
    return plan


def _schema(cur, database):
    cur.execute("SELECT TABLE_NAME AS table_name,COLUMN_NAME AS name,DATA_TYPE AS data_type,"
                "GENERATION_EXPRESSION AS `generated`,CHARACTER_MAXIMUM_LENGTH AS max_length "
                "FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=%s ORDER BY ORDINAL_POSITION", (database,))
    metadata = {t: {} for t in TABLES}
    for row in cur.fetchall():
        if row["table_name"] in metadata:
            metadata[row["table_name"]][row["name"]] = row
    cur.execute("SELECT TABLE_NAME AS table_name,COLUMN_NAME AS name,CONSTRAINT_NAME AS constraint_name,"
                "REFERENCED_TABLE_NAME AS ref_table FROM information_schema.KEY_COLUMN_USAGE "
                "WHERE TABLE_SCHEMA=%s ORDER BY ORDINAL_POSITION", (database,))
    primary, foreign = {t: [] for t in TABLES}, {t: set() for t in TABLES}
    for row in cur.fetchall():
        table = row["table_name"]
        if table in primary:
            if row["constraint_name"] == "PRIMARY":
                primary[table].append(row["name"])
            if row["ref_table"]:
                foreign[table].add(row["name"])
    expected_columns, _ = expected_structure()
    if any(set(metadata[t]) != expected_columns[t] or tuple(primary[t]) != PRIMARY_KEYS[t] for t in TABLES):
        raise ServiceError("La estructura no coincide con las 36 tablas originales. No se actualizó ningún dato.")
    return metadata, foreign


def _validate_fields(plan, metadata, foreign):
    for change in plan["changes"]:
        table = change["table"]
        for column, spec in change["fields"].items():
            field = metadata[table].get(column)
            if (not field or field["data_type"] not in TEXT_TYPES or field["generated"]
                    or column in PRIMARY_KEYS[table] or column in foreign[table]):
                raise ServiceError("El plan intenta cambiar una clave, fecha, estado o cantidad. No se modificó ningún dato.")
            if field["max_length"] is not None and len(spec["value"]) > field["max_length"]:
                raise ServiceError("Un texto del plan supera la longitud de su columna. No se modificó ningún dato.")


def _snapshot(cur, lock=False):
    result = {}
    for table in TABLES:
        cur.execute("SELECT * FROM " + quote(table) + " ORDER BY "
                    + ",".join(map(quote, PRIMARY_KEYS[table])) + (" FOR UPDATE" if lock else ""))
        rows = cur.fetchall()
        result[table] = {tuple(row[k] for k in PRIMARY_KEYS[table]): dict(row) for row in rows}
        if len(result[table]) != len(rows):
            raise ServiceError("No se pudo comprobar la identidad de todos los registros.")
    return result


def _pending(plan, snapshot):
    changes, tables = [], {}
    complete = skipped = missing = 0
    for entry in plan["changes"]:
        table, keys = entry["table"], entry["keys"]
        row = snapshot[table].get(tuple(keys[k] for k in PRIMARY_KEYS[table]))
        if row is None:
            missing += 1
            continue
        fields, old = {}, {}
        for name, spec in entry["fields"].items():
            current = row[name]
            if current == spec["value"]:
                complete += 1
            elif isinstance(current, str) and _digest(current) in spec["source_sha256"]:
                fields[name], old[name] = spec["value"], current
            else:
                skipped += 1
        if fields:
            changes.append({"table": table, "keys": keys, "fields": fields, "old": old})
            counts = tables.setdefault(table, {"rows": 0, "cells": 0})
            counts["rows"] += 1
            counts["cells"] += len(fields)
    return changes, {"version": plan["version"], "cells": sum(t["cells"] for t in tables.values()),
                     "rows": len(changes), "tables": tables, "already_complete": complete,
                     "skipped_cells": skipped, "missing_rows": missing}


def _triggers(cur, database):
    cur.execute("SELECT TRIGGER_NAME AS name,EVENT_MANIPULATION AS event_name,EVENT_OBJECT_TABLE AS table_name,"
                "ACTION_TIMING AS timing,ACTION_STATEMENT AS body,SQL_MODE AS sql_mode,"
                "CHARACTER_SET_CLIENT AS charset,COLLATION_CONNECTION AS collation,"
                "DATABASE_COLLATION AS database_collation,DEFINER AS definer "
                "FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=%s ORDER BY TRIGGER_NAME", (database,))
    records = {}
    for item in cur.fetchall():
        record = dict(item)
        name = record["name"]
        cur.execute("SHOW CREATE TRIGGER " + quote(database) + "." + quote(name))
        detail = cur.fetchone()
        ddl = detail.get("SQL Original Statement") if detail else None
        if not isinstance(ddl, str) or not ddl:
            raise ServiceError("Su cuenta no puede conservar las reglas originales. Use una cuenta con permiso TRIGGER.")
        record["ddl"] = ddl
        records[name] = record
    return records


def _fingerprint(records):
    return _digest(json.dumps(records, ensure_ascii=False, sort_keys=True, separators=(",", ":")))


def _require_guards(records):
    expected = expected_structure()[1]["TRIGGER"]
    if len(records) != 23 or set(records) != expected or not set(GUARD_TABLES).issubset(records):
        raise ServiceError("No se pudieron conservar las 23 reglas originales. No se modificó ningún dato.")


def _other_sessions(cur, database):
    cur.execute("SELECT COUNT(*) AS n FROM information_schema.PROCESSLIST "
                "WHERE DB=%s AND ID<>CONNECTION_ID()", (database,))
    if cur.fetchone()["n"]:
        raise ServiceError("Cierre otras ventanas o conexiones que estén usando esta base y vuelva a intentar la actualización.")


def _require_restore_privilege(cur, records, names):
    """Do not remove a DEFINER that this connection cannot put back."""
    if not names:
        return
    cur.execute("SELECT CURRENT_USER() AS account")
    account = cur.fetchone()["account"]
    if all(records[name]["definer"] == account for name in names):
        return
    cur.execute("SHOW GRANTS")
    grants = [str(next(iter(row.values()))) for row in cur.fetchall()]
    for grant in grants:
        match = re.match(r"GRANT (.+?) ON \*\.\* TO ", grant, re.I)
        if match and {p.strip().upper() for p in match[1].split(",")} & {"ALL PRIVILEGES", "SUPER", "SET_USER_ID"}:
            return
    raise ServiceError("Esta cuenta no puede volver a crear las reglas con su propietario original. Use la cuenta que instaló la base o una cuenta administradora; no se modificó ningún dato.")


def _write_record(path, record, exclusive=False):
    temporary = None
    try:
        if exclusive:
            with path.open("x", encoding="utf-8", newline="\n") as output:
                json.dump(record, output, ensure_ascii=False, indent=2)
                output.flush()
                os.fsync(output.fileno())
            path.chmod(0o600)
        else:
            # Keep the last complete copy until its replacement is durable.
            temporary = path.with_name(path.name + "." + uuid.uuid4().hex + ".tmp")
            with temporary.open("x", encoding="utf-8", newline="\n") as output:
                json.dump(record, output, ensure_ascii=False, indent=2)
                output.flush()
                os.fsync(output.fileno())
            temporary.chmod(0o600)
            temporary.replace(path)
    except (OSError, ValueError):
        if exclusive:
            raise ServiceError("No se pudo guardar el archivo privado de recuperación junto al respaldo. No se modificó la base.") from None
        # Rule restoration must continue even if the disk becomes unavailable.
        record["log_write_failed"] = True
    finally:
        if temporary is not None:
            try:
                temporary.unlink(missing_ok=True)
            except OSError:
                pass


def _status(path, record, value):
    record["status"] = value
    record["updated_at"] = datetime.now().isoformat(timespec="seconds")
    _write_record(path, record)


def _backup_matches(path, before, metadata):
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
        sections = payload["tables"]
        for table in TABLES:
            names = sections[table]["columns"]
            expected_names = {n for n, field in metadata[table].items() if not field["generated"]}
            if set(names) != expected_names:
                return False
            rows = [[HospitalService._json_value(row[n]) for n in names] for row in before[table].values()]
            normalize = lambda values: sorted(json.dumps(r, ensure_ascii=False, sort_keys=True) for r in values)
            if normalize(rows) != normalize(sections[table]["rows"]):
                return False
        return True
    except (OSError, ValueError, KeyError, TypeError):
        return False


def _expected_after(before, changes):
    result = copy.deepcopy(before)
    for change in changes:
        identity = tuple(change["keys"][k] for k in PRIMARY_KEYS[change["table"]])
        result[change["table"]][identity].update(change["fields"])
    return result


def _restore_on(conn, database, original, attempted):
    with conn.cursor() as cur:
        current = _triggers(cur, database)
        cur.execute("SELECT @@SESSION.sql_mode AS sql_mode,@@SESSION.character_set_client AS charset,"
                    "@@SESSION.collation_connection AS collation")
        context = cur.fetchone()
        try:
            for name in sorted(attempted):
                saved = original[name]
                if name in current:
                    if current[name] != saved:
                        raise ServiceError("Una regla cambió durante el mantenimiento. Se conservó su definición en el archivo de recuperación.")
                    continue
                conn.set_character_set(saved["charset"], saved["collation"])
                cur.execute("SET SESSION sql_mode=%s", (saved["sql_mode"],))
                cur.execute(saved["ddl"])
        finally:
            conn.set_character_set(context["charset"], context["collation"])
            cur.execute("SET SESSION sql_mode=%s", (context["sql_mode"],))
        restored = _triggers(cur, database)
        if _fingerprint(restored) != _fingerprint(original):
            raise ServiceError("No coinciden todas las reglas originales después de restaurarlas.")


def _restore_guards(service, conn, original, attempted):
    try:
        _restore_on(conn, service.settings.database, original, attempted)
        return
    except Exception:
        # A lost connection must not be the reason a trigger stays removed.
        with service._connection() as rescue:
            _restore_on(rescue, service.settings.database, original, attempted)


def preview_cleanup(settings: Settings):
    """Cuenta cambios exactos pendientes; no guarda archivos ni modifica MySQL."""
    plan, service = _load_plan(), HospitalService(settings)
    with service._connection() as conn, conn.cursor() as cur:
        metadata, foreign = _schema(cur, settings.database)
        _validate_fields(plan, metadata, foreign)
        cur.execute("START TRANSACTION WITH CONSISTENT SNAPSHOT, READ ONLY")
        try:
            _, report = _pending(plan, _snapshot(cur))
        finally:
            conn.rollback()
    return report


def apply_cleanup(settings: Settings, backup_path):
    """Aplica la actualización reconocida y conserva datos del equipo y reglas.

    ``backup_path`` debe ser un nombre JSON nuevo en una carpeta privada local.
    No se eliminan tablas, bases ni registros. Si no quedan coincidencias, no
    se crea respaldo ni se retira ninguna regla.
    """
    plan, service = _load_plan(), HospitalService(settings)
    destination = Path(backup_path).expanduser().resolve()
    recovery = destination.with_name(destination.name + ".reglas.json")
    lock_name = "hospital_cleanup_" + _digest(settings.database)[:40]
    with service._connection() as conn, conn.cursor() as cur:
        acquired = False
        try:
            cur.execute("SELECT GET_LOCK(%s,0) AS acquired", (lock_name,))
            acquired = cur.fetchone()["acquired"] == 1
            if not acquired:
                raise ServiceError("Otra actualización de datos está en curso. Espere a que termine.")
            metadata, foreign = _schema(cur, settings.database)
            _validate_fields(plan, metadata, foreign)
            _other_sessions(cur, settings.database)
            original = _triggers(cur, settings.database)
            _require_guards(original)
            cur.execute("START TRANSACTION WITH CONSISTENT SNAPSHOT, READ ONLY")
            try:
                before = _snapshot(cur)
            finally:
                conn.rollback()
            changes, report = _pending(plan, before)
            report.update(success=True, data_committed=False, guards_restored=True,
                          backup_path=None, recovery_path=None)
            if not changes:
                return report
            if destination.exists() or recovery.exists():
                raise ServiceError("Elija un nombre nuevo para el respaldo; ya existe ese archivo o su archivo de recuperación.")
            changed_tables = {c["table"] for c in changes}
            guards = {name for name, table in GUARD_TABLES.items() if table in changed_tables}
            _require_restore_privilege(cur, original, guards)
            backup = service.export_backup(destination)
            if not _backup_matches(destination, before, metadata):
                raise ServiceError("La base cambió mientras se hacía el respaldo. No se actualizó ningún dato; vuelva a intentar con un nombre nuevo.")
            record = {"format": "hospital-data-cleanup-recovery-v1", "version": plan["version"],
                      "database": settings.database, "status": "prepared",
                      "created_at": datetime.now().isoformat(timespec="seconds"),
                      "backup_path": str(destination), "backup_sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
                      "trigger_fingerprint": _fingerprint(original), "triggers": original,
                      "attempted_triggers": [], "data_committed": False}
            _write_record(recovery, record, exclusive=True)
            attempted = set()
            committed = False
            try:
                _other_sessions(cur, settings.database)
                if _fingerprint(_triggers(cur, settings.database)) != _fingerprint(original):
                    raise ServiceError("Las reglas cambiaron desde la comprobación. No se modificó ningún dato.")
                _status(recovery, record, "removing_guards")
                for name in sorted(guards):
                    # Record the attempted DROP before sending it: a connection
                    # can fail after MySQL accepted DDL but before replying.
                    attempted.add(name)
                    record["attempted_triggers"] = sorted(attempted)
                    _status(recovery, record, "removing_guards")
                    cur.execute("DROP TRIGGER " + quote(settings.database) + "." + quote(name))
                _other_sessions(cur, settings.database)
                cur.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ")
                conn.begin()
                if _snapshot(cur, lock=True) != before:
                    raise ServiceError("La base cambió antes de actualizarla. Se cancelaron los cambios; vuelva a intentar con un respaldo nuevo.")
                _status(recovery, record, "updating_texts")
                for change in changes:
                    table, keys, fields, old = (change[k] for k in ("table", "keys", "fields", "old"))
                    names, key_names = list(fields), PRIMARY_KEYS[table]
                    where = [quote(k) + "=%s" for k in key_names]
                    where += ["BINARY " + quote(n) + "=BINARY %s" for n in names]
                    statement = ("UPDATE " + quote(table) + " SET " + ",".join(quote(n) + "=%s" for n in names)
                                 + " WHERE " + " AND ".join(where))
                    values = [fields[n] for n in names] + [keys[k] for k in key_names] + [old[n] for n in names]
                    cur.execute(statement, values)
                    if cur.rowcount != 1:
                        raise ServiceError("Un registro cambió durante la actualización. Se cancelaron todos los cambios de texto.")
                expected = _expected_after(before, changes)
                if _snapshot(cur) != expected:
                    raise ServiceError("La comprobación detectó un cambio fuera de los textos previstos. Se canceló la actualización.")
                _other_sessions(cur, settings.database)
                _status(recovery, record, "committing_data")
                conn.commit()
                committed = True
                record["data_committed"] = True
                _status(recovery, record, "data_committed")
            except Exception:
                try:
                    conn.rollback()
                    _status(recovery, record, "failed_after_commit" if committed else "rolled_back")
                except Exception:
                    _status(recovery, record, "connection_lost_verify_backup_and_data")
                raise
            finally:
                if attempted:
                    try:
                        _restore_guards(service, conn, original, attempted)
                        record["guards_restored"] = True
                        _status(recovery, record, "guards_restored_after_commit" if committed else "guards_restored_after_rollback")
                    except Exception:
                        record["guards_restored"] = False
                        _status(recovery, record, "guard_recovery_required")
                        raise ServiceError("No se pudieron restaurar todas las reglas. Cierre la aplicación y conserve el respaldo y el archivo de recuperación: " + str(recovery)) from None
            with service._connection() as verify, verify.cursor() as verify_cur:
                guards_match = _fingerprint(_triggers(verify_cur, settings.database)) == _fingerprint(original)
                verify_cur.execute("START TRANSACTION WITH CONSISTENT SNAPSHOT, READ ONLY")
                try:
                    rows_match = _snapshot(verify_cur) == expected
                finally:
                    verify.rollback()
                if not guards_match or not rows_match:
                    _status(recovery, record, "post_commit_verification_failed")
                    raise ServiceError("Los textos se guardaron, pero la comprobación final detectó un cambio. Conserve el respaldo y revise el archivo de recuperación.")
            _status(recovery, record, "verified")
            report.update(data_committed=True, guards_restored=True, backup_path=backup["path"],
                          recovery_path=str(recovery), trigger_count=len(original),
                          trigger_fingerprint=_fingerprint(original), total_rows=sum(len(v) for v in before.values()),
                          recovery_log_updated=not record.get("log_write_failed", False))
            return report
        finally:
            if acquired:
                try:
                    cur.execute("SELECT RELEASE_LOCK(%s)", (lock_name,))
                except Exception:
                    pass  # MySQL releases the lock when this connection closes.
