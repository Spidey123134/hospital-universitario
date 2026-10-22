"""Documentación reproducible del esquema; no modifica ni ejecuta SQL.

Python 3 + reportlab. SVG y Mermaid se generan del mismo DDL que el diccionario.
Las pruebas SQL se ejecutan por separado; ESTADO_PRUEBAS debe describir evidencia real.
"""
from pathlib import Path
import re
import json
import html
import math
from collections import OrderedDict

BASE = Path(__file__).resolve().parent
DIAGRAMAS = BASE / 'diagramas'
ESTADO_PRUEBAS = 'Pendiente de ejecución documentada en MySQL. No se atribuyen resultados a pruebas que aún no se han confirmado.'
VERSION_VALIDADA = 'MySQL 8.0.45, instancia temporal de pruebas en modo estricto.'

def evidencia_pruebas():
    path=BASE/'VALIDACION.json'
    if not path.exists(): return None
    evidence=json.loads(path.read_text(encoding='utf-8-sig'))
    summary=evidence['resumen']
    evidence['texto_documental']=(f"La ejecución documentada en VALIDACION.json está {evidence['estado']}: "
        f"{summary['correctas']} de {summary['total']} comprobaciones correctas y {summary['fallidas']} fallidas. "
        "Incluye carga del proyecto, consistencia del modelo y datos, ejecución de las 20 consultas, "
        "rechazos esperados y dos pruebas con sesiones concurrentes (agenda e inventario). "
        +('La base temporal de pruebas se eliminó correctamente.' if evidence['limpieza']['correcta'] else 'La limpieza de la base temporal requiere revisión.'))
    return evidence

MODULOS = OrderedDict([
    ('organizacion', ('Organización y personas', ['departamentos','especialidades','personal','medicos','medico_especialidad','pacientes','contactos_emergencia','aseguradoras','polizas'])),
    ('infraestructura', ('Infraestructura', ['habitaciones','camillas'])),
    ('atencion', ('Atención clínica', ['citas','consultas','diagnosticos','consulta_diagnosticos','alergias_paciente'])),
    ('hospitalizacion', ('Hospitalización', ['hospitalizaciones','asignaciones_camilla','notas_enfermeria'])),
    ('farmacia', ('Farmacia e inventario', ['medicamentos','proveedores','lotes_medicamento','recetas','receta_detalle','dispensaciones','dispensacion_detalle','movimientos_inventario'])),
    ('procedimientos', ('Estudios y procedimientos', ['procedimientos','ordenes_procedimiento','resultados_procedimiento'])),
    ('cobros', ('Cobros', ['facturas','factura_detalle','pagos'])),
    ('acceso', ('Acceso de la aplicación', ['roles','usuarios','usuario_roles'])),
])
COLORES = ['#155E75','#4D7C0F','#2563EB','#7C3AED','#B45309','#BE185D','#047857','#475569']
PROPOSITOS = {
 'departamentos':'Catálogo de áreas organizativas del hospital.',
 'especialidades':'Catálogo de especialidades profesionales.',
 'personal':'Identidad laboral común de médicos y otros trabajadores.',
 'medicos':'Subtipo de personal con cédula profesional única; comparte su identificador con personal.',
 'medico_especialidad':'Relación de muchos a muchos entre médicos y especialidades.',
 'pacientes':'Identidad del paciente, expediente y datos de contacto básicos.',
 'contactos_emergencia':'Contactos ordenados por prioridad para un paciente.',
 'aseguradoras':'Catálogo de entidades aseguradoras.',
 'polizas':'Cobertura básica de un paciente con vigencia; no liquida reclamaciones.',
 'habitaciones':'Ubicación física por departamento, edificio, piso y tipo.',
 'camillas':'Camilla física y condición operativa; la ocupación se obtiene de asignaciones.',
 'citas':'Intervalo planeado entre un paciente y un médico; permite cancelación.',
 'consultas':'Evento de atención clínica, con o sin cita, que determina paciente y médico.',
 'diagnosticos':'Catálogo de diagnósticos; los códigos de demostración no constituyen un catálogo clínico oficial.',
 'consulta_diagnosticos':'Diagnósticos de una consulta y marca de principal; máximo un principal por consulta.',
 'alergias_paciente':'Registro básico de sustancia y reacción informada por paciente.',
 'hospitalizaciones':'Estancia derivada de una consulta de ingreso, con responsable, ingreso y alta.',
 'asignaciones_camilla':'Historial temporal de ocupación y traslados de una hospitalización.',
 'notas_enfermeria':'Observaciones de personal de enfermería durante una estancia.',
 'medicamentos':'Catálogo de productos con concentración, presentación y unidad de inventario.',
 'proveedores':'Catálogo de proveedores de medicamentos.',
 'lotes_medicamento':'Lote de un producto recibido de un proveedor, con caducidad y costo histórico.',
 'recetas':'Encabezado de prescripción asociado a una consulta.',
 'receta_detalle':'Indicaciones y cantidad prescrita por renglón; permite varios medicamentos por receta.',
 'dispensaciones':'Evento de entrega de una receta por personal de farmacia; admite entregas parciales.',
 'dispensacion_detalle':'Cantidad de un renglón prescrito entregada desde un lote compatible.',
 'movimientos_inventario':'Libro de entradas, salidas y ajustes firmados; existencia = suma de cantidades por lote.',
 'procedimientos':'Catálogo común de estudios de laboratorio, imagen, cirugía y otros procedimientos.',
 'ordenes_procedimiento':'Solicitud de un único procedimiento a partir de una consulta.',
 'resultados_procedimiento':'Un informe final por orden; no implementa versiones de resultados.',
 'facturas':'Cuenta académica del paciente, con póliza opcional del mismo paciente.',
 'factura_detalle':'Cargos con descripción y precio históricos; importe generado por renglón.',
 'pagos':'Pagos parciales positivos asociados a una factura.',
 'roles':'Roles conceptuales de la futura aplicación; no son roles del servidor MySQL.',
 'usuarios':'Cuenta vinculada a un trabajador; campo para hash, sin motor de autenticación.',
 'usuario_roles':'Relación de muchos a muchos entre cuentas de aplicación y roles.',
}
REFERENCIAS = [
 ('Claves foráneas y acciones referenciales', 'https://dev.mysql.com/doc/refman/8.0/en/create-table-foreign-keys.html'),
 ('Restricciones CHECK y versión 8.0.16', 'https://dev.mysql.com/doc/refman/8.0/en/create-table-check-constraints.html'),
 ('Columnas generadas', 'https://dev.mysql.com/doc/refman/8.0/en/create-table-generated-columns.html'),
 ('Lecturas con bloqueo de InnoDB', 'https://dev.mysql.com/doc/refman/8.0/en/innodb-locking-reads.html'),
 ('Metadatos SDI de InnoDB', 'https://dev.mysql.com/doc/refman/8.0/en/serialized-dictionary-information.html'),
 ('Importación de espacios de tablas', 'https://dev.mysql.com/doc/refman/8.0/en/innodb-table-import.html'),
]

def split_sql(text):
    out, buf, depth, quoted = [], [], 0, False
    for c in text:
        if c == "'": quoted = not quoted
        if not quoted:
            if c == '(': depth += 1
            elif c == ')': depth -= 1
            elif c == ',' and depth == 0:
                out.append(''.join(buf).strip()); buf=[]; continue
        buf.append(c)
    if buf: out.append(''.join(buf).strip())
    return out

def parse_ddl():
    source = (BASE/'01_esquema.sql').read_text(encoding='utf-8-sig')
    source = re.sub(r'--[^\n]*', '', source)
    tables = OrderedDict()
    for name, body in re.findall(r'CREATE TABLE\s+(\w+)\s*\((.*?)\)\s*ENGINE=InnoDB;', source, re.S|re.I):
        obj={'name':name,'columns':[],'pk':[],'unique':[],'fks':[],'checks':[],'indexes':[]}
        for piece in split_sql(body):
            fm = re.search(r'CONSTRAINT\s+(\w+)\s+FOREIGN KEY\s*\(([^)]+)\)\s+REFERENCES\s+(\w+)\s*\(([^)]+)\)',piece,re.I)
            if fm:
                obj['fks'].append({'name':fm[1], 'cols':[x.strip() for x in fm[2].split(',')], 'parent':fm[3], 'refs':[x.strip() for x in fm[4].split(',')]}); continue
            pm = re.match(r'PRIMARY KEY\s*\(([^)]+)\)',piece,re.I)
            if pm: obj['pk']=[x.strip() for x in pm[1].split(',')]; continue
            um = re.match(r'UNIQUE\s*\(([^)]+)\)',piece,re.I)
            if um: obj['unique'].append([x.strip() for x in um[1].split(',')]); continue
            if re.match('CONSTRAINT',piece,re.I):
                cm=re.match(r'CONSTRAINT\s+(\w+)\s+CHECK\s*\((.*)\)$',piece,re.S|re.I)
                if cm: obj['checks'].append((cm[1],cm[2]))
                continue
            if re.match('KEY',piece,re.I): obj['indexes'].append(piece); continue
            colm=re.match(r'(\w+)\s+((?:ENUM\([^)]*\))|(?:[A-Z]+(?:\([^)]*\))?(?:\s+UNSIGNED)?))(.*)',piece,re.S)
            if not colm: raise ValueError((name,piece))
            cname, ctype, rest=colm.groups()
            gen = re.search(r'GENERATED ALWAYS AS\s*\((.*)\)\s+STORED',rest,re.S|re.I)
            default = re.search(r'DEFAULT\s+(.+?)(?=\s+(?:UNIQUE|PRIMARY|CHECK)|$)',rest,re.S|re.I)
            col={'name':cname,'type':ctype,'nullable':not bool(re.search(r'NOT NULL|PRIMARY KEY',rest,re.I)),'default':default[1].strip() if default else '', 'generated':gen[1].strip() if gen else '', 'auto':'AUTO_INCREMENT' in rest}
            if 'PRIMARY KEY' in rest: obj['pk'].append(cname)
            if re.search(r'\bUNIQUE\b',rest): obj['unique'].append([cname])
            obj['columns'].append(col)
        for col in obj['columns']:
            if col['name'] in obj['pk']: col['nullable']=False
            col['fk']=[f['name'] for f in obj['fks'] if col['name'] in f['cols']]
            col['uk']=any(col['name'] in u for u in obj['unique'])
        tables[name]=obj
    assert len(tables)==36, len(tables)
    expected=[t for _,(_,names) in MODULOS.items() for t in names]
    assert set(expected)==set(tables)
    for name,t in tables.items():
        assert t['pk'], name
        for f in t['fks']:
            assert f['parent'] in tables
            assert all(x in [c['name'] for c in t['columns']] for x in f['cols'])
            assert all(x in [c['name'] for c in tables[f['parent']]['columns']] for x in f['refs'])
    return tables

