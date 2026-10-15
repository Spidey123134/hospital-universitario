"""Ventanas para utilizar el hospital sin escribir sentencias SQL.

Ejecutar desde la carpeta del proyecto: python -m app_hospital.main
"""
from __future__ import annotations

import csv
from datetime import date, datetime, timedelta
import json
import os
from pathlib import Path
import queue
import sys
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import webbrowser

from .db import HospitalService, ServiceError, Settings

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / 'conexion_hospital.json'
BG = '#f4f6fa'
BLUE = '#1757a6'
INK = '#152b47'
MUTED = '#52647a'


def display(value):
    if value is None:
        return ''
    if isinstance(value, datetime):
        return value.strftime('%Y-%m-%d %H:%M:%S')
    return str(value)


class ScrollFrame(ttk.Frame):
    def __init__(self, parent, **kwargs):
        super().__init__(parent, **kwargs)
        self.canvas = tk.Canvas(self, highlightthickness=0, background='white')
        bar = ttk.Scrollbar(self, orient='vertical', command=self.canvas.yview)
        self.body = ttk.Frame(self.canvas, style='White.TFrame')
        self.window = self.canvas.create_window((0, 0), window=self.body, anchor='nw')
        self.canvas.configure(yscrollcommand=bar.set)
        self.canvas.pack(side='left', fill='both', expand=True)
        bar.pack(side='right', fill='y')
        self.body.bind('<Configure>', lambda e: self.canvas.configure(scrollregion=self.canvas.bbox('all')))
        self.canvas.bind('<Configure>', lambda e: self.canvas.itemconfigure(self.window, width=e.width))
        self.canvas.bind('<Enter>', lambda e: self.canvas.focus_set())
        self.canvas.bind('<MouseWheel>', lambda e: self.canvas.yview_scroll(-int(e.delta / 120), 'units'))


class GridTable(ttk.Frame):
    def __init__(self, parent):
        super().__init__(parent)
        self.tree = ttk.Treeview(self, show='headings', selectmode='browse')
        self.ybar = ttk.Scrollbar(self, orient='vertical', command=self.tree.yview)
        self.xbar = ttk.Scrollbar(self, orient='horizontal', command=self.tree.xview)
        self.tree.configure(yscrollcommand=self.ybar.set, xscrollcommand=self.xbar.set)
        self.tree.grid(row=0, column=0, sticky='nsew')
        self.ybar.grid(row=0, column=1, sticky='ns')
        self.xbar.grid(row=1, column=0, sticky='ew')
        self.rowconfigure(0, weight=1); self.columnconfigure(0, weight=1)
        self.columns = []; self.rows = []

    def fill(self, columns, rows):
        self.columns = list(columns); self.rows = list(rows)
        self.tree.delete(*self.tree.get_children())
        self.tree.configure(columns=self.columns)
        for name in self.columns:
            label = name.replace('_', ' ').capitalize()
            self.tree.heading(name, text=label)
            self.tree.column(name, width=min(310, max(130, len(label) * 9)), minwidth=85, stretch=False)
        for i, row in enumerate(self.rows):
            values = [display(row.get(c))[:1500] for c in self.columns]
            self.tree.insert('', 'end', iid=str(i), values=values, tags=('even' if i % 2 == 0 else 'odd',))
        self.tree.tag_configure('even', background='#ffffff')
        self.tree.tag_configure('odd', background='#edf3fa')

    def selected(self):
        selection = self.tree.selection()
        return self.rows[int(selection[0])] if selection else None


