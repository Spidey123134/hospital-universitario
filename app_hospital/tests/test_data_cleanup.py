"""Pruebas de preservación y recuperación de la actualización de textos.

No conectan con MySQL ni leen credenciales. La prueba con servidor y el respaldo
completo se ejecutan aparte sobre una copia UUID de la base del proyecto.
"""
from __future__ import annotations

import copy
import json
from contextlib import ExitStack
from datetime import date
from decimal import Decimal
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import TestCase, main
from unittest.mock import MagicMock, Mock, patch

from app_hospital import data_cleanup as cleanup
from app_hospital.db import ServiceError, Settings, expected_structure


def entry(table="pacientes", keys=None, field="domicilio", old="Domicilio ficticio 1", new="Calle Robles 17, Colonia Centro"):
    return {"table": table, "keys": keys or {"paciente_id": 1},
            "fields": {field: {"value": new, "source_sha256": [cleanup._digest(old)]}}}


def plan(*changes):
    return {"version": "unidad-v1", "changes": list(changes)}


def snapshot(table="pacientes", row=None):
    result = {table: {} for table in cleanup.TABLES}
    if row:
        result[table][tuple(row[k] for k in cleanup.PRIMARY_KEYS[table])] = row
    return result


class PlanTests(TestCase):
    def load(self, payload):
        with TemporaryDirectory() as folder:
            source = Path(folder) / "plan.json"
            source.write_text(json.dumps(payload), encoding="utf-8")
            with patch.object(cleanup, "PLAN_PATH", source):
                return cleanup._load_plan()

    def test_accepts_versioned_exact_hash_plan(self):
        payload = plan(entry())
        self.assertEqual(self.load(payload), payload)

    def test_rejects_names_outside_catalog_and_wrong_primary_keys(self):
        for table, keys in (("mysql.user", {"paciente_id": 1}), ("pacientes", {"otro_id": 1}),
                            ("pacientes", {"paciente_id": "1"}), ("pacientes", {"paciente_id": True})):
            with self.subTest(table=table, keys=keys), self.assertRaises(ServiceError):
                self.load(plan(entry(table, keys)))

    def test_rejects_duplicate_rows_and_malformed_source_hash(self):
        with self.assertRaises(ServiceError):
            self.load(plan(entry(), entry()))
        bad = entry()
        bad["fields"]["domicilio"]["source_sha256"] = ["not-a-sha256"]
        with self.assertRaises(ServiceError):
            self.load(plan(bad))

    def test_rejects_sql_in_field_names_and_embedded_nul(self):
        with self.assertRaises(ServiceError):
            self.load(plan(entry(field="domicilio; DROP DATABASE x")))
        with self.assertRaises(ServiceError):
            self.load(plan(entry(new="Calle\x00Robles")))

    def test_rejects_numeric_enum_generated_fk_and_primary_columns(self):
        for field_type, generated, foreign, name in (("int", "", False, "numero"),
                ("enum", "", False, "estado"), ("varchar", "algo", False, "calculado"),
                ("varchar", "", True, "referencia"), ("varchar", "", False, "paciente_id")):
            with self.subTest(kind=field_type, name=name), self.assertRaises(ServiceError):
                cleanup._validate_fields(plan(entry(field=name)),
                    {"pacientes": {name: {"data_type": field_type, "generated": generated, "max_length": 250}}},
                    {"pacientes": {name} if foreign else set()})

    def test_rejects_text_that_does_not_fit_column(self):
        with self.assertRaises(ServiceError):
            cleanup._validate_fields(plan(entry()),
                {"pacientes": {"domicilio": {"data_type": "varchar", "generated": "", "max_length": 5}}},
                {"pacientes": set()})


