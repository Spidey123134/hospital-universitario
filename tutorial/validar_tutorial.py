#!/usr/bin/env python3
"""Verifica el tutorial en una base UUID propia del servidor indicado.

No instala servidores, no inicia servicios y no modifica los SQL originales.
Elimina exclusivamente la base UUID que crea en esta ejecución.
La contraseña se hereda de MYSQL_PWD y nunca se escribe en argumentos o informes.
"""
from __future__ import annotations

from datetime import datetime, timezone
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import uuid


ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--mysql", default="mysql", help="Ruta del cliente mysql.")
parser.add_argument("--host", default="127.0.0.1")
parser.add_argument("--port", type=int, default=3306)
parser.add_argument("--user", required=True)
parser.add_argument("--output", type=Path, default=Path(__file__).with_name("VALIDACION_TUTORIAL.json"))
args = parser.parse_args()
if not 1 <= args.port <= 65535:
    parser.error("--port debe estar entre 1 y 65535.")
MYSQL = args.mysql
DATABASE = "hospital_tutorial_" + uuid.uuid4().hex
OUTPUT = args.output
ERROR = re.compile(r"ERROR\s+(\d+)\s+\(")
results: list[dict] = []
owns_database = False
database_removed = False
fatal_error = None
server_version = None


def sql(statement: str, use_database: bool = True):
    command = [str(MYSQL), "--no-defaults", "--protocol=TCP",
               "--host=" + args.host, "--port=" + str(args.port), "--user=" + args.user,
               "--batch", "--raw", "--skip-column-names",
               "--default-character-set=utf8mb4", "--connect-timeout=10"]
    if use_database:
        command.append("--database=" + DATABASE)
    return subprocess.run(command, input=statement, text=True, encoding="utf-8",
                          errors="replace", capture_output=True, timeout=120)


def record(name: str, correct: bool, detail: str, category: str = "ejercicio", **extra):
    results.append({"nombre": name, "categoria": category,
                    "correcta": bool(correct), "detalle": detail, **extra})


def execute(name: str, statement: str, expected: str | None = None,
            use_database: bool = True):
    result = sql(statement, use_database)
    correct = result.returncode == 0
    if expected is not None:
        correct = correct and result.stdout.strip() == expected
    match = ERROR.search(result.stderr)
    record(name, correct, "Resultado esperado confirmado." if correct else
           "El resultado no coincide con lo esperado.",
           esperado=expected,
           obtenido=result.stdout.strip(),
           error_mysql=int(match.group(1)) if match else None)
    if result.returncode:
        raise RuntimeError("Error SQL en " + name)
    return result


def reject(name: str, statement: str, expected_code: int):
    result = sql(statement)
    match = ERROR.search(result.stderr)
    code = int(match.group(1)) if match else None
    record(name, result.returncode != 0 and code == expected_code,
           "La operación inválida se rechazó con el código esperado.",
           "rechazo", esperado=expected_code, error_mysql=code)


