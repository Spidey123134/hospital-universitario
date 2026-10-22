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


PLACEHOLDER = re.compile(
    r"fictici|simulad|de prueba|didactic|demostraci|inventad|\bDEMO\b|marcador",
    re.IGNORECASE,
)
TEXT_TYPES = frozenset(("char", "varchar", "tinytext", "text", "mediumtext", "longtext", "enum", "set"))
SENSITIVE = re.compile(r"password|passwd|contrase|clave|secret|token|hash", re.IGNORECASE)


def normalized(value):
    """Reconoce también didáctico y demostración, con o sin acentos."""
    return "".join(char for char in unicodedata.normalize("NFKD", str(value))
                   if not unicodedata.combining(char))


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
                        match = PLACEHOLDER.search(normalized(value))
                        if not match:
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
