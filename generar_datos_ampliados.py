"""Regenera las cargas de 143 y 789 registros sin modificar la documentación.

Los lotes de inserción y sus textos completos se mantienen en
datos/carga_ampliada.json. Los CSV del aporte del equipo siguen siendo la fuente
de sus 15 nombres/cédulas y de las dosis, vías y observaciones de sus 15 recetas.
Este programa escribe archivos; nunca se conecta ni modifica MySQL.
"""
from __future__ import annotations

from collections import Counter
import csv
import json
from pathlib import Path
import re
import unicodedata

ROOT = Path(__file__).resolve().parent
BAD_VALUE = re.compile(
    r"ficti(?:ci|ti|o\b)|simulad|placeholder|demostraci|did[aá]ctic|acad[eé]mic|docente|inventad|"
    r"(?:^|[\W_])(?:demo|dummy|tbd|xxx)(?:$|[\W_])|\bmarcador\b|"
    r"\b(?:dato|texto|domicilio|direcci[oó]n|nombre|nota|registro|paciente|medicamento) de prueba\b|"
    r"\bpor (?:completar|definir|llenar)\b|"
    r"TEL-(?:PAC-|CON-|ASEG-|PROV-)?|example\.invalid|"
    r"ver texto de dosis|\bAPORTE EQUIPO\b|\bpaciente fuente\b|\bcamilla fuente\b",
    re.I,
)


def capture(name):
    with (ROOT / "aporte_equipo" / name).open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def lit(value):
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("\\", "\\\\").replace("'", "''") + "'"


def normalize(text):
    return "".join(char for char in unicodedata.normalize("NFKD", text) if not unicodedata.combining(char)).casefold()


def sql_strings(source):
    """Lee literales sin confundir comentarios SQL con datos almacenados."""
    index = 0
    while index < len(source):
        char = source[index]
        if source.startswith('/*', index):
            end = source.find('*/', index + 2)
            if end < 0:
                raise ValueError('Comentario SQL incompleto en la carga inicial.')
            index = end + 2
            continue
        if char == '#' or (source.startswith('--', index)
                           and (index + 2 == len(source) or source[index + 2].isspace())):
            end = source.find('\n', index)
            index = len(source) if end < 0 else end + 1
            continue
        if char not in "'\"`":
            index += 1
            continue
        delimiter, value = char, []
        index += 1
        while index < len(source):
            char = source[index]
            if char == '\\' and index + 1 < len(source):
                value.append(source[index + 1])
                index += 2
                continue
            if char == delimiter:
                if index + 1 < len(source) and source[index + 1] == delimiter:
                    value.append(char)
                    index += 2
                    continue
                index += 1
                break
            value.append(char)
            index += 1
        else:
            raise ValueError('Literal SQL incompleto en la carga inicial.')
        if delimiter != '`':
            yield ''.join(value)


def validate_initial(source):
    for value in sql_strings(source):
        if BAD_VALUE.search(value):
            raise ValueError('Texto de relleno rechazado en 03_datos_demo.sql: ' + value[:100])


def find_row(batches, table, keys):
    matches = []
    for batch in batches:
        if batch["kind"] != "insert" or batch["table"] != table:
            continue
        indices = {column: index for index, column in enumerate(batch["columns"])}
        for row in batch["rows"]:
            if all(row[indices[column]] == key for column, key in keys.items()):
                matches.append((row, indices))
    if len(matches) != 1:
        raise ValueError("El aporte requiere una fila única en " + table + ": " + str(keys))
    return matches[0]


def use_team_sources(batches):
    doctors = capture("medicos_captura.csv")
    recipes = capture("recetas_captura.csv")
    if len(doctors) != 15 or len(recipes) != 15:
        raise ValueError("El aporte actual debe conservar sus 15 médicos y 15 recetas; revise los CSV y el modelo antes de ampliarlo.")
    for doctor in doctors:
        doctor_id = int(doctor["medico_id_destino"])
        row, columns = find_row(batches, "personal", {"personal_id": doctor_id})
        row[columns["nombre"]] = doctor["nombre"]
        row[columns["apellido_paterno"]] = doctor["apellido_paterno"]
        row, columns = find_row(batches, "medicos", {"medico_id": doctor_id})
        row[columns["cedula_profesional"]] = doctor["cedula_profesional"]
    for recipe in recipes:
        recipe_id = int(recipe["receta_id_destino"])
        row, columns = find_row(batches, "recetas", {"receta_id": recipe_id})
        row[columns["observaciones"]] = recipe["observaciones"]
        row, columns = find_row(batches, "receta_detalle", {"receta_id": recipe_id, "renglon": 1})
        row[columns["dosis"]] = recipe["dosis"]
        row[columns["via_administracion"]] = recipe["via_administracion"]