try:
    if not re.fullmatch(r"hospital_tutorial_[0-9a-f]{32}", DATABASE):
        raise RuntimeError("Identificador temporal inválido.")
    identity = sql("SELECT @@port, VERSION();", False)
    if identity.returncode:
        raise RuntimeError("El servidor indicado no está disponible.")
    port, server_version = identity.stdout.strip().split("\t")
    if int(port) != args.port:
        raise RuntimeError("El puerto informado por el servidor no coincide con el solicitado.")
    record("Conexión al servidor indicado", True,
           "Versión " + server_version + "; puerto " + str(args.port) + "; se utilizará exclusivamente una base UUID propia.", "entorno")
    check = sql("SELECT COUNT(*) FROM information_schema.schemata "
                f"WHERE schema_name = '{DATABASE}';", False)
    if check.returncode or check.stdout.strip() != "0":
        raise RuntimeError("La base UUID no está libre; no se utiliza ni elimina.")
    source = (ROOT / "hospital_completo.sql").read_text(encoding="utf-8-sig")
    source = re.sub(r"\bhospital_universitario\b", DATABASE, source)
    directives = re.findall(
        r"\b(?:USE|(?:CREATE|DROP)\s+(?:DATABASE|SCHEMA))\s+"
        r"(?:(?:IF\s+NOT\s+EXISTS|IF\s+EXISTS)\s+)?`?([A-Za-z0-9_]+)`?",
        source, flags=re.I)
    if any(item.lower() != DATABASE for item in directives):
        raise RuntimeError("El instalador apunta a una base diferente.")
    # La autorización de limpieza empieza solo tras comprobar identidad y UUID libre.
    owns_database = True
    execute("Instalación completa en base UUID propia", source, use_database=False)

    execute("01: USE y SELECT DATABASE", "SELECT DATABASE();", DATABASE)
    execute("02: 36 tablas y 6 vistas", "SELECT table_type, COUNT(*) "
            "FROM information_schema.tables WHERE table_schema = DATABASE() "
            "GROUP BY table_type ORDER BY table_type;", "BASE TABLE\t36\nVIEW\t6")
    structure = sql("DESCRIBE pacientes; SHOW CREATE TABLE pacientes;")
    record("03: DESCRIBE y SHOW CREATE TABLE pacientes",
           structure.returncode == 0 and "AUTO_INCREMENT" in structure.stdout
           and "ck_paciente_nacimiento" in structure.stdout,
           "AUTO_INCREMENT y CHECK del paciente presentes.")
    execute("04: cinco pacientes originales", "SELECT paciente_id, expediente_clinico "
            "FROM pacientes ORDER BY paciente_id;",
            "1\tEXP-2026-0001\n2\tEXP-2026-0002\n3\tEXP-2026-0003\n"
            "4\tEXP-2026-0004\n5\tEXP-2026-0005")
    execute("05a: filtro pacientes activos sexo F", "SELECT paciente_id FROM pacientes "
            "WHERE activo = 1 AND sexo = 'F' ORDER BY paciente_id;", "1\n4")
    execute("05b: LIKE encuentra Alex Rojas Medina", "SELECT paciente_id FROM pacientes "
            "WHERE nombre LIKE '%Alex%';", "3")
    execute("06: LEFT JOIN conserva cinco pacientes", "SELECT p.paciente_id, ce.contacto_id "
            "FROM pacientes p LEFT JOIN contactos_emergencia ce "
            "ON ce.paciente_id=p.paciente_id AND ce.prioridad=1 ORDER BY p.paciente_id;",
            "1\t1\n2\t3\n3\t4\n4\t5\n5\t6")

    patient_actions = sql("""
SET SQL_SAFE_UPDATES = 1;
INSERT INTO pacientes
  (expediente_clinico, nombre, apellido_paterno, apellido_materno,
   fecha_nacimiento, sexo, telefono)
VALUES ('EXP-2026-0031', 'Nicolás', 'Herrera', 'Ríos',
        '2000-01-15', 'NO_ESPECIFICADO', '5512349087');
SET @paciente_tutorial = LAST_INSERT_ID();
SELECT 'INSERTADO', COUNT(*) FROM pacientes
WHERE paciente_id=@paciente_tutorial AND expediente_clinico='EXP-2026-0031';
SELECT 'AUTOID', @paciente_tutorial > 5;
START TRANSACTION;
SELECT 'ANTES', telefono FROM pacientes WHERE paciente_id=@paciente_tutorial;
UPDATE pacientes SET telefono='5587654301'
WHERE paciente_id=@paciente_tutorial;
SELECT 'DURANTE', telefono FROM pacientes WHERE paciente_id=@paciente_tutorial;
ROLLBACK;
SELECT 'DESPUES', telefono FROM pacientes WHERE paciente_id=@paciente_tutorial;
DELETE FROM pacientes WHERE paciente_id=@paciente_tutorial
AND expediente_clinico='EXP-2026-0031';
SELECT 'BORRADAS', ROW_COUNT();
SELECT 'RESTANTES', COUNT(*) FROM pacientes WHERE paciente_id=@paciente_tutorial;
SELECT 'ORIGINALES', COUNT(*) FROM pacientes;
""")
    rows = dict(row.split("\t", 1) for row in patient_actions.stdout.strip().splitlines()
                if "\t" in row)
    safe = patient_actions.returncode == 0
    match = ERROR.search(patient_actions.stderr)
    record("07: INSERT con AUTO_INCREMENT y LAST_INSERT_ID",
           safe and rows.get("INSERTADO") == "1" and rows.get("AUTOID") == "1",
           "Un paciente ficticio nuevo, ID mayor que 5, capturado en la misma conexión.",
           sql_safe_updates=1, error_mysql=int(match.group(1)) if match else None)
    record("08: UPDATE con WHERE y ROLLBACK",
           safe and rows.get("ANTES") == "5512349087"
           and rows.get("DURANTE") == "5587654301"
           and rows.get("DESPUES") == "5512349087",
           "El teléfono cambia dentro de la transacción y regresa al original.",
           sql_safe_updates=1)
    record("09: DELETE restringido al paciente nuevo",
           safe and rows.get("BORRADAS") == "1" and rows.get("RESTANTES") == "0"
           and rows.get("ORIGINALES") == "5",
           "Se elimina una fila propia; permanecen los cinco pacientes originales.",
           sql_safe_updates=1)

    execute("10: sp_agendar_cita y parámetro OUT", """
SET @cita_tutorial = NULL;
CALL sp_agendar_cita(4,1,'2026-10-15 15:00:00','2026-10-15 15:30:00',
                    'Control de seguimiento',@cita_tutorial);
SELECT @cita_tutorial IS NOT NULL;
SELECT paciente_id,medico_id,inicio,fin,estado FROM citas
WHERE cita_id=@cita_tutorial;
""", "1\n4\t1\t2026-10-15 15:00:00\t2026-10-15 15:30:00\tPROGRAMADA")
    reject("10: horario repetido rechazado", "CALL sp_agendar_cita(4,1,"
           "'2026-10-15 15:00:00','2026-10-15 15:30:00','Duplicada',@salida);", 1644)
    execute("11a: ocupación registrada de camillas", "SELECT disponibilidad,COUNT(*) "
            "FROM v_camillas_estado GROUP BY disponibilidad ORDER BY disponibilidad;",
            "DISPONIBLE\t4\nMANTENIMIENTO\t1\nOCUPADA\t1")
    execute("11b: hospitalización cerrada y abierta", "SELECT hospitalizacion_id, "
            "fecha_alta IS NULL FROM hospitalizaciones ORDER BY hospitalizacion_id;", "1\t0\n2\t1")

    execute("12a: farmacia antes de entrega", "SELECT cantidad_prescrita,cantidad_entregada,"
            "cantidad_pendiente FROM v_recetas_pendientes WHERE receta_id=2 AND renglon=1;"
            "SELECT stock FROM v_stock_lotes WHERE lote_id=3;", "4\t0\t4\n40")
    execute("12b: sp_dispensar registra una unidad", """
SET @dispensacion_tutorial=NULL;
CALL sp_dispensar(2,1,3,1,6,'2026-10-10 10:00:00',@dispensacion_tutorial);
SELECT @dispensacion_tutorial IS NOT NULL;
SELECT cantidad_prescrita,cantidad_entregada,cantidad_pendiente
FROM v_recetas_pendientes WHERE receta_id=2 AND renglon=1;
SELECT stock FROM v_stock_lotes WHERE lote_id=3;
""", "1\n4\t1\t3\n39")
    execute("13a: factura antes del abono", "SELECT total,pagado,saldo "
            "FROM v_facturas_saldo WHERE factura_id=1;", "850.00\t500.00\t350.00")
    execute("13b: sp_registrar_pago registra 25", """
SET @pago_tutorial=NULL;
CALL sp_registrar_pago(1,'2026-10-10 10:30:00',25.00,'EFECTIVO',
                       'EFE-202610-000025',@pago_tutorial);
SELECT @pago_tutorial IS NOT NULL;
SELECT total,pagado,saldo FROM v_facturas_saldo WHERE factura_id=1;
""", "1\n850.00\t525.00\t325.00")
    reject("14a: código UNIQUE repetido", "INSERT INTO departamentos(codigo,nombre) "
           "VALUES('DEP-001','Consulta externa');", 1062)
    reject("14b: CHECK prioridad mayor que cero", "INSERT INTO contactos_emergencia "
           "(paciente_id,nombre,parentesco,telefono,prioridad) "
           "VALUES(1,'Teresa Herrera Ríos','Hermana','5512349088',0);", 3819)
    reject("14c: FK de paciente inexistente", "INSERT INTO contactos_emergencia "
           "(paciente_id,nombre,parentesco,telefono,prioridad) "
           "VALUES(999999,'Teresa Herrera Ríos','Hermana','5512349088',1);", 1452)
    execute("15: CREATE y ALTER de tabla de práctica", """
CREATE TABLE prueba_estructura (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(100) NOT NULL
);
ALTER TABLE prueba_estructura ADD COLUMN observaciones VARCHAR(200) NULL;
SELECT column_name,data_type,character_maximum_length,is_nullable
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='prueba_estructura'
AND column_name='observaciones';
""", "observaciones\tvarchar\t200\tYES")
    execute("Cuentas inactivas con tres hashes PBKDF2 distintos", "SELECT COUNT(*) FROM usuarios "
            "WHERE activo=1; SELECT COUNT(DISTINCT password_hash) FROM usuarios WHERE "
            "password_hash REGEXP '^pbkdf2_sha256[$][1-9][0-9]*[$][0-9a-f]{24}[$][A-Za-z0-9+/]{43}=$';", "0\n3")
    reject("Instalación no repetible encima de base existente",
           f"CREATE DATABASE {DATABASE};", 1007)
    query_source = (ROOT / "04_consultas.sql").read_text(encoding="utf-8-sig")
    query_source = re.sub(r"\bhospital_universitario\b", DATABASE, query_source)
    query_result = sql(query_source)
    record("Las 20 consultas siguen siendo ejecutables tras ejercicios",
           query_result.returncode == 0,
           "Consultas de lectura ejecutadas; los resultados incorporan la cita, entrega y abono del tutorial.")