class PreservationTests(TestCase):
    def test_duration_correction_is_restricted_and_does_not_touch_team_recipes(self):
        change = entry('receta_detalle', {'receta_id': 5, 'renglon': 1},
                       'duracion_dias', old='4', new=2)
        loaded = PlanTests().load(plan(change))
        row = {'receta_id': 5, 'renglon': 1, 'medicamento_id': 5, 'duracion_dias': 4}
        pending, report = cleanup._pending(loaded, snapshot('receta_detalle', row))
        self.assertEqual(report['cells'], 1)
        self.assertEqual(pending[0]['fields']['duracion_dias'], 2)
        for recipe_id, target in ((26, 2), (5, 3), (5, True), (5, 0)):
            bad = entry('receta_detalle', {'receta_id': recipe_id, 'renglon': 1},
                        'duracion_dias', old='4', new=target)
            with self.subTest(recipe_id=recipe_id, target=target), self.assertRaises(ServiceError):
                PlanTests().load(plan(bad))

    def test_duration_correction_preserves_custom_duration_and_changed_medicine(self):
        change = entry('receta_detalle', {'receta_id': 5, 'renglon': 1},
                       'duracion_dias', old='4', new=2)
        for duration, medicine in ((3, 5), (4, 1)):
            row = {'receta_id': 5, 'renglon': 1, 'medicamento_id': medicine,
                   'duracion_dias': duration}
            pending, report = cleanup._pending(plan(change), snapshot('receta_detalle', row))
            self.assertEqual(pending, [])
            self.assertEqual(report['skipped_cells'], 1)

    def test_only_exact_original_changes_and_team_edits_survive(self):
        change = entry()
        initial = snapshot(row={"paciente_id": 1, "domicilio": "Domicilio ficticio 1"})
        pending, report = cleanup._pending(plan(change), initial)
        self.assertEqual((report["cells"], report["rows"], report["skipped_cells"]), (1, 1, 0))
        self.assertEqual(pending[0]["old"]["domicilio"], "Domicilio ficticio 1")
        initial["pacientes"][(1,)]["domicilio"] = "Domicilio ficticio 1 modificado por el equipo"
        pending, report = cleanup._pending(plan(change), initial)
        self.assertEqual(pending, [])
        self.assertEqual(report["skipped_cells"], 1)

    def test_hash_is_exact_with_accents_case_and_spaces(self):
        change = entry(old="Observación pendiente")
        for actual in ("Observacion pendiente", "observación pendiente", "Observación pendiente "):
            with self.subTest(actual=actual):
                pending, report = cleanup._pending(plan(change), snapshot(row={"paciente_id": 1, "domicilio": actual}))
                self.assertEqual(pending, [])
                self.assertEqual(report["skipped_cells"], 1)

    def test_second_application_is_zero_and_missing_row_not_inserted(self):
        change = entry()
        pending, report = cleanup._pending(plan(change), snapshot(row={"paciente_id": 1, "domicilio": change["fields"]["domicilio"]["value"]}))
        self.assertEqual((pending, report["cells"], report["already_complete"]), ([], 0, 1))
        pending, report = cleanup._pending(plan(change), snapshot())
        self.assertEqual((pending, report["missing_rows"]), ([], 1))

    def test_mixed_row_changes_original_field_without_touching_personalized_field(self):
        change = entry()
        change["fields"]["nombre"] = {"value": "Daniela", "source_sha256": [cleanup._digest("Paciente Uno")]}
        before = snapshot(row={"paciente_id": 1, "domicilio": "Domicilio ficticio 1", "nombre": "Mi paciente"})
        pending, report = cleanup._pending(plan(change), before)
        self.assertEqual(set(pending[0]["fields"]), {"domicilio"})
        self.assertEqual((report["cells"], report["skipped_cells"]), (1, 1))

    def test_expected_snapshot_preserves_all_numerics_dates_and_input(self):
        before = snapshot(row={"paciente_id": 1, "domicilio": "Domicilio ficticio 1",
                               "fecha_nacimiento": date(2000, 1, 1), "peso": Decimal("65.50"), "activo": 1})
        untouched = copy.deepcopy(before)
        changes, _ = cleanup._pending(plan(entry()), before)
        after = cleanup._expected_after(before, changes)
        self.assertEqual(before, untouched)
        self.assertEqual(after["pacientes"][(1,)]["peso"], Decimal("65.50"))
        self.assertEqual(after["pacientes"][(1,)]["fecha_nacimiento"], date(2000, 1, 1))
        self.assertEqual(after["pacientes"][(1,)]["activo"], 1)


