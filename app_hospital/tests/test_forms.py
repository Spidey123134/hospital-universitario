"""Pruebas de formularios y conexión sin servidor MySQL.

Ejecutar: python -m unittest app_hospital.tests.test_forms -v
Requieren Tk disponible; no abren cuadros de diálogo ni guardan configuración.
"""
from __future__ import annotations

from datetime import date, datetime, time
from decimal import Decimal
from unittest import TestCase, main
from unittest.mock import Mock, patch

from app_hospital import main as ui


def field(name="dato", kind="varchar", **changes):
    value = {
        "name": name,
        "label": "Dato de práctica",
        "data_type": kind,
        "column_type": kind,
        "nullable": False,
        "required": True,
        "default": None,
        "enum_values": [],
    }
    value.update(changes)
    return value


class DataFormTests(TestCase):
    def setUp(self):
        self.root = ui.tk.Tk()
        self.root.withdraw()
        self.addCleanup(self.root.destroy)

    def form(self, fields, initial=None, options=None):
        form = ui.DataForm(self.root, fields, options or (lambda _field, _search: []), initial)
        form.pack()
        self.addCleanup(form.destroy)
        return form

    @staticmethod
    def put(form, name, value):
        control = form.controls[name]
        if isinstance(control, ui.ttk.Combobox):
            control.set(value)
        elif isinstance(control, ui.tk.Text):
            control.delete("1.0", "end")
            control.insert("1.0", value)
        else:
            control.delete(0, "end")
            control.insert(0, value)

    def assert_invalid(self, spec, value):
        form = self.form([spec])
        self.put(form, spec["name"], value)
        control = form.controls[spec["name"]]
        with patch.object(control, "focus_set") as focused:
            with self.assertRaises(ValueError) as caught:
                form.values()
            self.assertIn(spec["label"], str(caught.exception))
            focused.assert_called_once()

    def test_boolean_uses_readonly_yes_no_options_and_numeric_values(self):
        form = self.form([field("activo", "tinyint", column_type="tinyint(1)")])
        widget = form.controls["activo"]
        self.assertIsInstance(widget, ui.ttk.Combobox)
        self.assertEqual(str(widget.cget("state")), "readonly")
        self.assertEqual(tuple(widget.cget("values")), ("No", "Sí"))
        for label, expected in (("No", 0), ("Sí", 1)):
            with self.subTest(label=label):
                self.put(form, "activo", label)
                self.assertEqual(form.values()["activo"], expected)

    def test_boolean_default_is_shown_as_label(self):
        for default, label in (("0", "No"), (1, "Sí")):
            with self.subTest(default=default):
                form = self.form([field("activo", "tinyint", column_type="tinyint(1)", default=default)])
                self.assertEqual(form.controls["activo"].get(), label)
                self.assertEqual(form.values()["activo"], int(default))

    def test_nullable_boolean_can_clear_existing_value(self):
        spec = field("activo", "tinyint", column_type="tinyint(1)", nullable=True, required=False)
        form = self.form([spec], initial={"activo": 1})
        self.assertIn("", tuple(form.controls["activo"].cget("values")))
        self.assertEqual(form.controls["activo"].get(), "Sí")
        self.put(form, "activo", "")
        self.assertEqual(form.values(), {"activo": None})

    def test_integer_without_boolean_width_keeps_numeric_entry(self):
        form = self.form([field("prioridad", "tinyint", column_type="tinyint unsigned")])
        self.assertNotIsInstance(form.controls["prioridad"], ui.ttk.Combobox)
        self.put(form, "prioridad", "3")
        self.assertEqual(int(form.values()["prioridad"]), 3)

    def test_missing_required_value_names_and_focuses_field(self):
        self.assert_invalid(field("nombre", label="Nombre del paciente"), "  ")

    def test_blank_default_is_omitted_on_creation(self):
        form = self.form([field("fecha_registro", "datetime", required=False, default="CURRENT_TIMESTAMP")])
        self.put(form, "fecha_registro", "")
        self.assertEqual(form.values(), {})

    def test_blank_optional_value_is_omitted_on_creation(self):
        form = self.form([field("telefono", nullable=True, required=False)])
        self.assertEqual(form.values(), {})

    def test_blank_optional_value_clears_value_on_edit(self):
        form = self.form([field("telefono", nullable=True, required=False)], {"telefono": "5512345678"})
        self.put(form, "telefono", "")
        self.assertEqual(form.values(), {"telefono": None})

    def test_valid_calendar_date_is_accepted(self):
        form = self.form([field("nacimiento", "date")])
        self.put(form, "nacimiento", "2004-02-29")
        self.assertIn(form.values()["nacimiento"], ("2004-02-29", date(2004, 2, 29)))

    def test_invalid_calendar_dates_are_explained_before_save(self):
        for value in ("2026-02-29", "2026-04-31", "19/10/2026"):
            with self.subTest(value=value):
                self.assert_invalid(field("nacimiento", "date", label="Fecha de nacimiento"), value)

    def test_valid_datetime_and_time_are_accepted(self):
        cases = (
            (field("inicio", "datetime"), "2026-10-19 10:35:00", datetime(2026, 10, 19, 10, 35)),
            (field("hora", "time"), "15:20:00", time(15, 20)),
        )
        for spec, text, converted in cases:
            with self.subTest(kind=spec["data_type"]):
                form = self.form([spec])
                self.put(form, spec["name"], text)
                self.assertIn(form.values()[spec["name"]], (text, converted))

    def test_invalid_datetime_and_time_are_explained_before_save(self):
        for kind, value in (("datetime", "2026-10-19 25:00:00"), ("datetime", "2026-02-30 12:00:00"), ("time", "25:00:00"), ("time", "3pm")):
            with self.subTest(kind=kind, value=value):
                self.assert_invalid(field("horario", kind, label="Horario de atención"), value)

    def test_valid_decimal_is_accepted(self):
        form = self.form([field("precio", "decimal")])
        self.put(form, "precio", "350.50")
        self.assertEqual(Decimal(str(form.values()["precio"])), Decimal("350.50"))

    def test_non_finite_and_malformed_decimals_are_rejected(self):
        for value in ("NaN", "Infinity", "-Infinity", "350,50", "$350.50"):
            with self.subTest(value=value):
                self.assert_invalid(field("precio", "decimal", label="Precio unitario"), value)

    def test_integer_rejects_fraction_exponent_and_words(self):
        for value in ("1.5", "1e2", "uno"):
            with self.subTest(value=value):
                self.assert_invalid(field("cantidad", "int", label="Cantidad solicitada"), value)

    def test_text_at_maximum_length_is_accepted(self):
        form = self.form([field("nombre", max_length=5)])
        self.put(form, "nombre", "Lucía")
        self.assertEqual(form.values(), {"nombre": "Lucía"})

    def test_text_above_maximum_length_names_and_focuses_field(self):
        self.assert_invalid(field("nombre", max_length=5, label="Nombre del paciente"), "Daniela")

    def test_enum_must_match_a_list_option(self):
        self.assert_invalid(field("sexo", "enum", enum_values=["F", "M", "NO_ESPECIFICADO"], label="Sexo registrado"), "OTRO_TEXTO")

    def test_reference_is_saved_as_identifier_and_never_as_label(self):
        spec = field("paciente_id", "int", reference={"table": "pacientes", "column": "paciente_id"})
        form = self.form([spec], options=lambda _field, _search: [(37, "Daniela Serrano · EXP-0037")])
        self.put(form, "paciente_id", "37 · Daniela Serrano · EXP-0037")
        self.assertEqual(form.values(), {"paciente_id": 37})

    def test_multiline_text_is_preserved(self):
        form = self.form([field("observacion", "text")])
        self.put(form, "observacion", "Primera línea.\nSegunda línea.")
        self.assertEqual(form.values(), {"observacion": "Primera línea.\nSegunda línea."})


