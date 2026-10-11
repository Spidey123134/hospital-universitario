"""Comprueba la demostracion y la fusion del equipo en dos bases UUID propias.

Usa solamente la biblioteca estandar y el cliente mysql. Ejemplo:
python validar_datos_ampliados.py --mysql C:/MySQL/bin/mysql.exe --user root \
    --port 3306 --output VALIDACION_DATOS_AMPLIADOS.json
Las credenciales, si hacen falta, se heredan de MYSQL_PWD, nunca se imprimen.
No carga ni modifica hospital_universitario. Elimina solo las bases creadas
con UUID por esta ejecucion. Requiere permisos CREATE/DROP DATABASE.
"""
from pathlib import Path
import argparse
import csv
import hashlib
import json
import re
import uuid
from validar_proyecto import Runner, TABLES, ValidationError, utc_now

ROOT=Path(__file__).resolve().parent
EXPECTED=dict(zip(TABLES,[8,16,25,18,19,30,31,5,18,9,15,54,45,8,40,9,11,12,21,15,4,16,40,64,11,22,38,8,29,15,29,60,24,6,7,7]))

def load_csv(name):
    with (ROOT/'aporte_equipo'/name).open(encoding='utf-8-sig',newline='') as file:
        return list(csv.DictReader(file))

def quote(text): return "'"+str(text).replace("'","''")+"'"

def source(name,database):
    sql=(ROOT/name).read_text(encoding='utf-8-sig')
    sql=re.sub(r'\bhospital_universitario\b',database,sql,flags=re.I)
    directives=re.findall(r'\b(?:USE|(?:CREATE|DROP)\s+(?:DATABASE|SCHEMA))\s+(?:(?:IF\s+NOT\s+EXISTS|IF\s+EXISTS)\s+)?`?([A-Za-z0-9_]+)`?',sql,re.I)
    if any(x.lower()!=database for x in directives):
        raise ValidationError('Un script apunta fuera de la base UUID propia.')
    return sql

def counts(runner):
    result=runner.sql(' UNION ALL '.join(f"SELECT '{t}',COUNT(*) FROM `{t}`" for t in TABLES)+';')
    if result.returncode: raise ValidationError('No se pudieron contar las tablas.')
    return {t:int(n) for t,n in (row.split('\t') for row in result.stdout.strip().splitlines())}

def snapshot(runner):
    result={}
    for table in TABLES:
        output=runner.sql(f'SELECT * FROM `{table}`;')
        if output.returncode: raise ValidationError('No se pudo comparar el contenido completo.')
        # El orden de lectura no esta garantizado: ordenar las filas completas.
        result[table]=hashlib.sha256('\n'.join(sorted(output.stdout.splitlines())).encode('utf-8')).hexdigest()
    return result

