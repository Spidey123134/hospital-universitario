"""Prueba de las ventanas reales sobre una base MySQL temporal propia.

Ejemplo: python -m app_hospital.tests.gui_smoke --user root --port 33087
Requiere escritorio Windows y Pillow solo para capturas de la propia ventana.
No modifica hospital_universitario. Elimina solamente su base UUID de prueba.
"""
import argparse
from datetime import datetime,timezone
import hashlib
import json
import os
from pathlib import Path
import time
import uuid
from unittest.mock import patch

import pymysql
from PIL import ImageGrab
from app_hospital import main as ui

ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--host',default='127.0.0.1'); parser.add_argument('--port',type=int,default=3306)
    parser.add_argument('--user',required=True)
    args=parser.parse_args()
    database='hospital_prueba_'+uuid.uuid4().hex
    checks=[]; dialogs=[]; owned=False; copy_database=None; copy_owned=False
    capture_dir=ROOT/'capturas'; capture_dir.mkdir(exist_ok=True)
    qa=ROOT.parent/'tmp'/'app_gui'; qa.mkdir(parents=True,exist_ok=True)
    app=None
    def check(label,ok,detail=''):
        checks.append({'nombre':label,'correcta':bool(ok),'detalle':detail})
        if not ok: raise AssertionError(label+': '+detail)
    def wait(app,timeout=100):
        end=time.monotonic()+timeout
        while time.monotonic()<end:
            app.update()
            if not app.busy:
                app.update(); time.sleep(.1); app.update()
                if not app.busy: return
            time.sleep(.015)
        raise AssertionError('La ventana no termino su operacion.')
    def capture(app,name):
        app.lift(); app.update(); time.sleep(.25)
        x,y=app.winfo_rootx(),app.winfo_rooty()
        ImageGrab.grab(bbox=(x,y,x+app.winfo_width(),y+app.winfo_height()),all_screens=True).save(capture_dir/name)
    def fully_visible(widget,window):
        window.update_idletasks()
        return bool(widget.winfo_ismapped()) and widget.winfo_width()>1 and widget.winfo_height()>1 and widget.winfo_rootx()>=window.winfo_rootx() and widget.winfo_rooty()>=window.winfo_rooty() and widget.winfo_rootx()+widget.winfo_width()<=window.winfo_rootx()+window.winfo_width() and widget.winfo_rooty()+widget.winfo_height()<=window.winfo_rooty()+window.winfo_height()
    password=os.environ.get('MYSQL_PWD','')
    connection=pymysql.connect(host=args.host,port=args.port,user=args.user,password=password,autocommit=True)
    try:
        with connection.cursor() as cur:
            cur.execute('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name=%s',(database,))
            check('La base UUID esta libre',cur.fetchone()[0]==0)
        with patch.object(ui,'CONFIG',qa/'conexion_prueba.json'),patch.object(ui.messagebox,'showerror',side_effect=lambda title,text,**k:dialogs.append(('error',title,text))),patch.object(ui.messagebox,'showinfo',side_effect=lambda title,text,**k:dialogs.append(('info',title,text))),patch.object(ui.messagebox,'askyesno',return_value=True):
            app=ui.HospitalApp(); app.geometry('1280x850+30+20'); app.update()
            capture(app,'01_conexion.png')
            for key,value in dict(host=args.host,port=str(args.port),user=args.user,password=password,database=database).items(): app.connection_vars[key].set(value)
            app.test_connection(); wait(app)
            check('Probar conexion desde boton funciona',not [x for x in dialogs if x[0]=='error'],str(dialogs[-1:]))
            app.install_demo(); owned=True; wait(app,180)
            check('Crear base desde interfaz funciona',not [x for x in dialogs if x[0]=='error'],str(dialogs[-1:]))
            app.open_hospital(); wait(app)
            check('La interfaz abre 36 tablas',len(app.catalog)==36)
            first_doctor=next(row for row in app.service.browse('personal',limit=200)['rows'] if row['personal_id']==1)
            check('La instalacion muestra Elena y su correo coherente',first_doctor['nombre']=='Elena' and first_doctor['apellido_paterno']=='Márquez' and first_doctor['email']=='elena.marquez.1@example.com')
            check('Inicio muestra 789 registros',app.card_vars['_total'].get()=='789')
            check('Todas las tablas se muestran con registros','0 tablas vacías' in app.count_summary.get())
            check('Los botones de respaldo son visibles en Inicio',app.backup_button.winfo_ismapped() and app.restore_button.winfo_ismapped() and app.backup_button.winfo_y()+app.backup_button.winfo_height()<=app.backup_button.master.winfo_height())
            capture(app,'02_inicio.png')
            app.geometry('1020x700+30+20'); app.goto_table('pacientes'); wait(app)
            check('En 1020x700 la paginacion queda visible',fully_visible(app.prev_button,app) and fully_visible(app.next_button,app))
            app.tabs.select(app.pages['Operaciones']); app.update()
            operation_button=next(button for frame in app.pages['Operaciones'].winfo_children() for button in frame.winfo_children() if isinstance(button,ui.ttk.Button) and button.cget('text')=='Guardar operación')
            check('En 1020x700 Guardar operacion queda visible',fully_visible(operation_button,app))
            app.geometry('1280x850+30+20'); app.tabs.select(app.pages['Registros']); app.update()
            module=next(t['module'] for t in app.catalog if t['name']=='medicos')
            app.module_picker.set(module); app.select_module(); wait(app)
            filtered=[t for t in app.catalog if t['module']==module]
            check('El filtro de area mantiene una tabla valida',app.current_table in {t['name'] for t in filtered} and len(app.table_picker.cget('values'))==len(filtered))
            app.goto_table('pacientes'); wait(app)
            check('Ir a Pacientes restaura Todas las areas',app.module_picker.get()=='Todas las áreas' and app.current_table=='pacientes' and len(app.table_picker.cget('values'))==36)
            check('La tabla Pacientes muestra 30 filas',len(app.record_grid.rows)==30)
            capture(app,'03_pacientes.png')
            app.new_record(); app.update()
            form=app.active_form
            check('El formulario muestra Activo mediante Si o No',isinstance(form.controls['activo'],ui.ttk.Combobox) and form.controls['activo'].get()=='Sí')
            sample={'expediente_clinico':'UNI-PRUEBA-001','nombre':'Daniela','apellido_paterno':'Serrano','apellido_materno':'Molina','fecha_nacimiento':'2002-03-15','sexo':'F','telefono':'5550000000','email':'daniela.serrano@example.com','domicilio':'Domicilio ficticio del ejercicio'}
            for name,value in sample.items():
                widget=form.controls[name]
                if isinstance(widget,ui.ttk.Combobox): widget.set(value)
                else: widget.delete(0,'end'); widget.insert(0,value)
            form.controls['fecha_nacimiento'].delete(0,'end'); form.controls['fecha_nacimiento'].insert(0,'2002-02-30')
            previous_dialogs=len(dialogs)
            with patch.object(app.service,'create',wraps=app.service.create) as create:
                form.save(); app.update()
                check('Una fecha imposible se rechaza antes de enviar a MySQL',not create.called and app.active_form_window.winfo_exists() and app.service.counts()['pacientes']==30 and any(d[0]=='error' and 'Fecha nacimiento' in d[2] for d in dialogs[previous_dialogs:]))
            del dialogs[previous_dialogs:]
            form.controls['fecha_nacimiento'].delete(0,'end'); form.controls['fecha_nacimiento'].insert(0,sample['fecha_nacimiento'])
            capture(app.active_form_window,'04_nuevo_paciente.png')
            form.save(); wait(app)
            check('Formulario guarda paciente en MySQL',app.service.counts()['pacientes']==31)
            app.search.set('UNI-PRUEBA-001'); app.search_records(); wait(app)
            check('Buscador encuentra el paciente',len(app.record_grid.rows)==1 and app.record_grid.rows[0]['nombre']=='Daniela')
            app.record_grid.tree.selection_set('0'); app.edit_record(); app.update()
            form=app.active_form; form.controls['telefono'].delete(0,'end'); form.controls['telefono'].insert(0,'5551111111'); form.save(); wait(app)
            check('Edicion desde formulario persiste',app.record_grid.rows[0]['telefono']=='5551111111')
            app.new_record(); app.update(); temporary_form=app.active_form
            app.busy=True; temporary_form.close(); app.update()
            check('No se cierra un formulario mientras guarda',app.active_form_window.winfo_exists())
            app.busy=False; temporary_form.close(); app.update()
            app.goto_table('pagos'); wait(app)
            app.record_grid.tree.selection_set('0'); app.view_record(); app.update()
            details=app.details_text.get('1.0','end-1c')
            check('Ver registro muestra el historial de pagos sin editarlo',str(app.edit_button.cget('state'))=='disabled' and str(app.details_text.cget('state'))=='disabled' and 'Monto' in details and str(app.record_grid.rows[0]['monto']) in details)
            app.details_window.destroy()
            app.tabs.select(app.pages['Operaciones'])
            index=next(i for i,w in enumerate(app.workflows_data) if w['name']=='agendar_cita')
            app.workflow_picker.current(index); app.select_workflow(); app.update()
            app.busy=True; app.workflow_picker.current(0 if index!=0 else 1); app.select_workflow()
            check('Selector conserva operacion durante una tarea',app.workflow_picker.current()==index)
            app.busy=False
            form=app.workflow_form
            for name in ('paciente_id','medico_id'):
                options=form.maps[name]; selected=next(label for label,key in options.items() if int(key)==(31 if name=='paciente_id' else 1))
                form.controls[name].set(selected)
            for name,value in {'inicio':'2030-01-15 09:00:00','fin':'2030-01-15 09:30:00','motivo':'Revision ficticia del tutorial'}.items():
                widget=form.controls[name]
                if isinstance(widget,ui.tk.Text): widget.delete('1.0','end'); widget.insert('1.0',value)
                else: widget.delete(0,'end'); widget.insert(0,value)
            capture(app,'05_agendar_cita.png')
            app.save_workflow(); wait(app)
            check('Operacion de cita guarda desde ventana',app.service.counts()['citas']==55)
            app.tabs.select(app.pages['Consultas'])
            index=next(i for i,r in enumerate(app.reports_data) if r['name']=='recetas')
            app.report_picker.current(index); app.show_report(); wait(app)
            check('Consulta de recetas combina nombres y detalles',len(app.report_grid.rows)==64 and 'paciente' in app.report_grid.columns)
            capture(app,'06_consulta_recetas.png')
            export=qa/'consulta.csv'
            with patch.object(ui.filedialog,'asksaveasfilename',return_value=str(export)): app.export_grid(app.report_grid)
            check('Boton exporta CSV con cabecera y64renglones',export.exists() and len(export.read_text(encoding='utf-8-sig').splitlines())==65)
            backup=qa/('respaldo_'+uuid.uuid4().hex+'.hospital.json')
            with patch.object(ui.filedialog,'asksaveasfilename',return_value=str(backup)): app.backup()
            wait(app)
            check('Boton crea respaldo completo',backup.exists() and len(json.loads(backup.read_text(encoding='utf-8'))['tables'])==36)
            check('No hubo errores en el recorrido de ventanas',not [x for x in dialogs if x[0]=='error'],str([x for x in dialogs if x[0]=='error']))
            check('La configuracion de prueba no guarda contrasena',not (qa/'conexion_prueba.json').exists() or 'password' not in json.loads((qa/'conexion_prueba.json').read_text()))
            copy_database='hospital_prueba_'+uuid.uuid4().hex
            with connection.cursor() as cur:
                cur.execute('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name=%s',(copy_database,))
                check('El destino de restauracion UUID esta libre',cur.fetchone()[0]==0)
            original_database=app.connection_vars['database'].get()
            with patch.object(ui.filedialog,'askopenfilename',return_value=str(backup)),patch.object(ui.simpledialog,'askstring',return_value=None),patch.object(ui.HospitalService,'restore_backup') as restore_backup:
                app.restore(); app.update()
                check('Cancelar el nombre de restauracion conserva conexion y datos',not restore_backup.called and not app.busy and app.connection_vars['database'].get()==original_database and app.service.counts()['pacientes']==31)
            with patch.object(ui.filedialog,'askopenfilename',return_value=str(backup)),patch.object(ui.simpledialog,'askstring',return_value=copy_database): app.restore()
            copy_owned=True
            wait(app,180)
            check('Restaurar cambia al destino solo despues de crear la copia',app.connection_vars['database'].get()==copy_database and app.service.settings.database==original_database)
            check('La restauracion conserva la base original',app.service.counts()['pacientes']==31 and app.service.counts()['citas']==55)
            app.open_hospital(); wait(app)
            check('La restauracion desde el boton conserva los datos',app.service.counts()['pacientes']==31 and app.service.counts()['citas']==55)
            check('Al abrir una base se limpian los formularios anteriores',app.workflow_current is None and app.workflow_form is None and not app.report_grid.rows)
            app.connection_vars['password'].set(''); app.destroy(); app=None
    except Exception as error:
        checks.append({'nombre':'Recorrido completo de interfaz','correcta':False,'detalle':type(error).__name__+': '+str(error)})
        import traceback; traceback.print_exc()
    finally:
        if app:
            try: app.destroy()
            except Exception: pass
        if owned:
            with connection.cursor() as cur: cur.execute('DROP DATABASE IF EXISTS `'+database+'`')
        if copy_owned:
            with connection.cursor() as cur: cur.execute('DROP DATABASE IF EXISTS `'+copy_database+'`')
        with connection.cursor() as cur:
            cur.execute('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name=%s',(database,))
            checks.append({'nombre':'Solo se elimina la base UUID propia','correcta':cur.fetchone()[0]==0,'detalle':database})
        connection.close()
    passed=sum(x['correcta'] for x in checks)
    report={'fecha_utc':datetime.now(timezone.utc).isoformat(),'estado':'APROBADO' if passed==len(checks) else 'FALLIDO','resumen':{'total':len(checks),'correctas':passed,'fallidas':len(checks)-passed},'pruebas':checks,'huellas_sha256':{'app_hospital/main.py':hashlib.sha256((ROOT/'main.py').read_bytes()).hexdigest()}}
    (ROOT.parent/'VALIDACION_INTERFAZ.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,ensure_ascii=True))
    return 0 if passed==len(checks) else 1

if __name__=='__main__': raise SystemExit(main())
