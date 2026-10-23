"""Marcadores de relleno y mensajes honestos de revisión, sin servidor MySQL.

Ejecutar: python -m unittest app_hospital.tests.test_audit_data -v
No escribe datos ni abre ventanas. Los casos de la interfaz usan servicios falsos.
"""
from __future__ import annotations

from types import SimpleNamespace
from unittest import TestCase, main
from unittest.mock import MagicMock, Mock, patch

from app_hospital import main as ui
from app_hospital.catalog import TABLES
from app_hospital.db import HospitalService, ServiceError
from app_hospital.tests import audit_data as audit


def plan(**changes):
    return {"cells": 0, "rows": 0, "tables": {}, "skipped_cells": 0,
            "missing_rows": 0, **changes}


def report(**changes):
    return {"matching_cells": 0, "cells_scanned": 1696, "examples": [], **changes}


class MarkerTests(TestCase):
    def test_detects_clear_legacy_markers_with_accents_and_case(self):
        for value in ("Domicilio ficticio", "DATO FICTIO", "Paciente ficticia",
                      "texto fictios", "Registro simulado", "Ejemplo didáctico",
                      "De demostración", "Nombre inventado", "DEMO", "Sustancia de prueba A"):
            with self.subTest(value=value):
                self.assertTrue(audit.contains_placeholder(value))

    def test_detects_placeholder_spellings_and_obvious_completion_markers(self):
        for value in ("placeholder", "PLACE HOLDER", "un place-holder", "place_holder",
                      "Domicilio por completar", "por definir", "por llenar",
                      "por capturar", "Pendiente de completar", "pendientes de definir",
                      "Marcador de relleno", "Marcador temporal", "Texto de relleno", "TBD"):
            with self.subTest(value=value):
                self.assertTrue(audit.contains_placeholder(value))

    def test_does_not_treat_valid_clinical_states_or_terms_as_filler(self):
        for value in ("Prueba de glucosa", "Resultado de prueba de glucosa",
                      "Resultado de prueba", "Diagnóstico pendiente", "Resultado pendiente",
                      "Sin alergias", "Marcador tumoral", "Determinación de marcadores tumorales",
                      "Pendiente de valoración por cardiología", "Todo dentro del intervalo de referencia",
                      "Demografía del paciente", "Calle Robles 17", None, ""):
            with self.subTest(value=value):
                self.assertFalse(audit.contains_placeholder(value))

    def test_scanner_is_not_a_clinical_completeness_validator(self):
        self.assertFalse(audit.contains_placeholder("Según orden médica"))
        self.assertFalse(audit.contains_placeholder("Documento recibido y archivado"))


class ReviewMessageTests(TestCase):
    def test_zero_plan_only_claims_known_update_and_marker_audit(self):
        result = audit.cleanup_review_message(plan(), report())
        self.assertFalse(result["warning"])
        self.assertIn("No quedan valores iniciales pendientes de esta actualización", result["message"])
        self.assertIn("1696 campos de texto", result["message"])
        self.assertIn("no comprueba", result["message"])
        self.assertNotIn("Datos completos", result["title"])
        self.assertNotIn("ya están completos", result["status"])

    def test_unknown_markers_with_zero_plan_show_locations_without_value(self):
        result = audit.cleanup_review_message(plan(), report(matching_cells=1, examples=[{
            "table": "pacientes", "column": "domicilio", "primary_key": {"paciente_id": 2},
            "value": "dato fictio que no debe aparecer en el cuadro",
        }]))
        self.assertTrue(result["warning"])
        self.assertIn("1 campo con marcadores", result["message"])
        self.assertIn("pacientes (paciente_id=2): domicilio", result["message"])
        self.assertIn("Registros", result["message"])
        self.assertNotIn("que no debe aparecer", result["message"])

    def test_personalized_fields_are_retained_and_never_declared_complete(self):
        result = audit.cleanup_review_message(plan(skipped_cells=3), report())
        self.assertTrue(result["warning"])
        self.assertIn("Se conservaron 3 campos", result["message"])
        self.assertIn("cambios del equipo", result["message"])
        self.assertIn("campos conservados fuera del plan: 3", result["status"])

    def test_deleted_rows_are_reported_without_reinsertion(self):
        result = audit.cleanup_review_message(plan(missing_rows=2), report())
        self.assertTrue(result["warning"])
        self.assertIn("No se encontraron 2 registros", result["message"])
        self.assertIn("No se volvieron a insertar", result["message"])

    def test_success_reports_actual_changes_and_remaining_markers(self):
        result = audit.cleanup_review_message(plan(cells=6), report(matching_cells=2), applied=True)
        self.assertTrue(result["warning"])
        self.assertIn("Se actualizaron 6 campos reconocidos", result["message"])
        self.assertIn("respaldo", result["message"])
        self.assertIn("2 campos con marcadores", result["message"])

    def test_post_commit_audit_failure_does_not_claim_rollback_or_successful_scan(self):
        result = audit.cleanup_review_message(plan(cells=6), None,
                                             applied=True, audit_error="Conexión interrumpida.")
        self.assertTrue(result["warning"])
        self.assertIn("Los cambios anteriores sí quedaron guardados", result["message"])
        self.assertIn("Conexión interrumpida", result["message"])
        self.assertNotIn("no encontró", result["message"])