def original_metadata():
    out={}
    for path in sorted((BASE/'evidencia_original').glob('*.sdi.json')):
        data=json.loads(path.read_text(encoding='utf-8-sig'))
        table=next(x['dd_object'] for x in data if x.get('dd_object_type')=='Table')
        out[table['name']]={'cols':[(c['name'],c['column_type_utf8'],c['is_nullable']) for c in table['columns'] if c['hidden']==1], 'fks':[(f['name'],f['referenced_table_name'],f['delete_rule']) for f in table['foreign_keys']]}
    assert len(out)==5
    return out

def keys(table,col):
    out=[]
    if col['name'] in table['pk']: out.append('PK')
    if col['fk']: out.append('FK')
    if col['uk']: out.append('UK*')
    if col['auto']: out.append('AI')
    if col['generated']: out.append('G')
    return ', '.join(out) or '-'

def fk_optional(t,f):
    return any(c['nullable'] for c in t['columns'] if c['name'] in f['cols'])

def fk_child_one(t,f):
    return any(set(k).issubset(f['cols']) for k in [t['pk']]+t['unique'])

def mermaid(tables, names):
    names=list(names)
    out=['erDiagram']
    for name in names:
        t=tables[name]; out.append(f'    {name} {{')
        for c in t['columns']:
            dtype='ENUM' if c['type'].startswith('ENUM(') else re.sub(r'[^a-zA-Z0-9_]', '_', c['type']).strip('_')
            marks=[]
            if c['name'] in t['pk']: marks.append('PK')
            if c['fk']: marks.append('FK')
            if c['uk']: marks.append('UK')
            note=('NULL' if c['nullable'] else 'NOT NULL') + ('; GENERATED STORED' if c['generated'] else '')
            out.append(f'        {dtype} {c["name"]}' + (' '+', '.join(marks) if marks else '') + f' "{note}"')
        out.append('    }')
    for child in names:
        t=tables[child]
        for f in t['fks']:
            if f['parent'] not in names: continue
            parent_end='|o' if fk_optional(t,f) else '||'
            child_end='o|' if fk_child_one(t,f) else 'o{'
            sep='--' if set(f['cols']).issubset(t['pk']) else '..'
            out.append(f'    {f["parent"]} {parent_end}{sep}{child_end} {child} : "{f["name"]}"')
    out+=['', '%% PK=clave primaria; FK=foránea; UK=participa en restricción única (puede ser compuesta).', '%% Opcionalidad y cardinalidad se calculan de NULL y claves únicas declaradas.', '%% Un padre puede tener cero hijos: la FK no obliga a crear filas dependientes.', '%% Consulte DICCIONARIO.md para ENUM, claves compuestas y expresiones completas.']
    return '\n'.join(out)+'\n'

