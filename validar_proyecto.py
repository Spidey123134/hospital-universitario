#!/usr/bin/env python3
"""Pruebas de integridad del proyecto hospitalario, sin paquetes externos.

Ejemplo (la contraseña, si se necesita, debe existir en MYSQL_PWD):
    python validar_proyecto.py --mysql "C:/MySQL/bin/mysql.exe" \
        --user root --port 33087 --output VALIDACION.json

Se crea una base hospital_prueba_<UUID>, se cargan los tres scripts del
proyecto y se ejecutan pruebas positivas y negativas. La base temporal se
elimina al finalizar. Este programa nunca acepta un nombre de base para
eliminar y no importa los archivos .ibd del prototipo.

Salida: JSON en la consola y, opcionalmente, en --output.
Código de salida: 0 si todas las pruebas pasan; 1 si falla alguna prueba.
"""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
import sys
from threading import Barrier
import uuid


TABLES = (
    "departamentos", "especialidades", "personal", "medicos",
    "medico_especialidad", "pacientes", "contactos_emergencia",
    "aseguradoras", "polizas", "habitaciones", "camillas", "citas",
    "consultas", "diagnosticos", "consulta_diagnosticos", "alergias_paciente",
    "hospitalizaciones", "asignaciones_camilla", "notas_enfermeria",
    "medicamentos", "proveedores", "lotes_medicamento", "recetas",
    "receta_detalle", "dispensaciones", "dispensacion_detalle",
    "movimientos_inventario", "procedimientos", "ordenes_procedimiento",
    "resultados_procedimiento", "facturas", "factura_detalle", "pagos",
    "roles", "usuarios", "usuario_roles",
)
TEMP_DATABASE = re.compile(r"hospital_prueba_[0-9a-f]{32}\Z")
MYSQL_ERROR = re.compile(r"ERROR\s+(\d+)\s+\(([^)]+)\)")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


class ValidationError(Exception):
    """Error del entorno o de preparación; no incluye credenciales."""