class RecoveryTests(TestCase):
    def test_trigger_contract_rejects_missing_or_additional_rule(self):
        names = expected_structure()[1]["TRIGGER"]
        records = {name: {"ddl": name} for name in names}
        cleanup._require_guards(records)
        records.pop(next(iter(names)))
        with self.assertRaises(ServiceError):
            cleanup._require_guards(records)
        records["unexpected"] = {"ddl": "unknown"}
        with self.assertRaises(ServiceError):
            cleanup._require_guards(records)

    def test_connection_failure_retries_guard_restoration_on_new_connection(self):
        service, original, rescue = Mock(), Mock(), Mock()
        context = MagicMock()
        context.__enter__.return_value = rescue
        service._connection.return_value = context
        with patch.object(cleanup, "_restore_on", side_effect=[ConnectionError(), None]) as restore:
            cleanup._restore_guards(service, original, {"a": {}}, {"a"})
        self.assertEqual(restore.call_count, 2)
        self.assertIs(restore.call_args_list[0].args[0], original)
        self.assertIs(restore.call_args_list[1].args[0], rescue)

    def test_recovery_file_is_exclusive_and_atomic_update_keeps_definitions(self):
        with TemporaryDirectory() as folder:
            file = Path(folder) / "backup.reglas.json"
            record = {"status": "prepared", "triggers": {"a": {"ddl": "CREATE TRIGGER a"}}}
            cleanup._write_record(file, record, exclusive=True)
            with self.assertRaises(ServiceError):
                cleanup._write_record(file, {"overwrite": True}, exclusive=True)
            cleanup._status(file, record, "verified")
            restored = json.loads(file.read_text(encoding="utf-8"))
            self.assertEqual(restored["status"], "verified")
            self.assertEqual(restored["triggers"]["a"]["ddl"], "CREATE TRIGGER a")
            self.assertEqual(list(Path(folder).glob("*.tmp")), [])

    def test_other_connection_is_rejected_before_maintenance(self):
        cursor = Mock()
        cursor.fetchone.return_value = {"n": 1}
        with self.assertRaisesRegex(ServiceError, "Cierre otras"):
            cleanup._other_sessions(cursor, "hospital_universitario")

    def test_cannot_drop_guard_when_account_cannot_restore_its_definer(self):
        cursor = Mock()
        cursor.fetchone.return_value = {"account": "equipo@localhost"}
        cursor.fetchall.return_value = [{"grants": "GRANT SELECT, UPDATE, TRIGGER ON `hospital`.* TO `equipo`@`localhost`"}]
        with self.assertRaisesRegex(ServiceError, "propietario original"):
            cleanup._require_restore_privilege(cursor, {"a": {"definer": "root@localhost"}}, {"a"})

    def test_dml_failure_rolls_back_and_always_restores_attempted_guard(self):
        row = {"movimiento_id": 1, "motivo": "Recepcion ficticia A1", "cantidad": 100}
        before = snapshot("movimientos_inventario", row)
        change = entry("movimientos_inventario", {"movimiento_id": 1}, "motivo", row["motivo"], "Recepción de lote")
        connection, cursor, service = MagicMock(), MagicMock(), MagicMock()
        connection.cursor.return_value.__enter__.return_value = cursor
        service._connection.return_value.__enter__.return_value = connection
        cursor.fetchone.return_value = {"acquired": 1}
        cursor.execute.side_effect = lambda statement, *_: (_ for _ in ()).throw(RuntimeError("DML failure")) if statement.startswith("UPDATE ") else None
        guards = {name: {"ddl": "CREATE TRIGGER " + name} for name in expected_structure()[1]["TRIGGER"]}
        with TemporaryDirectory() as folder, ExitStack() as stack:
            destination = Path(folder) / "backup.json"
            def backup(path):
                Path(path).write_text("{}", encoding="utf-8")
                return {"path": str(path)}
            service.export_backup.side_effect = backup
            for name, value in (("_load_plan", plan(change)), ("HospitalService", service),
                    ("_schema", ({}, {})), ("_validate_fields", None), ("_other_sessions", None),
                    ("_triggers", guards), ("_snapshot", before), ("_backup_matches", True),
                    ("_require_restore_privilege", None)):
                stack.enter_context(patch.object(cleanup, name, return_value=value))
            restore = stack.enter_context(patch.object(cleanup, "_restore_guards"))
            with self.assertRaisesRegex(RuntimeError, "DML failure"):
                cleanup.apply_cleanup(Settings(), destination)
            restore.assert_called_once()
            self.assertEqual(restore.call_args.args[3], {"tr_mov_update"})
            connection.rollback.assert_called()
            record = json.loads(Path(str(destination) + ".reglas.json").read_text(encoding="utf-8"))
            self.assertFalse(record["data_committed"])
            self.assertTrue(record["guards_restored"])
            self.assertEqual(record["status"], "guards_restored_after_rollback")
            self.assertEqual([call.args[0] for call in cursor.execute.call_args_list if call.args[0].startswith("DROP TRIGGER")],
                             ["DROP TRIGGER `hospital_universitario`.`tr_mov_update`"])


if __name__ == "__main__":
    main()
