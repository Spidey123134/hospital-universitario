r"""Prueba real de la actualización en una copia temporal, nunca en la original.

Ejemplo desde la carpeta del proyecto:
  python -m app_hospital.tests.integration_cleanup --user root --port 3306 ^
    --mysql-client "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"

La contraseña se toma de MYSQL_PWD. --source-backup permite probar un respaldo
anterior y --expected-cells comprueba el número de textos antiguos reconocidos.
Los respaldos de la prueba quedan en --backup-dir (por defecto una carpeta
temporal privada). Solo se crea/elimina la base hospital_prueba_<UUID> propia.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone
import uuid
from unittest.mock import patch

import pymysql

from app_hospital import data_cleanup as cleanup
from app_hospital.db import HospitalService, PROJECT, ServiceError, Settings, quote


def utc():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


class CleanupQA:
    def __init__(self, args):
        self.args, self.checks = args, []
        self.database = "hospital_prueba_" + uuid.uuid4().hex
        self.owned = False
        self.password = os.environ.get("MYSQL_PWD", "")
        self.settings = Settings(args.host, args.port, args.user, self.password, self.database)
        self.connection = pymysql.connect(host=args.host, port=args.port, user=args.user,
            password=self.password, charset="utf8mb4", autocommit=True,
            cursorclass=pymysql.cursors.DictCursor)
        self.folder = (args.backup_dir or Path(tempfile.mkdtemp(prefix="hospital_cleanup_qa_"))).resolve()
        self.folder.mkdir(parents=True, exist_ok=True)
        self.report = {"inicio_utc": utc(), "base_temporal": self.database}

    def check(self, label, condition):
        self.checks.append({"prueba": label, "correcta": bool(condition)})
        if not condition:
            raise AssertionError(label)

    def rows(self, database):
        result = {}
        with self.connection.cursor() as cur:
            cur.execute("SELECT COUNT(*) AS n FROM information_schema.SCHEMATA WHERE SCHEMA_NAME=%s", (database,))
            if not cur.fetchone()["n"]:
                return None
            for table in cleanup.TABLES:
                cur.execute("SELECT * FROM " + quote(database) + "." + quote(table)
                            + " ORDER BY " + ",".join(map(quote, cleanup.PRIMARY_KEYS[table])))
                result[table] = {tuple(r[k] for k in cleanup.PRIMARY_KEYS[table]): r for r in cur.fetchall()}
        return result

    def triggers(self):
        service = HospitalService(self.settings)
        with service._connection() as conn, conn.cursor() as cur:
            return cleanup._triggers(cur, self.database)

    def import_source(self):
        with self.connection.cursor() as cur:
            cur.execute("SELECT COUNT(*) AS n FROM information_schema.SCHEMATA WHERE SCHEMA_NAME=%s", (self.database,))
            self.check("El nombre UUID de prueba estaba libre", cur.fetchone()["n"] == 0)
        source = self.args.source_backup.read_text(encoding="utf-8-sig")
        self.check("El respaldo contiene la base del proyecto", "`hospital_universitario`" in source)
        source = source.replace("`hospital_universitario`", quote(self.database))
        self.check("La importación no conserva referencias a la base original", "`hospital_universitario`" not in source)
        self.owned = True
        client = self.args.mysql_client or shutil.which("mysql")
        if not client:
            raise ServiceError("Indique --mysql-client con la ruta al cliente mysql de MySQL 8.")
        kwargs = {"creationflags": subprocess.CREATE_NO_WINDOW} if os.name == "nt" else {}
        result = subprocess.run([str(client), "--host=" + self.args.host, "--port=" + str(self.args.port),
            "--user=" + self.args.user, "--default-character-set=utf8mb4"], input=source,
            encoding="utf-8", stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=os.environ.copy(), **kwargs)
        self.check("El respaldo anterior se importa en la copia UUID", result.returncode == 0)

    def run(self):
        original = self.rows("hospital_universitario")
        try:
            self.report["etapa"] = "importacion_del_respaldo"
            self.import_source()
            baseline = self.rows(self.database)
            guards = self.triggers()
            self.check("La copia tiene 36 tablas y 789 filas", len(baseline) == 36 and sum(map(len, baseline.values())) == 789)
            self.check("La copia conserva las 23 reglas", len(guards) == 23)
            self.report["etapa"] = "vista_previa"
            preview = cleanup.preview_cleanup(self.settings)
            self.report["vista_previa"] = preview
            if self.args.expected_cells is not None:
                self.check("El conteo de textos antiguos coincide con el esperado", preview["cells"] == self.args.expected_cells)
            plan = cleanup._load_plan()
            pending, _ = cleanup._pending(plan, baseline)
            expected = cleanup._expected_after(baseline, pending)

            if pending:
                self.report["etapa"] = "fallo_controlado_y_recuperacion"
                with patch.object(cleanup, "_expected_after", side_effect=RuntimeError("fallo controlado antes de COMMIT")):
                    try:
                        cleanup.apply_cleanup(self.settings, self.folder / "antes_fallo_controlado.json")
                    except ServiceError:
                        pass
                    else:
                        raise AssertionError("La falla controlada debía interrumpir la actualización")
                self.check("La falla tras retirar reglas revierte todos los textos", self.rows(self.database) == baseline)
                self.check("La falla restaura las 23 definiciones y sus contextos exactos", self.triggers() == guards)
                failed_record = json.loads((self.folder / "antes_fallo_controlado.json.reglas.json").read_text(encoding="utf-8"))
                self.check("El archivo de recuperación confirma rollback y reglas restauradas",
                           not failed_record["data_committed"] and failed_record["guards_restored"])

            self.report["etapa"] = "actualizacion_completa"
            result = cleanup.apply_cleanup(self.settings, self.folder / "antes_actualizacion.json")
            self.report["resultado"] = {k: v for k, v in result.items() if k not in {"backup_path", "recovery_path"}}
            self.check("Se actualizan únicamente los textos reconocidos por clave y huella", result["cells"] == preview["cells"])
            after = self.rows(self.database)
            self.check("Todas las filas coinciden con el plan sin cambios adicionales", after == expected)
            self.check("Claves, relaciones, fechas, estados, importes y cantidades se conservan", self.only_text_changes(baseline, after, pending))
            self.check("Las 23 reglas conservan sus definiciones y contexto exactos", self.triggers() == guards)
            self.check("La auditoría de textos de relleno queda en cero", not self.bad_values(after))
            self.check("Una segunda vista previa tiene cero cambios", cleanup.preview_cleanup(self.settings)["cells"] == 0)
            again = cleanup.apply_cleanup(self.settings, self.folder / "no_debe_crearse.json")
            self.check("Una segunda aplicación no escribe ni retira reglas", again["cells"] == 0
                       and not (self.folder / "no_debe_crearse.json").exists() and self.rows(self.database) == after)
            self.report["etapa"] = "datos_personalizados_del_equipo"
            self.customized_value_test(after)
            self.report["etapa"] = "completada"
        except Exception as error:
            # Exception types and test labels are sufficient evidence. MySQL
            # errors can contain field contents; never publish their raw text.
            self.report["error_tipo"] = type(error).__name__
            self.checks.append({"prueba": "La secuencia completa termina", "correcta": False})
        finally:
            try:
                self.check("La base hospital_universitario original queda intacta", self.rows("hospital_universitario") == original)
            except Exception:
                self.checks.append({"prueba": "Verificar base original", "correcta": False})
            if self.owned and re.fullmatch(r"hospital_prueba_[a-f0-9]{32}", self.database):
                with self.connection.cursor() as cur:
                    cur.execute("DROP DATABASE " + quote(self.database))
                    cur.execute("SELECT COUNT(*) AS n FROM information_schema.SCHEMATA WHERE SCHEMA_NAME=%s", (self.database,))
                    self.checks.append({"prueba": "Solo se elimina la copia UUID propia", "correcta": cur.fetchone()["n"] == 0})
            self.connection.close()
        total = len(self.checks)
        passed = sum(c["correcta"] for c in self.checks)
        self.report.update(fin_utc=utc(), estado="APROBADO" if passed == total else "FALLIDO",
            resumen={"total": total, "correctas": passed, "fallidas": total - passed}, pruebas=self.checks,
            huellas_sha256={str(file.relative_to(PROJECT)).replace("\\", "/"): hashlib.sha256(file.read_bytes()).hexdigest()
                for file in (Path(__file__), Path(cleanup.__file__), cleanup.PLAN_PATH)})
        self.args.output.write_text(json.dumps(self.report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(json.dumps({"estado": self.report["estado"], "resumen": self.report["resumen"], "evidencia": str(self.args.output)}, ensure_ascii=True))
        return 0 if passed == total else 1

    @staticmethod
    def only_text_changes(before, after, pending):
        allowed = {(p["table"], tuple(p["keys"][k] for k in cleanup.PRIMARY_KEYS[p["table"]]), n)
                   for p in pending for n in p["fields"]}
        for table, rows in before.items():
            if rows.keys() != after[table].keys():
                return False
            for key, row in rows.items():
                for name, old in row.items():
                    new = after[table][key][name]
                    if old != new and ((table, key, name) not in allowed or not isinstance(old, str) or not isinstance(new, str)):
                        return False
        return True

    @staticmethod
    def bad_values(rows):
        pattern = re.compile(r"fictici|simulad|placeholder|did[aá]ctic|de prueba|docente|demostraci|inventad|demo|acad[eé]mic|de la captura|sin uso cl[ií]nico", re.I)
        return [(table, name) for table, records in rows.items() for row in records.values()
                for name, value in row.items() if isinstance(value, str) and pattern.search(value)]

    def customized_value_test(self, cleaned):
        table, key, field = "pacientes", 1, "domicilio"
        original = cleaned[table][(key,)][field]
        customized = "Avenida del Parque 25, Colonia Los Olivos"
        source = self.folder / "plan_personalizacion.json"
        fixture = {"version": "qa-personalizacion", "changes": [{"table": table, "keys": {"paciente_id": key},
            "fields": {field: {"value": original, "source_sha256": [cleanup._digest("Dirección inicial QA")]}}}]}
        source.write_text(json.dumps(fixture, ensure_ascii=False), encoding="utf-8")
        with self.connection.cursor() as cur:
            cur.execute("UPDATE " + quote(self.database) + ".`pacientes` SET domicilio=%s WHERE paciente_id=%s", (customized, key))
        try:
            with patch.object(cleanup, "PLAN_PATH", source):
                preview = cleanup.preview_cleanup(self.settings)
                result = cleanup.apply_cleanup(self.settings, self.folder / "no_modificar_personalizado.json")
            self.check("Una dirección escrita por el equipo no coincide con el marcador original",
                       preview["cells"] == 0 and preview["skipped_cells"] == 1)
            self.check("La actualización conserva los datos personalizados del equipo",
                       result["cells"] == 0 and self.rows(self.database)[table][(key,)][field] == customized)
        finally:
            with self.connection.cursor() as cur:
                cur.execute("UPDATE " + quote(self.database) + ".`pacientes` SET domicilio=%s WHERE paciente_id=%s", (original, key))
        self.check("La prueba de personalización no deja cambios adicionales", self.rows(self.database) == cleaned)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=3306)
    parser.add_argument("--user", required=True)
    parser.add_argument("--mysql-client", type=Path)
    parser.add_argument("--source-backup", type=Path, default=PROJECT / "entrega_base" / "hospital_universitario_respaldo.sql")
    parser.add_argument("--backup-dir", type=Path)
    parser.add_argument("--expected-cells", type=int)
    parser.add_argument("--output", type=Path, default=PROJECT / "VALIDACION_LIMPIEZA.json")
    return CleanupQA(parser.parse_args()).run()


if __name__ == "__main__":
    raise SystemExit(main())