def svg_er(tables,names,title,path,columns=3,full=False):
    names=list(names); width_card=410; col_step=555; row_step=465; xmargin=120; ymargin=200
    rows=math.ceil(len(names)/columns); width=xmargin*2+columns*col_step-110; height=ymargin+rows*row_step+170
    palette={n:COLORES[i] for i,(_,(_,ns)) in enumerate(MODULOS.items()) for n in ns}
    positions={n:(xmargin+(i%columns)*col_step, ymargin+(i//columns)*row_step) for i,n in enumerate(names)}
    esc=lambda s:html.escape(str(s),quote=True)
    out=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
         '<defs><marker id="many" markerWidth="16" markerHeight="20" refX="14" refY="10" orient="auto" overflow="visible"><path d="M 2 2 L 14 10 L 2 18 M 2 10 L 14 10" fill="none" stroke="#64748b" stroke-width="1.6"/><circle cx="0" cy="10" r="2.5" fill="white" stroke="#64748b"/></marker><marker id="one" markerWidth="16" markerHeight="20" refX="14" refY="10" orient="auto" overflow="visible"><path d="M 8 2 L 8 18" stroke="#64748b" stroke-width="1.6"/><circle cx="0" cy="10" r="2.5" fill="white" stroke="#64748b"/></marker></defs>',
         f'<rect width="{width}" height="{height}" fill="#f8fafc"/>',
         f'<text x="55" y="50" font-family="Segoe UI,Arial,sans-serif" font-size="30" font-weight="700" fill="#0f172a">{esc(title)}</text>',
         '<text x="55" y="84" font-family="Segoe UI,Arial,sans-serif" font-size="17" fill="#475569">MySQL · PK primaria · FK foránea · UK* participa en UNIQUE (puede ser compuesto) · G generado · ? permite NULL</text>',
         '<text x="55" y="112" font-family="Segoe UI,Arial,sans-serif" font-size="16" fill="#475569">Las conexiones van de padre a hijo. Círculo + pata de cuervo = 0..N hijos; círculo + barra = 0..1 hijo.</text>']
    edges=[]
    for child in names:
        for f in tables[child]['fks']:
            if f['parent'] in names: edges.append((child,f))
    for ix,(child,f) in enumerate(edges):
        px,py=positions[f['parent']]; cx,cy=positions[child]
        ph=50+len(tables[f['parent']]['columns'])*24
        ch=50+len(tables[child]['columns'])*24
        shift=(ix%8)*7
        if px==cx:
            x1=px+width_card; y1=py+25+shift; x2=cx+width_card; y2=cy+25+shift
            route=x1+25+(ix%5)*11
            d=f'M{x1},{y1} H{route} V{y2} H{x2}'
            lx=route+4; ly=(y1+y2)/2
        else:
            left_to_right=cx>px
            x1=px+(width_card if left_to_right else 0); y1=py+25+shift
            x2=cx+(0 if left_to_right else width_card); y2=cy+25+shift
            if py==cy:
                bridge=min(py,cy)-20-(ix%5)*10
                d=f'M{x1},{y1} H{x1+(20 if left_to_right else -20)} V{bridge} H{x2-(20 if left_to_right else -20)} V{y2} H{x2}'
                lx=(x1+x2)/2; ly=bridge-3
            else:
                route=(x1+x2)/2 + shift
                d=f'M{x1},{y1} H{route} V{y2} H{x2}'
                lx=route+5; ly=(y1+y2)/2
        mark='one' if fk_child_one(tables[child],f) else 'many'
        out.append(f'<path d="{d}" fill="none" stroke="#64748b" stroke-opacity="0.54" stroke-width="1.7" marker-end="url(#{mark})"/>')
        out.append(f'<text x="{lx}" y="{ly}" font-family="Arial,sans-serif" font-size="12" fill="#334155" paint-order="stroke" stroke="#f8fafc" stroke-width="4">F{ix+1:02d}</text>')
    for name in names:
        t=tables[name]; x,y=positions[name]; h=50+len(t['columns'])*24
        color=palette[name]
        out.extend([f'<g data-table="{name}" data-x="{x}" data-y="{y}" data-width="{width_card}" data-height="{h}">',f'<rect x="{x}" y="{y}" width="{width_card}" height="{h}" rx="9" fill="white" stroke="{color}" stroke-width="2"/>',
                    f'<path d="M{x+9} {y} H{x+width_card-9} Q{x+width_card} {y} {x+width_card} {y+9} V{y+38} H{x} V{y+9} Q{x} {y} {x+9} {y}" fill="{color}"/>',
                    f'<text x="{x+12}" y="{y+26}" font-family="Segoe UI,Arial,sans-serif" font-weight="700" font-size="19" fill="white">{esc(name)}</text>'])
        for i,c in enumerate(t['columns']):
            yy=y+61+i*24
            dtype=c['type'].split('(')[0].split()[0]
            k=keys(t,c).replace(', ', '/')
            if c['nullable']: k+=' ?'
            if i%2==0: out.append(f'<rect x="{x+1}" y="{yy-17}" width="{width_card-2}" height="24" fill="#f1f5f9"/>')
            out.append(f'<text x="{x+10}" y="{yy}" font-family="Consolas,monospace" font-size="14" fill="#0f172a">{esc(c["name"])}</text>')
            out.append(f'<text x="{x+288}" y="{yy}" font-family="Arial,sans-serif" font-size="11" fill="#475569">{esc(dtype)} {esc(k)}</text>')
        out.append('</g>')
    foot_y=ymargin+rows*row_step+15
    out.append(f'<text x="55" y="{foot_y}" font-family="Arial,sans-serif" font-size="17" fill="#0f172a">{len(names)} entidades · {len(edges)} claves foráneas visibles · zoom recomendado: 100% o más.</text>')
    out.append(f'<text x="55" y="{foot_y+28}" font-family="Arial,sans-serif" font-size="15" fill="#475569">El catálogo numerado de relaciones está en el archivo {esc(path.stem)}_relaciones.md; Mermaid conserva nombres completos de FK.</text>')
    out.append(f'<text x="55" y="{foot_y+55}" font-family="Arial,sans-serif" font-size="15" fill="#475569">La obligatoriedad del padre se ve en el FK del hijo: ? = referencia opcional; sin ? = obligatoria. Tipos completos en DICCIONARIO.md.</text>')
    out.append('</svg>')
    path.write_text('\n'.join(out),encoding='utf-8')
    catalog=[f'# Relaciones de {title}', '', 'Identificadores Fxx impresos junto a conexiones del SVG. La cardinalidad expresa lo permitido por el DDL.', '', '| ID | Padre | Hijo | Columnas FK → columnas padre | Padre requerido por hijo | Hijos por padre | Restricción |', '| --- | --- | --- | --- | --- | --- | --- |']
    for i,(child,f) in enumerate(edges):
        catalog.append(f'| F{i+1:02d} | `{f["parent"]}` | `{child}` | `{", ".join(f["cols"])}` → `{", ".join(f["refs"])}` | {"No" if fk_optional(tables[child],f) else "Sí"} | {"0..1" if fk_child_one(tables[child],f) else "0..N"} | `{f["name"]}` |')
    catalog+=['','Las FKs compuestas vinculan una combinación coherente. No deben interpretarse como relaciones independientes por columna. Las reglas transaccionales pueden imponer condiciones adicionales al DDL.']
    path.with_name(path.stem+'_relaciones.md').write_text('\n'.join(catalog)+'\n',encoding='utf-8')

def module_svg():
    positions=[(65,170),(670,170),(1275,170),(65,425),(670,425),(1275,425),(65,680),(670,680)]
    W,H=1850,1000; out=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs><marker id="arrow" markerWidth="12" markerHeight="10" refX="10" refY="5" orient="auto"><path d="M0 0 L10 5 L0 10" fill="#64748b"/></marker></defs><rect width="100%" height="100%" fill="#f8fafc"/>', '<text x="65" y="68" font-family="Segoe UI,Arial,sans-serif" font-size="42" font-weight="700" fill="#0f172a">Hospital universitario</text>', '<text x="65" y="110" font-family="Segoe UI,Arial,sans-serif" font-size="25" fill="#475569">36 tablas · 8 módulos · modelo académico de punta a punta</text>']
    for i,(key,(name,ns)) in enumerate(MODULOS.items()):
        x,y=positions[i]
        out.append(f'<rect x="{x}" y="{y}" width="515" height="205" rx="18" fill="white" stroke="{COLORES[i]}" stroke-width="3"/>')
        out.append(f'<rect x="{x}" y="{y}" width="8" height="205" rx="4" fill="{COLORES[i]}"/>')
        out.append(f'<text x="{x+25}" y="{y+42}" font-family="Segoe UI,Arial,sans-serif" font-size="25" font-weight="700" fill="{COLORES[i]}">{html.escape(name)} ({len(ns)})</text>')
        lines=[]; buf=''
        for n in ns:
            value=n.replace('_',' ')
            if len(buf)+len(value)+3>48: lines.append(buf); buf=''
            buf += (' · ' if buf else '')+value
        if buf: lines.append(buf)
        for j,line in enumerate(lines): out.append(f'<text x="{x+25}" y="{y+78+j*25}" font-family="Segoe UI,Arial,sans-serif" font-size="18" fill="#334155">{html.escape(line)}</text>')
    x,y=positions[7]
    out.append('<text x="1275" y="748" font-family="Segoe UI,Arial,sans-serif" font-size="22" fill="#0f172a">Recorrido demostrable</text>')
    for j,line in enumerate(['Paciente → cita → consulta', 'Diagnóstico → receta / orden', 'Entrega / resultado → cargo → pago']):
        out.append(f'<text x="1275" y="{790+j*31}" font-family="Segoe UI,Arial,sans-serif" font-size="19" fill="#475569">{html.escape(line)}</text>')
    out.append('<text x="65" y="950" font-family="Segoe UI,Arial,sans-serif" font-size="21" fill="#475569">Prescripción ≠ entrega · Operación de camilla ≠ ocupación · Tarifa actual ≠ precio histórico</text></svg>')
    (DIAGRAMAS/'vision_modulos.svg').write_text('\n'.join(out),encoding='utf-8')
    (DIAGRAMAS/'vision_modulos.mmd').write_text('''flowchart LR
    P[Paciente y cobertura] --> C[Cita o urgencia]
    C --> Q[Consulta y diagnóstico]
    Q --> H[Hospitalización y camilla]
    H --> N[Notas de enfermería]
    Q --> R[Receta y detalle]
    R --> D[Dispensación]
    L[Lotes y movimientos] --> D
    D --> I[Salida de inventario]
    Q --> O[Orden de procedimiento]
    O --> E[Resultado]
    Q --> F[Factura académica]
    F --> G[Pagos parciales]
    A[Personal y roles de aplicación] -. operación .-> Q
''',encoding='utf-8')

def markdown_dictionary(tables):
    out=['# Diccionario de datos', '', 'Fuente de verdad: `01_esquema.sql`. Generado del DDL, no de capturas. MySQL 8.0.16 o posterior; InnoDB y utf8mb4.', '', 'PK = clave primaria; FK = clave foránea; UK* = participa en una restricción UNIQUE, que puede ser compuesta; AI = AUTO_INCREMENT; G = columna generada STORED. La columna NULL indica si se admite NULL. BOOLEAN equivale a un entero lógico; los CHECK limitan valores a 0/1. No se incluyen columnas internas de InnoDB.', '', 'Las claves compuestas completas se enumeran bajo cada tabla. El símbolo UK* por columna no afirma unicidad individual. Sin una cláusula ON DELETE/ON UPDATE explícita, InnoDB restringe cambios del padre con hijos asociados [Manual MySQL](https://dev.mysql.com/doc/refman/8.0/en/create-table-foreign-keys.html).', '']
    ix=0
    for key,(title,ns) in MODULOS.items():
        out.extend([f'## {title}',''])
        for name in ns:
            ix+=1; t=tables[name]
            out.extend([f'### {ix:02d}. {name}', '',PROPOSITOS[name], '', '| Campo | Tipo SQL | NULL | Claves | Predeterminado / expresión |', '| --- | --- | --- | --- | --- |'])
            for c in t['columns']:
                value=('Generado: '+c['generated']) if c['generated'] else c['default'] or ('Secuencia automática' if c['auto'] else '-')
                out.append(f'| `{c["name"]}` | `{c["type"]}` | {"Sí" if c["nullable"] else "No"} | {keys(t,c)} | `{value.replace("|","&#124;")}` |')
            out.extend(['', '**PK:** `'+', '.join(t['pk'])+'`.'])
            if t['unique']: out.append('**UNIQUE:** '+ '; '.join('`('+', '.join(u)+')`' for u in t['unique'])+'.')
            for f in t['fks']: out.append(f'- **{f["name"]}:** `({", ".join(f["cols"])})` → `{f["parent"]}({", ".join(f["refs"])})`.')
            if t['checks']:
                out.append(''); out.append('**CHECK:**')
                for name_check, expr in t['checks']: out.append(f'- `{name_check}`: `{expr}`.')
            if t['indexes']: out.append('\n**Índices adicionales:** '+ '; '.join('`'+i+'`' for i in t['indexes'])+'.')
            out.append('')
    out.extend(['## Campos y valores calculados', '', '- Edad: calcular desde `pacientes.fecha_nacimiento` para la fecha consultada; no se almacena.', '- Existencia por lote: `SUM(movimientos_inventario.cantidad)`. Entradas positivas, salidas negativas y ajustes con signo.', '- Total de factura: suma de `factura_detalle.importe`. Saldo: total menos suma de pagos. No existe un total editable independiente.', '- Disponibilidad de camilla: condición operativa habilitada y ausencia de asignación activa; también deben respetarse los períodos consultados.', '- `medico_agenda`, `paciente_agenda`, `diagnostico_principal`, `paciente_internado`, `camilla_ocupada` y `hospitalizacion_asignada` son auxiliares generados de restricciones, sin significado clínico nuevo.', '- `factura_detalle.importe` es un cálculo determinista generado; descripción y precio_unitario son instantáneas históricas deliberadas.', '', '## Unidad y dominio', '', 'Una sola moneda académica: pesos mexicanos (MXN), sin conversión. Los importes usan DECIMAL con dos decimales. Las cantidades de inventario son enteras y se expresan en unidad_inventario; las cantidades cobradas permiten fracciones. Las fechas de calendario usan DATE y eventos DATETIME; el proyecto asume una zona local común, America/Mexico_City. SQL no incorpora automáticamente esa política de zona horaria.', '', 'No debe ingresarse una contraseña en texto claro en password_hash. El sistema de ejemplo no autentica personas ni concede permisos del servidor MySQL.'])
    return '\n'.join(out)+'\n'

MODELO = '''# Modelo hospitalario y justificación

## Objetivo y alcance

Diseñar una base relacional de un hospital para un proyecto universitario de sistemas en MySQL. El modelo conecta identidad, atención, hospitalización, farmacia, estudios y cobros, y aporta un soporte conceptual para el acceso de una aplicación. Son 36 tablas distribuidas en 8 módulos. El diseño parte de cinco tablas entregadas como prototipo; ampliar el alcance no supone que ese prototipo cubriera todos estos procesos.

La propuesta es una base académica amplia. La consigna del profesor sigue pendiente: ajustar cantidad de registros, diagramas o formato final conforme a la rúbrica. No se inventan institución, autor, grupo ni matrícula.

## Evidencia del prototipo

Se recuperaron metadatos SDI de camillas.ibd, medicamentos.ibd, medicos.ibd, pacientes.ibd y recetas.ibd. El manifiesto registra huellas SHA-256 y versión 80029 (MySQL 8.0.29). Esta versión corresponde a los archivos revisados, no certifica la instalación local actual. Se conservan las estructuras JSON en evidencia_original; los registros originales todavía no se han recuperado ni validado.

Aspectos aprovechables: claves primarias enteras, expediente y cédula únicos, separación de médicos/pacientes/medicamentos/camillas y relaciones con receta. Limitaciones estructurales detectadas:

| Prototipo | Efecto permitido | Cambio del modelo |
| --- | --- | --- |
| Una receta tiene un medicamento_id | Varios medicamentos requieren repetir encabezados | recetas + receta_detalle |
| camilla_id obligatorio en recetas | La receta ambulatoria exige camilla | Ocupación en hospitalizaciones/asignaciones_camilla |
| Cinco tablas sin estancia ni traslados | No representa ingreso, alta e historial de ocupación | Hospitalización y asignaciones temporales |
| Fecha de receta admite NULL | Puede quedar una prescripción sin fecha | Fecha NOT NULL con valor predeterminado |
| FK receta-paciente con borrado cascada | Borrar paciente puede borrar recetas | Restricción de borrado e inactivación de entidades |
| Estado de camilla libre y nullable | Mezcla funcionamiento con ocupación | ENUM operativo y ocupación calculada |

Estos son comportamientos posibles del esquema; no se afirma que existan filas inválidas. Cambiar de estructura requiere una migración explícita. Los scripts propuestos no importan los .ibd y no modifican los originales.

## Modelo conceptual

El paciente es la identidad común de la atención. La cita es un plan; la consulta es el evento realizado y puede registrar urgencias sin cita. La consulta vincula diagnósticos y origina recetas, órdenes o una estancia. La hospitalización conserva su responsable y las asignaciones permiten traslados sin reescribir el historial.

Personal almacena datos laborales comunes; medicos es un subtipo con el mismo identificador y su cédula. Medico_especialidad resuelve la relación de muchos a muchos. Contactos y pólizas dependen del paciente. Departamentos y habitaciones organizan recursos físicos, y camillas conserva su estado operativo.

En farmacia, medicamentos describe el producto y lotes_medicamento identifica recepciones, proveedor y caducidad. Recetar no reduce existencias: dispensaciones registra entregas y movimientos_inventario registra su impacto. La cantidad disponible se calcula con el libro de movimientos. Una receta puede entregarse parcialmente y desde varios lotes compatibles, sin superar la cantidad prescrita.

Procedimientos agrupa laboratorio, imagen, cirugía y otros. Cada orden solicita un procedimiento, y puede tener cero o un resultado final. Solicitar varios procedimientos genera varias órdenes; el modelo no guarda versiones de informes.

Facturas es una cuenta académica, no un comprobante fiscal CFDI. Sus detalles conservan descripción y precio al emitir el cargo; pagos almacena eventos parciales. La póliza, si existe, pertenece al mismo paciente de la cuenta. Usuarios y roles describen autorización futura de una aplicación; no implementan autenticación ni GRANT del servidor.

## Cardinalidades y opcionalidad

- Un paciente puede tener cero o muchas citas, consultas, pólizas, alergias y contactos. Cada una de esas filas pertenece a un paciente.
- Un trabajador puede tener cero o una fila en medicos y cero o una cuenta en usuarios. Un médico puede tener varias especialidades y una especialidad varios médicos.
- Una cita puede tener cero o una consulta; la referencia a cita es opcional en consulta. Cuando existe, paciente y médico coinciden por FK compuesta.
- Una consulta puede tener muchas recetas, órdenes y diagnósticos, y cero o una hospitalización de ingreso. La receta pertenece a una consulta; cada detalle pertenece a una receta y medicamento.
- Una hospitalización tiene cero o muchas asignaciones y notas; la operación de ingreso debe crear una asignación si el caso lo requiere. El DDL por sí solo no exige que un padre tenga hijos.
- Una receta admite varias dispensaciones; cada entrega contiene detalles que apuntan a su renglón y lote. Un detalle de entrega puede tener cero o un movimiento asociado por UNIQUE; el procedimiento debe producir su salida en la misma transacción.
- Una orden tiene cero o un resultado, una factura varios detalles y pagos, y una cuenta varios roles por la tabla puente.

Los diagramas físicos representan las FKs y lo que realmente permite el DDL. La obligatoriedad de un hijo no implica que un padre tenga al menos un hijo. Las reglas de negocio pueden exigir más condiciones que las cardinalidades físicas.

## Normalización: 1FN, 2FN y 3FN

### Primera forma normal

Cada celda guarda un valor del dominio y cada fila se identifica mediante PK. No se guardan listas de medicamentos, diagnósticos o especialidades separadas por comas: se usan receta_detalle, consulta_diagnosticos y medico_especialidad. Por ejemplo, una receta de tres medicamentos contiene un encabezado y tres renglones, sin columnas medicamento_1, medicamento_2 o medicamento_3. Dosis y frecuencia son indicaciones textuales del alcance académico; no constituyen listas relacionales de productos. Para reglas de dosificación estructuradas harían falta catálogos y unidades adicionales.

### Segunda forma normal

En tablas con PK compuesta, los atributos del evento dependen de toda la clave. En receta_detalle, (receta_id, renglon) identifica la indicación completa: medicamento, dosis, frecuencia, duración y cantidad. El nombre y concentración del medicamento dependen solo de medicamento_id y se guardan en medicamentos. En medico_especialidad y usuario_roles no hay atributos que dependan de una parte de la clave. En consulta_diagnosticos, es_principal y observaciones describen la asociación de ese diagnóstico con esa consulta, no el catálogo general.

### Tercera forma normal

Se separan dependencias entre atributos no clave: nombre de aseguradora en aseguradoras, nombre de departamento en departamentos, datos laborales en personal y descripciones de productos en medicamentos. Las recetas obtienen paciente y médico a través de consultas, evitando copias editables. Las órdenes obtienen el paciente de la misma consulta. La edad se calcula a la fecha consultada y no se almacena como dato que envejece.

No se afirma que todas las columnas físicas satisfagan estrictamente 3FN sin excepciones. El núcleo se organiza con criterio de 3FN y se aplican tres excepciones deliberadas:

1. FKs compuestas de coherencia. Consultas repite paciente_id/medico_id respecto de una cita opcional; hospitalizaciones conserva paciente_id junto a consulta_ingreso_id; dispensacion_detalle repite receta_id/medicamento_id para comprobar encabezado, renglón y lote; movimientos_inventario conserva lote_id para vincular la salida compatible; facturas conserva paciente_id aunque una póliza opcional ya identifica a su paciente. Las restricciones compuestas impiden que estos IDs se contradigan. Su finalidad es integridad verificable, y se documentan como redundancia controlada.
2. Instantáneas de cobro. Descripción y precio_unitario de factura_detalle corresponden al cargo histórico, no a la tarifa vigente del catálogo; costo_unitario es el costo histórico del lote. No son copias que se deban actualizar al cambiar precios. El detalle de factura no utiliza un id polimórfico sin FK ni pretende automatizar el origen de cada cargo.
3. Columnas derivadas. Importe y auxiliares de unicidad activa son GENERATED ALWAYS STORED, mantenidos por MySQL. No se editan manualmente. Existencia, edad, total y saldo se obtienen por consulta o vistas; no hay una segunda copia editable independiente.

Las PK enteras facilitan FKs y no convierten por sí solas una tabla en normalizada. Las claves de negocio se mantienen con UNIQUE (expediente, cédula, códigos, folios y combinaciones de lote/póliza).

## Reglas de negocio y mecanismos

| Regla | Mecanismo declarativo | Validación operativa adicional |
| --- | --- | --- |
| Identificadores válidos y relaciones existentes | PK, FK y UNIQUE | Inactivación de catálogos con historial |
| Consulta/cita, estancia/consulta, póliza/factura coherentes | FKs compuestas | No alterar identidades de eventos ya ligados |
| Fecha fin posterior a inicio | CHECK sobre fila | Agenda, estancia y asignación entre filas |
| Citas de duración válida y sin inicio duplicado | CHECK y UNIQUE generado | Impedir cualquier traslape de médico y paciente; bloquear recursos al validar |
| Un principal por consulta | UNIQUE sobre columna generada | Permite cero: exigir uno al cerrar atención si la rúbrica lo pide |
| Un ingreso activo por paciente y una ocupación activa | UNIQUE sobre columnas generadas | Traslapes históricos, pertenencia a estancia y camilla operativa |
| Lote del medicamento prescrito | FKs compuestas | Caducidad, existencia, saldo de receta y puesto de farmacia |
| Signo correcto de movimientos | CHECK; enlace único a salida | Evitar saldo negativo con transacción y bloqueo del lote |
| Cobro calculado y pago positivo | Importe generado y CHECK | No exceder saldo, estados y bloquear factura para pagos simultáneos |
| Médico y enfermería en el evento apropiado | FK a personal/medicos | Verificar puesto y activo, en rutinas/trigger según implementación |

Un índice único sobre el inicio de una cita no evita intervalos que empiezan a distinta hora y se superponen. Las columnas generadas de asignación solo restringen filas abiertas; no prueban ausencia de traslapes históricos. Estas reglas necesitan operaciones transaccionales adicionales, inspeccionables en 02_reglas.sql.

Las transacciones de negocio deben confirmar encabezado y detalles como una unidad. Validar un saldo con SELECT y después insertar sin bloquear el recurso permite carreras; las rutinas deben leer con bloqueo dentro de una transacción y deshacer todos los cambios ante error. También hace falta que una aplicación limite la escritura a operaciones autorizadas: conservar acceso de escritura directa puede saltarse reglas implementadas solo en procedimientos.

## Supuestos defendibles

- Se modela una sede lógica y una zona local común. No hay red multisede ni multimoneda.
- Una consulta identifica al médico que prescribe o solicita. Si atiende otro médico, registrar otro evento clínico para conservar su autoría.
- Una consulta de ingreso origina como máximo una estancia; un paciente puede tener varias estancias sucesivas, una activa a la vez.
- Los intervalos de citas y asignaciones usan [inicio, fin): terminar a las 10:00 permite comenzar otra a las 10:00. Una asignación sin fin es activa.
- Se permite entrega parcial y múltiples lotes, pero se bloquean entregas que excedan la prescripción o el inventario; se rechazan lotes caducados conforme a la fecha operativa.
- Los movimientos de inventario se capturan cronológicamente por lote: la fecha no puede anteceder al último movimiento. Correcciones de existencia se registran con un nuevo AJUSTE firmado, sin reescribir el libro histórico.
- La unidad de inventario debe permanecer consistente por producto. No hay conversión entre caja, tableta y mililitro.
- Un resultado final por orden y una orden por procedimiento. Cirugía es un tipo de catálogo y no una programación completa de quirófanos/equipo.
- Cobros en MXN, sin impuestos, CFDI, reembolsos, notas de crédito ni liquidación de aseguradoras.
- Los ejemplos contienen datos ficticios; no se han migrado registros del prototipo.

## Limitaciones y evolución

No se incluyen interoperabilidad HL7/FHIR, PACS/DICOM, expediente con firmas y versionado, consentimiento, auditoría completa de cambios, respaldo operativo, gestión de accesos real, nómina, compras con requisiciones/órdenes/recepciones, quirófanos detallados, turnos y guardias, emergencias con triaje completo, reclamaciones de seguros ni contabilidad fiscal. La presencia de usuarios/roles no resuelve estos procesos.

Una evolución razonable es agregar primero auditoría y permisos de aplicación, después agenda/turnos y catálogo estructurado de unidades; solo entonces ampliar módulos especializados. Estas extensiones requieren requisitos específicos y pruebas, no únicamente agregar tablas.

## Referencias técnicas

Las decisiones físicas de FK, CHECK, columnas generadas y bloqueos se apoyan en el manual oficial de MySQL 8.0. CHECK se exige a partir de MySQL 8.0.16. Los metadatos SDI son evidencia de estructura, y la importación de .ibd exige compatibilidad y revisión de datos; no sustituye una migración lógica.
'''

def write_model():
    text=MODELO+'\n'+ '\n'.join(f'- [{title}]({url})' for title,url in REFERENCIAS)+'\n'
    (BASE/'MODELO.md').write_text(text,encoding='utf-8')

def readme():
    return f'''# Hospital universitario en MySQL

Propuesta académica integral con **36 tablas**, diagramas físicos, diccionario, reporte y scripts separados. La estructura original de cinco tablas se conserva como evidencia; los datos de esos archivos no se migran automáticamente.

## Empieza aquí

1. Lee `REVISION.md` para entender qué había y qué se corrigió.
2. Abre `diagramas/vision_modulos.svg` y `diagramas/er_completo.svg` en un navegador; usa zoom para el ER completo. Los SVG son vectoriales.
3. Usa `MODELO.md` para alcance, cardinalidades, reglas y normalización; `DICCIONARIO.md` enumera todos los campos y claves.
4. Consulta `reporte_hospital.pdf` para una presentación formal del mismo diseño.

## Archivos

| Archivo | Uso |
| --- | --- |
| 01_esquema.sql | Crea hospital_universitario, sus 36 tablas, claves, CHECK e índices |
| hospital_completo.sql | Opción sencilla: estructura, reglas y datos ficticios en un archivo |
| 02_reglas.sql | 6 vistas, 6 procedimientos y 23 triggers de validación |
| 03_datos_demo.sql | Carga datos ficticios coherentes |
| 04_consultas.sql | Consultas de atención, ocupación, farmacia, resultados y cobros |
| REVISION.md | Hallazgos sobre las cinco tablas originales |
| MODELO.md | Justificación, normalización, supuestos y límites |
| DICCIONARIO.md | Campos, tipos, NULL, PK, FK, UNIQUE, CHECK y derivados |
| reporte_hospital.pdf | Reporte académico legible e imprimible |
| diagramas/*.svg | ER completo, ER por módulos y visión funcional |
| diagramas/*.mmd | Fuentes Mermaid consistentes con el DDL |
| diagramas/*_relaciones.md | Correspondencia Fxx del SVG con cada FK exacta |
| evidencia_original/*.sdi.json | Metadatos recuperados, no registros de pacientes |
| evidencia_original/manifest.json | Tamaños, versiones y huellas de los originales |
| validar_proyecto.py / VALIDACION.json | Ejecutor y evidencia real de las pruebas de servidor |
| generar_documentacion.py | Regenera diccionario, diagramas y PDF desde 01_esquema.sql; lee evidencia histórica en VALIDACION.json |

## Requisitos y ejecución en MySQL Workbench

MySQL **8.0.16 o posterior** (no MariaDB). InnoDB, utf8mb4 y permisos para crear un esquema nuevo, tablas, vistas, procedimientos y triggers. La propuesta usa CHECK aplicados y columnas generadas; no ejecutar en una versión anterior suponiendo la misma protección. Versión utilizada en la validación de esta entrega: {VERSION_VALIDADA}

1. Conéctate a un servidor de pruebas en MySQL Workbench.
2. Elige UNA forma de instalación: ejecuta hospital_completo.sql completo una vez; o ejecuta por separado 01_esquema.sql → 02_reglas.sql → 03_datos_demo.sql, en ese orden. No ejecutes ambas opciones: contienen la misma instalación y datos.
3. La instalación crea un esquema NUEVO llamado hospital_universitario; si ya existe, detente y decide otro nombre antes de ejecutar. No elimina bases anteriores. DELIMITER es una instrucción del cliente: ejecuta las reglas como script completo.
4. Ejecuta 04_consultas.sql y revisa sus 20 consultas junto con las preguntas que responde cada una.
5. Consulta VALIDACION.json para los resultados verificables. validar_proyecto.py crea su propia base hospital_prueba_UUID, carga y verifica los scripts, y la elimina al finalizar. Usa sus argumentos --mysql, --user, --port y --output en un servidor de pruebas; no se acepta un nombre de base existente para eliminar. La contraseña, si se necesita, se lee de MYSQL_PWD y no debe escribirse en argumentos públicos.

También puedes usar el cliente mysql: desde su consola, SOURCE ruta/01_esquema.sql y luego los archivos en el orden anterior; usa una ruta real de tu equipo. En PowerShell evita reutilizar comandos de redirección de Bash sin adaptación. No pongas una contraseña en el historial de comandos.

## Estado de verificación

{ESTADO_PRUEBAS}

El diccionario y Mermaid se generan del mismo DDL y comprueban 36 tablas, PK presentes y referencias a columnas existentes. La inspección estática no sustituye ejecutar SQL en un servidor. La validación funcional/concurrente se documenta por separado y solo se afirma cuando existe evidencia.

La evidencia adjunta corresponde a los scripts entregados. Al cambiar SQL o datos, vuelve a ejecutar el validador y actualiza el JSON antes de presentar esos resultados como validación del nuevo contenido. Las dos pruebas concurrentes comprueban los casos incluidos; no constituyen una certificación de todos los escenarios de concurrencia posibles.

Los seis procedimientos de negocio gestionan sus propias transacciones. Invócalos con CALL como operaciones autónomas, fuera de otra transacción abierta: agendar cita, asignar/trasladar camilla, dar alta, registrar movimiento, dispensar medicamento y registrar pago. Consulta los parámetros exactos en 02_reglas.sql; los parámetros de fecha permiten casos de prueba y no implican que el servidor los obtenga todos de su reloj.

En inventario, captura movimientos por orden cronológico de cada lote; las rutinas rechazan fechas anteriores al último movimiento. Las correcciones se hacen con un nuevo AJUSTE y su motivo. No modifiques ni borres movimientos históricos. En cobros, crea la factura ABIERTA, agrega sus detalles y luego actualízala a EMITIDA; los pagos registrados son inmutables y no hay flujo de devolución en este alcance.

Los usuarios ficticios se cargan inactivos y con hashes marcadores sin credenciales funcionales. La propuesta no implementa autenticación. Las reglas de agenda, camas y saldos que se implementan en procedimientos requieren que la aplicación futura use esas operaciones y restrinja escrituras directas.

## Guion para defender el proyecto

- Explica el caso: cita o urgencia → consulta → diagnóstico → receta/orden → dispensación/resultado → factura → pago.
- Muestra cómo una receta admite varios renglones y la entrega parcial no modifica la prescripción.
- Explica la diferencia entre operación de una camilla y ocupación; conserva traslados con intervalos.
- Justifica las tablas puente para relaciones M:N y muestra ejemplos de 1FN, 2FN y 3FN en MODELO.md.
- Señala las excepciones controladas: FKs compuestas, precios históricos y columnas generadas. No afirmes 3FN estricta de todas las columnas físicas.
- Distingue una regla CHECK por fila de reglas entre filas que necesitan transacciones y bloqueos.
- Consulta existencia por lote y saldo de factura para mostrar una fuente única de valores calculados.
- Reconoce límites académicos: factura no fiscal, resultados sin versiones, cirugías simplificadas y acceso sin autenticación.

## Datos originales y alcance

Los .ibd originales permanecen intactos. Este proyecto usa una base nueva y datos ficticios; no es una recuperación de filas ni una migración de los registros originales. Para migrar, solicita un respaldo SQL del prototipo o realiza una recuperación compatible y valida sus datos antes de transformarlos.

La consigna detallada del profesor está pendiente. El diseño cubre procesos principales de un hospital con fines académicos y puede ajustarse a la rúbrica sin prometer que cubre literalmente todos los sistemas de un hospital real.
'''

def pdf_report(tables, original):
    from reportlab.pdfgen import canvas
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, Flowable
    from reportlab.lib import colors
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.enums import TA_LEFT
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    fontdir=Path('C:/Windows/Fonts')
    fonts={'Main':'arial.ttf','MainBold':'arialbd.ttf','MainItalic':'ariali.ttf','Code':'consola.ttf'}
    import reportlab
    fallback_dir=Path(reportlab.__file__).resolve().parent/'fonts'
    fallback_fonts={'Main':'Vera.ttf','MainBold':'VeraBd.ttf','MainItalic':'VeraIt.ttf','Code':'Vera.ttf'}
    for name,file in fonts.items():
        fontpath=fontdir/file
        if not fontpath.exists(): fontpath=fallback_dir/fallback_fonts[name]
        pdfmetrics.registerFont(TTFont(name,str(fontpath)))
    pdfmetrics.registerFontFamily('Main',normal='Main',bold='MainBold',italic='MainItalic',boldItalic='MainBold')
    styles=getSampleStyleSheet()
    for name in styles.byName: styles[name].fontName='Main'
    styles.add(ParagraphStyle(name='TitleHospital',fontName='MainBold',fontSize=29,leading=34,textColor=colors.HexColor('#0f172a'),spaceAfter=13))
    styles.add(ParagraphStyle(name='Subtitle',fontName='Main',fontSize=12,leading=17,textColor=colors.HexColor('#475569'),spaceAfter=12))
    styles.add(ParagraphStyle(name='BodyHospital',fontName='Main',fontSize=9.2,leading=13.5,textColor=colors.HexColor('#1e293b'),spaceAfter=7))
    styles.add(ParagraphStyle(name='SmallHospital',fontName='Main',fontSize=7.6,leading=10.4,textColor=colors.HexColor('#334155'),spaceAfter=4))
    styles.add(ParagraphStyle(name='CellHospital',fontName='Main',fontSize=7.1,leading=9.4,textColor=colors.HexColor('#1e293b'),spaceAfter=0,splitLongWords=True))
    styles.add(ParagraphStyle(name='CellHeader',fontName='MainBold',fontSize=7.1,leading=9.4,textColor=colors.white,spaceAfter=0))
    styles['Heading1'].fontName='MainBold'; styles['Heading1'].fontSize=17; styles['Heading1'].leading=22; styles['Heading1'].textColor=colors.HexColor('#155e75'); styles['Heading1'].spaceBefore=10; styles['Heading1'].spaceAfter=9
    styles['Heading2'].fontName='MainBold'; styles['Heading2'].fontSize=11.4; styles['Heading2'].leading=15; styles['Heading2'].textColor=colors.HexColor('#0f172a'); styles['Heading2'].spaceBefore=8; styles['Heading2'].spaceAfter=6
    doc=SimpleDocTemplate(str(BASE/'reporte_hospital.pdf'),pagesize=A4,rightMargin=43,leftMargin=43,topMargin=53,bottomMargin=47,title='Hospital universitario - modelo y diccionario',author='Proyecto académico',subject='Base de datos hospitalaria en MySQL')
    story=[]; W=A4[0]-86
    def P(text,style='BodyHospital'):
        return Paragraph(text,styles[style])
    def para(text): story.append(P(html.escape(text)))
    def heading(text,level=1): story.append(P(html.escape(text),'Heading'+str(level)))
    def bullet(text): story.append(P('• '+html.escape(text)))
    def table(headers,rows,widths):
        data=[[P(html.escape(h),'CellHeader') for h in headers]]+[[P(html.escape(str(v)).replace('\n','<br/>'),'CellHospital') for v in row] for row in rows]
        t=Table(data,colWidths=widths,repeatRows=1,hAlign='LEFT')
        t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#155e75')),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#f1f5f9')]),('GRID',(0,0),(-1,-1),0.3,colors.HexColor('#cbd5e1')),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),5),('RIGHTPADDING',(0,0),(-1,-1),5),('TOPPADDING',(0,0),(-1,-1),5),('BOTTOMPADDING',(0,0),(-1,-1),5)]))
        return t
    class ModuleView(Flowable):
        def __init__(self): Flowable.__init__(self); self.width=W; self.height=292
        def draw(self):
            c=self.canv; ww=(W-12)/2; hh=64
            for i,(key,(title,ns)) in enumerate(MODULOS.items()):
                x=(i%2)*(ww+12); y=218-(i//2)*72
                c.setFillColor(colors.HexColor('#f1f5f9')); c.setStrokeColor(colors.HexColor(COLORES[i])); c.roundRect(x,y,ww,hh,7,fill=1,stroke=1)
                c.setFillColor(colors.HexColor(COLORES[i])); c.setFont('MainBold',9.3); c.drawString(x+10,y+44,title)
                c.setFillColor(colors.HexColor('#475569')); c.setFont('Main',8.8); c.drawString(x+10,y+27,f'{len(ns)} tablas')
                short={'organizacion':'Identidad, personal, cobertura','infraestructura':'Habitaciones y camillas','atencion':'Citas, consulta y diagnóstico','hospitalizacion':'Estancias, traslados y notas','farmacia':'Prescripción, entrega y lotes','procedimientos':'Solicitud e informe final','cobros':'Cargos históricos y pagos','acceso':'Cuentas y roles conceptuales'}[key]
                c.setFont('Main',8); c.drawString(x+10,y+11,short)
    def footer(c,doc):
        c.saveState(); c.setStrokeColor(colors.HexColor('#cbd5e1')); c.line(43,34,A4[0]-43,34); c.setFillColor(colors.HexColor('#64748b')); c.setFont('Main',7.5); c.drawString(43,22,'Hospital universitario | MySQL | Proyecto académico'); c.drawRightString(A4[0]-43,22,str(doc.page)); c.restoreState()
    story.append(P('Base de datos<br/>de un hospital','TitleHospital'))
    story.append(P('Diseño relacional, justificación y diccionario técnico<br/>MySQL · 36 tablas · 8 módulos', 'Subtitle'))
    para('Propuesta para un proyecto universitario de sistemas. Este reporte presenta un modelo amplio y coherente de los procesos principales, sus reglas y las limitaciones de la implementación académica.')
    story.append(ModuleView())
    heading('Objetivo')
    para('Relacionar el registro de pacientes y trabajadores con atención, hospitalización, farmacia, estudios y cobros. Entregar scripts reproducibles, diagramas que coincidan con sus FKs y material para explicar el diseño.')
    para('No se inventan autor, escuela, matrícula ni rúbrica. La consigna detallada del profesor sigue pendiente. Fecha de elaboración: 10 de octubre de 2026, America/Mexico_City.')
    story.append(PageBreak())
    heading('1. Del prototipo a un modelo integral')
    para('Se analizaron metadatos SDI de cinco espacios de tablas InnoDB: camillas, medicamentos, medicos, pacientes y recetas. Su versión registrada es 8.0.29. Esto acredita la estructura de esos archivos, no la versión instalada actualmente. El manifiesto conserva tamaños y SHA-256; los registros originales no se han recuperado ni validado.')
    para('El prototipo ya aporta PK enteras, cédula y expediente únicos y separación de catálogos. Los hallazgos describen límites o comportamientos permitidos; no prueban la existencia de filas inválidas.')
    rows=[['Una receta guarda un medicamento','Repetición del encabezado para varios productos','Encabezado recetas y renglones receta_detalle'],['Camilla obligatoria en receta','La atención ambulatoria exige recurso físico','Camilla vinculada a la estancia, no a la receta'],['Sin estancia ni traslados','No hay ingreso/alta e historial de ocupación','Hospitalizaciones y asignaciones con períodos'],['Fecha de receta nullable','Se permite fecha ausente','NOT NULL y predeterminado'],['Borrado cascada de receta-paciente','Borrar identidad puede borrar historia','FK restrictiva e inactivación'],['Estado de camilla libre/nullable','Valores inconsistentes y ocupación confundida','ENUM operativo y asignaciones separadas']]
    story.append(table(['Hallazgo','Consecuencia','Corrección'],rows,[W*.30,W*.31,W*.39]))
    heading('Preservación y migración',2)
    para('Los .ibd originales permanecen intactos y el esquema nuevo se llama hospital_universitario. Crear este esquema no importa sus filas. Para una migración se requiere un respaldo SQL o recuperación compatible, revisión de los datos y una transformación explícita; copiar archivos no demuestra integridad.')
    heading('Criterio de alcance',2)
    para('El proyecto cubre atención, recursos, inventario y cobros enlazados. No pretende representar literalmente todos los procesos de un hospital real. Su amplitud se fundamenta en relaciones y operaciones demostrables, no en un número arbitrario de catálogos.')
    story.append(PageBreak())
    heading('2. Estructura y recorrido de la información')
    for key,(title,ns) in MODULOS.items():
        heading(f'{title} ({len(ns)} tablas)',2)
        desc={'organizacion':'Departamentos, especialidades y personal organizan a los trabajadores. Medicos comparte PK con personal y puede tener varias especialidades. Pacientes, contactos, aseguradoras y pólizas conservan identidad y cobertura básica.', 'infraestructura':'Habitaciones localiza recursos; camillas conserva condición operativa. La disponibilidad se obtiene de ocupaciones, sin confundir mantenimiento con paciente asignado.', 'atencion':'Citas programa intervalos y consultas registra atenciones con o sin cita. Diagnósticos se relacionan por tabla puente, y alergias se asocia al paciente.', 'hospitalizacion':'La estancia conserva ingreso, alta y médico responsable. Asignaciones registra cada ocupación/traslado y notas_enfermeria las observaciones del personal.', 'farmacia':'Catálogo de productos, proveedores y lotes; recetas y renglones; dispensaciones y renglones; libro firmado de movimientos. Recetar y entregar son eventos distintos.', 'procedimientos':'Una orden solicita un procedimiento de laboratorio, imagen, cirugía u otro; se admite un único informe final por orden.', 'cobros':'Una cuenta académica conserva cargos con precios históricos y recibe varios pagos parciales; la póliza opcional debe pertenecer al mismo paciente.', 'acceso':'Usuarios y roles describe futuras cuentas de aplicación. No autentica personas ni crea cuentas, permisos o roles del servidor MySQL.'}[key]
        para(desc)
    heading('Recorrido principal',2)
    para('Paciente → cita o urgencia → consulta → diagnóstico → receta u orden → entrega de medicamento o resultado → cargo → pago. Si se requiere internamiento: consulta → hospitalización → camilla y traslados → notas → alta.')
    story.append(PageBreak())
    heading('3. Cardinalidades y diagramas')
    rows=[['Paciente / consulta','1 a N','Paciente puede no tener atención; cada consulta sí tiene paciente'],['Personal / médico','1 a 0..1','Subtipo con PK compartida; no todo trabajador es médico'],['Médico / especialidad','N a M','Resuelto con medico_especialidad'],['Cita / consulta','1 a 0..1','Consulta puede no tener cita; cita_id es opcional y único'],['Consulta / hospitalización','1 a 0..1','FK compuesta conserva el paciente de ingreso'],['Receta / detalle','1 a N permitido','El DDL no exige que el encabezado tenga al menos un renglón'],['Hospitalización / asignación','1 a N','Traslados sucesivos; máximo una asignación abierta'],['Receta / dispensación','1 a N','Entrega parcial y detalles de lote/renglón'],['Orden / resultado','1 a 0..1','Un informe final, sin versionado'],['Factura / pago','1 a N','Varios pagos positivos y parciales'],['Usuario / rol','N a M','Resuelto con usuario_roles']]
    story.append(table(['Relación','Cardinalidad','Interpretación'],rows,[W*.30,W*.16,W*.54]))
    heading('Material vectorial adjunto',2)
    para('diagramas/er_completo.svg contiene las 36 entidades, campos y FKs; es un lienzo vectorial para revisar con zoom. Los SVG por módulo amplían las relaciones locales e incluyen sus padres externos. Los archivos .mmd son fuentes Mermaid del mismo DDL. Cada catálogo *_relaciones.md vincula etiquetas Fxx con columnas y nombre exacto de restricción.')
    para('PK identifica filas; FK asegura referencia; UK* indica participación en UNIQUE, que puede ser compuesto; G identifica un campo generado; ? permite NULL. Las conexiones dibujadas van del padre al hijo: círculo y pata de cuervo = 0..N; círculo y barra = 0..1. La columna nullable permite reconocer si el padre es opcional. Mermaid expresa también esa opcionalidad.')
    para('Los diagramas muestran lo permitido por las restricciones físicas. Una FK obligatoria en el hijo no obliga al padre a tener hijos. Las reglas de ingreso, cierre y consistencia entre filas se explican en la sección de mecanismos.')
    story.append(PageBreak())
    heading('4. Normalización y decisiones deliberadas')
    heading('Primera forma normal (1FN)',2)
    para('Cada fila tiene PK y cada celda representa un valor del dominio. No hay listas de medicamentos, diagnósticos o especialidades en una columna: una receta con tres medicamentos usa un encabezado y tres filas de receta_detalle. Consulta_diagnosticos y medico_especialidad resuelven conjuntos. Dosis y frecuencia siguen siendo indicaciones textuales académicas; una dosificación plenamente estructurada requeriría dominios y unidades adicionales.')
    heading('Segunda forma normal (2FN)',2)
    para('En receta_detalle, la clave (receta_id, renglon) identifica la indicación completa y sus cantidades. Nombre, principio activo y presentación dependen del producto y se mantienen en medicamentos. En las tablas puente medico_especialidad y usuario_roles no existen atributos dependientes de solo una parte de la PK. En consulta_diagnosticos, principal y observaciones describen la asociación completa.')
    heading('Tercera forma normal (3FN)',2)
    para('El nombre del departamento está en departamentos y el de aseguradora en aseguradoras; datos de trabajadores en personal y productos en medicamentos. Recetas y órdenes obtienen paciente/médico a través de consulta. Edad se calcula desde fecha_nacimiento. Las PK artificiales simplifican referencias; las claves de negocio se conservan con UNIQUE y no se asume que un ID por sí solo normalice una tabla.')
    heading('Excepciones físicas controladas',2)
    for text in [
      'FKs compuestas: consultas repite paciente/médico de una cita opcional; hospitalizaciones paciente de la consulta; dispensacion_detalle receta y medicamento; movimientos lote; facturas paciente de póliza opcional. Estas columnas permiten verificar combinaciones coherentes y representan redundancia deliberada.',
      'Instantáneas: factura_detalle conserva descripción y precio_unitario del cargo y lotes conserva costo_unitario recibido. Son valores históricos, no copias que se sincronicen con una tarifa actual.',
      'Derivados: importe y auxiliares de unicidad activa son GENERATED ALWAYS STORED. Edad, existencia, total y saldo se calculan. No hay una segunda copia editable independiente del mismo valor.'
    ]: bullet(text)
    para('Por estas excepciones, se describe un núcleo diseñado con criterio de 3FN y desnormalizaciones justificadas; no se afirma 3FN estricta de todas las columnas físicas.')
    story.append(PageBreak())
    heading('5. Integridad y reglas de negocio')
    rows=[['Identidad y vínculos','PK, FK, UNIQUE','Restricción de borrado protege historial; activo permite inactivar'],['Cita/consulta y consulta/estancia coherentes','FK compuesta','Paciente y médico de la referencia deben coincidir'],['Intervalo de cita válido','CHECK + UNIQUE inicial','Traslapes requieren validar paciente y médico bajo bloqueo'],['Un diagnóstico principal','UNIQUE generado','Máximo uno; no obliga a registrar principal'],['Un ingreso/ocupación activos','UNIQUE generado','No prueba traslapes históricos ni pertenencia temporal a estancia'],['Lote del producto indicado','FKs compuestas','Validar caducidad, cantidad prescrita y saldo del lote'],['Signo y vínculo de salida','CHECK + UNIQUE','Transacción para entrega y movimiento sin doble descuento'],['Cargo y pago','DECIMAL, importe generado, CHECK','Bloquear factura y validar estado/saldo para pagos simultáneos'],['Puesto/actividad del trabajador','FK identifica al personal','Rutina/trigger verifica función y actividad cuando corresponde']]
    story.append(table(['Regla','DDL','Regla operativa adicional'],rows,[W*.28,W*.25,W*.47]))
    heading('Concurrencia y atomicidad',2)
    para('La comprobación del saldo y la escritura deben ocurrir en una misma transacción, con bloqueo del recurso. Revisar stock antes de insertar sin bloquear permite que dos sesiones consuman la misma existencia. Las rutinas de negocio deben confirmar encabezado, detalle y movimiento como una unidad, y deshacer todo ante error. Lo mismo aplica a agenda, ocupación y pagos.')
    para('Un UNIQUE sobre inicio solo impide un inicio duplicado, no dos citas con horas iniciales distintas que se superpongan. Las columnas activas generadas restringen filas abiertas; no sustituyen la revisión de períodos cerrados. Los intervalos se interpretan como [inicio, fin), permitiendo continuidad exacta.')
    para('Las reglas que existan solo en procedimientos pueden saltarse con escritura directa. Una aplicación posterior debe limitar operaciones permitidas y aplicar permisos reales. Las tablas de usuarios/roles no sustituyen ese control.')
    story.append(PageBreak())
    heading('6. Supuestos, limitaciones y validación')
    for text in [
      'Una sede lógica, una zona local común America/Mexico_City y MXN como única moneda. DATETIME no aplica automáticamente esa política de zona.',
      'Consulta identifica al médico que prescribe o solicita; la intervención de otro profesional se registra en otra atención. Una consulta de ingreso origina como máximo una estancia.',
      'Una unidad de inventario coherente por producto; cantidades enteras sin conversión caja/tableta/ml. Se permiten entregas parciales y varios lotes compatibles.',
      'Libro de inventario cronológico por lote: la fecha operativa no antecede al último movimiento. Correcciones mediante nuevos AJUSTE con motivo, sin modificar ni borrar historia.',
      'Una orden por procedimiento y un resultado final por orden. Cirugía es un tipo del catálogo, sin programación detallada de quirófanos, equipo ni anestesia.',
      'Facturas académicas sin CFDI, impuestos, contabilidad fiscal, notas de crédito, reembolsos ni liquidación de reclamaciones.',
      'Datos de ejemplo ficticios. No se han migrado filas del prototipo ni se demuestra recuperación de los .ibd.'
    ]: bullet(text)
    heading('Procesos fuera del alcance',2)
    para('Interoperabilidad HL7/FHIR, PACS/DICOM, expediente firmado y versionado, consentimientos, auditoría integral, respaldo operativo, autenticación y permisos reales, nómina, compras completas, guardias/turnos, triaje especializado, reclamaciones de seguros y operación multisede. Esas ampliaciones requieren requisitos y pruebas específicos.')
    heading('Uso y estado de pruebas',2)
    para('En MySQL Workbench, elegir una instalación: hospital_completo.sql una vez, o 01_esquema.sql → 02_reglas.sql → 03_datos_demo.sql. No ejecutar ambas opciones. Después ejecutar las 20 consultas de 04_consultas.sql. La base requerida es MySQL 8.0.16 o posterior, con InnoDB y utf8mb4; no se da por compatible con MariaDB.')
    para('02_reglas.sql aporta 6 vistas, 6 procedimientos y 23 triggers. Los CALL de negocio gestionan sus propias transacciones y se ejecutan como operaciones autónomas, fuera de otra transacción. Sus parámetros de fecha permiten controlar los casos. Los usuarios ficticios están inactivos y sus hashes son marcadores; no existen credenciales funcionales ni autenticación implementada.')
    para('Versión validada: '+VERSION_VALIDADA)
    para(ESTADO_PRUEBAS)
    para('La generación documental comprueba 36 tablas, PK presentes y FKs que apuntan a tablas/columnas existentes. Esta inspección estática no sustituye la compilación del SQL, la carga de datos, las pruebas de rechazo ni pruebas concurrentes en servidor.')
    evidence=evidencia_pruebas()
    if evidence:
        from collections import Counter
        story.append(PageBreak())
        heading('6.1. Evidencia de la ejecución')
        para('Resultados del archivo VALIDACION.json de la entrega, obtenidos en MySQL 8.0.45. Las cifras incluyen preparación, verificaciones de consistencia, rechazos esperados y concurrencia; no se presentan como casos independientes de negocio del mismo tipo.')
        counts=Counter(t['categoria'] for t in evidence['pruebas'])
        labels={'preparacion':'Preparación y ejecución de SQL','consistencia':'Modelo, datos y resultados','rechazo':'Rechazos esperados por integridad','concurrencia':'Dos sesiones sobre el mismo recurso'}
        rows=[[labels.get(key,key),str(counts[key]),str(sum(t['correcta'] for t in evidence['pruebas'] if t['categoria']==key))] for key in ['preparacion','consistencia','rechazo','concurrencia']]
        rows.append(['TOTAL',str(evidence['resumen']['total']),str(evidence['resumen']['correctas'])])
        story.append(table(['Grupo','Comprobaciones','Correctas'],rows,[W*.68,W*.16,W*.16]))
        heading('Casos concurrentes comprobados',2)
        for test in evidence['pruebas']:
            if test['categoria']=='concurrencia': bullet(test['nombre']+'. '+test['detalle'])
        heading('Resultados del conjunto ficticio',2)
        para('Las existencias por lote de los tres productos de demostración son 142, 57 y 40 unidades. Los saldos se calculan del detalle y los pagos, sin copiar un total editable a facturas.')
        story.append(table(['Factura demo','Total MXN','Pagado MXN','Saldo MXN'],[['FAC-2026-00001','850.00','500.00','350.00'],['FAC-2026-00002','800.00','800.00','0.00'],['FAC-2026-00003','1,200.00','400.00','800.00'],['FAC-2026-00004','750.00','0.00','750.00']],[W*.40,W*.20,W*.20,W*.20]))
        heading('Límites de la evidencia',2)
        para('La limpieza de la base temporal está registrada en el JSON. Las dos pruebas simultáneas verifican los escenarios incluidos (una cita aceptada y otra rechazada; una salida de 7 aceptada y otra rechazada con stock inicial 10), sin certificar todos los intercalados posibles de producción. Al cambiar SQL o datos se deben repetir las pruebas y reemplazar la evidencia; regenerar documentación por sí solo no ejecuta el servidor.')
    story.append(PageBreak())
    heading('7. Diccionario de las 36 tablas')
    para('Este diccionario se genera desde 01_esquema.sql. PK = primaria; FK = foránea; UK* = participa en UNIQUE (puede ser compuesta); AI = secuencia automática; G = generado STORED. NULL señala opcionalidad. Las claves completas y CHECK se enumeran al pie de cada tabla. Los tipos mostrados son los declarados, incluido UNSIGNED.')
    para('BOOLEAN tiene semántica lógica mediante CHECK 0/1. ENUM enumera estados limitados. Las acciones de FK sin cláusula explícita restringen borrado/actualización del padre con hijos en InnoDB. No se muestran columnas internas del motor.')
    n=0
    for key,(title,names) in MODULOS.items():
        if n: story.append(PageBreak())
        heading(title)
        for name in names:
            n+=1; t=tables[name]
            block=[P(f'{n:02d}. {html.escape(name)}','Heading2'),P(html.escape(PROPOSITOS[name]))]
            rows=[]
            for c in t['columns']:
                value=('G: '+c['generated']) if c['generated'] else c['default'] or ('AUTO_INCREMENT' if c['auto'] else '-')
                dtype=c['type'].replace(",'",",\n'")
                rows.append([c['name'],dtype,'Sí' if c['nullable'] else 'No',keys(t,c),value])
            block.append(table(['Campo','Tipo SQL','NULL','Clave','Predeterminado / generado'],rows,[W*.285,W*.195,W*.062,W*.095,W*.363]))
            block.append(Spacer(1,6))
            block.append(P('PK: '+html.escape(', '.join(t['pk']))+'.','SmallHospital'))
            if t['unique']: block.append(P('UNIQUE: '+html.escape('; '.join('('+', '.join(x)+')' for x in t['unique']))+'.','SmallHospital'))
            for f in t['fks']: block.append(P(html.escape(f'{f["name"]}: ({", ".join(f["cols"])}) → {f["parent"]}({", ".join(f["refs"])}).'),'SmallHospital'))
            for check,expr in t['checks']: block.append(P(html.escape(check+': '+expr+'.'),'SmallHospital'))
            for index in t['indexes']: block.append(P(html.escape('Índice: '+index+'.'),'SmallHospital'))
            block.append(Spacer(1,10))
            story.append(KeepTogether(block))
    story.append(PageBreak())
    heading('8. Fuentes y guía de revisión')
    para('Manual oficial MySQL 8.0, consultado el 10 de octubre de 2026. Referencias técnicas para las decisiones físicas; las reglas hospitalarias son supuestos académicos del proyecto.')
    for title,url in REFERENCIAS:
        story.append(P('<b>'+html.escape(title)+'</b><br/><link href="'+html.escape(url,quote=True)+'" color="#155e75">'+html.escape(url)+'</link>','SmallHospital')); story.append(Spacer(1,7))
    heading('Evidencia original incluida',2)
    rows=[]
    for name,obj in original.items(): rows.append([name,', '.join(c[0] for c in obj['cols']),str(len(obj['fks']))])
    story.append(table(['Tabla original','Columnas visibles recuperadas','FK'],rows,[W*.20,W*.70,W*.10]))
    heading('Para la exposición',2)
    for text in [
      'Recorrer un paciente desde cita/consulta hasta receta, entrega y pago; mostrar un traslado si se explica hospitalización.',
      'Demostrar varias líneas por receta, entrega parcial, existencia por lote y precios históricos.',
      'Justificar tablas puente, NULL permitido y claves compuestas; distinguir las reglas por fila de las que exigen transacción.',
      'Presentar las pruebas reales y reconocer lo que quedó pendiente; ajustar la entrega a la rúbrica del profesor.'
    ]: bullet(text)
    doc.build(story,onFirstPage=footer,onLaterPages=footer)

def main():
    global ESTADO_PRUEBAS
    evidence=evidencia_pruebas()
    if evidence: ESTADO_PRUEBAS=evidence['texto_documental']
    tables=parse_ddl(); original=original_metadata(); DIAGRAMAS.mkdir(exist_ok=True)
    (BASE/'DICCIONARIO.md').write_text(markdown_dictionary(tables),encoding='utf-8')
    write_model()
    # README.md se mantiene por separado: contiene la instalación y la interfaz vigentes.
    (DIAGRAMAS/'er_completo.mmd').write_text(mermaid(tables,tables),encoding='utf-8')
    svg_er(tables,tables,'Hospital universitario - modelo físico completo',DIAGRAMAS/'er_completo.svg',columns=6,full=True)
    for key,(title,names) in MODULOS.items():
        # Incluir padres de FK externos para que cada relación saliente sea visible.
        external=[]
        for name in names:
            for f in tables[name]['fks']:
                if f['parent'] not in names and f['parent'] not in external: external.append(f['parent'])
        local=names+external
        (DIAGRAMAS/f'er_{key}.mmd').write_text(mermaid(tables,local),encoding='utf-8')
        svg_er(tables,local,title+' - relaciones físicas',DIAGRAMAS/f'er_{key}.svg',columns=3)
    module_svg(); pdf_report(tables,original)
    print(json.dumps({'tables':len(tables),'columns':sum(len(t['columns']) for t in tables.values()),'foreign_keys':sum(len(t['fks']) for t in tables.values()),'pdf':str(BASE/'reporte_hospital.pdf')},ensure_ascii=False))

if __name__=='__main__': main()