except Exception as exc:
    fatal_error = str(exc)
    record("Preparación o ejecución", False, fatal_error, "entorno")
finally:
    if owns_database:
        cleanup = sql(f"DROP DATABASE IF EXISTS `{DATABASE}`;", False)
        verify = sql("SELECT COUNT(*) FROM information_schema.schemata "
                     f"WHERE schema_name='{DATABASE}';", False)
        database_removed = cleanup.returncode == 0 and verify.returncode == 0 \
            and verify.stdout.strip() == "0"
        record("Limpieza de base UUID propia", database_removed,
               "Se eliminó exclusivamente la base creada para esta ejecución.", "limpieza")
    files = {filename: hashlib.sha256((ROOT / filename).read_bytes()).hexdigest()
             for filename in ("hospital_completo.sql", "01_esquema.sql", "02_reglas.sql",
                              "03_datos_demo.sql", "04_consultas.sql")}
    passed = sum(entry["correcta"] for entry in results)
    report = {
        "estado": "APROBADO" if results and passed == len(results) else "FALLIDO",
        "fecha_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "fecha_didactica": "2026-10-10",
        "servidor": {"version": server_version, "host": args.host, "puerto": args.port,
                     "base_de_prueba_aislada_por_uuid": True},
        "base_temporal": DATABASE,
        "base_temporal_eliminada": database_removed,
        "instancia_detenida_al_final": False,
        "total": len(results), "correctas": passed, "fallidas": len(results)-passed,
        "alcance": "SQL del tutorial sobre copia UUID propia; no valida la interfaz de Workbench ni Reverse Engineer.",
        "huellas_sha256_originales": files,
        "resultados": results,
    }
    OUTPUT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key:report[key] for key in ("estado","total","correctas","fallidas",
                     "base_temporal_eliminada")}, ensure_ascii=False))
    raise SystemExit(0 if report["estado"] == "APROBADO" else 1)