class ConnectionAndCancelTests(TestCase):
    def setUp(self):
        self.dialogs = []
        self.patches = [
            patch.object(ui.HospitalApp, "_read_config", return_value={}),
            patch.object(ui.HospitalApp, "_save_config"),
            patch.object(ui.messagebox, "showinfo", side_effect=lambda title, text, **_kwargs: self.dialogs.append(text)),
            patch.object(ui.messagebox, "showerror", side_effect=lambda title, text, **_kwargs: self.dialogs.append(text)),
        ]
        for mock_patch in self.patches:
            mock_patch.start()
            self.addCleanup(mock_patch.stop)
        self.app = ui.HospitalApp()
        self.app.withdraw()
        self.addCleanup(self.app.destroy)

    def run_connection(self, result):
        service = Mock()
        service.test_connection.return_value = result
        def inline_run(_label, task, callback):
            callback(task())
        with patch.object(ui, "HospitalService", return_value=service), patch.object(self.app, "_run", side_effect=inline_run):
            self.app.test_connection()
        service.test_connection.assert_called_once()
        service.install_demo.assert_not_called()
        return " ".join(self.dialogs + [self.app.status.get()]).lower()

    def test_existing_compatible_database_instructs_to_open_it(self):
        text = self.run_connection({"database_exists": True, "compatible": True, "table_count": 36, "missing_tables": [], "version": "8.0"})
        self.assertIn("abrir hospital", text)
        self.assertTrue(any(word in text for word in ("exist", "encontr", "lista", "preparada")), text)

    def test_missing_database_instructs_to_create_it(self):
        text = self.run_connection({"database_exists": False, "compatible": False, "table_count": 0, "missing_tables": ["pacientes"], "version": "8.0"})
        self.assertTrue(any(word in text for word in ("no existe", "todavía no", "aún no")), text)
        self.assertIn("crear", text)

    def test_incompatible_existing_database_warns_before_installing(self):
        text = self.run_connection({"database_exists": True, "compatible": False, "table_count": 34, "missing_tables": ["pacientes", "recetas"], "version": "8.0"})
        self.assertTrue(any(word in text for word in ("faltan", "incomplet", "compatible", "no contiene")), text)
        self.assertTrue(any(word in text for word in ("otro nombre", "revis", "conserv")), text)

    def test_cancel_new_record_does_not_call_create_or_update(self):
        service = Mock()
        service.settings = self.app._settings()
        self.app.service = service
        self.app.catalog = [{"name": "pacientes", "label": "Pacientes", "module": "Pacientes", "can_create": True, "can_update": True}]
        self.app.current_table = "pacientes"
        self.app.metadata["pacientes"] = [field("nombre", editable_create=True, editable_update=True)]
        self.app.new_record()
        form = self.app.active_form
        window = self.app.active_form_window
        self.assertTrue(window.winfo_exists())
        form.close()
        self.assertFalse(window.winfo_exists())
        service.create.assert_not_called()
        service.update.assert_not_called()


if __name__ == "__main__":
    main()
