r"""Pruebas reales de la interfaz contra MySQL, sin modificar bases del usuario.

Ejemplo (desde propuesta_hospital):
  .venv_app\Scripts\python.exe app_hospital/tests/integration_mysql.py --port 33087 --user root

Solo crea y elimina una base hospital_prueba_<UUID> de esta ejecucion.
La contrasena se toma de MYSQL_PWD, no de argumentos ni archivos del proyecto.
Requiere CREATE/DROP DATABASE y CREATE USER en la instancia de pruebas.
La cuenta SELECT efímera se elimina al terminar su prueba. No usar datos reales.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from decimal import Decimal
import hashlib
import importlib.metadata
import json
import os
import re
import secrets
from pathlib import Path
import sys
import traceback
import uuid

import pymysql

APP = Path(__file__).resolve().parents[1]
PROJECT = APP.parent
sys.path.insert(0, str(PROJECT))
from app_hospital.db import HospitalService, ServiceError, Settings


def utc():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


class IntegrationQA:
    def __init__(self, args):
        self.args = args
        self.database = 'hospital_prueba_' + uuid.uuid4().hex
        self.checks = []
        self.owns_database = False
        self.additional_databases = set()
        self.expected = json.loads((PROJECT / 'VALIDACION_DATOS_AMPLIADOS.json').read_text(encoding='utf-8'))['filas_por_tabla']
        self.connection = pymysql.connect(host=args.host, port=args.port, user=args.user,
            password=os.environ.get('MYSQL_PWD', ''), charset='utf8mb4', autocommit=True,
            cursorclass=pymysql.cursors.DictCursor)
        self.settings = Settings(args.host, args.port, args.user, os.environ.get('MYSQL_PWD', ''), self.database)
        self.service = HospitalService(self.settings)
        self.original_before = self.snapshot_original()
        self.initial_counts = None
        self.report_data = {'inicio_utc': utc(), 'base_temporal': self.database,
            'mysql_version': self.scalar('SELECT VERSION()'),
            'python_version': sys.version.split()[0],
            'pymysql_version': importlib.metadata.version('PyMySQL')}

    def sql(self, sql, values=None):
        with self.connection.cursor() as cursor:
            cursor.execute(sql, values)
            return cursor.fetchall()

    def scalar(self, sql, values=None):
        rows = self.sql(sql, values)
        return next(iter(rows[0].values())) if rows else None

    def value(self, sql, values=None):
        return self.scalar(sql.replace('@DB@', '`' + self.database + '`'), values)

    def rows(self, table, where='', values=None):
        return self.sql('SELECT * FROM `' + self.database + '`.`' + table + '` ' + where, values)

    def record(self, label, ok, detail=''):
        self.checks.append({'prueba': label, 'correcta': bool(ok), 'detalle': str(detail)})
        if not ok:
            print('FALLO:', label, detail)

    def check(self, label, value, expected=True):
        self.record(label, value == expected, f'Esperado: {expected}; obtenido: {value}')
        return value

    def reject(self, label, operation):
        try:
            operation()
        except ServiceError as error:
            self.record(label, True, str(error))
            return True
        except Exception as error:
            self.record(label, False, 'Error tecnico sin traducir: ' + type(error).__name__)
            return False
        self.record(label, False, 'La operacion fue aceptada.')
        return False

    def flow(self, name, **values):
        return self.service.run_workflow(name, values)

    def snapshot_original(self):
        return self.snapshot_database('hospital_universitario')

    def snapshot_database(self, database):
        present = self.scalar('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name=%s', (database,))
        if not present:
            return {'existia': False}
        names = self.sql("SELECT table_name FROM information_schema.tables WHERE table_schema=%s AND table_type='BASE TABLE' ORDER BY table_name", (database,))
        fingerprint = {}
        for item in names:
            name = item['TABLE_NAME'] if 'TABLE_NAME' in item else item['table_name']
            rows = self.sql('SELECT * FROM `' + database + '`.`' + name + '`')
            canonical = sorted(json.dumps(row, sort_keys=True, default=str, ensure_ascii=False) for row in rows)
            fingerprint[name] = hashlib.sha256('\n'.join(canonical).encode('utf-8')).hexdigest()
        return {'existia': True, 'huellas_tablas': fingerprint}

    def install_and_browse(self):
        self.check('Conexion antes de instalar: la base no existe', self.service.test_connection()['database_exists'], False)
        self.owns_database = True
        self.sql('CREATE DATABASE `' + self.database + '`')
        self.reject('Instalador tambien protege una base existente vacia', self.service.install_demo)
        self.check('Base vacia preexistente no recibe tablas sin permiso', self.scalar("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=%s", (self.database,)), 0)
        self.sql('DROP DATABASE `' + self.database + '`')
        installed = self.service.install_demo(personalized=False)
        self.record('Instalacion desde un boton sin cliente SQL externo', isinstance(installed, dict), 'Respuesta de instalacion recibida.')
        self.check('Conexion despues de instalar: 36 tablas', self.service.test_connection()['table_count'], 36)
        self.initial_counts = self.service.counts()
        self.check('Conteos de las 36 tablas coinciden con la demostracion', self.initial_counts, self.expected)
        self.check('Todas las tablas tienen registros', all(n > 0 for n in self.initial_counts.values()))
        self.check('Total inicial: 789 registros', sum(self.initial_counts.values()), 789)
        self.reject('Instalador rechaza sobrescribir una base existente', self.service.install_demo)
        self.check('Reinstalacion rechazada conserva todos los conteos', self.service.counts(), self.initial_counts)
        tables = self.service.tables()
        self.check('Catalogo contiene las 36 tablas', set(t['name'] for t in tables), set(self.expected))
        for table in tables:
            name = table['name']
            result = self.service.browse(name, limit=3)
            self.record('Lectura paginada de ' + name,
                result['total'] == self.expected[name] and len(result['rows']) == min(3, self.expected[name])
                and bool(result['columns']), 'Conteo y primeras filas correctos.')
            columns = self.service.columns(name)
            self.record('Metadatos de formulario de ' + name, bool(columns)
                and all('editable_create' in c and 'editable_update' in c for c in columns), 'Campos de creacion y edicion identificados.')
        patients = self.service.browse('pacientes', limit=5, offset=5)
        self.check('Paginacion respeta limite y desplazamiento', len(patients['rows']), 5)
        first = self.service.browse('pacientes', limit=5)
        self.check('Segunda pagina contiene otras claves', set(x['paciente_id'] for x in patients['rows']).isdisjoint(x['paciente_id'] for x in first['rows']))
        options = self.service.fk_options('contactos_emergencia', 'paciente_id')
        self.check('Combobox de pacientes muestra 30 opciones', len(options), 30)
        self.check('Combobox muestra nombres ademas del numero', all(len(str(label)) > len(str(value)) for value, label in options))
        self.check('Busqueda de combobox por nombre encuentra registros', bool(self.service.fk_options('contactos_emergencia', 'paciente_id', search='Ana')))
        users=self.service.browse('usuarios')
        hashes={str(row['password_hash']) for row in self.rows('usuarios')}
        visible=json.dumps(users,default=str)
        self.check('Consulta de usuarios oculta los hashes guardados',all(secret not in visible for secret in hashes))
        self.reject('Alta de usuario y hash desde tabla esta bloqueada',lambda:self.service.create('usuarios',{'personal_id':20,'nombre_usuario':'QA','password_hash':'texto sin hash'}))
        self.reject('Identificador de tabla inyectado se rechaza', lambda: self.service.browse('pacientes`; DROP DATABASE mysql;--'))
        self.reject('Identificador de columna inyectado se rechaza', lambda: self.service.fk_options('contactos_emergencia', 'paciente_id`; SELECT 1;--'))
        self.reject('Nombre de base inyectado se rechaza', lambda: HospitalService(Settings(self.args.host, self.args.port, self.args.user, '', 'x`; DROP DATABASE mysql;--')).test_connection())

    def current_data_and_schema(self):
        """La instalación visible al usuario usa los contactos nuevos y reglas completas."""
        name = 'hospital_prueba_' + uuid.uuid4().hex
        self.check('Destino UUID de la version actual esta libre', self.scalar('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name=%s', (name,)), 0)
        self.additional_databases.add(name)
        current = HospitalService(Settings(self.args.host, self.args.port, self.args.user, os.environ.get('MYSQL_PWD', ''), name))
        installed = current.install_demo()
        self.check('Instalacion predeterminada mantiene 789 registros', installed['total_rows'], 789)
        self.check('Contactos personalizados conservan conteos por tabla', current.counts(), self.initial_counts)
        schema = current.validate_schema()
        self.check('Validacion completa comprueba 205 columnas', schema['column_count'], 205)
        self.check('Validacion completa comprueba 6 vistas, 6 procedimientos y 23 triggers',
                   (schema['view_count'], schema['procedure_count'], schema['trigger_count']), (6, 6, 23))
        self.check('Cuenta de pruebas puede comprobar reglas', schema['rules_verified'])
        phone_tables = ('personal', 'pacientes', 'contactos_emergencia', 'aseguradoras', 'proveedores')
        phones = [row['telefono'] for table in phone_tables for row in self.sql('SELECT telefono FROM `' + name + '`.`' + table + '`')]
        emails = [row['email'] for table in ('personal', 'pacientes', 'proveedores') for row in self.sql('SELECT email FROM `' + name + '`.`' + table + '`')]
        self.check('Instalacion desde Python incluye 95 telefonos completos', len(phones), 95)
        self.check('Todos los telefonos tienen diez digitos', all(isinstance(v,str) and re.fullmatch(r'\d{10}',v) for v in phones))
        self.check('Instalacion desde Python incluye 59 correos personalizados', len(emails), 59)
        self.check('Correos usan un dominio de ejemplos y formato correcto', all(isinstance(v,str) and re.fullmatch(r'[a-z0-9]+(?:[._-][a-z0-9]+)*@example\.com',v) for v in emails))
        first_names = ['Elena','Andrés','Gabriela','Laura','Héctor','Verónica','Óscar','Raquel']
        first_staff = self.sql('SELECT personal_id,nombre,email FROM `' + name + '`.personal WHERE personal_id BETWEEN 1 AND 8 ORDER BY personal_id')
        self.check('Personal inicial usa ocho nombres completos de presentacion',[row['nombre'] for row in first_staff],first_names)
        email_names = ['elena','andres','gabriela','laura','hector','veronica','oscar','raquel']
        self.check('Correos personalizados corresponden al nombre del personal',all(row['email'].startswith(expected + '.') for row,expected in zip(first_staff,email_names)))
        doctor_sql = ('SELECT p.personal_id,p.nombre,p.apellido_paterno,m.cedula_profesional FROM `{}`.personal p '
                      'JOIN `{}`.medicos m ON m.medico_id=p.personal_id WHERE m.medico_id BETWEEN 9 AND 23 ORDER BY m.medico_id')
        self.check('Quince medicos del equipo conservan nombres y cedulas', self.sql(doctor_sql.format(name,name)), self.sql(doctor_sql.format(self.database,self.database)))
        changed = {'departamentos','personal','medicos','pacientes','contactos_emergencia','aseguradoras','proveedores',
                   'habitaciones','camillas','polizas','lotes_medicamento','usuarios'}
        baseline = self.snapshot_database(self.database)['huellas_tablas']
        actual = self.snapshot_database(name)['huellas_tablas']
        self.check('Actualizacion conserva 24 tablas de historial y relaciones',
                   {table: digest for table,digest in actual.items() if table not in changed},
                   {table: digest for table,digest in baseline.items() if table not in changed})
        patient_names = {row['nombre'] for row in self.sql('SELECT nombre FROM `' + name + '`.pacientes')}
        for table, key in (('citas','cita_id'), ('consultas','consulta_id'), ('recetas','receta_id'), ('hospitalizaciones','hospitalizacion_id'), ('facturas','factura_id')):
            pairs = current.reference_options(table,key)
            self.record('Lista de ' + table + ' muestra nombres de pacientes', bool(pairs) and any(patient in pairs[0][1] for patient in patient_names), 'Relaciones elegibles por nombre y fecha o estado.')
        lot = current.reference_options('lotes_medicamento','lote_id')[0][1]
        self.check('Lista de lotes identifica medicamento y caducidad', 'Caduca ' in lot and ' | ' in lot)
        expected_beds = {r['camilla_id'] for r in self.sql('SELECT camilla_id FROM `' + name + "`.v_camillas_estado WHERE disponibilidad='DISPONIBLE'")}
        self.check('Operacion solo propone camillas operativas y libres', {key for key,label in current.workflow_options('asignar_camilla','camilla_id')}, expected_beds)
        for workflow, states in (('confirmar_cita', ('PROGRAMADA',)), ('cancelar_cita', ('PROGRAMADA','CONFIRMADA'))):
            expected = {r['cita_id'] for r in self.sql('SELECT cita_id FROM `' + name + '`.citas WHERE estado IN (' + ','.join(['%s']*len(states)) + ')', states)}
            self.check('Lista ' + workflow + ' ofrece solo estados permitidos', {key for key,label in current.workflow_options(workflow,'cita_id')}, expected)
        self.check('Buscador de relaciones admite nombres personalizados', bool(current.reference_options('citas','cita_id',search='Daniela')))
        self.check('Buscador de relaciones conserva texto con apariencia SQL como dato', current.reference_options('citas','cita_id',search="' OR 1=1; --"), [])
        self.sql('ALTER TABLE `' + name + '`.pacientes RENAME COLUMN domicilio TO domicilio_incompatible')
        try:
            self.reject('Validacion rechaza una copia con tabla presente y campo faltante',current.validate_schema)
        finally:
            self.sql('ALTER TABLE `' + name + '`.pacientes RENAME COLUMN domicilio_incompatible TO domicilio')
        for kind, object_name in (('VIEW','v_stock_lotes'),('PROCEDURE','sp_agendar_cita'),('TRIGGER','tr_pago_delete')):
            self.sql('DROP ' + kind + ' `' + name + '`.`' + object_name + '`')
            try:
                self.reject('Validacion rechaza falta de ' + kind.lower(),current.validate_schema)
            finally:
                statement = next(s for s in current._script('02_reglas.sql') if re.match(r'CREATE ' + kind + r'\s+' + re.escape(object_name) + r'\b',s))
                self.sql('USE `' + name + '`')
                self.sql(statement)
        self.check('Estructura reparada de prueba vuelve a ser compatible', current.validate_schema()['rules_verified'])
        # Cuenta efímera y exclusiva de esta prueba; no toca cuentas del equipo.
        account = 'hospital_qa_' + uuid.uuid4().hex[:20]
        account_host = self.scalar("SELECT SUBSTRING_INDEX(USER(),'@',-1)")
        password = secrets.token_urlsafe(28)
        owned_account = False
        try:
            self.sql('CREATE USER %s@%s IDENTIFIED BY %s', (account,account_host,password))
            owned_account = True
            self.sql('GRANT SELECT, SHOW VIEW ON `' + name + '`.* TO %s@%s', (account,account_host))
            reader = HospitalService(Settings(self.args.host,self.args.port,account,password,name))
            status = reader.validate_schema()
            self.check('Cuenta SELECT puede abrir el hospital sin privilegio TRIGGER',status['read_only'])
            self.check('Cuenta SELECT reconoce metadatos de reglas no visibles',status['rules_verified'],False)
            self.check('Cuenta SELECT puede consultar los pacientes',reader.browse('pacientes')['total'],30)
            self.reject('Cuenta SELECT no puede modificar pacientes',lambda:reader.update('pacientes',{'paciente_id':1},{'nombre':'No permitido'}))
            self.check('Intento de cuenta SELECT conserva datos',current.browse('pacientes')['rows'][0]['nombre'],'Daniela')
        finally:
            if owned_account:
                self.sql('DROP USER %s@%s',(account,account_host))

    def crud_and_validation(self):
        values = {'expediente_clinico': 'QA-' + uuid.uuid4().hex[:12], 'nombre': "Ana O'Connor; DROP TABLE pacientes; --",
            'apellido_paterno': 'Prueba', 'fecha_nacimiento': '2000-02-29', 'sexo': 'F'}
        created = self.service.create('pacientes', values)
        self.patient_id = int(created['lastrowid'])
        row = self.rows('pacientes', 'WHERE paciente_id=%s', (self.patient_id,))[0]
        self.check('Alta desde formulario devuelve clave y guarda texto literal con comillas', row['nombre'], values['nombre'])
        self.check('Texto con apariencia SQL no elimina pacientes', self.service.counts()['pacientes'], 31)
        self.check('Busqueda acepta comillas como texto literal', self.service.browse('pacientes', search="O'Connor")['total'], 1)
        changed = self.service.update('pacientes', {'paciente_id': self.patient_id}, {'telefono': '555 010 9999', 'email': 'qa@example.invalid'})
        self.check('Editar actualiza exactamente una fila', changed['affected'], 1)
        self.check('Telefono editado persiste', self.rows('pacientes', 'WHERE paciente_id=%s', (self.patient_id,))[0]['telefono'], '555 010 9999')
        self.reject('Fecha imposible se explica al usuario', lambda: self.service.create('pacientes', {**values, 'expediente_clinico': 'QABADDATE', 'fecha_nacimiento': '2026-02-31'}))
        self.reject('Nacimiento posterior al registro se rechaza', lambda: self.service.create('pacientes', {**values, 'expediente_clinico': 'QAFUTURE', 'fecha_nacimiento': '2099-01-01'}))
        self.reject('Expediente duplicado se rechaza', lambda: self.service.create('pacientes', values))
        self.reject('Campo obligatorio ausente se rechaza', lambda: self.service.create('pacientes', {'expediente_clinico':'QANONAME', 'apellido_paterno':'Prueba', 'fecha_nacimiento':'2000-01-01'}))
        self.reject('Campo obligatorio vacio se rechaza', lambda: self.service.create('pacientes', {**values, 'expediente_clinico':'QAEMPTY', 'nombre':'   '}))
        self.reject('Valor ENUM inexistente se rechaza', lambda: self.service.create('pacientes', {**values, 'expediente_clinico':'QAENUM', 'sexo':'INVALIDO'}))
        self.reject('Referencia a paciente inexistente se rechaza', lambda: self.service.create('contactos_emergencia', {'paciente_id':99999999, 'nombre':'Prueba', 'parentesco':'Familiar', 'telefono':'000', 'prioridad':1}))
        self.reject('Campo desconocido no se convierte en SQL', lambda: self.service.update('pacientes', {'paciente_id':self.patient_id}, {'nombre`=NULL; --':'x'}))
        self.reject('Edicion sin clave no modifica varias filas', lambda: self.service.update('pacientes', {}, {'telefono':'ERROR'}))
        self.reject('Edicion no permite cambiar la clave', lambda: self.service.update('pacientes', {'paciente_id':self.patient_id}, {'paciente_id':5000}))
        self.check('Errores de formulario no insertan pacientes incompletos', self.service.counts()['pacientes'], 31)
        self.reject('Alta directa de pago protegida', lambda: self.service.create('pagos', {'factura_id':1, 'fecha':'2030-06-01 10:00:00', 'monto':1, 'metodo':'EFECTIVO'}))
        self.reject('Alta directa de movimiento protegida', lambda: self.service.create('movimientos_inventario', {'lote_id':1, 'personal_id':6, 'fecha':'2030-06-01 10:00:00', 'tipo':'ENTRADA', 'cantidad':100, 'motivo':'QA'}))
        self.reject('Alta directa de citas protegida', lambda: self.service.create('citas', {'paciente_id':self.patient_id,'medico_id':1,'inicio':'2030-06-01 10:00:00','fin':'2030-06-01 10:30:00','motivo':'QA'}))
        self.reject('Edicion directa de inventario protegida', lambda: self.service.update('movimientos_inventario', {'movimiento_id':1}, {'cantidad':99999}))
        self.reject('Edicion directa de pago protegida', lambda: self.service.update('pagos', {'pago_id':1}, {'monto':99999}))
        self.reject('Alta de clave calculada protegida', lambda: self.service.create('consulta_diagnosticos', {'consulta_id':1,'diagnostico_id':8,'es_principal':0,'diagnostico_principal':1}))
        self.reject('Workflow inexistente se rechaza', lambda: self.flow('sp_fake; DROP TABLE pacientes'))

    def appointments_and_hospital(self):
        self.flow('agendar_cita', paciente_id=self.patient_id, medico_id=1, inicio='2030-06-01 10:00:00', fin='2030-06-01 10:30:00', motivo='Consulta de prueba')
        cita_id = self.value('SELECT cita_id FROM @DB@.citas WHERE paciente_id=%s AND inicio=%s', (self.patient_id,'2030-06-01 10:00:00'))
        self.record('Agendar cita mediante procedimiento devuelve un registro', cita_id is not None, 'Sin SQL introducido por el usuario.')
        self.reject('Cita que solapa al medico se rechaza', lambda: self.flow('agendar_cita', paciente_id=2, medico_id=1, inicio='2030-06-01 10:15:00', fin='2030-06-01 10:45:00', motivo='Solapamiento'))
        self.reject('Cita con fin anterior al inicio se rechaza', lambda: self.flow('agendar_cita', paciente_id=self.patient_id, medico_id=1, inicio='2030-06-01 12:00:00', fin='2030-06-01 11:00:00', motivo='Intervalo invalido'))
        self.flow('confirmar_cita', cita_id=cita_id)
        self.check('Confirmar cita cambia su estado', self.value('SELECT estado FROM @DB@.citas WHERE cita_id=%s', (cita_id,)), 'CONFIRMADA')
        self.consult_id = self.service.create('consultas', {'cita_id':cita_id,'paciente_id':self.patient_id,'medico_id':1,'fecha':'2030-06-01 10:05:00','tipo':'PROGRAMADA','motivo':'Control de prueba'})['lastrowid']
        hosp_id = self.service.create('hospitalizaciones', {'consulta_ingreso_id':self.consult_id,'paciente_id':self.patient_id,'medico_responsable_id':1,'fecha_ingreso':'2030-06-01 10:40:00','motivo':'Estancia de prueba'})['lastrowid']
        available = self.sql('SELECT camilla_id FROM `' + self.database + "`.v_camillas_estado WHERE disponibilidad='DISPONIBLE' ORDER BY camilla_id")
        bed1, bed2 = available[0]['camilla_id'], available[1]['camilla_id']
        self.flow('asignar_camilla', hospitalizacion_id=hosp_id, camilla_id=bed1, inicio='2030-06-01 10:45:00')
        self.check('Asignar camilla crea ocupacion abierta', self.value('SELECT COUNT(*) FROM @DB@.asignaciones_camilla WHERE hospitalizacion_id=%s AND camilla_id=%s AND fin IS NULL', (hosp_id,bed1)), 1)
        self.reject('Camilla en mantenimiento no se asigna', lambda: self.flow('asignar_camilla', hospitalizacion_id=hosp_id, camilla_id=6, inicio='2030-06-01 11:00:00'))
        self.flow('asignar_camilla', hospitalizacion_id=hosp_id, camilla_id=bed2, inicio='2030-06-01 11:00:00')
        self.check('Traslado cierra camilla anterior y conserva historial', self.value('SELECT COUNT(*) FROM @DB@.asignaciones_camilla WHERE hospitalizacion_id=%s', (hosp_id,)), 2)
        self.check('Solo queda una asignacion abierta tras traslado', self.value('SELECT COUNT(*) FROM @DB@.asignaciones_camilla WHERE hospitalizacion_id=%s AND fin IS NULL', (hosp_id,)), 1)
        self.reject('Alta anterior a la estancia se rechaza', lambda: self.flow('alta_hospitalaria', hospitalizacion_id=hosp_id, fecha='2030-05-31 09:00:00', resumen='Prueba'))
        self.flow('alta_hospitalaria', hospitalizacion_id=hosp_id, fecha='2030-06-02 09:00:00', resumen='Alta de prueba')
        self.check('Alta libera todas las camillas de la estancia', self.value('SELECT COUNT(*) FROM @DB@.asignaciones_camilla WHERE hospitalizacion_id=%s AND fin IS NULL', (hosp_id,)), 0)
        self.reject('Alta repetida se rechaza', lambda: self.flow('alta_hospitalaria', hospitalizacion_id=hosp_id, fecha='2030-06-02 10:00:00', resumen='Repetida'))
        self.reject('Asignar camilla a estancia cerrada se rechaza', lambda: self.flow('asignar_camilla', hospitalizacion_id=hosp_id, camilla_id=bed1, inicio='2030-06-03 10:00:00'))
        self.flow('agendar_cita', paciente_id=self.patient_id, medico_id=1, inicio='2030-06-03 10:00:00', fin='2030-06-03 10:30:00', motivo='Cita para cancelar')
        cancel_id = self.value('SELECT cita_id FROM @DB@.citas WHERE paciente_id=%s AND inicio=%s', (self.patient_id,'2030-06-03 10:00:00'))
        self.flow('cancelar_cita', cita_id=cancel_id)
        self.check('Cancelar cita conserva historial y cambia estado', self.value('SELECT estado FROM @DB@.citas WHERE cita_id=%s', (cancel_id,)), 'CANCELADA')
        self.reject('Confirmar una cita cancelada se rechaza', lambda: self.flow('confirmar_cita', cita_id=cancel_id))

    def tutorial_example(self):
        """Reproduce los valores de la guia para principiantes desde el servicio."""
        patient=self.service.create('pacientes',{'expediente_clinico':'UNI-PRUEBA-001','nombre':'Daniela','apellido_paterno':'Prueba','fecha_nacimiento':'2004-05-20','sexo':'F'})['lastrowid']
        self.service.create('contactos_emergencia',{'paciente_id':patient,'nombre':'Madre de Daniela','parentesco':'Madre','telefono':'555 010 0000','prioridad':1})
        self.check('Tutorial: alta de Daniela y contacto de emergencia',self.value('SELECT COUNT(*) FROM @DB@.contactos_emergencia WHERE paciente_id=%s',(patient,)),1)
        self.flow('agendar_cita',paciente_id=patient,medico_id=1,inicio='2026-11-02 10:00:00',fin='2026-11-02 10:30:00',motivo='Ejercicio del tutorial')
        self.check('Tutorial: cita del 2 de noviembre creada',self.value('SELECT COUNT(*) FROM @DB@.citas WHERE paciente_id=%s AND inicio=%s',(patient,'2026-11-02 10:00:00')),1)
        consult=self.service.create('consultas',{'paciente_id':patient,'medico_id':1,'fecha':'2026-11-02 11:00:00','tipo':'URGENCIA','motivo':'Ejemplo para aprender'})['lastrowid']
        self.check('Tutorial: consulta de urgencia sin cita',self.value('SELECT cita_id IS NULL FROM @DB@.consultas WHERE consulta_id=%s',(consult,)),1)
        prescription=self.service.create('recetas',{'consulta_id':consult,'fecha_prescripcion':'2026-11-02 11:05:00','observaciones':'Ejemplo ficticio del tutorial'})['lastrowid']
        self.service.create('receta_detalle',{'receta_id':prescription,'renglon':1,'medicamento_id':4,'dosis':'Dosis simulada','frecuencia':'Ejemplo simulado','duracion_dias':1,'via_administracion':'Simulada','cantidad_prescrita':1})
        self.check('Tutorial: receta con un medicamento simulado',self.value('SELECT cantidad_pendiente FROM @DB@.v_recetas_pendientes WHERE receta_id=%s AND renglon=1',(prescription,)),1)
        invoice=self.service.create('facturas',{'folio':'UNI-COBRO-001','paciente_id':patient,'fecha':'2026-11-02 12:00:00'})['lastrowid']
        self.service.create('factura_detalle',{'factura_id':invoice,'renglon':1,'descripcion':'Servicio de demostracion','cantidad':1,'precio_unitario':'100.00'})
        self.flow('emitir_factura',factura_id=invoice)
        self.flow('registrar_pago',factura_id=invoice,fecha='2026-11-02 12:10:00',monto='40.00',metodo='EFECTIVO',referencia='Ejercicio')
        self.check('Tutorial: factura de 100 menos abono de 40 deja 60',self.value('SELECT saldo FROM @DB@.v_facturas_saldo WHERE factura_id=%s',(invoice,)),Decimal('60.00'))
        hospital=self.service.create('hospitalizaciones',{'consulta_ingreso_id':consult,'paciente_id':patient,'medico_responsable_id':1,'fecha_ingreso':'2026-11-02 11:30:00','motivo':'Estancia ficticia de demostracion'})['lastrowid']
        bed=self.value("SELECT MIN(camilla_id) FROM @DB@.v_camillas_estado WHERE disponibilidad='DISPONIBLE'")
        self.flow('asignar_camilla',hospitalizacion_id=hospital,camilla_id=bed,inicio='2026-11-02 11:35:00')
        self.flow('alta_hospitalaria',hospitalizacion_id=hospital,fecha='2026-11-02 13:00:00',resumen='Fin del ejercicio ficticio')
        self.check('Tutorial: alta cierra estancia y libera camilla',self.value('SELECT COUNT(*) FROM @DB@.asignaciones_camilla WHERE hospitalizacion_id=%s AND fin IS NULL',(hospital,)),0)

    def pharmacy(self):
        drug = self.service.create('medicamentos', {'codigo':'QA-'+uuid.uuid4().hex[:10], 'principio_activo':'Compuesto de prueba','concentracion':'10 mg simulados','presentacion':'Caja de prueba','unidad_inventario':'Unidad simulada','stock_minimo':2})['lastrowid']
        lot = self.service.create('lotes_medicamento', {'medicamento_id':drug,'proveedor_id':1,'numero_lote':'QA-LOTE','fecha_recepcion':'2029-01-01','fecha_caducidad':'2031-12-31','costo_unitario':'12.50'})['lastrowid']
        self.flow('registrar_movimiento', lote_id=lot, personal_id=6, fecha='2030-06-01 09:00:00', tipo='ENTRADA', cantidad=20, motivo='Entrada de prueba')
        self.check('Entrada de almacen suma existencias', self.value('SELECT stock FROM @DB@.v_stock_lotes WHERE lote_id=%s', (lot,)), 20)
        self.reject('Salida que deja stock negativo se rechaza', lambda: self.flow('registrar_movimiento', lote_id=lot, personal_id=6, fecha='2030-06-01 09:05:00', tipo='SALIDA', cantidad=-21, motivo='Prueba'))
        self.reject('Movimiento anterior al ultimo registro se rechaza', lambda: self.flow('registrar_movimiento', lote_id=lot, personal_id=6, fecha='2030-05-31 09:00:00', tipo='ENTRADA', cantidad=1, motivo='Prueba'))
        self.reject('Personal ajeno a farmacia no mueve inventario', lambda: self.flow('registrar_movimiento', lote_id=lot, personal_id=1, fecha='2030-06-01 09:10:00', tipo='ENTRADA', cantidad=1, motivo='Prueba'))
        prescription = self.service.create('recetas', {'consulta_id':self.consult_id,'fecha_prescripcion':'2030-06-01 10:10:00','observaciones':'Receta de prueba de interfaz'})['lastrowid']
        self.service.create('receta_detalle', {'receta_id':prescription,'renglon':1,'medicamento_id':drug,'dosis':'Dosis simulada','frecuencia':'Ejemplo academico','duracion_dias':1,'via_administracion':'Simulada','cantidad_prescrita':5})
        self.flow('dispensar', receta_id=prescription, renglon=1, lote_id=lot, cantidad=3, personal_id=6, fecha='2030-06-01 12:00:00')
        self.check('Entrega registra cabecera y detalle relacionados', self.value('SELECT COUNT(*) FROM @DB@.dispensacion_detalle WHERE receta_id=%s AND renglon=1 AND cantidad=3', (prescription,)), 1)
        self.check('Entrega resta existencias del lote', self.value('SELECT stock FROM @DB@.v_stock_lotes WHERE lote_id=%s', (lot,)), 17)
        self.check('Receta conserva dos unidades pendientes', self.value('SELECT cantidad_pendiente FROM @DB@.v_recetas_pendientes WHERE receta_id=%s AND renglon=1', (prescription,)), 2)
        snapshot = {t:self.service.counts()[t] for t in ['dispensaciones','dispensacion_detalle','movimientos_inventario']}
        self.reject('Entrega superior a lo recetado se rechaza', lambda: self.flow('dispensar', receta_id=prescription, renglon=1, lote_id=lot, cantidad=3, personal_id=6, fecha='2030-06-01 12:05:00'))
        self.check('Entrega rechazada revierte cabecera detalle y movimiento', {t:self.service.counts()[t] for t in snapshot}, snapshot)
        self.reject('Lote de otro medicamento no se entrega', lambda: self.flow('dispensar', receta_id=prescription, renglon=1, lote_id=1, cantidad=1, personal_id=6, fecha='2030-06-01 12:10:00'))
        self.reject('Personal ajeno a farmacia no entrega recetas', lambda: self.flow('dispensar', receta_id=prescription, renglon=1, lote_id=lot, cantidad=1, personal_id=1, fecha='2030-06-01 12:10:00'))
        self.reject('Detalle de receta ya entregada es inmutable', lambda: self.service.update('receta_detalle', {'receta_id':prescription,'renglon':1}, {'cantidad_prescrita':99}))

    def billing(self):
        invoice = self.service.create('facturas', {'folio':'QA-'+uuid.uuid4().hex[:12], 'paciente_id':self.patient_id, 'fecha':'2030-06-01 15:00:00'})['lastrowid']
        self.reject('Emitir factura sin conceptos se rechaza', lambda: self.flow('emitir_factura', factura_id=invoice))
        self.service.create('factura_detalle', {'factura_id':invoice,'renglon':1,'descripcion':'Servicio de prueba','cantidad':'2','precio_unitario':'125.00','descuento':'10.00'})
        self.check('Importe se calcula automaticamente', self.value('SELECT importe FROM @DB@.factura_detalle WHERE factura_id=%s AND renglon=1', (invoice,)), Decimal('240.00'))
        self.reject('Pago de factura aun abierta se rechaza', lambda: self.flow('registrar_pago', factura_id=invoice,fecha='2030-06-01 16:00:00',monto='10.00',metodo='EFECTIVO',referencia='QA'))
        self.flow('emitir_factura', factura_id=invoice)
        self.check('Emitir factura cambia a EMITIDA', self.value('SELECT estado FROM @DB@.facturas WHERE factura_id=%s', (invoice,)), 'EMITIDA')
        self.reject('Factura emitida no admite nuevos conceptos', lambda: self.service.create('factura_detalle', {'factura_id':invoice,'renglon':2,'descripcion':'No permitido','cantidad':'1','precio_unitario':'1.00'}))
        self.reject('Factura emitida no admite cambio de importe', lambda: self.service.update('factura_detalle', {'factura_id':invoice,'renglon':1}, {'precio_unitario':'1.00'}))
        self.flow('registrar_pago', factura_id=invoice,fecha='2030-06-01 16:00:00',monto='100.00',metodo='EFECTIVO',referencia='QA')
        self.check('Pago parcial deja saldo correcto', self.value('SELECT saldo FROM @DB@.v_facturas_saldo WHERE factura_id=%s', (invoice,)), Decimal('140.00'))
        self.reject('Pago superior al saldo se rechaza', lambda: self.flow('registrar_pago', factura_id=invoice,fecha='2030-06-01 16:05:00',monto='200.00',metodo='EFECTIVO',referencia='QA'))
        self.reject('Pago anterior a factura se rechaza', lambda: self.flow('registrar_pago', factura_id=invoice,fecha='2030-05-31 16:00:00',monto='10.00',metodo='EFECTIVO',referencia='QA'))
        self.reject('Factura con pago no se anula', lambda: self.flow('anular_factura', factura_id=invoice))
        self.flow('registrar_pago', factura_id=invoice,fecha='2030-06-01 16:10:00',monto='140.00',metodo='TARJETA',referencia='QA-final')
        self.check('Segundo pago liquida la factura', self.value('SELECT saldo FROM @DB@.v_facturas_saldo WHERE factura_id=%s', (invoice,)), Decimal('0.00'))
        other = self.service.create('facturas', {'folio':'QA-CANCEL-'+uuid.uuid4().hex[:8],'paciente_id':self.patient_id,'fecha':'2030-06-01 17:00:00'})['lastrowid']
        self.flow('anular_factura', factura_id=other)
        self.check('Anular factura sin pagos conserva registro', self.value('SELECT estado FROM @DB@.facturas WHERE factura_id=%s', (other,)), 'ANULADA')
        self.reject('Factura anulada no se emite de nuevo', lambda: self.flow('emitir_factura', factura_id=other))

    def reports_and_safety(self):
        reports = self.service.list_reports()
        self.record('Hay reportes disponibles desde botones', len(reports) >= 6, f'Reportes: {len(reports)}')
        for item in reports:
            result = self.service.report(item['name'], limit=50)
            self.record('Reporte de ' + item['name'], isinstance(result,dict) and isinstance(result.get('rows'),list)
                and bool(result.get('columns')), f'Filas recibidas: {len(result.get("rows", []))}')
        self.reject('Reporte arbitrario no permite ejecutar SQL', lambda: self.service.report('SELECT * FROM mysql.user'))
        self.check('Todas las existencias siguen no negativas', self.value('SELECT COUNT(*) FROM @DB@.v_stock_lotes WHERE stock<0'), 0)
        self.check('Ninguna entrega excede lo prescrito', self.value('SELECT COUNT(*) FROM @DB@.v_recetas_pendientes WHERE cantidad_pendiente<0'), 0)
        self.check('Ninguna factura tiene saldo negativo', self.value('SELECT COUNT(*) FROM @DB@.v_facturas_saldo WHERE saldo<0'), 0)
        self.reject('Configuracion de puerto invalido se explica', lambda: HospitalService(Settings(self.args.host, 99999, self.args.user, '', self.database)).test_connection())
        sentinel='CONTRASENA_DE_PRUEBA_NO_MOSTRAR_84'
        try:
            HospitalService(Settings(self.args.host, self.args.port, self.args.user, sentinel, self.database)).test_connection()
        except ServiceError as error:
            self.check('Error de conexion no revela contrasena', sentinel not in str(error))
        else:
            self.record('Error de conexion no revela contrasena', False, 'La instancia acepto inesperadamente la contrasena incorrecta.')
        self.check('Representacion de ajustes no revela contrasena', sentinel not in repr(Settings(self.args.host, self.args.port, self.args.user, sentinel, self.database)))

    def concurrency(self):
        """Dos ventanas independientes deben respetar las mismas reglas atomicas."""
        def invoke(name, values):
            try:
                HospitalService(self.settings).run_workflow(name, values)
                return 'aceptada'
            except ServiceError:
                return 'rechazada'
        appointment={'paciente_id':self.patient_id,'medico_id':1,'inicio':'2030-06-04 10:00:00',
            'fin':'2030-06-04 10:30:00','motivo':'Prueba de dos ventanas'}
        with ThreadPoolExecutor(max_workers=2) as pool:
            results=list(pool.map(lambda _:invoke('agendar_cita', appointment),range(2)))
        self.check('Dos ventanas no pueden reservar la misma cita', sorted(results), ['aceptada','rechazada'])
        self.check('Solo se registra una de las citas simultaneas', self.value('SELECT COUNT(*) FROM @DB@.citas WHERE paciente_id=%s AND inicio=%s', (self.patient_id,appointment['inicio'])),1)
        invoice=self.service.create('facturas', {'folio':'QA-CONC-'+uuid.uuid4().hex[:8], 'paciente_id':self.patient_id, 'fecha':'2030-06-01 18:00:00'})['lastrowid']
        self.service.create('factura_detalle', {'factura_id':invoice,'renglon':1,'descripcion':'Prueba simultanea','cantidad':1,'precio_unitario':'100.00'})
        self.flow('emitir_factura', factura_id=invoice)
        payment={'factura_id':invoice,'fecha':'2030-06-01 19:00:00','monto':'70.00','metodo':'EFECTIVO','referencia':'Dos ventanas'}
        with ThreadPoolExecutor(max_workers=2) as pool:
            results=list(pool.map(lambda _:invoke('registrar_pago',payment),range(2)))
        self.check('Dos cobros simultaneos no pueden exceder el saldo',sorted(results),['aceptada','rechazada'])
        self.check('Cobros simultaneos conservan el saldo correcto',self.value('SELECT saldo FROM @DB@.v_facturas_saldo WHERE factura_id=%s',(invoice,)),Decimal('30.00'))

    def backups(self):
        folder=APP/'tmp'/'qa'
        folder.mkdir(parents=True,exist_ok=True)
        path=folder/('respaldo_'+uuid.uuid4().hex+'.json')
        before=self.snapshot_database(self.database)
        exported=self.service.export_backup(path)
        self.check('Respaldo JSON incluye las 36 tablas',exported['tables'],36)
        self.check('Respaldo JSON incluye todas las filas actuales',exported['rows'],sum(self.service.counts().values()))
        payload=json.loads(path.read_text(encoding='utf-8'))
        self.check('Respaldo no almacena ajustes ni contrasena de conexion',set(payload),{'format','created_at','tables'})
        backup_hash=hashlib.sha256(path.read_bytes()).hexdigest()
        self.reject('Guardar un respaldo no sobrescribe un archivo existente',lambda:self.service.export_backup(path))
        self.check('Respaldo existente conserva exactamente sus bytes',hashlib.sha256(path.read_bytes()).hexdigest(),backup_hash)
        restored_name='hospital_prueba_'+uuid.uuid4().hex
        self.check('Base UUID de restauracion esta libre',self.scalar('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name=%s',(restored_name,)),0)
        self.additional_databases.add(restored_name)
        restored=HospitalService(Settings(self.args.host,self.args.port,self.args.user,os.environ.get('MYSQL_PWD',''),restored_name))
        result=restored.restore_backup(path)
        self.check('Restauracion reconstruye las 36 tablas',result['tables'],36)
        self.check('Restauracion conserva todas las filas sin valores calculados perdidos',self.snapshot_database(restored_name),before)
        self.check('Restauracion reconstruye los 23 triggers',self.scalar('SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema=%s',(restored_name,)),23)
        self.check('Restauracion reconstruye los 6 procedimientos',self.scalar('SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema=%s AND routine_type=%s',(restored_name,'PROCEDURE')),6)
        self.check('Restauracion reconstruye las 6 vistas',self.scalar('SELECT COUNT(*) FROM information_schema.views WHERE table_schema=%s',(restored_name,)),6)
        self.reject('Restauracion rechaza sobrescribir una base existente',lambda:restored.restore_backup(path))
        self.check('Restauracion repetida conserva todos los registros',self.snapshot_database(restored_name),before)
        tampered=folder/('respaldo_invalido_'+uuid.uuid4().hex+'.json')
        payload['tables']['pacientes']['columns'][0]='paciente_id`; DROP TABLE pacientes;--'
        tampered.write_text(json.dumps(payload,ensure_ascii=False),encoding='utf-8')
        self.reject('Restauracion no ejecuta identificadores SQL del archivo JSON',lambda:restored.restore_backup(tampered))
        self.check('Intento de archivo invalido conserva la base restaurada',self.snapshot_database(restored_name),before)
        self.check('Respaldar y restaurar conserva la base de origen',self.snapshot_database(self.database),before)

    def run(self):
        try:
            for phase in [self.install_and_browse, self.current_data_and_schema, self.crud_and_validation, self.tutorial_example, self.appointments_and_hospital, self.pharmacy, self.billing, self.concurrency, self.backups, self.reports_and_safety]:
                try:
                    phase()
                except Exception as error:
                    self.record('Fase completa: ' + phase.__name__, False, type(error).__name__ + ': ' + str(error))
                    traceback.print_exc()
            self.report_data['filas_iniciales_por_tabla'] = self.initial_counts
        finally:
            self.record('Base hospital_universitario original intacta', self.snapshot_original() == self.original_before,
                'Comparacion SHA-256 de todas las filas de sus tablas antes y despues.')
            if self.owns_database and self.database.startswith('hospital_prueba_') and len(self.database) == len('hospital_prueba_') + 32:
                self.sql('DROP DATABASE IF EXISTS `' + self.database + '`')
            for name in self.additional_databases:
                if name.startswith('hospital_prueba_') and len(name)==len('hospital_prueba_')+32:
                    self.sql('DROP DATABASE IF EXISTS `' + name + '`')
            gone = self.scalar('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name=%s', (self.database,)) == 0
            self.record('Se elimina solamente la base UUID propia', gone, self.database)
            self.record('Se eliminan solamente las bases UUID de restauracion propias',all(self.scalar('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name=%s',(name,))==0 for name in self.additional_databases),'Nombres generados y verificados libres antes de restaurar.')
            self.connection.close()
        total = len(self.checks)
        passed = sum(c['correcta'] for c in self.checks)
        self.report_data.update(fin_utc=utc(), estado='APROBADO' if passed == total else 'FALLIDO',
            resumen={'total':total,'correctas':passed,'fallidas':total-passed}, pruebas=self.checks,
            huellas_sha256={str(p.relative_to(PROJECT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
                for p in [APP/'db.py',APP/'catalog.py',Path(__file__).resolve(),PROJECT/'hospital_demostracion.sql',PROJECT/'07_contactos_y_catalogos.sql'] if p.exists()})
        self.args.output.write_text(json.dumps(self.report_data, ensure_ascii=False, indent=2, default=str)+'\n', encoding='utf-8')
        print(json.dumps({'estado':self.report_data['estado'],'resumen':self.report_data['resumen'],'evidencia':str(self.args.output)}, ensure_ascii=True))
        return 0 if passed == total else 1


def main():
    parser=argparse.ArgumentParser(description=__doc__,formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--host',default='127.0.0.1')
    parser.add_argument('--port',type=int,default=3306)
    parser.add_argument('--user',required=True)
    parser.add_argument('--output',type=Path,default=PROJECT/'VALIDACION_APP.json')
    args=parser.parse_args()
    return IntegrationQA(args).run()


if __name__=='__main__':
    raise SystemExit(main())
