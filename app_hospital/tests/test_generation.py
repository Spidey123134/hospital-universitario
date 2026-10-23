"""La carga inicial también debe rechazar relleno antes de regenerar SQL."""
from unittest import TestCase

import generar_datos_ampliados as generator


class InitialDataTests(TestCase):
    def test_rejects_placeholders_in_initial_insert_values(self):
        for text in ('Domicilio fictio', 'dato ficticio', 'placeholder',
                     'Por completar', 'Por definir', 'Paciente de prueba'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                generator.validate_initial("INSERT INTO pacientes VALUES ('" + text + "');")

    def test_allows_medical_test_names_and_global_academic_comments(self):
        generator.validate_initial(
            "-- Datos ficticios para el proyecto\n"
            "/* Demostración académica */ INSERT INTO procedimientos VALUES ('Prueba de glucosa');"
        )

    def test_comment_symbols_inside_a_value_do_not_hide_placeholder(self):
        for value in ('Calle -- placeholder', 'Calle # por definir', 'Nota /* ficticio */'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                generator.validate_initial("INSERT INTO pacientes VALUES ('" + value + "');")

    def test_double_quoted_values_are_also_checked(self):
        with self.assertRaises(ValueError):
            generator.validate_initial('INSERT INTO pacientes VALUES ("dato ficticio");')

    def test_escaped_quotes_do_not_hide_following_text(self):
        for source in ("INSERT INTO a VALUES ('O''Brien placeholder');",
                       "INSERT INTO a VALUES ('O\\'Brien por completar');"):
            with self.subTest(source=source), self.assertRaises(ValueError):
                generator.validate_initial(source)

    def test_malformed_source_is_rejected_before_writing_files(self):
        for source in ("INSERT INTO a VALUES ('sin cerrar);", '/* sin cerrar'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                generator.validate_initial(source)