class ScanTests(TestCase):
    def service(self, rows):
        service = MagicMock(spec=HospitalService)
        service.settings = SimpleNamespace(database="hospital_universitario")
        metadata = [{"table_name": table, "column_name": name, "data_type": kind,
                     "column_key": "PRI" if name == "id" else ""}
                    for table in TABLES for name, kind in
                    (("id", "int"), ("nota", "varchar"), ("estado", "enum"), ("password_hash", "varchar"))]
        cursor = MagicMock()
        cursor.fetchall.return_value = metadata
        selected = {"rows": []}
        def execute(statement, args=None):
            self.assertTrue(statement.startswith("SELECT "), statement)
            if "information_schema.COLUMNS" in statement:
                self.assertEqual(args, ("hospital_universitario",))
                return
            table = next(t for t in TABLES if " FROM `" + t + "`" in statement)
            selected["rows"] = list(rows.get(table, []))
        def fetchmany(size):
            page = selected["rows"][:size]
            selected["rows"] = selected["rows"][size:]
            return page
        cursor.execute.side_effect = execute
        cursor.fetchmany.side_effect = fetchmany
        service._connection.return_value.__enter__.return_value.cursor.return_value.__enter__.return_value = cursor
        return service, cursor

    def test_scans_every_catalog_table_all_pages_and_redacts_sensitive_values(self):
        rows = {TABLES[0]: [{"id": i, "nota": "Calle Robles 17", "estado": "ACTIVO",
                             "password_hash": None} for i in range(1, 602)],
                TABLES[-1]: [{"id": 1, "nota": "dato fictio", "estado": "ACTIVO",
                              "password_hash": "placeholder-secreto"}]}
        service, cursor = self.service(rows)
        result = audit.scan_service(service)
        self.assertEqual(result["table_count"], 36)
        self.assertEqual(result["tables"][TABLES[0]]["rows"], 601)
        self.assertEqual(result["matching_cells"], 2)
        self.assertEqual(result["cells_scanned"], 1205)
        self.assertEqual(result["estado"], "FALLIDO")
        self.assertEqual(result["examples"][-1]["value"], "[campo sensible omitido]")
        self.assertNotIn("placeholder-secreto", str(result))
        self.assertFalse(service.create.called)
        self.assertEqual(cursor.execute.call_count, 37)

    def test_example_limit_does_not_limit_match_counts_or_scan(self):
        service, _ = self.service({TABLES[0]: [{"id": 1, "nota": "por completar",
                                               "estado": "DEMO", "password_hash": None}]})
        result = audit.scan_service(service, max_examples=0)
        self.assertEqual(result["matching_cells"], 2)
        self.assertEqual(result["examples"], [])

    def test_missing_catalog_table_is_an_error_instead_of_clean_result(self):
        service, cursor = self.service({})
        cursor.fetchall.return_value = []
        with self.assertRaises(ServiceError):
            audit.scan_service(service)

    def test_example_limit_must_be_nonnegative_integer(self):
        service, _ = self.service({})
        for limit in (-1, 1.2, "2"):
            with self.subTest(limit=limit), self.assertRaises(ValueError):
                audit.scan_service(service, max_examples=limit)


