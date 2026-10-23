"""Audita todos los campos de texto del catálogo del hospital, sin modificarlos.

Uso: python -m app_hospital.tests.audit_data --port 3307 --user root
La contraseña se lee de MYSQL_PWD o se solicita de forma oculta. El informe
cuenta también los campos sensibles, pero nunca muestra sus valores.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import getpass
import json
import os
from pathlib import Path
import re
import sys
import unicodedata

from app_hospital.catalog import TABLES
from app_hospital.db import HospitalService, ServiceError, Settings, quote


# Se buscan señales explícitas, no diagnósticos o resultados por su contenido.
# «Marcador tumoral», «prueba de glucosa» y «diagnóstico pendiente» pueden ser
# datos válidos. Tampoco se inspeccionan los avisos generales de los manuales.
PLACEHOLDER = re.compile(
    r"\bfict(?:ici[oa]s?|i[oa]s?)\b|\bsimulad[oa]s?\b|"
    r"\bdidactic[oa]s?\b|\bdemostraci(?:on|ones)\b|\binventad[oa]s?\b|\bdemo\b|"
    r"\bplace[\s_-]*holders?\b|\bpor\s+(?:completar|definir|llenar|capturar)\b|"
    r"\bpendiente(?:s)?\s+de\s+(?:completar|definir|llenar|capturar)\b|"
    r"\b(?:datos?|domicilio|direccion|paciente|sustancia|texto|registro|valor|nombre|"
    r"correo|email|telefono|contacto|folio|referencia|expediente)\s+de\s+prueba\b|"
    r"\bmarcador(?:es)?\s+(?:de\s+)?(?:relleno|posicion|temporal(?:es)?)\b|"
    r"\b(?:dato|texto|valor|nombre|domicilio)\s+de\s+relleno\b|\btbd\b",
    re.IGNORECASE,
)
TEXT_TYPES = frozenset(("char", "varchar", "tinytext", "text", "mediumtext", "longtext", "enum", "set"))
SENSITIVE = re.compile(r"password|passwd|contrase|clave|secret|token|hash", re.IGNORECASE)


def normalized(value):
    """Quita acentos para reconocer las mismas señales al escribir sin tildes."""
    return "".join(char for char in unicodedata.normalize("NFKD", str(value))
                   if not unicodedata.combining(char))


def contains_placeholder(value):
    """Detecta marcadores explícitos; nunca autoriza reemplazar un valor."""
    return value is not None and bool(PLACEHOLDER.search(normalized(value)))


def cleanup_review_message(plan_report, audit_report, *, applied=False, audit_error=None):
    """Prepara un mensaje verificable para la revisión anterior o posterior.

    Un plan sin cambios no prueba que la base esté completa: pueden existir
    personalizaciones, filas eliminadas o marcadores fuera del plan conocido.
    Esta función no muestra el contenido de los campos ni cambia registros.
    """
    changed = int(plan_report.get("cells", 0)) if applied else 0
    skipped = int(plan_report.get("skipped_cells", 0))
    missing = int(plan_report.get("missing_rows", 0))
    parts = []
    if applied and changed:
        action = "Se actualizó 1 campo reconocido" if changed == 1 else f"Se actualizaron {changed} campos reconocidos"
        parts.append(f"{action} por el plan. "
                     "Se comprobaron los registros y las reglas de la base. "
                     "El respaldo anterior quedó guardado en la ubicación elegida.")
    else:
        parts.append("No quedan valores iniciales pendientes de esta actualización. "
                     "No se modificó ningún registro.")
    if skipped:
        action = "Se conservó 1 campo que difiere" if skipped == 1 else f"Se conservaron {skipped} campos que difieren"
        parts.append(f"{action} del plan: pueden ser "
                     "cambios del equipo y deben revisarse manualmente si todavía contienen relleno.")
    if missing:
        action = "No se encontró 1 registro incluido" if missing == 1 else f"No se encontraron {missing} registros incluidos"
        parts.append(f"{action} en el plan. "
                     "No se volvieron a insertar.")
    if audit_report is None:
        parts.append("No se pudo completar la búsqueda de marcadores después de la actualización. "
                     "Los cambios anteriores sí quedaron guardados. Vuelve a pulsar Completar datos "
                     "del proyecto para revisar la base.")
        if audit_error:
            parts.append(str(audit_error))
        return {"warning": True, "title": "Datos guardados; revisión pendiente",
                "status": "Los cambios se guardaron; falta revisar los marcadores de relleno.",
                "message": "\n\n".join(parts)}
    markers = int(audit_report["matching_cells"])
    examined = int(audit_report["cells_scanned"])
    if markers:
        marker_count = "1 campo" if markers == 1 else f"{markers} campos"
        parts.append(f"La búsqueda en {examined} campos de texto encontró {marker_count} "
                     "con marcadores de relleno. Los que no coinciden exactamente con el plan "
                     "se conservan; revísalos en Registros.")
        locations = []
        for example in audit_report.get("examples", [])[:5]:
            keys = ", ".join(f"{key}={value}" for key, value in example.get("primary_key", {}).items())
            locations.append(f"• {example['table']} ({keys or 'sin clave visible'}): {example['column']}")
        if locations:
            parts.append("Ubicaciones para revisar:\n" + "\n".join(locations))
    else:
        parts.append(f"La búsqueda revisó {examined} campos de texto y no encontró marcadores de relleno.")
    parts.append("Esta búsqueda reconoce marcadores explícitos; no comprueba que cada expediente "
                 "o resultado clínico esté completo.")
    warning = bool(markers or skipped or missing)
    return {"warning": warning,
            "title": "Revisión con pendientes" if warning else "Revisión de datos",
            "status": (f"Revisión: marcadores pendientes: {markers}; campos conservados fuera del plan: {skipped}."
                       if warning else "Actualización conocida revisada; no se encontraron marcadores de relleno."),
            "message": "\n\n".join(parts)}


def scan_service(settings: Settings | HospitalService, max_examples=30):
    """Revisa las 36 tablas y devuelve conteos y ejemplos de relleno.

    Los nombres SQL proceden únicamente de TABLES y de metadatos verificados.
    Se recorren todas las filas, sin el límite de la pantalla. Ningún valor de
    password_hash u otro campo sensible se incorpora a los ejemplos.
    """
    service = settings if isinstance(settings, HospitalService) else HospitalService(settings)
    if not isinstance(max_examples, int) or max_examples < 0:
        raise ValueError("max_examples debe ser un entero no negativo.")
    report = {
        "fecha_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "estado": "APROBADO", "database": service.settings.database,
        "table_count": 0, "text_column_count": 0, "cells_scanned": 0,
        "matching_cells": 0, "tables": {}, "examples": [],
    }
    with service._connection() as connection, connection.cursor() as cursor:
        cursor.execute(
            "SELECT TABLE_NAME AS table_name, COLUMN_NAME AS column_name, "
            "DATA_TYPE AS data_type, COLUMN_KEY AS column_key "
            "FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=%s "
            "ORDER BY TABLE_NAME, ORDINAL_POSITION", (service.settings.database,),
        )
        metadata = cursor.fetchall()
        for table in TABLES:
            columns = [column for column in metadata if column["table_name"] == table]
            if not columns:
                raise ServiceError("La auditoría no encontró las 36 tablas completas del hospital.")
            texts = [column["column_name"] for column in columns if column["data_type"].lower() in TEXT_TYPES]
            primary = [column["column_name"] for column in columns if column["column_key"] == "PRI"]
            fields = list(dict.fromkeys(primary + texts))
            table_report = {"rows": 0, "text_columns": len(texts), "cells": 0, "matches": 0}
            report["tables"][table] = table_report
            report["text_column_count"] += len(texts)
            if not fields:
                cursor.execute("SELECT COUNT(*) AS n FROM " + quote(table))
                table_report["rows"] = cursor.fetchone()["n"]
                continue
            statement = "SELECT " + ", ".join(quote(field) for field in fields) + " FROM " + quote(table)
            if primary:
                statement += " ORDER BY " + ", ".join(quote(field) for field in primary)
            cursor.execute(statement)
            while True:
                rows = cursor.fetchmany(500)
                if not rows:
                    break
                table_report["rows"] += len(rows)
                for row in rows:
                    for field in texts:
                        value = row[field]
                        if value is None:
                            continue
                        table_report["cells"] += 1
                        if not contains_placeholder(value):
                            continue
                        table_report["matches"] += 1
                        if len(report["examples"]) < max_examples:
                            report["examples"].append({
                                "table": table,
                                "primary_key": {key: row[key] for key in primary if not SENSITIVE.search(key)},
                                "column": field,
                                "value": "[campo sensible omitido]" if SENSITIVE.search(field) else str(value)[:240],
                            })
            report["cells_scanned"] += table_report["cells"]
            report["matching_cells"] += table_report["matches"]
    report["table_count"] = len(report["tables"])
    if report["matching_cells"]:
        report["estado"] = "FALLIDO"
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=3306)
    parser.add_argument("--user", default="root")
    parser.add_argument("--database", default="hospital_universitario")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    password = os.environ.get("MYSQL_PWD")
    if password is None:
        password = getpass.getpass("Contraseña de MySQL: ") if sys.stdin.isatty() else ""
    try:
        report = scan_service(Settings(args.host, args.port, args.user, password, args.database))
    except ServiceError as error:
        print(json.dumps({"estado": "ERROR", "detalle": str(error)}, ensure_ascii=False))
        return 2
    output = json.dumps(report, ensure_ascii=False, indent=2, default=str) + "\n"
    if args.output:
        args.output.write_text(output, encoding="utf-8")
    print(output, end="")
    return 0 if report["matching_cells"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