class Runner:
    def __init__(self, args: argparse.Namespace, database: str):
        if not TEMP_DATABASE.fullmatch(database):
            raise ValidationError("Identificador temporal no permitido.")
        self.args = args
        self.database = database
        self.results: list[dict] = []

    def sql(self, statement: str, *, use_database: bool = True,
            timeout: int = 90) -> subprocess.CompletedProcess:
        # Sin shell, sin --password y sin copiar la contraseña a argumentos,
        # registros o al JSON. mysql hereda MYSQL_PWD si ya está definida.
        command = [
            self.args.mysql, "--no-defaults", "--protocol=TCP",
            "--batch", "--raw", "--skip-column-names",
            "--default-character-set=utf8mb4", "--connect-timeout=10",
            f"--host={self.args.host}", f"--port={self.args.port}",
            f"--user={self.args.user}",
        ]
        if use_database:
            command.append(f"--database={self.database}")
        try:
            return subprocess.run(
                command, input=statement, text=True, encoding="utf-8",
                errors="replace", stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                timeout=timeout, check=False,
            )
        except FileNotFoundError as exc:
            raise ValidationError("No se encontró el ejecutable mysql indicado.") from exc
        except subprocess.TimeoutExpired as exc:
            raise ValidationError("MySQL superó el tiempo límite de una operación.") from exc
        except OSError as exc:
            raise ValidationError("No se pudo ejecutar el cliente mysql.") from exc

    @staticmethod
    def error_code(result: subprocess.CompletedProcess) -> int | None:
        match = MYSQL_ERROR.search(result.stderr)
        return int(match.group(1)) if match else None

    def record(self, name: str, category: str, ok: bool, detail: str,
               *, error_code: int | None = None) -> None:
        entry = {"nombre": name, "categoria": category,
                 "correcta": bool(ok), "detalle": detail}
        if error_code is not None:
            entry["error_mysql"] = error_code
        self.results.append(entry)

    def must_run(self, name: str, statement: str, *, use_database: bool = True,
                 timeout: int = 90) -> subprocess.CompletedProcess:
        result = self.sql(statement, use_database=use_database, timeout=timeout)
        code = self.error_code(result)
        ok = result.returncode == 0
        self.record(name, "preparacion", ok,
                    "SQL ejecutado." if ok else
                    "MySQL rechazó el SQL; revise el código de error registrado.",
                    error_code=code)
        if not ok:
            raise ValidationError(f"Falló la preparación: {name}.")
        return result

    def scalar(self, statement: str) -> str:
        result = self.sql(statement)
        if result.returncode != 0:
            code = self.error_code(result)
            raise ValidationError(f"No se pudo consultar la prueba (error MySQL {code}).")
        rows = result.stdout.strip().splitlines()
        if len(rows) != 1 or "\t" in rows[0]:
            raise ValidationError("La consulta de prueba no devolvió un valor único.")
        return rows[0]

    def expect_value(self, name: str, statement: str, expected: str,
                     category: str = "consistencia") -> None:
        observed = self.scalar(statement)
        self.record(name, category, observed == expected,
                    f"Esperado: {expected}; obtenido: {observed}.")

    def reject(self, name: str, statement: str, codes: tuple[int, ...],
               *, routine: bool = False, expected_message: str | None = None) -> None:
        # Las pruebas DML directas se revierten incluso si el dato inválido
        # se acepta. Las rutinas manejan su propia transacción.
        sql = statement if routine else f"START TRANSACTION;\n{statement}\nROLLBACK;"
        result = self.sql(sql)
        code = self.error_code(result)
        ok = result.returncode != 0 and code in codes
        if expected_message is not None:
            ok = ok and expected_message in result.stderr
        detail = ("Operación inválida rechazada por la regla esperada." if ok else
                  "La operación fue aceptada o falló por una regla distinta.")
        self.record(name, "rechazo", ok, detail, error_code=code)

    def load_project(self, directory: Path) -> None:
        check = self.sql(
            "SELECT COUNT(*) FROM information_schema.schemata "
            f"WHERE schema_name = '{self.database}';", use_database=False)
        if check.returncode != 0:
            raise ValidationError("No se pudo conectar o consultar el servidor MySQL.")
        if check.stdout.strip() != "0":
            raise ValidationError("La base temporal ya existe; no se utilizará ni eliminará.")
        scripts = []
        for filename in ("01_esquema.sql", "02_reglas.sql", "03_datos_demo.sql"):
            path = directory / filename
            if not path.is_file():
                raise ValidationError(f"Falta el archivo requerido {filename}.")
            source = path.read_text(encoding="utf-8-sig")
            source = re.sub(r"\bhospital_universitario\b", self.database,
                            source, flags=re.IGNORECASE)
            # Evita que una futura edición introduzca USE/CREATE/DROP de
            # otra base. Los nombres se limitan a la base UUID de esta ejecución.
            directives = re.findall(
                r"\b(?:USE|(?:CREATE|DROP)\s+(?:DATABASE|SCHEMA))\s+"
                r"(?:(?:IF\s+NOT\s+EXISTS|IF\s+EXISTS)\s+)?`?([A-Za-z0-9_]+)`?",
                source, flags=re.IGNORECASE,
            )
            if any(name.lower() != self.database for name in directives):
                raise ValidationError(f"{filename} contiene una directiva hacia otra base.")
            scripts.append((filename, source))
        # La autorización de limpieza solo existe tras confirmar que el UUID
        # estaba libre y que todos los archivos usan exclusivamente esa base.
        self.owns_database = True
        for filename, source in scripts:
            self.must_run(f"Carga de {filename}", source,
                          use_database=filename != "01_esquema.sql", timeout=180)
        combined_path = directory / "hospital_completo.sql"
        if not combined_path.is_file():
            raise ValidationError("Falta hospital_completo.sql.")

        def executable_content(source: str) -> str:
            # El combinado añade un encabezado de comentarios. Comparar todo
            # el contenido ejecutable verifica también orden y delimitadores.
            source = re.sub(r"(?m)^\s*--[^\n]*(?:\n|$)", "", source)
            return "\n".join(line.strip() for line in source.splitlines() if line.strip())

        combined = combined_path.read_text(encoding="utf-8-sig")
        components = "\n".join((directory / name).read_text(encoding="utf-8-sig")
                               for name, _ in scripts)
        identical = executable_content(combined) == executable_content(components)
        self.record("Instalador combinado igual a 01 + 02 + 03", "consistencia", identical,
                    "El contenido ejecutable coincide, incluido su orden." if identical else
                    "El instalador combinado difiere de los componentes probados.")

    def check_demo(self) -> None:
        self.expect_value(
            "Cantidad de tablas", "SELECT COUNT(*) FROM information_schema.tables "
            "WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE';", "36")
        sql = "\nUNION ALL\n".join(
            f"SELECT '{table}', COUNT(*) FROM `{table}`" for table in TABLES) + ";"
        result = self.sql(sql)
        if result.returncode != 0:
            raise ValidationError("No se pudieron consultar las tablas esperadas.")
        counts = {}
        for row in result.stdout.strip().splitlines():
            name, count = row.split("\t")
            counts[name] = int(count)
        empty = [table for table in TABLES if counts.get(table, 0) == 0]
        self.record("Datos ficticios en las 36 tablas", "consistencia", not empty,
                    "Todas contienen datos." if not empty else
                    "Tablas sin datos: " + ", ".join(empty))
        self.expect_value("Seis vistas", "SELECT COUNT(*) FROM information_schema.views "
                          "WHERE table_schema = DATABASE();", "6")
        self.expect_value("Seis procedimientos", "SELECT COUNT(*) FROM information_schema.routines "
                          "WHERE routine_schema = DATABASE() AND routine_type = 'PROCEDURE';", "6")
        self.expect_value("Veintitrés triggers", "SELECT COUNT(*) FROM information_schema.triggers "
                          "WHERE trigger_schema = DATABASE();", "23")
        self.expect_value("Stock demo: A=142, B=57 y C=40",
                          "SELECT GROUP_CONCAT(CONCAT(medicamento_id,':',stock_total) "
                          "ORDER BY medicamento_id SEPARATOR ',') FROM v_stock_medicamentos;",
                          "1:142,2:57,3:40")
        self.expect_value("Facturas demo: totales, pagos y saldos",
                          "SELECT GROUP_CONCAT(CONCAT(factura_id,':',CAST(total AS CHAR),':',"
                          "CAST(pagado AS CHAR),':',CAST(saldo AS CHAR)) ORDER BY factura_id "
                          "SEPARATOR ',') FROM v_facturas_saldo;",
                          "1:850.00:500.00:350.00,2:800.00:800.00:0.00,"
                          "3:1200.00:400.00:800.00,4:750.00:0.00:750.00")
        self.check_balances("Datos de demostración")
        query_path = Path(__file__).resolve().parent / "04_consultas.sql"
        if not query_path.is_file():
            raise ValidationError("Falta 04_consultas.sql.")
        queries = query_path.read_text(encoding="utf-8-sig")
        headings = re.findall(r"^\s*--\s*(\d{2})\.", queries, flags=re.MULTILINE)
        if headings != [f"{number:02d}" for number in range(1, 21)]:
            raise ValidationError("04_consultas.sql no contiene las 20 consultas numeradas esperadas.")
        queries = re.sub(r"\bhospital_universitario\b", self.database, queries,
                         flags=re.IGNORECASE)
        self.must_run("Ejecución de las 20 consultas de 04_consultas.sql", queries)

    def check_balances(self, prefix: str) -> None:
        self.expect_value(
            f"{prefix}: ningún lote con stock negativo",
            "SELECT COUNT(*) FROM (SELECT l.lote_id, COALESCE(SUM(m.cantidad),0) AS stock "
            "FROM lotes_medicamento l LEFT JOIN movimientos_inventario m USING(lote_id) "
            "GROUP BY l.lote_id) AS existencias WHERE stock < 0;", "0")
        self.expect_value(
            f"{prefix}: entregas con su salida exacta",
            "SELECT COUNT(*) FROM dispensacion_detalle d LEFT JOIN movimientos_inventario m "
            "ON m.dispensacion_detalle_id = d.dispensacion_detalle_id "
            "WHERE m.movimiento_id IS NULL OR m.lote_id <> d.lote_id "
            "OR m.tipo <> 'SALIDA' OR m.cantidad <> -CAST(d.cantidad AS SIGNED);", "0")
        self.expect_value(
            f"{prefix}: importes de factura correctos",
            "SELECT COUNT(*) FROM factura_detalle WHERE importe <> "
            "ROUND(cantidad * precio_unitario - descuento,2) OR importe < 0;", "0")
        self.expect_value(
            f"{prefix}: pagos sin exceder factura emitida",
            "SELECT COUNT(*) FROM facturas f JOIN "
            "(SELECT factura_id,SUM(monto) AS pagado FROM pagos GROUP BY factura_id) p "
            "USING(factura_id) LEFT JOIN (SELECT factura_id,SUM(importe) AS total "
            "FROM factura_detalle GROUP BY factura_id) d USING(factura_id) "
            "WHERE p.pagado > COALESCE(d.total,0) OR f.estado <> 'EMITIDA';", "0")

    def check_fixtures(self) -> None:
        # IDs alejados de los datos de demostración. Los nombres, sustancias e
        # informes son ficticios; los resultados publican únicamente contadores.
        self.must_run("Creación de fixtures independientes", """
START TRANSACTION;
INSERT INTO departamentos VALUES (900001,'VALIDACION-DEP','Departamento ficticio de pruebas');
INSERT INTO personal(personal_id,numero_empleado,departamento_id,nombre,apellido_paterno,puesto) VALUES
 (900001,'VALIDACION-MED1',900001,'Profesional ficticio','Prueba','MEDICO'),
 (900002,'VALIDACION-FAR',900001,'Profesional ficticio','Prueba','FARMACIA'),
 (900003,'VALIDACION-ENF',900001,'Profesional ficticio','Prueba','ENFERMERIA'),
 (900004,'VALIDACION-ADM',900001,'Profesional ficticio','Prueba','ADMINISTRACION'),
 (900005,'VALIDACION-MED2',900001,'Profesional ficticio','Prueba','MEDICO');
INSERT INTO medicos VALUES(900001,'VALIDACION-CED1'),(900005,'VALIDACION-CED2');
INSERT INTO pacientes(paciente_id,expediente_clinico,nombre,apellido_paterno,fecha_nacimiento) VALUES
 (900001,'VALIDACION-PAC1','Paciente ficticio','Prueba','1990-01-01'),
 (900002,'VALIDACION-PAC2','Paciente ficticio','Prueba','1990-01-01');
INSERT INTO aseguradoras VALUES(900001,'Aseguradora ficticia de pruebas',NULL);
INSERT INTO polizas VALUES(900001,900002,900001,'VALIDACION-POL',CURRENT_DATE,CURRENT_DATE + INTERVAL 1 YEAR);
INSERT INTO habitaciones VALUES(900001,900001,'VALIDACION-HAB','Edificio ficticio',1,'GENERAL');
INSERT INTO camillas VALUES
 (900001,900001,'VALIDACION-CAM1','OPERATIVA'),
 (900002,900001,'VALIDACION-CAM2','MANTENIMIENTO'),
 (900003,900001,'VALIDACION-CAM3','OPERATIVA');
INSERT INTO consultas(consulta_id,paciente_id,medico_id,fecha,tipo,motivo) VALUES
 (900001,900001,900001,NOW() - INTERVAL 4 DAY,'URGENCIA','Atencion ficticia de prueba'),
 (900002,900002,900005,NOW() - INTERVAL 3 HOUR,'URGENCIA','Atencion ficticia de prueba');
INSERT INTO hospitalizaciones(hospitalizacion_id,consulta_ingreso_id,paciente_id,
 medico_responsable_id,fecha_ingreso,motivo) VALUES
 (900001,900001,900001,900001,NOW() - INTERVAL 2 HOUR,'Estancia ficticia'),
 (900002,900002,900002,900005,NOW() - INTERVAL 2 HOUR,'Estancia ficticia');
INSERT INTO medicamentos VALUES
 (900001,'VALIDACION-MED-A','Sustancia ficticia A','Valor de prueba','Envase ficticio','unidad de prueba',0),
 (900002,'VALIDACION-MED-B','Sustancia ficticia B','Valor de prueba','Envase ficticio','unidad de prueba',0);
INSERT INTO proveedores VALUES(900001,'Proveedor ficticio de pruebas',NULL,NULL);
INSERT INTO lotes_medicamento VALUES
 (900001,900001,900001,'VALIDACION-LOTE1',CURRENT_DATE - INTERVAL 3 DAY,CURRENT_DATE + INTERVAL 1 YEAR,1),
 (900002,900002,900001,'VALIDACION-LOTE2',CURRENT_DATE,CURRENT_DATE + INTERVAL 1 YEAR,1),
 (900003,900001,900001,'VALIDACION-CADUCADO',CURRENT_DATE - INTERVAL 30 DAY,CURRENT_DATE - INTERVAL 1 DAY,1),
 (900004,900001,900001,'VALIDACION-CONCURRENTE',CURRENT_DATE,CURRENT_DATE + INTERVAL 1 YEAR,1);
INSERT INTO recetas VALUES(900001,900001,NOW() - INTERVAL 2 DAY,'Receta ficticia de prueba');
INSERT INTO receta_detalle VALUES
 (900001,1,900001,'Texto de prueba','Texto de prueba',1,'Texto de prueba',10),
 (900001,2,900001,'Texto de prueba','Texto de prueba',1,'Texto de prueba',200);
INSERT INTO facturas VALUES
 (900001,'VALIDACION-FAC',900001,NULL,NOW() - INTERVAL 1 HOUR,'ABIERTA'),
 (900002,'VALIDACION-VACIA',900001,NULL,NOW() - INTERVAL 1 HOUR,'ABIERTA');
INSERT INTO factura_detalle(factura_id,renglon,descripcion,cantidad,precio_unitario,descuento)
 VALUES(900001,1,'Cargo ficticio',2,100,0);
UPDATE facturas SET estado='EMITIDA' WHERE factura_id=900001;
INSERT INTO procedimientos VALUES(900001,'VALIDACION-PROC','Estudio ficticio','OTRO',100);
INSERT INTO ordenes_procedimiento(orden_id,consulta_id,procedimiento_id,fecha_solicitud,estado) VALUES
 (900001,900001,900001,NOW() - INTERVAL 1 HOUR,'CANCELADA'),
 (900002,900001,900001,NOW() - INTERVAL 1 HOUR,'SOLICITADA');
INSERT INTO resultados_procedimiento VALUES
 (900001,900002,900001,NOW(),'Informe ficticio sin contenido clinico');
COMMIT;
""")

        agenda_start = "TIMESTAMP(CURRENT_DATE + INTERVAL 2 DAY,'09:00:00')"
        agenda_end = "TIMESTAMP(CURRENT_DATE + INTERVAL 2 DAY,'09:30:00')"
        self.must_run("Agendar cita válida con sp_agendar_cita",
                      f"CALL sp_agendar_cita(900001,900001,{agenda_start},{agenda_end},"
                      "'VALIDACION-CITA',@nueva_cita);")
        self.expect_value("La cita válida se guardó",
                          "SELECT COUNT(*) FROM citas WHERE motivo='VALIDACION-CITA';", "1")
        self.must_run("Entrada válida de inventario",
                      "CALL sp_registrar_movimiento(900001,900002,NOW(),'ENTRADA',100,"
                      "'Entrada ficticia de pruebas',@movimiento);")
        self.expect_value("Stock después de la entrada",
                          "SELECT stock FROM v_stock_lotes WHERE lote_id=900001;", "100")
        self.must_run("Primera entrega parcial válida",
                      "CALL sp_dispensar(900001,1,900001,4,900002,NOW(),@entrega);")
        self.must_run("Segunda entrega parcial válida",
                      "CALL sp_dispensar(900001,1,900001,3,900002,NOW(),@entrega);")
        self.expect_value("Stock luego de entregar 4 y 3 unidades",
                          "SELECT stock FROM v_stock_lotes WHERE lote_id=900001;", "93")
        self.expect_value("Receta parcialmente dispensada: quedan 3 unidades",
                          "SELECT cantidad_pendiente FROM v_recetas_pendientes "
                          "WHERE receta_id=900001 AND renglon=1;", "3")
        self.must_run("Pago parcial válido",
                      "CALL sp_registrar_pago(900001,NOW(),25,'EFECTIVO','VALIDACION-PAGO',@pago);")
        self.expect_value("Saldo después del abono",
                          "SELECT saldo FROM v_facturas_saldo WHERE factura_id=900001;", "175.00")
        assign_start = "(SELECT fecha_ingreso + INTERVAL 10 MINUTE FROM hospitalizaciones WHERE hospitalizacion_id=900001)"
        self.must_run("Primera asignación válida",
                      f"SET @inicio={assign_start}; CALL sp_asignar_camilla(900001,900001,@inicio,@asignacion);")
        self.expect_value("La camilla está ocupada",
                          "SELECT disponibilidad FROM v_camillas_estado WHERE camilla_id=900001;", "OCUPADA")

        direct_tests = [
            ("PK duplicada", "INSERT INTO departamentos VALUES(900001,'OTRO-CODIGO','Otro nombre');", (1062,)),
            ("FK a paciente inexistente", "INSERT INTO contactos_emergencia(paciente_id,nombre,parentesco,telefono) VALUES(4290000000,'Ficticio','Prueba','Prueba');", (1452,)),
            ("CHECK de prioridad positiva", "INSERT INTO contactos_emergencia(paciente_id,nombre,parentesco,telefono,prioridad) VALUES(900001,'Ficticio','Prueba','Prueba',0);", (3819,)),
            ("Consulta con paciente distinto de la cita", "INSERT INTO consultas(cita_id,paciente_id,medico_id,tipo,motivo) SELECT cita_id,900002,900001,'PROGRAMADA','Prueba inválida' FROM citas WHERE motivo='VALIDACION-CITA';", (1452,)),
            ("Póliza de otro paciente", "INSERT INTO facturas(folio,paciente_id,poliza_id) VALUES('VALIDACION-POL-INVALIDA',900001,900001);", (1452,)),
            ("Médico con puesto incorrecto", "INSERT INTO medicos VALUES(900004,'VALIDACION-CED-INVALIDA');", (1644,)),
            ("Consulta: identidad inmutable", "UPDATE consultas SET paciente_id=900002 WHERE consulta_id=900001;", (1644,)),
            ("Receta: consulta inmutable", "UPDATE recetas SET consulta_id=900002 WHERE receta_id=900001;", (1644,)),
            ("Factura emitida: no insertar conceptos", "INSERT INTO factura_detalle(factura_id,renglon,descripcion,cantidad,precio_unitario) VALUES(900001,2,'Prueba',1,10);", (1644,)),
            ("Factura emitida: no modificar conceptos", "UPDATE factura_detalle SET precio_unitario=1 WHERE factura_id=900001;", (1644,)),
            ("Factura emitida: no borrar conceptos", "DELETE FROM factura_detalle WHERE factura_id=900001;", (1644,)),
            ("Factura emitida: no reabrir", "UPDATE facturas SET estado='ABIERTA' WHERE factura_id=900001;", (1644,)),
            ("Factura con pagos: no anular", "UPDATE facturas SET estado='ANULADA' WHERE factura_id=900001;", (1644,)),
            ("Factura vacía: no emitir", "UPDATE facturas SET estado='EMITIDA' WHERE factura_id=900002;", (1644,)),
            ("Factura nueva: debe iniciar abierta", "INSERT INTO facturas(folio,paciente_id,estado) VALUES('VALIDACION-EMITIDA-INVALIDA',900001,'EMITIDA');", (1644,)),
            ("Pago: no modificar historial", "UPDATE pagos SET monto=1 WHERE factura_id=900001;", (1644,)),
            ("Pago: no borrar historial", "DELETE FROM pagos WHERE factura_id=900001;", (1644,)),
            ("Receta dispensada: indicaciones inmutables", "UPDATE receta_detalle SET cantidad_prescrita=1 WHERE receta_id=900001 AND renglon=1;", (1644,)),
            ("Entrega: cantidad inmutable", "UPDATE dispensacion_detalle SET cantidad=1 WHERE receta_id=900001 AND renglon=1;", (1644,)),
            ("Movimiento: cantidad igual a entrega", "INSERT INTO movimientos_inventario(lote_id,dispensacion_detalle_id,personal_id,fecha,tipo,cantidad,motivo) SELECT lote_id,dispensacion_detalle_id,900002,NOW(),'SALIDA',-1,'Prueba inválida' FROM dispensacion_detalle WHERE receta_id=900001 AND renglon=1 ORDER BY dispensacion_detalle_id LIMIT 1;", (1644,)),
            ("Movimiento: no actualizar historial", "UPDATE movimientos_inventario SET cantidad=cantidad+1 WHERE lote_id=900001 AND tipo='ENTRADA';", (1644,)),
            ("Movimiento: no borrar historial", "DELETE FROM movimientos_inventario WHERE lote_id=900001 AND tipo='ENTRADA';", (1644,)),
            ("Resultado de orden cancelada", "INSERT INTO resultados_procedimiento(orden_id,personal_id,fecha_resultado,informe) VALUES(900001,900001,NOW(),'Informe ficticio inválido');", (1644,)),
            ("Orden con resultado: no cancelar", "UPDATE ordenes_procedimiento SET estado='CANCELADA' WHERE orden_id=900002;", (1644,)),
            ("Nota de enfermería con puesto incorrecto", "INSERT INTO notas_enfermeria(hospitalizacion_id,personal_id,observacion) VALUES(900001,900004,'Prueba inválida');", (1644,)),
        ]
        for name, statement, codes in direct_tests:
            self.reject(name, statement, codes)

        routine_tests = [
            ("Cita duplicada", f"CALL sp_agendar_cita(900001,900001,{agenda_start},{agenda_end},'Duplicada',@cita);"),
            ("Cita parcialmente solapada", "CALL sp_agendar_cita(900002,900001,TIMESTAMP(CURRENT_DATE + INTERVAL 2 DAY,'09:15:00'),TIMESTAMP(CURRENT_DATE + INTERVAL 2 DAY,'09:45:00'),'Solapada',@cita);"),
            ("Salida que dejaría inventario negativo", "CALL sp_registrar_movimiento(900001,900002,NOW(),'SALIDA',-94,'Prueba inválida',@movimiento);"),
            ("Entrega que supera lo prescrito", "CALL sp_dispensar(900001,1,900001,4,900002,NOW(),@entrega);"),
            ("Entrega con stock insuficiente", "CALL sp_dispensar(900001,2,900001,100,900002,NOW(),@entrega);"),
            ("Entrega desde lote de otro medicamento", "CALL sp_dispensar(900001,1,900002,1,900002,NOW(),@entrega);"),
            ("Entrega desde lote caducado", "CALL sp_dispensar(900001,1,900003,1,900002,NOW(),@entrega);"),
            ("Camilla ya ocupada", "CALL sp_asignar_camilla(900002,900001,NOW(),@asignacion);"),
            ("Camilla en mantenimiento", "CALL sp_asignar_camilla(900002,900002,NOW(),@asignacion);"),
            ("Asignación anterior al ingreso", "SET @inicio=(SELECT fecha_ingreso - INTERVAL 1 MINUTE FROM hospitalizaciones WHERE hospitalizacion_id=900002); CALL sp_asignar_camilla(900002,900003,@inicio,@asignacion);"),
            ("Pago mayor al saldo", "CALL sp_registrar_pago(900001,NOW(),176,'EFECTIVO','Prueba inválida',@pago);"),
            ("Pago sobre factura abierta", "CALL sp_registrar_pago(900002,NOW(),1,'EFECTIVO','Prueba inválida',@pago);"),
        ]
        for name, statement in routine_tests:
            self.reject(name, statement, (1644,), routine=True)

        # Recepción hace tres días y receta hace dos: la fecha de ayer cumple
        # esas reglas, pero precede a los movimientos realizados hoy. Además
        # se comprueba el mensaje exacto para aislar la restricción temporal.
        self.reject(
            "Movimiento retroactivo anterior al último del lote",
            "CALL sp_registrar_movimiento(900001,900002,DATE_SUB(NOW(),INTERVAL 1 DAY),"
            "'SALIDA',-1,'Movimiento ficticio retroactivo',@movimiento);",
            (1644,), routine=True,
            expected_message="Los movimientos del lote deben registrarse cronologicamente")
        self.reject(
            "Entrega retroactiva anterior al último movimiento del lote",
            "CALL sp_dispensar(900001,1,900001,1,900002,"
            "DATE_SUB(NOW(),INTERVAL 1 DAY),@entrega);",
            (1644,), routine=True,
            expected_message="La entrega no puede preceder al ultimo movimiento del lote")

        self.must_run("Traslado válido entre camillas",
                      "SET @traslado=(SELECT fecha_ingreso + INTERVAL 30 MINUTE FROM hospitalizaciones WHERE hospitalizacion_id=900001); CALL sp_asignar_camilla(900001,900003,@traslado,@asignacion);")
        self.expect_value("Traslado: primera asignación cerrada y segunda abierta",
                          "SELECT CONCAT(SUM(fin IS NOT NULL),':',SUM(fin IS NULL)) "
                          "FROM asignaciones_camilla WHERE hospitalizacion_id=900001;", "1:1")
        self.must_run("Alta hospitalaria válida",
                      "CALL sp_alta_hospitalaria(900001,NOW(),'Cierre ficticio de pruebas');")
        self.expect_value("El alta cierra la estancia y libera la camilla",
                          "SELECT COUNT(*) FROM hospitalizaciones h WHERE hospitalizacion_id=900001 "
                          "AND fecha_alta IS NOT NULL AND NOT EXISTS (SELECT 1 FROM asignaciones_camilla a "
                          "WHERE a.hospitalizacion_id=h.hospitalizacion_id AND a.fin IS NULL);", "1")
        self.reject("Estancia cerrada: no asignar camilla",
                    "CALL sp_asignar_camilla(900001,900001,NOW(),@asignacion);", (1644,), routine=True)

        concurrent_start = "TIMESTAMP(CURRENT_DATE + INTERVAL 3 DAY,'15:00:00')"
        concurrent_end = "TIMESTAMP(CURRENT_DATE + INTERVAL 3 DAY,'15:30:00')"
        self.concurrent_one_success(
            "Dos citas simultáneas: solo una se registra",
            f"CALL sp_agendar_cita(900002,900005,{concurrent_start},{concurrent_end},"
            "'VALIDACION-CITA-CONCURRENTE',@cita);")
        self.expect_value("Concurrencia de citas: una fila final",
                          "SELECT COUNT(*) FROM citas WHERE motivo='VALIDACION-CITA-CONCURRENTE';", "1")
        self.must_run("Stock inicial para prueba simultánea",
                      "CALL sp_registrar_movimiento(900004,900002,NOW(),'ENTRADA',10,'Prueba simultánea',@movimiento);")
        self.concurrent_one_success(
            "Dos salidas simultáneas de 7 con stock 10: solo una se acepta",
            "CALL sp_registrar_movimiento(900004,900002,NOW(),'SALIDA',-7,'Prueba simultánea',@movimiento);")
        self.expect_value("Concurrencia de stock: saldo final 3",
                          "SELECT stock FROM v_stock_lotes WHERE lote_id=900004;", "3")

    def concurrent_one_success(self, name: str, statement: str) -> None:
        barrier = Barrier(2)

        def execute() -> subprocess.CompletedProcess:
            barrier.wait(timeout=15)
            return self.sql(statement)

        with ThreadPoolExecutor(max_workers=2) as pool:
            futures = [pool.submit(execute) for _ in range(2)]
            results = [future.result(timeout=120) for future in futures]
        successes = sum(result.returncode == 0 for result in results)
        rejections = sum(result.returncode != 0 and self.error_code(result) == 1644
                         for result in results)
        self.record(name, "concurrencia", successes == 1 and rejections == 1,
                    f"Operaciones aceptadas: {successes}; rechazos de negocio: {rejections}.")

    def cleanup(self) -> dict:
        if not getattr(self, "owns_database", False):
            return {"correcta": True, "detalle": "No se creó una base temporal."}
        if not TEMP_DATABASE.fullmatch(self.database):
            return {"correcta": False, "detalle": "Limpieza bloqueada por identificador no permitido."}
        result = self.sql(f"DROP DATABASE IF EXISTS `{self.database}`;", use_database=False)
        return {"correcta": result.returncode == 0,
                "detalle": "Base temporal eliminada." if result.returncode == 0 else
                "No se pudo eliminar la base temporal de esta ejecución.",
                "error_mysql": self.error_code(result)}


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--mysql", default="mysql", help="Ruta del cliente mysql; admite espacios.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=3306)
    parser.add_argument("--user", required=True)
    parser.add_argument("--output", type=Path, help="Archivo JSON opcional con los resultados.")
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error("--port debe estar entre 1 y 65535.")
    database = "hospital_prueba_" + uuid.uuid4().hex
    runner = Runner(args, database)
    report = {"proyecto": "Hospital universitario", "base_temporal": database,
              "inicio_utc": utc_now(), "servidor": {"host": args.host, "port": args.port}}
    try:
        runner.load_project(Path(__file__).resolve().parent)
        runner.check_demo()
        runner.check_fixtures()
        runner.check_balances("Estado final")
    except ValidationError as exc:
        runner.record("Ejecución completa", "entorno", False, str(exc))
    except Exception as exc:
        # No serializar excepciones arbitrarias: podrían contener parámetros
        # del entorno o SQL. El tipo basta para localizar un fallo del validador.
        runner.record("Ejecución completa", "entorno", False,
                      f"Fallo inesperado del validador: {type(exc).__name__}.")
    finally:
        try:
            cleanup = runner.cleanup()
        except Exception:
            cleanup = {"correcta": False,
                       "detalle": "No se pudo completar la limpieza de la base temporal propia."}
        report["limpieza"] = cleanup
    passed = sum(item["correcta"] for item in runner.results)
    failed = len(runner.results) - passed
    ok = failed == 0 and cleanup["correcta"]
    report.update({"fin_utc": utc_now(), "estado": "APROBADO" if ok else "FALLIDO",
                   "resumen": {"total": len(runner.results), "correctas": passed,
                               "fallidas": failed}, "pruebas": runner.results})
    content = json.dumps(report, ensure_ascii=False, indent=2)
    if args.output:
        try:
            args.output.write_text(content + "\n", encoding="utf-8")
        except OSError:
            print("No se pudo escribir el archivo --output.", file=sys.stderr)
            print(content)
            return 1
    print(content)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