def validate(batches):
    counts = Counter()
    for batch in batches:
        if batch.get("kind") == "statement":
            if not re.fullmatch(r"UPDATE facturas SET estado\s*=\s*'EMITIDA' WHERE factura_id BETWEEN 5 AND 24", batch["sql"], re.I):
                raise ValueError("Instrucción de actualización no prevista en la carga ampliada.")
            continue
        if batch.get("kind") != "insert" or not re.fullmatch(r"[a-z_]+", batch["table"]):
            raise ValueError("Lote de carga inválido.")
        for row in batch["rows"]:
            if len(row) != len(batch["columns"]):
                raise ValueError("Cantidad incorrecta de valores en " + batch["table"])
            for column, value in zip(batch["columns"], row):
                if isinstance(value, str) and BAD_VALUE.search(value):
                    raise ValueError("Texto genérico rechazado en " + batch["table"] + "." + column + ": " + value[:100])
        counts[batch["table"]] += len(batch["rows"])
    if sum(counts.values()) != 646:
        raise ValueError("La ampliación debe conservar 646 filas; revise los cambios del archivo JSON.")
    return counts


def sql_batch(batch):
    if batch["kind"] == "statement":
        return batch["sql"] + ";\n"
    return ("INSERT INTO " + batch["table"] + " (" + ", ".join(batch["columns"]) + ") VALUES\n  "
            + ",\n  ".join("(" + ", ".join(lit(value) for value in row) + ")" for row in batch["rows"]) + ";\n")


def generate():
    payload = json.loads((ROOT / "datos/carga_ampliada.json").read_text(encoding="utf-8-sig"))
    if payload.get("version") != 1 or payload.get("rows_added") != 646:
        raise ValueError("La versión del archivo de carga ampliada no es compatible.")
    batches = payload["batches"]
    use_team_sources(batches)
    additions = validate(batches)
    initial_source = (ROOT / '03_datos_demo.sql').read_text(encoding='utf-8-sig')
    validate_initial(initial_source)
    header = ("-- CARGA AMPLIADA DEL HOSPITAL UNIVERSITARIO.\n"
              "-- Conjunto académico con identidades y operaciones inventadas, sin datos de pacientes reales.\n"
              "-- Agrega 646 registros a los 143 de 03_datos_demo.sql. Ejecutar una sola vez.\n"
              "-- Los CSV de aporte_equipo conservan la transcripción y procedencia del trabajo del equipo.\n"
              "-- Detenerse ante el primer error; no ejecutar COMMIT si falla un INSERT.\n"
              "SET NAMES utf8mb4;\nUSE hospital_universitario;\nSTART TRANSACTION;\n\n")
    expanded = header + "\n".join(map(sql_batch, batches)) + "\nCOMMIT;\n"
    core_header = ("-- INSTALACIÓN INICIAL: estructura, reglas y 143 registros.\n"
                   "-- Conjunto académico con datos inventados; no corresponde a pacientes reales.\n")
    core = core_header + "\n\n".join(
        [(ROOT / name).read_text(encoding="utf-8-sig") for name in ('01_esquema.sql', '02_reglas.sql')]
        + [initial_source])
    combined_header = ("-- INSTALACIÓN COMPLETA CON 789 REGISTROS EN 36 TABLAS.\n"
                       "-- Ejecutar una sola vez en una base nueva; no ejecutar también hospital_completo.sql.\n")
    # Validar todo antes de reemplazar los tres archivos reproducibles.
    for name, text in (("hospital_completo.sql", core), ("05_datos_demo_ampliados.sql", expanded),
                       ("hospital_demostracion.sql", combined_header + core + "\n\n" + expanded)):
        (ROOT / name).write_text(text, encoding="utf-8")
    print(json.dumps({"filas_agregadas": sum(additions.values()), "por_tabla": additions}, ensure_ascii=False))


if __name__ == "__main__":
    generate()