def verify(r):
    r.expect_value('Estructura conservada: 36 tablas',"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_type='BASE TABLE';",'36')
    actual=counts(r)
    for table,n in EXPECTED.items():
        r.record('Registros de '+table,'conteos',actual.get(table)==n,f'Esperados: {n}; obtenidos: {actual.get(table)}.')
    r.record('Total de filas de demostracion','conteos',sum(actual.values())==789,f'Total obtenido: {sum(actual.values())}.')
    r.check_balances('Demostracion fusionada')
    checks=[
        ('Agenda sin citas solapadas',"SELECT COUNT(*) FROM citas a JOIN citas b ON a.cita_id<b.cita_id AND (a.medico_id=b.medico_id OR a.paciente_id=b.paciente_id) AND a.inicio<b.fin AND b.inicio<a.fin WHERE a.estado<>'CANCELADA' AND b.estado<>'CANCELADA';"),
        ('Consultas dentro de su cita',"SELECT COUNT(*) FROM consultas c JOIN citas a USING(cita_id) WHERE c.fecha<a.inicio OR c.fecha>a.fin;"),
        ('Recetas posteriores a su consulta',"SELECT COUNT(*) FROM recetas r JOIN consultas c USING(consulta_id) WHERE r.fecha_prescripcion<c.fecha;"),
        ('Camillas sin ocupaciones solapadas',"SELECT COUNT(*) FROM asignaciones_camilla a JOIN asignaciones_camilla b ON a.asignacion_id<b.asignacion_id AND a.camilla_id=b.camilla_id AND a.inicio<COALESCE(b.fin,'9999-12-31') AND b.inicio<COALESCE(a.fin,'9999-12-31');"),
        ('Asignaciones dentro de la estancia',"SELECT COUNT(*) FROM asignaciones_camilla a JOIN hospitalizaciones h USING(hospitalizacion_id) WHERE a.inicio<h.fecha_ingreso OR (h.fecha_alta IS NOT NULL AND (a.fin IS NULL OR a.fin>h.fecha_alta));"),
        ('Camillas ocupadas operativas',"SELECT COUNT(*) FROM asignaciones_camilla a JOIN camillas c USING(camilla_id) WHERE a.fin IS NULL AND c.estado_operativo<>'OPERATIVA';"),
        ('Notas dentro de la estancia',"SELECT COUNT(*) FROM notas_enfermeria n JOIN hospitalizaciones h USING(hospitalizacion_id) WHERE n.fecha<h.fecha_ingreso OR (h.fecha_alta IS NOT NULL AND n.fecha>h.fecha_alta);"),
        ('Entregas no exceden lo prescrito',"SELECT COUNT(*) FROM v_recetas_pendientes WHERE cantidad_pendiente<0;"),
        ('Entregas posteriores a la receta',"SELECT COUNT(*) FROM dispensaciones d JOIN recetas r USING(receta_id) WHERE d.fecha<r.fecha_prescripcion;"),
        ('Lotes coinciden con medicamento dispensado',"SELECT COUNT(*) FROM dispensacion_detalle d JOIN lotes_medicamento l USING(lote_id) WHERE d.medicamento_id<>l.medicamento_id;"),
        ('Existencias historicas nunca negativas',"SELECT COUNT(*) FROM (SELECT SUM(cantidad) OVER (PARTITION BY lote_id ORDER BY fecha,movimiento_id ROWS UNBOUNDED PRECEDING) AS saldo FROM movimientos_inventario) s WHERE saldo<0;"),
        ('Procedimientos posteriores a consulta',"SELECT COUNT(*) FROM ordenes_procedimiento o JOIN consultas c USING(consulta_id) WHERE o.fecha_solicitud<c.fecha;"),
        ('Resultados posteriores a solicitud',"SELECT COUNT(*) FROM resultados_procedimiento r JOIN ordenes_procedimiento o USING(orden_id) WHERE r.fecha_resultado<o.fecha_solicitud OR o.estado<>'REALIZADA';"),
        ('Pagos posteriores a factura',"SELECT COUNT(*) FROM pagos p JOIN facturas f USING(factura_id) WHERE p.fecha<f.fecha;"),
    ]
    for name,sql in checks: r.expect_value(name,sql,'0')
    r.expect_value('Siete hospitalizaciones abiertas','SELECT COUNT(*) FROM hospitalizaciones WHERE fecha_alta IS NULL;','7')
    r.expect_value('Saldo del ejercicio inicial conservado',"SELECT CONCAT(total,':',pagado,':',saldo) FROM v_facturas_saldo WHERE factura_id=1;",'850.00:500.00:350.00')
    r.expect_value('Existencias iniciales conservadas',"SELECT GROUP_CONCAT(stock ORDER BY lote_id SEPARATOR ':') FROM v_stock_lotes WHERE lote_id<=4;",'92:57:40:50')
    specids=[1,16,4,3,5,6,7,8,9,10,11,12,13,14,15]
    for i,row in enumerate(load_csv('medicos_captura.csv')):
        sql=f"SELECT COUNT(*) FROM medicos m JOIN personal p ON p.personal_id=m.medico_id JOIN medico_especialidad e USING(medico_id) WHERE m.medico_id={int(row['medico_id_destino'])} AND m.cedula_profesional={quote(row['cedula_profesional'])} AND p.nombre={quote(row['nombre'])} AND p.apellido_paterno={quote(row['apellido_paterno'])} AND e.especialidad_id={specids[i]};"
        r.expect_value('Medico del equipo '+row['medico_id_original'],sql,'1','transcripcion')
    for row in load_csv('recetas_captura.csv'):
        sql=f"SELECT COUNT(*) FROM recetas r JOIN consultas c USING(consulta_id) JOIN receta_detalle d USING(receta_id) WHERE r.receta_id={int(row['receta_id_destino'])} AND c.paciente_id={int(row['paciente_id_destino'])} AND c.medico_id={int(row['medico_id_destino'])} AND DATE(r.fecha_prescripcion)={quote(row['fecha_prescripcion'])} AND d.dosis={quote(row['dosis'])} AND d.via_administracion={quote(row['via_administracion'])} AND LOCATE({quote(row['observaciones'])},r.observaciones)>0;"
        r.expect_value('Receta del equipo '+row['receta_id_original'],sql,'1','transcripcion')
    # Ejecutar cada SELECT de la guia y comprobar sus filas de resultado.
    text=re.sub(r'(?m)^\s*--[^\n]*','',source('06_ver_datos.sql',r.database))
    queries=[x.strip()+';' for x in text.split(';') if x.strip().upper().startswith('SELECT')]
    expected=[18,30,15,64,15,11,29,8,15,15]
    r.record('Diez consultas para ver datos','consultas',len(queries)==10,f'Consultas encontradas: {len(queries)}.')
    for i,(sql,n) in enumerate(zip(queries,expected),1):
        result=r.sql(sql)
        observed=len(result.stdout.strip().splitlines()) if result.stdout.strip() else 0
        r.record(f'Consulta visual {i}','consultas',result.returncode==0 and observed==n,f'Filas esperadas: {n}; obtenidas: {observed}.',error_code=r.error_code(result))
    r.must_run('Las 20 consultas originales siguen funcionando',source('04_consultas.sql',r.database))
    return actual

