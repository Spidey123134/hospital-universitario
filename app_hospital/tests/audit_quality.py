"""Revisa contenido y relaciones del conjunto académico, sin escribir en MySQL.

Complementa la búsqueda de marcadores: una frase sin «ficticio» también puede
estar incompleta. No certifica la idoneidad clínica de ningún tratamiento.
"""
from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
import getpass
import hashlib
import json
import os
from pathlib import Path
import re

from app_hospital.catalog import TABLES
from app_hospital.db import HospitalService, PROJECT, Settings, quote
from app_hospital.tests.audit_data import normalized, scan_service


GENERIC = {
    ('consultas', 'notas'): ('Se registraron antecedentes y signos vitales. La valoración y los documentos de atención quedan integrados al expediente.',),
    ('consulta_diagnosticos', 'observaciones'): ('Diagnóstico principal registrado en la consulta.', 'Diagnóstico complementario registrado en el expediente.'),
    ('hospitalizaciones', 'resumen_alta'): ('Alta registrada tras valoración del médico responsable. Resumen de atención integrado al expediente.',),
    ('recetas', 'observaciones'): ('Medicamentos e indicaciones registrados durante la consulta. Receta incorporada al expediente.',),
    ('factura_detalle', 'descripcion'): ('Consulta médica de seguimiento', 'Servicio de diagnóstico y procedimiento', 'Medicamento dispensado en farmacia'),
}