class DataForm(ttk.Frame):
    """Construye entradas etiquetadas; las referencias se eligen por nombre."""
    def __init__(self, parent, fields, options, initial=None):
        super().__init__(parent, style='White.TFrame', padding=16)
        self.fields = fields; self.controls = {}; self.maps = {}; self.options = options
        self.initial = initial or {}
        self.columnconfigure(1, weight=1)
        for i, field in enumerate(fields):
            name = field['name']
            required = field.get('required', not field.get('nullable', False))
            label = field.get('label', name.replace('_', ' ').capitalize()) + (' *' if required else '')
            ttk.Label(self, text=label, style='White.TLabel').grid(row=i * 2, column=0, sticky='nw', padx=(0,18), pady=(9,3))
            box = ttk.Frame(self, style='White.TFrame'); box.grid(row=i*2, column=1, sticky='ew', pady=(6,3))
            box.columnconfigure(0, weight=1)
            ref = field.get('reference')
            dtype = field.get('data_type', field.get('type', 'varchar'))
            enum = field.get('enum_values', field.get('choices', []))
            value = self.initial.get(name, field.get('default'))
            if isinstance(value, str) and ('CURRENT_TIMESTAMP' in value.upper() or value.upper() == 'NOW()'):
                value = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            if value is None and dtype in ('datetime','timestamp') and required:
                value = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            if ref:
                widget = ttk.Combobox(box, state='readonly', width=55)
                widget.grid(row=0, column=0, sticky='ew')
                self.maps[name] = {}
                def load_reference(field=field, widget=widget, filter_value='', selected=value, required=required):
                    pairs = options(field, filter_value)
                    choices = [''] if not required else []
                    mapping = {}
                    for key, text in pairs:
                        shown = f'{key} · {text}'
                        mapping[shown] = key; choices.append(shown)
                    # A selected value must remain identifiable even outside first page.
                    if selected is not None and selected not in mapping.values():
                        shown = f'{selected} · Registro actual'
                        mapping[shown] = selected; choices.insert(0,shown)
                    self.maps[field['name']] = mapping
                    widget.configure(values=choices)
                    if selected is not None:
                        match = next((label for label, key in mapping.items() if str(key)==str(selected)), '')
                        widget.set(match)
                load_reference()
                search = ttk.Entry(box, width=25)
                search.grid(row=1, column=0, sticky='ew', pady=(5,0))
                search.insert(0,'')
                def filter_reference(field=field, widget=widget, search=search, loader=load_reference):
                    try:
                        loader(filter_value=search.get().strip(), selected=None)
                        widget.set('')
                    except ServiceError as exc:
                        messagebox.showerror('No se pudo buscar', str(exc), parent=self.winfo_toplevel())
                ttk.Button(box, text='Buscar en la lista', command=filter_reference).grid(row=1,column=1,padx=(6,0),pady=(5,0))
            elif enum:
                choices = [str(x) for x in enum]
                if not required: choices = [''] + choices
                widget = ttk.Combobox(box, values=choices, state='readonly', width=55)
                widget.grid(row=0,column=0,sticky='ew'); widget.set(display(value))
            elif dtype in ('text','mediumtext','longtext'):
                widget = tk.Text(box, height=4, wrap='word', font=('Segoe UI',10), relief='solid', borderwidth=1)
                widget.grid(row=0,column=0,sticky='ew'); widget.insert('1.0',display(value))
            else:
                widget = ttk.Entry(box, width=55)
                widget.grid(row=0,column=0,sticky='ew'); widget.insert(0,display(value))
            self.controls[name] = widget
            hint = field.get('hint', '')
            if dtype=='date': hint = 'Fecha: AAAA-MM-DD. Ejemplo: 2002-03-15.'
            elif dtype in ('datetime','timestamp'): hint='Fecha y hora: AAAA-MM-DD HH:MM:SS. Ejemplo: 2026-10-20 09:00:00.'
            elif dtype=='time': hint='Hora de 24 horas: HH:MM:SS.'
            elif ref: hint='Elige un registro por su nombre. Puedes filtrar la lista con el buscador de abajo.'
            elif dtype in ('decimal','float','double'): hint='Escribe números con punto decimal. Ejemplo: 350.00.'
            if hint:
                ttk.Label(self,text=hint,style='Hint.TLabel',wraplength=630).grid(row=i*2+1,column=1,sticky='w',pady=(0,5))

    def values(self):
        result = {}
        for field in self.fields:
            name=field['name']; widget=self.controls[name]
            value=widget.get('1.0','end-1c').strip() if isinstance(widget,tk.Text) else widget.get().strip()
            required=field.get('required',not field.get('nullable',False))
            if not value:
                # On creation omit blank defaults, on editing nullable blanks clear them.
                if required and field.get('default') is None:
                    raise ValueError('Completa el campo '+field.get('label',name)+'.')
                if name in self.initial and field.get('nullable',False): result[name]=None
                elif required and field.get('default') is None: result[name]=value
                continue
            if field.get('reference'):
                if value not in self.maps[name]: raise ValueError('Selecciona un registro de la lista de '+field.get('label',name)+'.')
                result[name]=self.maps[name][value]
            else: result[name]=value
        return result


class HospitalApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('Hospital universitario · Gestión de datos')
        self.geometry('1280x850'); self.minsize(1020,700)
        self.configure(bg=BG)
        self.service=None; self.busy=False; self.current_table=None; self.offset=0
        self.catalog=[]; self.metadata={}; self.workflows_data=[]
        self._jobs=queue.Queue()
        self.style=ttk.Style(self); self.style.theme_use('clam')
        self.style.configure('.',font=('Segoe UI',10))
        self.style.configure('TFrame',background=BG)
        self.style.configure('TLabel',background=BG,foreground=INK)
        self.style.configure('White.TFrame',background='white')
        self.style.configure('White.TLabel',background='white',foreground=INK)
        self.style.configure('Hint.TLabel',background='white',foreground=MUTED,font=('Segoe UI',9))
        self.style.configure('Title.TLabel',font=('Segoe UI',21,'bold'),foreground=INK)
        self.style.configure('Subtitle.TLabel',font=('Segoe UI',10),foreground=MUTED)
        self.style.configure('TButton',padding=(12,7))
        self.style.configure('Accent.TButton',background=BLUE,foreground='white',padding=(14,8))
        self.style.map('Accent.TButton',background=[('active','#124582'),('disabled','#849cba')])
        self.style.configure('Treeview',rowheight=30,font=('Segoe UI',10))
        self.style.configure('Treeview.Heading',font=('Segoe UI',10,'bold'),background='#dce7f5')
        self.style.configure('TNotebook.Tab',padding=(18,10))
        header=ttk.Frame(self,padding=(24,15)); header.pack(fill='x')
        ttk.Label(header,text='Hospital universitario',style='Title.TLabel').pack(anchor='w')
        ttk.Label(header,text='Consulta y registra información con formularios. Los datos de muestra son ficticios.',style='Subtitle.TLabel').pack(anchor='w',pady=(4,0))
        self.connection=ttk.Frame(self,padding=(24,8)); self.connection.pack(fill='x')
        self.connection_vars={}; self.connection_entries=[]
        labels=[('host','Servidor','127.0.0.1',18),('port','Puerto','3306',7),('user','Usuario','root',15),('password','Contraseña','',18),('database','Base de datos','hospital_universitario',29)]
        saved=self._read_config()
        for i,(name,label,default,width) in enumerate(labels):
            ttk.Label(self.connection,text=label).grid(row=0,column=i,sticky='w',padx=(0,12))
            var=tk.StringVar(value=saved.get(name,default) if name!='password' else '')
            entry=ttk.Entry(self.connection,textvariable=var,width=width,show='*' if name=='password' else '')
            entry.grid(row=1,column=i,sticky='ew',padx=(0,12),pady=(4,10))
            self.connection_vars[name]=var
            self.connection_entries.append(entry)
        self.remember=tk.BooleanVar(value=bool(saved))
        ttk.Checkbutton(self.connection,text='Recordar conexión sin guardar contraseña',variable=self.remember).grid(row=2,column=0,columnspan=3,sticky='w')
        actions=ttk.Frame(self.connection); actions.grid(row=2,column=3,columnspan=2,sticky='e')
        self.test_button=ttk.Button(actions,text='Probar conexión',command=self.test_connection); self.test_button.pack(side='left',padx=3)
        self.install_button=ttk.Button(actions,text='Crear base con ejemplos',command=self.install_demo); self.install_button.pack(side='left',padx=3)
        self.open_button=ttk.Button(actions,text='Abrir hospital',style='Accent.TButton',command=self.open_hospital); self.open_button.pack(side='left',padx=3)
        self.status=tk.StringVar(value='Paso 1: revisa la conexión. Paso 2: crea la base una sola vez. Paso 3: abre el hospital.')
        statusline=ttk.Frame(self,padding=(24,8)); statusline.pack(fill='x')
        ttk.Label(statusline,textvariable=self.status,wraplength=1100).pack(side='left')
        self.progress=ttk.Progressbar(statusline,mode='indeterminate',length=110); self.progress.pack(side='right')
        self.tabs=ttk.Notebook(self); self.tabs.pack(fill='both',expand=True,padx=24,pady=(0,16))
        self.pages={}
        for label in ('Inicio','Registros','Operaciones','Consultas','Guía'):
            frame=ttk.Frame(self.tabs,padding=16); self.tabs.add(frame,text=label); self.pages[label]=frame
        self._build_home(); self._build_records(); self._build_operations(); self._build_reports(); self._build_help()
        self.after(80,self._poll)
        self.protocol('WM_DELETE_WINDOW',self.close)

    def _read_config(self):
        try:
            data=json.loads(CONFIG.read_text(encoding='utf-8'))
            return {key:value for key,value in data.items() if key in ('host','port','user','database')}
        except (OSError,ValueError,AttributeError): return {}

    def _settings(self):
        values={key:var.get().strip() if key!='password' else var.get() for key,var in self.connection_vars.items()}
        try: values['port']=int(values['port'])
        except ValueError: raise ValueError('El puerto debe ser un número, por ejemplo 3306.')
        return Settings(**values)

    def _save_config(self):
        try:
            if self.remember.get():
                data={key:var.get().strip() for key,var in self.connection_vars.items() if key!='password'}
                CONFIG.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
            elif CONFIG.exists(): CONFIG.unlink()
        except OSError:
            messagebox.showinfo('Conexión sin recordar','La operación de MySQL terminó. No se pudieron guardar las preferencias en esta carpeta; tendrás que escribir la conexión la próxima vez.',parent=self)

    def _poll(self):
        try:
            while True:
                ok,value,callback=self._jobs.get_nowait()
                self.busy=False; self.progress.stop()
                for button in (self.test_button,self.install_button,self.open_button): button.configure(state='normal')
                for entry in self.connection_entries: entry.configure(state='normal')
                for picker in (self.table_picker,self.workflow_picker,self.report_picker): picker.configure(state='readonly')
                if ok:
                    try: callback(value)
                    except (ServiceError,ValueError,OSError) as exc: self._error(str(exc))
                    except tk.TclError:
                        self.status.set('La operación terminó. Pulsa Actualizar para volver a cargar los datos de la ventana.')
                else: self._error(value)
        except queue.Empty: pass
        self.after(80,self._poll)

    def _run(self,label,task,callback):
        if self.busy:
            self.status.set('Espera a que termine la operación actual.'); return
        self.busy=True; self.status.set(label); self.progress.start(12)
        for button in (self.test_button,self.install_button,self.open_button): button.configure(state='disabled')
        for entry in self.connection_entries: entry.configure(state='disabled')
        for picker in (self.table_picker,self.workflow_picker,self.report_picker): picker.configure(state='disabled')
        def worker():
            try: self._jobs.put((True,task(),callback))
            except (ServiceError,ValueError,OSError) as exc: self._jobs.put((False,str(exc),callback))
            except Exception:
                self._jobs.put((False,'Ocurrió un error inesperado. Revisa la conexión y vuelve a abrir el programa. No se guardó información de contraseña en registros.',callback))
        threading.Thread(target=worker,daemon=True).start()

    def _error(self,text):
        self.status.set('No se completó la operación. '+text)
        messagebox.showerror('Revisa estos datos',text,parent=self)

    def _require_service(self):
        if self.service is None: raise ValueError('Primero pulsa Abrir hospital.')
        # A form must not silently switch databases when the connection boxes change.
        if self._settings()!=self.service.settings: raise ValueError('Cambiaste la conexión. Pulsa Abrir hospital para trabajar con esos datos.')
        return self.service

    def test_connection(self):
        try: service=HospitalService(self._settings())
        except (ValueError,ServiceError) as exc: return self._error(str(exc))
        def success(result):
            self._save_config()
            self.status.set('Conexión correcta al servidor MySQL. Ahora crea la base si es nueva o pulsa Abrir hospital.')
            messagebox.showinfo('Conexión correcta','El servidor respondió. Si esta es la primera vez, pulsa Crear base con ejemplos. Si ya tienes la base, pulsa Abrir hospital.',parent=self)
        self._run('Probando conexión con el servidor...',service.test_connection,success)

    def install_demo(self):
        try: service=HospitalService(self._settings())
        except (ValueError,ServiceError) as exc: return self._error(str(exc))
        if not messagebox.askyesno('Crear base con ejemplos','Se creará una base NUEVA llamada '+service.settings.database+' con las 36 tablas y datos ficticios. Si ya existe, la aplicación se detendrá sin reemplazarla.\n\n¿Crear esta base nueva?',parent=self): return
        def success(result):
            self._save_config(); self.status.set('Base creada con ejemplos. Pulsa Abrir hospital para ver y agregar registros.')
            messagebox.showinfo('Base lista','Se creó la demostración. Pulsa Abrir hospital. En Inicio verás cuántos registros tiene cada tabla.',parent=self)
        self._run('Creando las 36 tablas y cargando los ejemplos. Espera...',service.install_demo,success)

    def open_hospital(self):
        try: service=HospitalService(self._settings())
        except (ValueError,ServiceError) as exc: return self._error(str(exc))
        def task(): return service.tables(),service.counts(),service.workflows(),service.list_reports()
        def success(data):
            self.service=service; self.catalog,counts,self.workflows_data,reports=data
            self.metadata={}; self._save_config()
            for child in self.workflow_scroll.body.winfo_children(): child.destroy()
            self.workflow_form=None; self.workflow_current=None; self.workflow_picker.set('')
            self.workflow_description.set('Elige una operación para esta base.'); self.workflow_result.set('')
            self.report_grid.fill([],[]); self.report_note.set(''); self.record_grid.fill([],[])
            self.table_picker.configure(values=[self._table_label(t) for t in self.catalog])
            first=next((i for i,t in enumerate(self.catalog) if t['name']=='pacientes'),0)
            self.table_picker.current(first); self.current_table=self.catalog[first]['name']
            self.workflow_picker.configure(values=[w['label'] for w in self.workflows_data])
            self.report_picker.configure(values=[r['label'] for r in reports]); self.reports_data=reports
            if reports: self.report_picker.current(0)
            self._show_counts(counts)
            self.status.set('Hospital abierto. Ve a Registros para ver o agregar datos. Base: '+service.settings.database)
            self.tabs.select(self.pages['Inicio'])
            self.offset=0; self.load_records()
        self._run('Abriendo el hospital y contando los registros...',task,success)

    def _build_home(self):
        page=self.pages['Inicio']
        ttk.Label(page,text='Empieza por aquí',font=('Segoe UI',16,'bold')).pack(anchor='w')
        ttk.Label(page,text='1  Abre la conexión arriba.    2  Revisa los registros.    3  Usa Nuevo registro u Operaciones para seguir llenando la base.',wraplength=1100).pack(anchor='w',pady=(5,14))
        self.cards=ttk.Frame(page); self.cards.pack(fill='x')
        self.card_vars={}
        for i,(key,label) in enumerate([('pacientes','Pacientes'),('medicos','Médicos'),('medicamentos','Medicamentos'),('recetas','Recetas'),('_total','Registros totales')]):
            frame=ttk.Frame(self.cards,style='White.TFrame',padding=(20,12)); frame.pack(side='left',fill='both',expand=True,padx=(0,10))
            var=tk.StringVar(value='—'); self.card_vars[key]=var
            ttk.Label(frame,textvariable=var,font=('Segoe UI',23,'bold'),style='White.TLabel').pack(anchor='w')
            ttk.Label(frame,text=label,style='White.TLabel').pack(anchor='w')
        line=ttk.Frame(page); line.pack(fill='x',pady=(16,8))
        self.count_summary=tk.StringVar(value='Todavía no hay una base abierta. La demostración inicial incluye registros en las 36 tablas.')
        ttk.Label(line,textvariable=self.count_summary).pack(side='left')
        ttk.Button(line,text='Actualizar conteos',command=self.refresh_counts).pack(side='right')
        self.count_grid=GridTable(page)
        self.count_grid.tree.configure(height=4)
        bottom=ttk.Frame(page); bottom.pack(side='bottom',fill='x',pady=(12,0))
        ttk.Button(bottom,text='Ir a Pacientes',style='Accent.TButton',command=lambda:self.goto_table('pacientes')).pack(side='left')
        self.backup_button=ttk.Button(bottom,text='Crear respaldo completo',command=self.backup); self.backup_button.pack(side='left',padx=8)
        self.restore_button=ttk.Button(bottom,text='Restaurar respaldo en base nueva',command=self.restore); self.restore_button.pack(side='left')
        self.count_grid.pack(fill='both',expand=True)

    def _show_counts(self,counts):
        total=sum(counts.values()); empty=sum(n==0 for n in counts.values())
        for key,var in self.card_vars.items(): var.set(str(total if key=='_total' else counts.get(key,0)))
        labels={t['name']:t['label'] for t in self.catalog}
        self.count_grid.fill(['tabla','registros','estado'],[{'tabla':labels.get(t,t)+' ('+t+')','registros':n,'estado':'Con datos' if n else 'Sin registros'} for t,n in counts.items()])
        self.count_grid.tree.column('tabla',width=660,stretch=True)
        self.count_grid.tree.column('registros',width=130)
        self.count_grid.tree.column('estado',width=190)
        self.count_summary.set(f'{len(counts)} tablas · {total} registros · {empty} tablas vacías. Estos números cambian al guardar información.')

    def refresh_counts(self):
        try: service=self._require_service()
        except ValueError as exc: return self._error(str(exc))
        self._run('Actualizando conteos...',service.counts,lambda data:(self._show_counts(data),self.status.set('Conteos actualizados.')))

    @staticmethod
    def _table_label(table): return f"{table['module']} · {table['label']} ({table['name']})"

    def _build_records(self):
        page=self.pages['Registros']
        line=ttk.Frame(page); line.pack(fill='x')
        ttk.Label(line,text='Tabla').pack(side='left',padx=(0,8))
        self.table_picker=ttk.Combobox(line,state='readonly',width=72)
        self.table_picker.pack(side='left',fill='x',expand=True); self.table_picker.bind('<<ComboboxSelected>>',self.select_table)
        ttk.Button(line,text='Actualizar',command=self.load_records).pack(side='right',padx=(8,0))
        searchline=ttk.Frame(page); searchline.pack(fill='x',pady=10)
        ttk.Label(searchline,text='Buscar').pack(side='left',padx=(0,8))
        self.search=tk.StringVar(); entry=ttk.Entry(searchline,textvariable=self.search,width=34)
        entry.pack(side='left'); entry.bind('<Return>',lambda e:self.search_records())
        ttk.Button(searchline,text='Buscar',command=self.search_records).pack(side='left',padx=5)
        ttk.Button(searchline,text='Mostrar todos',command=self.clear_search).pack(side='left')
        self.new_button=ttk.Button(searchline,text='Nuevo registro',style='Accent.TButton',command=self.new_record); self.new_button.pack(side='right')
        self.edit_button=ttk.Button(searchline,text='Editar seleccionado',command=self.edit_record); self.edit_button.pack(side='right',padx=7)
        self.table_note=tk.StringVar(value='Abre el hospital para ver los registros. Aquí puedes consultar las 36 tablas.')
        ttk.Label(page,textvariable=self.table_note,wraplength=1100,foreground=MUTED).pack(anchor='w',pady=(0,8))
        self.record_grid=GridTable(page); self.record_grid.pack(fill='both',expand=True)
        self.record_grid.tree.bind('<Double-1>',lambda e:self.edit_record())
        foot=ttk.Frame(page); foot.pack(fill='x',pady=(10,0))
        self.pagination=tk.StringVar(value='')
        ttk.Label(foot,textvariable=self.pagination).pack(side='left')
        ttk.Button(foot,text='Exportar CSV',command=lambda:self.export_grid(self.record_grid)).pack(side='right')
        self.next_button=ttk.Button(foot,text='Siguiente',command=lambda:self.page_records(200)); self.next_button.pack(side='right',padx=6)
        self.prev_button=ttk.Button(foot,text='Anterior',command=lambda:self.page_records(-200)); self.prev_button.pack(side='right')

    def goto_table(self,name):
        if self.busy: return
        if not self.service: return self._error('Primero pulsa Abrir hospital.')
        for i,table in enumerate(self.catalog):
            if table['name']==name:
                self.table_picker.current(i); self.select_table(); self.tabs.select(self.pages['Registros']); return

    def select_table(self,event=None):
        if self.busy:
            for i,table in enumerate(self.catalog):
                if table['name']==self.current_table: self.table_picker.current(i)
            return
        i=self.table_picker.current()
        if i<0: return
        self.current_table=self.catalog[i]['name']; self.search.set(''); self.offset=0
        self.load_records()

    def search_records(self):
        if self.busy: return
        self.offset=0; self.load_records()
    def clear_search(self):
        if self.busy: return
        self.search.set(''); self.search_records()
    def page_records(self,delta):
        if self.busy: return
        self.offset=max(0,self.offset+delta); self.load_records()

    def load_records(self):
        try:
            service=self._require_service()
            if not self.current_table: return
            name=self.current_table; term=self.search.get(); offset=self.offset
            info=next(t for t in self.catalog if t['name']==name)
        except (ValueError,StopIteration) as exc: return self._error(str(exc))
        def task(): return service.browse(name,search=term,limit=200,offset=offset),service.columns(name)
        def success(data):
            result,cols=data; self.metadata[name]=cols
            self.record_grid.fill(result['columns'],result['rows'])
            self.table_note.set(info.get('note','') or 'Selecciona una fila para editarla o pulsa Nuevo registro. Los cambios se guardan en MySQL.')
            self.new_button.configure(state='normal' if info.get('can_create') else 'disabled')
            self.edit_button.configure(state='normal' if info.get('can_update') else 'disabled')
            total=result['total']; n=len(result['rows'])
            self.pagination.set(f'{offset+1 if n else 0}–{offset+n} de {total} registros · Hasta 200 por página')
            self.prev_button.configure(state='normal' if offset>0 else 'disabled')
            self.next_button.configure(state='normal' if offset+n<total else 'disabled')
            self.status.set(info['label']+': registros cargados.')
        self._run('Cargando registros...',task,success)

    def _record_form(self,row=None):
        try: service=self._require_service()
        except ValueError as exc: return self._error(str(exc))
        if self.busy: return
        name=self.current_table; info=next(t for t in self.catalog if t['name']==name)
        editing=row is not None
        if not info.get('can_update' if editing else 'can_create'):
            return self._error(info.get('note','Usa la pestaña Operaciones para registrar este movimiento.'))
        meta=self.metadata.get(name,[])
        fields=[dict(c) for c in meta if c.get('editable_update' if editing else 'editable_create',False)]
        if not fields: return self._error('Este registro se consulta desde aquí. Usa Operaciones para cambiarlo.')
        for c in fields: c['required']=not c.get('nullable',False) and c.get('default') is None
        window=tk.Toplevel(self); window.title(('Editar registro' if editing else 'Nuevo registro')+' · '+info['label'])
        window.geometry('900x720'); window.minsize(720,500); window.transient(self); window.grab_set()
        def close_form():
            if self.busy:
                messagebox.showinfo('Guardado en curso','Espera a que termine el guardado antes de cerrar este formulario.',parent=window)
                return
            if window.winfo_exists(): window.destroy()
        window.protocol('WM_DELETE_WINDOW',close_form)
        ttk.Label(window,text=info['label'],font=('Segoe UI',17,'bold'),padding=(18,12)).pack(anchor='w')
        ttk.Label(window,text='Los campos con * son obligatorios. Guarda al terminar; Cancelar cierra sin guardar.',padding=(18,0),wraplength=830).pack(anchor='w')
        scroll=ScrollFrame(window); scroll.pack(fill='both',expand=True,padx=16,pady=12)
        try:
            form=DataForm(scroll.body,fields,lambda c,s:service.fk_options(name,c['name'],search=s),row)
            form.pack(fill='both',expand=True)
        except (ServiceError,ValueError) as exc:
            window.destroy(); return self._error(str(exc))
        self.active_form=form; self.active_form_window=window
        buttons=ttk.Frame(window,padding=16); buttons.pack(fill='x')
        form_status=tk.StringVar(value='')
        ttk.Label(buttons,textvariable=form_status,wraplength=600).pack(side='left')
        def save():
            if self.busy: return
            try:
                self._require_service(); values=form.values()
                keys={c['name']:row[c['name']] for c in meta if c.get('primary')} if editing else None
            except ValueError as exc: return messagebox.showerror('Revisa el formulario',str(exc),parent=window)
            def task(): return service.update(name,keys,values) if editing else service.create(name,values)
            def success(result):
                if window.winfo_exists(): window.destroy()
                self.status.set('Registro guardado en MySQL.'); self.load_records()
                messagebox.showinfo('Registro guardado','Los datos se guardaron. Usa Buscar si no aparecen en la página actual.',parent=self)
            self._run('Guardando registro...',task,success)
        ttk.Button(buttons,text='Cancelar',command=close_form).pack(side='right',padx=(6,0))
        ttk.Button(buttons,text='Guardar',style='Accent.TButton',command=save).pack(side='right')
        form.save=save; form.close=close_form

    def new_record(self):
        if self.current_table: self._record_form()
        else: self._error('Primero abre el hospital.')
    def edit_record(self):
        row=self.record_grid.selected()
        if row is None: return self._error('Haz clic en una fila de la tabla y después pulsa Editar seleccionado.')
        self._record_form(row)

    def _build_operations(self):
        page=self.pages['Operaciones']
        ttk.Label(page,text='Operaciones del hospital',font=('Segoe UI',16,'bold')).pack(anchor='w')
        ttk.Label(page,text='Estas acciones comprueban disponibilidad, existencias y saldos antes de guardar.',wraplength=1050).pack(anchor='w',pady=(5,12))
        self.workflow_picker=ttk.Combobox(page,state='readonly',width=75)
        self.workflow_picker.pack(fill='x'); self.workflow_picker.bind('<<ComboboxSelected>>',self.select_workflow)
        self.workflow_description=tk.StringVar(value='Abre el hospital y elige una operación de la lista.')
        ttk.Label(page,textvariable=self.workflow_description,wraplength=1080).pack(anchor='w',pady=12)
        self.workflow_scroll=ScrollFrame(page); self.workflow_scroll.pack(fill='both',expand=True)
        foot=ttk.Frame(page); foot.pack(fill='x',pady=(10,0))
        self.workflow_result=tk.StringVar(value='')
        ttk.Label(foot,textvariable=self.workflow_result,wraplength=850).pack(side='left')
        ttk.Button(foot,text='Guardar operación',style='Accent.TButton',command=self.save_workflow).pack(side='right')
        self.workflow_form=None; self.workflow_current=None

    def select_workflow(self,event=None):
        if self.busy:
            if self.workflow_current:
                for i,w in enumerate(self.workflows_data):
                    if w['name']==self.workflow_current['name']: self.workflow_picker.current(i)
            else: self.workflow_picker.set('')
            return
        try: service=self._require_service()
        except ValueError as exc: return self._error(str(exc))
        i=self.workflow_picker.current()
        if i<0: return
        workflow=self.workflows_data[i]; self.workflow_current=workflow
        self.workflow_description.set(workflow.get('description',''))
        self.workflow_result.set('')
        for child in self.workflow_scroll.body.winfo_children(): child.destroy()
        try:
            fields=[]
            for field in workflow['fields']:
                field=dict(field)
                field['data_type']=field.get('data_type',field.get('type','varchar'))
                if field.get('type')=='enum': field['enum_values']=field.get('enum_values',field.get('choices',[]))
                if field.get('type')=='reference' and not field.get('reference'): field['reference']=True
                fields.append(field)
            self.workflow_form=DataForm(self.workflow_scroll.body,fields,lambda f,s:service.workflow_options(workflow['name'],f['name'],search=s))
            self.workflow_form.pack(fill='both',expand=True)
        except (ValueError,ServiceError) as exc: self._error(str(exc))

    def save_workflow(self):
        try:
            service=self._require_service()
            if not self.workflow_form or not self.workflow_current: raise ValueError('Elige una operación de la lista.')
            workflow=self.workflow_current; values=self.workflow_form.values()
        except ValueError as exc: return self._error(str(exc))
        if self.busy: return
        if not messagebox.askyesno('Guardar operación',workflow['label']+': se guardará en la base '+service.settings.database+'.\n\n¿Continuar?',parent=self): return
        def success(result):
            self.workflow_result.set('Operación guardada. '+display(result.get('message',result.get('id',''))))
            self.status.set('Operación guardada en MySQL. Actualiza los registros o consultas para ver el resultado.')
            messagebox.showinfo('Operación guardada',self.workflow_result.get(),parent=self)
        self._run('Registrando la operación...',lambda:service.run_workflow(workflow['name'],values),success)

    def _build_reports(self):
        page=self.pages['Consultas']
        ttk.Label(page,text='Consultas listas para mostrar',font=('Segoe UI',16,'bold')).pack(anchor='w')
        ttk.Label(page,text='Elige una consulta y pulsa Ver consulta. La aplicación reúne los nombres y los detalles automáticamente.').pack(anchor='w',pady=(5,12))
        bar=ttk.Frame(page); bar.pack(fill='x')
        self.report_picker=ttk.Combobox(bar,state='readonly',width=75); self.report_picker.pack(side='left',fill='x',expand=True)
        ttk.Button(bar,text='Ver consulta',style='Accent.TButton',command=self.show_report).pack(side='left',padx=8)
        ttk.Button(bar,text='Exportar CSV',command=lambda:self.export_grid(self.report_grid)).pack(side='right')
        self.report_note=tk.StringVar(value='')
        ttk.Label(page,textvariable=self.report_note,wraplength=1100).pack(anchor='w',pady=10)
        self.report_grid=GridTable(page); self.report_grid.pack(fill='both',expand=True)
        self.reports_data=[]

    def show_report(self):
        try:
            service=self._require_service(); i=self.report_picker.current()
            if i<0: raise ValueError('Elige una consulta de la lista.')
            info=self.reports_data[i]
        except ValueError as exc: return self._error(str(exc))
        def success(result):
            self.report_grid.fill(result['columns'],result['rows'])
            self.report_note.set(info.get('description','')+f" · {len(result['rows'])} filas mostradas (máximo 500).")
            self.status.set('Consulta cargada. Puedes exportar las filas mostradas a CSV.')
        self._run('Consultando información...',lambda:service.report(info['name'],limit=500),success)

    def export_grid(self,grid):
        if not grid.columns: return self._error('Primero carga los registros o una consulta.')
        path=filedialog.asksaveasfilename(parent=self,title='Exportar las filas mostradas',defaultextension='.csv',filetypes=[('CSV para hojas de cálculo','*.csv')],initialfile='hospital_'+datetime.now().strftime('%Y%m%d_%H%M')+'.csv')
        if not path: return
        try:
            with open(path,'w',encoding='utf-8-sig',newline='') as file:
                writer=csv.writer(file); writer.writerow(grid.columns)
                for row in grid.rows:
                    values=[]
                    for column in grid.columns:
                        val=display(row.get(column))
                        # Prevent spreadsheet formulas when users later open the CSV.
                        if val.startswith(('=','+','-','@','\t','\r')): val="'"+val
                        values.append(val)
                    writer.writerow(values)
            self.status.set(f'Se exportaron {len(grid.rows)} filas mostradas. El CSV no es un respaldo completo.')
            messagebox.showinfo('CSV guardado',f'Se exportaron {len(grid.rows)} filas. Para conservar toda la base usa Crear respaldo completo en Inicio.',parent=self)
        except OSError: self._error('No se pudo guardar el CSV. Elige una carpeta con permiso de escritura.')

    def backup(self):
        try: service=self._require_service()
        except ValueError as exc: return self._error(str(exc))
        path=filedialog.asksaveasfilename(parent=self,title='Guardar respaldo completo',defaultextension='.hospital.json',initialfile=service.settings.database+'_'+datetime.now().strftime('%Y%m%d_%H%M')+'.hospital.json',filetypes=[('Respaldo del hospital','*.hospital.json')])
        if not path: return
        self._run('Creando una copia completa de los datos...',lambda:service.export_backup(path),lambda result:(self.status.set('Respaldo completo guardado.'),messagebox.showinfo('Respaldo guardado','La copia contiene las 36 tablas y sus registros. Guárdala en un lugar que puedas encontrar. No contiene la contraseña de conexión.',parent=self)))

    def restore(self):
        try: service=HospitalService(self._settings())
        except (ValueError,ServiceError) as exc: return self._error(str(exc))
        path=filedialog.askopenfilename(parent=self,title='Elegir respaldo del hospital',filetypes=[('Respaldo del hospital','*.hospital.json'),('JSON','*.json')])
        if not path: return
        if not messagebox.askyesno('Restaurar en una base nueva','Destino: '+service.settings.database+'.\n\nEl nombre del campo Base de datos debe ser NUEVO. Si ya existe, se rechazará la restauración. Cambia ese campo antes de continuar si quieres conservar la base actual.\n\n¿Crear este destino nuevo desde el respaldo?',parent=self): return
        self._run('Restaurando los datos en la base nueva...',lambda:service.restore_backup(path),lambda result:(self.status.set('Respaldo restaurado. Pulsa Abrir hospital.'),messagebox.showinfo('Restauración terminada','Se creó el destino nuevo con los datos del respaldo. Pulsa Abrir hospital.',parent=self)))

    def _build_help(self):
        page=self.pages['Guía']
        ttk.Label(page,text='Cómo usar el programa',font=('Segoe UI',17,'bold')).pack(anchor='w')
        guide='''PRIMER USO
1. Instala Python y MySQL Server. El programa necesita que MySQL esté iniciado.
2. Escribe los datos de conexión de MySQL en los campos de arriba.
3. Pulsa Probar conexión. Después, Crear base con ejemplos una sola vez.
4. Pulsa Abrir hospital. Inicio muestra los conteos de las 36 tablas.

AGREGAR INFORMACIÓN
En Registros elige Pacientes, pulsa Nuevo registro, completa los campos y Guarda.
Las listas de relaciones muestran nombres para elegir médicos, pacientes o consultas.
Algunas tablas guardan historial: para citas, entregas, movimientos y pagos usa Operaciones.

VER Y GUARDAR UNA COPIA
Consultas reúne información de varias tablas sin que escribas código.
Exportar CSV guarda solo las filas que estás viendo. Crear respaldo completo conserva toda la base.

FECHAS
Fecha: AAAA-MM-DD, por ejemplo 2002-03-15.
Fecha y hora: AAAA-MM-DD HH:MM:SS, por ejemplo 2026-10-20 09:00:00.
Un campo opcional vacío se guarda sin dato o con el valor inicial que indique el sistema.

SI YA TIENES UNA BASE
Usa Abrir hospital. Crear base con ejemplos y Restaurar nunca reemplazan una base existente.
Las cuentas de usuarios de las tablas son parte del modelo académico; este programa usa la conexión MySQL.
'''
        text=tk.Text(page,wrap='word',font=('Segoe UI',11),background='white',foreground=INK,relief='flat',padx=20,pady=18)
        text.insert('1.0',guide); text.configure(state='disabled'); text.pack(fill='both',expand=True,pady=12)
        line=ttk.Frame(page); line.pack(fill='x')
        ttk.Button(line,text='Abrir tutorial PDF',style='Accent.TButton',command=lambda:self.open_file(ROOT/'tutorial_interfaz'/'tutorial_interfaz_hospital.pdf')).pack(side='left')
        ttk.Button(line,text='Abrir tutorial Word',command=lambda:self.open_file(ROOT/'tutorial_interfaz'/'tutorial_interfaz_hospital.docx')).pack(side='left',padx=8)
        ttk.Button(line,text='Abrir carpeta del proyecto',command=lambda:self.open_file(ROOT)).pack(side='left')

    def open_file(self,path):
        if not path.exists(): return self._error('No se encontró este archivo. Extrae o descarga la carpeta completa del proyecto.')
        try:
            if os.name=='nt': os.startfile(str(path))
            else: webbrowser.open(path.as_uri())
        except OSError: self._error('No se pudo abrir el archivo. Ábrelo desde la carpeta del proyecto.')

    def close(self):
        if self.busy:
            messagebox.showinfo('Operación en curso','Espera a que termine la operación antes de cerrar el programa.',parent=self)
            return
        self.connection_vars['password'].set(''); self.service=None; self.destroy()


def main():
    app=HospitalApp(); app.mainloop()


if __name__=='__main__': main()