def main():
    parser=argparse.ArgumentParser(description=__doc__,formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--mysql',default='mysql'); parser.add_argument('--host',default='127.0.0.1')
    parser.add_argument('--port',type=int,default=3306); parser.add_argument('--user',required=True)
    parser.add_argument('--output',type=Path)
    args=parser.parse_args()
    if not 1<=args.port<=65535: parser.error('Puerto fuera de rango.')
    first=Runner(args,'hospital_prueba_'+uuid.uuid4().hex)
    second=Runner(args,'hospital_prueba_'+uuid.uuid4().hex)
    report={'proyecto':'Hospital universitario: fusion del equipo','inicio_utc':utc_now(),'bases_temporales':[first.database,second.database]}
    cleanup=[]
    try:
        first.load_project(ROOT)
        # El tutorial continua trabajando con esta muestra pequena.
        first.check_demo()
        report['mysql_version']=first.scalar('SELECT VERSION();')
        first.must_run('Ampliacion 05 sobre la muestra existente',source('05_datos_demo_ampliados.sql',first.database),timeout=180)
        report['filas_por_tabla']=verify(first)
        after=snapshot(first)
        retry=first.sql(source('05_datos_demo_ampliados.sql',first.database))
        first.record('Una segunda carga rechaza duplicados','repeticion',retry.returncode!=0 and first.error_code(retry)==1062,'Se detiene en el primer INSERT duplicado.',error_code=first.error_code(retry))
        first.record('La segunda carga no cambia ningun registro','repeticion',snapshot(first)==after,'Comparacion de todas las filas de las 36 tablas.')
        available=second.sql("SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name="+quote(second.database)+';',use_database=False)
        if available.returncode or available.stdout.strip()!='0': raise ValidationError('La segunda base UUID no esta libre.')
        combined=source('hospital_demostracion.sql',second.database)
        second.owns_database=True
        second.must_run('Instalacion nueva con hospital_demostracion.sql',combined,use_database=False,timeout=180)
        first.record('Instalacion nueva y ampliacion producen datos identicos','equivalencia',snapshot(second)==after,'Comparacion completa por tabla, incluidos campos calculados.')
        report['huellas_sha256']={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in ['01_esquema.sql','02_reglas.sql','03_datos_demo.sql','hospital_completo.sql','05_datos_demo_ampliados.sql','hospital_demostracion.sql','06_ver_datos.sql','generar_datos_ampliados.py','validar_datos_ampliados.py','aporte_equipo/medicos_captura.csv','aporte_equipo/recetas_captura.csv']}
        report['filas_iniciales']=143; report['filas_agregadas']=646; report['filas_totales']=789
    except ValidationError as exc:
        first.record('Ejecucion completa','entorno',False,str(exc))
    except Exception as exc:
        first.record('Ejecucion completa','entorno',False,'Fallo inesperado: '+type(exc).__name__)
    finally:
        for runner in [first,second]:
            try: cleanup.append(runner.cleanup())
            except Exception: cleanup.append({'correcta':False,'detalle':'No se pudo completar la limpieza propia.'})
    checks=first.results+second.results
    passed=sum(x['correcta'] for x in checks)
    ok=passed==len(checks) and all(x['correcta'] for x in cleanup)
    report.update(fin_utc=utc_now(),estado='APROBADO' if ok else 'FALLIDO',resumen={'total':len(checks),'correctas':passed,'fallidas':len(checks)-passed},limpieza=cleanup,pruebas=checks)
    content=json.dumps(report,ensure_ascii=False,indent=2)+'\n'
    if args.output: args.output.write_text(content,encoding='utf-8')
    print(json.dumps({'estado':report['estado'],'resumen':report['resumen'],'fallos':[x for x in checks if not x['correcta']]},ensure_ascii=True))
    return 0 if ok else 1

if __name__=='__main__': raise SystemExit(main())