class CleanupButtonTests(TestCase):
    def app(self):
        app = Mock()
        app.read_only = False
        app._require_service.return_value = SimpleNamespace(settings=object())
        app._run.side_effect = lambda label, task, callback: callback(task())
        return app

    def test_zero_plan_audits_and_warns_for_unrecognized_marker_without_backup(self):
        app = self.app()
        with patch("app_hospital.data_cleanup.preview_cleanup", return_value=plan()), \
                patch("app_hospital.data_cleanup.apply_cleanup") as apply, \
                patch.object(audit, "scan_service", return_value=report(matching_cells=1)) as scan, \
                patch.object(ui.filedialog, "asksaveasfilename") as backup, \
                patch.object(ui.messagebox, "showwarning") as warning, \
                patch.object(ui.messagebox, "showinfo") as info:
            ui.HospitalApp.complete_project_data(app)
        scan.assert_called_once()
        warning.assert_called_once()
        self.assertIn("marcadores de relleno", warning.call_args.args[1])
        self.assertFalse(info.called or backup.called or apply.called)

    def test_zero_plan_preserves_personalized_fields_and_reports_them(self):
        app = self.app()
        with patch("app_hospital.data_cleanup.preview_cleanup", return_value=plan(skipped_cells=4)), \
                patch.object(audit, "scan_service", return_value=report()), \
                patch.object(ui.messagebox, "showwarning") as warning:
            ui.HospitalApp.complete_project_data(app)
        self.assertIn("Se conservaron 4 campos", warning.call_args.args[1])

    def test_apply_rechecks_all_text_after_confirmed_known_update(self):
        app = self.app()
        pending = plan(cells=2, rows=1, tables={"pacientes": {}})
        with patch("app_hospital.data_cleanup.preview_cleanup", return_value=pending), \
                patch("app_hospital.data_cleanup.apply_cleanup", return_value=pending) as apply, \
                patch.object(audit, "scan_service", side_effect=[report(matching_cells=3), report(matching_cells=1)]) as scan, \
                patch.object(ui.filedialog, "asksaveasfilename", return_value="backup.hospital.json"), \
                patch.object(ui.messagebox, "askyesno", return_value=True), \
                patch.object(ui.messagebox, "showwarning") as warning:
            ui.HospitalApp.complete_project_data(app)
        self.assertEqual(scan.call_count, 2)
        apply.assert_called_once_with(app._require_service.return_value.settings, "backup.hospital.json")
        self.assertIn("Se actualizaron 2 campos reconocidos", warning.call_args.args[1])
        self.assertIn("1 campo con marcadores", warning.call_args.args[1])
        app.load_records.assert_called_once()

    def test_scan_failure_after_saved_update_is_presented_as_review_pending(self):
        app = self.app()
        pending = plan(cells=2, rows=1, tables={"pacientes": {}})
        with patch("app_hospital.data_cleanup.preview_cleanup", return_value=pending), \
                patch("app_hospital.data_cleanup.apply_cleanup", return_value=pending), \
                patch.object(audit, "scan_service", side_effect=[report(), ServiceError("Sin conexión")]), \
                patch.object(ui.filedialog, "asksaveasfilename", return_value="backup.hospital.json"), \
                patch.object(ui.messagebox, "askyesno", return_value=True), \
                patch.object(ui.messagebox, "showwarning") as warning:
            ui.HospitalApp.complete_project_data(app)
        self.assertEqual(warning.call_args.args[0], "Datos guardados; revisión pendiente")
        self.assertIn("sí quedaron guardados", warning.call_args.args[1])
        app.load_records.assert_called_once()


if __name__ == "__main__":
    main()