def audit_quality(settings):
    service = HospitalService(settings)
    with service._connection() as conn, conn.cursor() as cursor:
        cursor.execute('START TRANSACTION WITH CONSISTENT SNAPSHOT, READ ONLY')
        try:
            rows = {}
            for table in TABLES:
                cursor.execute('SELECT * FROM ' + quote(table))
                rows[table] = cursor.fetchall()
        finally:
            conn.rollback()
    checks = []
    def check(name, condition, detail=None):
        item = {'nombre': name, 'correcta': bool(condition)}
        if detail is not None:
            item['detalle'] = detail
        checks.append(item)

    marker_audit = scan_service(settings)
    check('Las 36 tablas contienen registros', len(rows) == 36 and all(rows.values()))
    check('No hay marcadores explícitos en los textos', marker_audit['matching_cells'] == 0,
          {'campos_revisados': marker_audit['cells_scanned'], 'coincidencias': marker_audit['matching_cells']})
    generic_counts = {}
    for (table, column), phrases in GENERIC.items():
        count = sum(row[column] in phrases for row in rows[table])
        generic_counts[table + '.' + column] = count
        check('Sin frase genérica anterior en ' + table + '.' + column, count == 0, count)
    notes = [row['notas'] for row in rows['consultas'] if row['consulta_id'] <= 45]
    check('Las notas de las consultas no son una plantilla repetida',
          len(notes) == 45 and len(set(notes)) >= 30, {'notas': len(notes), 'textos_distintos': len(set(notes))})
    incorrect_vitals = [row['consulta_id'] for row in rows['consultas']
                        if all(row[field] is None for field in ('peso_kg', 'talla_cm', 'temperatura_c'))
                        and 'se registraron antecedentes y signos vitales' in normalized(row['notas']).lower()]
    check('No se afirma una captura de signos vitales inexistente', not incorrect_vitals, incorrect_vitals)
    incomplete_results = [row['resultado_id'] for row in rows['resultados_procedimiento']
                          if not row['informe'] or 'documento recibido y registrado' in normalized(row['informe']).lower()]
    check('Los informes contienen resultados y no solo recepción de documentos', not incomplete_results, incomplete_results)
    unspecified_doses = [{'receta_id': row['receta_id'], 'renglon': row['renglon']} for row in rows['receta_detalle']
                         if re.search(r'^\s*segun\s+(?:orden|indicacion)\s+medica\s*$', normalized(row['dosis']), re.I)]
    check('Las dosis no se sustituyen por Según orden médica', not unspecified_doses, unspecified_doses)
    ketorolac_durations = [{'receta_id': row['receta_id'], 'renglon': row['renglon']} for row in rows['receta_detalle']
                          if row['receta_id'] <= 25 and row['medicamento_id'] == 5 and row['duracion_dias'] > 2]
    check('Los ejemplos propios de ketorolaco parenteral no superan dos días', not ketorolac_durations, ketorolac_durations)
    delivered = {}
    for row in rows['dispensacion_detalle']:
        key = row['receta_id'], row['renglon']
        delivered[key] = delivered.get(key, 0) + row['cantidad']
    check('Las cantidades entregadas no superan las prescritas',
          all(delivered.get((row['receta_id'], row['renglon']), 0) <= row['cantidad_prescrita'] for row in rows['receta_detalle']))
    orders = {row['orden_id']: row for row in rows['ordenes_procedimiento']}
    check('Los resultados corresponden a órdenes realizadas',
          all(orders[row['orden_id']]['estado'] == 'REALIZADA' for row in rows['resultados_procedimiento']))
    check('Las altas abiertas conservan resumen nulo y las cerradas tienen resumen',
          all((row['resumen_alta'] is None if row['fecha_alta'] is None else bool(row['resumen_alta']))
              for row in rows['hospitalizaciones']))
    doctors = {row['medico_id']: row for row in rows['medicos']}
    people = {row['personal_id']: row for row in rows['personal']}
    with (PROJECT / 'aporte_equipo/medicos_captura.csv').open(encoding='utf-8-sig', newline='') as file:
        original_doctors = list(csv.DictReader(file))
    check('Se conservan los 15 nombres, apellidos y cédulas del equipo', len(original_doctors) == 15 and all(
        people[int(row['medico_id_destino'])]['nombre'] == row['nombre']
        and people[int(row['medico_id_destino'])]['apellido_paterno'] == row['apellido_paterno']
        and doctors[int(row['medico_id_destino'])]['cedula_profesional'] == row['cedula_profesional']
        for row in original_doctors))
    recipes = {row['receta_id']: row for row in rows['recetas']}
    details = {(row['receta_id'], row['renglon']): row for row in rows['receta_detalle']}
    with (PROJECT / 'aporte_equipo/recetas_captura.csv').open(encoding='utf-8-sig', newline='') as file:
        original_recipes = list(csv.DictReader(file))
    check('Se conservan exactamente las 15 dosis, vías y observaciones del equipo', len(original_recipes) == 15 and all(
        details[(int(row['receta_id_destino']), 1)]['dosis'] == row['dosis']
        and details[(int(row['receta_id_destino']), 1)]['via_administracion'] == row['via_administracion']
        and recipes[int(row['receta_id_destino'])]['observaciones'] == row['observaciones']
        for row in original_recipes))
    passed = sum(item['correcta'] for item in checks)
    return {'fecha_utc': datetime.now(timezone.utc).isoformat(timespec='seconds'),
            'estado': 'APROBADO' if passed == len(checks) else 'FALLIDO',
            'alcance': 'Contenido del conjunto académico y relaciones verificables; no certificación clínica.',
            'tablas': len(rows), 'registros': sum(map(len, rows.values())),
            'campos_textuales_revisados': marker_audit['cells_scanned'],
            'marcadores_explicitos': marker_audit['matching_cells'],
            'frases_genericas_anteriores': generic_counts,
            'resumen': {'total': len(checks), 'correctas': passed, 'fallidas': len(checks) - passed},
            'pruebas': checks,
            'huellas_sha256': {str(path.relative_to(PROJECT)).replace('\\', '/'): hashlib.sha256(path.read_bytes()).hexdigest()
                for path in (Path(__file__), PROJECT/'app_hospital/tests/audit_data.py', PROJECT/'datos/valores_completos.json',
                             PROJECT/'03_datos_demo.sql', PROJECT/'05_datos_demo_ampliados.sql')}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=3306)
    parser.add_argument('--user', required=True)
    parser.add_argument('--database', default='hospital_universitario')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    password = os.environ.get('MYSQL_PWD')
    if password is None:
        password = getpass.getpass('Contraseña de MySQL: ')
    report = audit_quality(Settings(args.host, args.port, args.user, password, args.database))
    output = json.dumps(report, ensure_ascii=False, indent=2, default=str) + '\n'
    if args.output:
        args.output.write_text(output, encoding='utf-8')
    print(output, end='')
    return 0 if report['estado'] == 'APROBADO' else 1


if __name__ == '__main__':
    raise SystemExit(main())
