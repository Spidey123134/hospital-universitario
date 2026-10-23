"""Genera una guía completa de tablas y relaciones directamente del esquema.

Python 3 + ReportLab + pypdf. No conecta ni modifica MySQL. Las imágenes de
los diagramas son vectores PDF y las fichas mantienen todos los tipos SQL.
Después de generar, renderizar y revisar visualmente todas las páginas.
"""
from __future__ import annotations

from collections import OrderedDict
from html import escape
from pathlib import Path
import hashlib
import json
import re

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import landscape, letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Flowable, Frame, KeepTogether, LongTable, NextPageTemplate,
    PageBreak, PageTemplate, Paragraph, Spacer, Table, TableStyle,
)
from pypdf import PdfReader

from generar_documentacion import (
    MODULOS, PROPOSITOS, parse_ddl, fk_child_one, fk_optional, keys,
)

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'output/pdf'
TEMP = ROOT / 'tmp/pdfs/relaciones'
PDF = OUT / 'relaciones_y_tablas_hospital.pdf'
INK = colors.HexColor('#152b3c')
MUTED = colors.HexColor('#536678')
BLUE = colors.HexColor('#155e75')
LIGHT = colors.HexColor('#edf4f7')
LINE = colors.HexColor('#d8e2e9')
PALETTE = ['#155e75', '#4d7c0f', '#2563eb', '#7c3aed', '#b45309', '#be185d', '#047857', '#475569']
W, H = letter
MARGIN = 42
BODY_WIDTH = W - 2 * MARGIN


def fonts():
    candidates = [Path('C:/Windows/Fonts'),
        Path.home()/'.cache/codex-runtimes/codex-primary-runtime/dependencies/native/poppler/Library/share/fonts']
    arial = candidates[0]
    if (arial/'arial.ttf').exists():
        files = {'Body': arial/'arial.ttf', 'BodyBold': arial/'arialbd.ttf', 'BodyItalic': arial/'ariali.ttf',
                 'Code': arial/'consola.ttf'}
    else:
        base = candidates[1]
        files = {'Body': base/'Ubuntu-R.ttf', 'BodyBold': base/'Ubuntu-B.ttf',
                 'BodyItalic': base/'Ubuntu-RI.ttf', 'Code': base/'SourceCodePro-Regular.ttf'}
    for name, path in files.items():
        if not path.exists() and name == 'Code':
            path = candidates[1]/'SourceCodePro-Regular.ttf'
        pdfmetrics.registerFont(TTFont(name, str(path)))
    pdfmetrics.registerFontFamily('Body', normal='Body', bold='BodyBold', italic='BodyItalic', boldItalic='BodyBold')


def styles():
    base = dict(fontName='Body', textColor=INK, fontSize=10, leading=13.2, spaceAfter=7)
    result = {'body': ParagraphStyle('body', **base)}
    for name, extra in {
        'title': dict(fontName='BodyBold', fontSize=27, leading=32, spaceAfter=15),
        'heading': dict(fontName='BodyBold', fontSize=19, leading=23, spaceAfter=9, keepWithNext=True),
        'subheading': dict(fontName='BodyBold', fontSize=11.5, leading=14.5, spaceBefore=10, spaceAfter=5, keepWithNext=True),
        'small': dict(fontSize=8.7, leading=11.3, spaceAfter=4),
        'cell': dict(fontSize=8.7, leading=11, spaceAfter=0),
        'code': dict(fontName='Code', fontSize=8.2, leading=10.8, spaceAfter=0),
        'index': dict(fontSize=9.5, leading=12.5, spaceAfter=0),
        'caption': dict(fontSize=8.7, leading=11.7, textColor=MUTED, spaceAfter=6),
    }.items():
        result[name] = ParagraphStyle(name, **(base | extra))
    return result


S = {}
SCHEMA = OrderedDict()
RELATIONS = []
TABLE_MODULE = {}


def p(text, style='body'):
    return Paragraph(text, S[style])


def code(value):
    return escape(str(value)).replace('_', '_<wbr/>').replace(',', ',<wbr/>')


def heading(text, anchor, level=0):
    obj = p(escape(text), 'heading')
    obj.anchor_key = anchor
    obj.outline_level = level
    obj.outline_title = text
    return obj


def link_table(name):
    return '<link href="#tabla_' + name + '" color="#155e75">' + code(name) + '</link>'


def table_style():
    return TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), LIGHT),
        ('LINEBELOW', (0, 0), (-1, 0), .8, BLUE),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LINEBELOW', (0, 1), (-1, -1), .3, LINE),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f8fafc')]),
    ])


class GuideDoc(BaseDocTemplate):
    def __init__(self, path, total=0):
        super().__init__(str(path), pagesize=letter, leftMargin=MARGIN, rightMargin=MARGIN,
                         topMargin=43, bottomMargin=40, title='Hospital universitario - todas las tablas y relaciones',
                         author='Proyecto Hospital Universitario', allowSplitting=1)
        self.locations = {}
        self.total = total
        frames = []
        for name, size in [('Portrait', letter), ('Landscape', landscape(letter))]:
            width, height = size
            frame = Frame(MARGIN, 39, width - 2*MARGIN, height - 82,
                          leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id=name)
            frames.append(PageTemplate(id=name, frames=[frame], pagesize=size, onPage=self.decorate))
        self.addPageTemplates(frames)

    def decorate(self, canvas, doc):
        width, height = canvas._pagesize
        canvas.saveState()
        canvas.setFont('Body', 8)
        canvas.setFillColor(MUTED)
        canvas.drawString(MARGIN, height - 24, 'HOSPITAL UNIVERSITARIO  /  TABLAS Y RELACIONES')
        canvas.setStrokeColor(LINE)
        canvas.line(MARGIN, 32, width - MARGIN, 32)
        canvas.drawString(MARGIN, 19, 'Estructura MySQL verificada - 23 de octubre de 2026')
        suffix = f' de {self.total}' if self.total else ''
        canvas.drawRightString(width - MARGIN, 19, f'{doc.page}{suffix}')
        canvas.restoreState()

    def afterFlowable(self, flowable):
        if hasattr(flowable, 'anchor_key'):
            key = flowable.anchor_key
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(flowable.outline_title, key, flowable.outline_level, closed=False)
            self.locations[key] = self.page


class ModuleDiagram(Flowable):
    """Tarjetas padre-hijo: cada FK visible una vez y sin cruces de líneas."""
    def __init__(self, module, width):
        super().__init__()
        self.module = module
        self.width = width
        names = MODULOS[module][1]
        self.children = [name for name in names if SCHEMA[name]['fks']]
        self.rows = (len(self.children) + 1)//2
        self.height = self.rows * 132 + 3

    def draw(self):
        c = self.canv
        gap = 16
        card_w = (self.width-gap)/2
        card_h = 120
        current_color = colors.HexColor(PALETTE[list(MODULOS).index(self.module)])
        for index, child in enumerate(self.children):
            x = (index % 2) * (card_w + gap)
            y = self.height - (index//2)*132 - card_h
            c.setFillColor(colors.HexColor('#f8fafc'))
            c.setStrokeColor(LINE)
            c.roundRect(x, y, card_w, card_h, 6, stroke=1, fill=1)
            c.setFillColor(current_color)
            c.setFont('BodyBold', 8.7)
            c.drawString(x+9, y+card_h-14, 'HIJA: ' + child)
            relations = [r for r in RELATIONS if r['child']==child]
            parent_w, child_w = 139, 141
            left = x+8
            right = x+card_w-8-child_w
            middle = y+48
            child_height = max(30, len(relations)*29+3)
            c.setStrokeColor(current_color)
            c.setFillColor(colors.white)
            c.roundRect(right, middle-child_height/2, child_w, child_height, 4, stroke=1, fill=1)
            c.setFillColor(INK)
            c.setFont('BodyBold', 9.1)
            c.drawCentredString(right+child_w/2, middle+3, child)
            c.setFont('Body', 7.7)
            c.setFillColor(MUTED)
            c.drawCentredString(right+child_w/2, middle-10, f"{len(SCHEMA[child]['columns'])} campos | {len(relations)} FK")
            c.linkRect('', 'tabla_'+child, (right, middle-child_height/2, right+child_w, middle+child_height/2), relative=1, thickness=0)
            for j, relation in enumerate(relations):
                cy = middle + (len(relations)-1)*15 - j*30
                parent = relation['parent']
                external = TABLE_MODULE[parent] != self.module
                color = MUTED if external else current_color
                c.setStrokeColor(color)
                c.setFillColor(colors.white if external else LIGHT)
                c.roundRect(left, cy-13, parent_w, 26, 3, stroke=1, fill=1)
                c.setFillColor(INK)
                c.setFont('Body', 8.7)
                c.drawCentredString(left+parent_w/2, cy+2, parent)
                c.setFont('Body', 6.8)
                c.setFillColor(MUTED)
                status = 'opcional: 0..1 padre' if relation['optional'] else 'obligatoria: 1 padre'
                c.drawCentredString(left+parent_w/2, cy-8, status + (' | otra área' if external else ''))
                start, end = left+parent_w, right
                c.setStrokeColor(color)
                c.setLineWidth(.8)
                c.line(start, cy, end, cy)
                c.line(end-3, cy+2, end, cy)
                c.line(end-3, cy-2, end, cy)
                c.setFillColor(INK)
                c.setFont('BodyBold', 7.2)
                c.drawCentredString((start+end)/2, cy+5, relation['id'])
                c.setFont('Body', 6.8)
                c.drawCentredString((start+end)/2, cy-8, relation['children'])
                c.linkRect('', 'relaciones', (start, cy-12, end, cy+13), relative=1, thickness=0)
                c.linkRect('', 'tabla_'+parent, (left, cy-13, left+parent_w, cy+13), relative=1, thickness=0)


def cover():
    story = [Spacer(1, 19), heading('Todas las tablas\ny sus relaciones', 'portada'),
             p('Hospital universitario', 'title'),
             p('Guía del modelo físico del repositorio. Incluye cada tabla, cada campo y cada clave foránea, con diagramas separados por área para poder leerlos e imprimirlos.'),
             Spacer(1, 10)]
    stats = Table([[p('<b>36 tablas</b>'), p('<b>205 campos</b>'), p('<b>48 relaciones FK</b>')]], colWidths=[176]*3)
    stats.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,-1),LIGHT),('BOX',(0,0),(-1,-1),.5,LINE),('TOPPADDING',(0,0),(-1,-1),12),('BOTTOMPADDING',(0,0),(-1,-1),8)]))
    story += [stats, Spacer(1, 14), p('<b>Cómo leer una relación</b>', 'subheading'),
              p('La tabla <b>hija</b> guarda la FK; la tabla <b>padre</b> contiene la clave a la que apunta. Por ejemplo, cada consulta corresponde a un paciente; un paciente puede tener cero o muchas consultas.'),
              p('<b>0..N</b> significa cero o muchos registros. <b>0..1</b> significa cero o uno. <b>1</b> significa exactamente uno. Son posibilidades del diseño, no el número de filas cargadas.'),
              p('<b>Claves y símbolos</b>', 'subheading')]
    legend = [
        ('PK', 'Clave primaria: identifica un registro. Puede estar formada por varios campos.'),
        ('FK', 'Clave foránea: conecta con una clave de otra tabla. Una FK compuesta es una sola relación.'),
        ('U*', 'Participa en UNIQUE. Revisa la combinación completa; cada campo no tiene por qué ser único por separado.'),
        ('AI', 'AUTO_INCREMENT: MySQL asigna el identificador automáticamente.'),
        ('G', 'Columna calculada y almacenada por MySQL; su expresión aparece en la ficha.'),
        ('NULL', 'Permite dejar el valor sin registrar. No equivale a cero ni a una cadena vacía.'),
    ]
    tab = Table([[p('<b>'+a+'</b>','cell'),p(b,'cell')] for a,b in legend], colWidths=[43,485])
    tab.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),('LINEBELOW',(0,0),(-1,-1),.3,LINE),('TOPPADDING',(0,0),(-1,-1),5),('BOTTOMPADDING',(0,0),(-1,-1),5)]))
    story += [tab, Spacer(1, 11), p('Usa el índice y los marcadores del lector PDF para saltar a una tabla. Los nombres de las tablas en los diagramas también se pueden pulsar.', 'caption'),
              p('Fuente: 01_esquema.sql y 02_reglas.sql. La estructura se contrastó con los metadatos del MySQL local el 23 de octubre de 2026. El documento describe el proyecto académico, no un sistema clínico certificado.', 'caption')]
    return story


def contents(page_refs):
    story = [heading('Índice de diagramas y tablas', 'indice'),
             p('Los números de página y los nombres son enlaces internos. Las ocho vistas asignan cada relación al área de su tabla hija, aunque el padre pertenezca a otra área.', 'small')]
    modules = list(MODULOS.items())
    data = [[p('<b>Diagrama por área</b>', 'cell'),p('<b>Pág.</b>', 'cell'),p('<b>Diagrama por área</b>', 'cell'),p('<b>Pág.</b>','cell')]]
    for i in range(4):
        cells=[]
        for key,(title,names) in (modules[i], modules[i+4]):
            cells += [p(f'<link href="#modulo_{key}" color="#155e75">{escape(title)}</link>','index'),p(f'<link href="#modulo_{key}" color="#155e75">{page_refs.get("modulo_"+key,"-")}</link>','index')]
        data.append(cells)
    table = Table(data,colWidths=[230,34,230,34]);table.setStyle(table_style())
    story += [table, Spacer(1,12),p('Fichas de las 36 tablas', 'subheading')]
    names=list(SCHEMA)
    data=[[p('<b>Tabla</b>','cell'),p('<b>Pág.</b>','cell'),p('<b>Tabla</b>','cell'),p('<b>Pág.</b>','cell')]]
    for i in range(18):
        cells=[]
        for index in (i,i+18):
            name=names[index]
            cells += [p(f'{index+1:02d}. '+link_table(name),'index'),p(f'<link href="#tabla_{name}" color="#155e75">{page_refs.get("tabla_"+name,"-")}</link>','index')]
        data.append(cells)
    tab=Table(data,colWidths=[230,34,230,34]);tab.setStyle(table_style())
    tab.setStyle(TableStyle([('TOPPADDING',(0,1),(-1,-1),3),('BOTTOMPADDING',(0,1),(-1,-1),3)]))
    story += [tab, Spacer(1,10),p(f'<link href="#relaciones" color="#155e75"><b>Catálogo completo de las 48 FK</b></link> - página <link href="#relaciones" color="#155e75">{page_refs.get("relaciones","-")}</link>. Incluye campos, restricciones y cardinalidades exactas.','small')]
    return story


def overview():
    story=[heading('Cómo se organiza el hospital', 'mapa'),
           p('Los 8 módulos reúnen las 36 tablas. Una misma tabla padre puede aparecer en varios diagramas como referencia; eso no crea otra tabla ni otra relación.'),
           p('Cada FK se enumera una sola vez, F01 a F48, y mantiene el identificador del diagrama físico del repositorio. Las relaciones conceptuales N:M se resuelven mediante tablas puente.','small')]
    data=[[p('<b>Área</b>','cell'),p('<b>Tablas incluidas</b>','cell'),p('<b>FK de sus hijas</b>','cell')]]
    for key,(title,names) in MODULOS.items():
        count=sum(len(SCHEMA[n]['fks']) for n in names)
        data.append([p(f'<link href="#modulo_{key}" color="#155e75">{escape(title)}</link>','cell'),p(', '.join(link_table(n) for n in names),'cell'),p(str(count),'cell')])
    table=Table(data,colWidths=[132,338,58],repeatRows=1);table.setStyle(table_style())
    story += [table,Spacer(1,12),p('Reglas que conviene tener presentes','subheading'),
        p('Un padre puede tener cero hijos: una FK exige que el padre exista cuando se usa una referencia, pero no obliga a crear filas hijas.'),
        p('Las 48 FK restringen borrar o cambiar la clave de un padre mientras tenga hijos asociados. El servidor las registra como NO ACTION; en InnoDB equivale a RESTRICT.'),
        p('En una FK compuesta opcional, MySQL admite la referencia parcialmente NULL. Las demás FK de esa fila siguen validando paciente, médico o lote cuando corresponda.'),
        p('Las relaciones no sustituyen los CHECK, las restricciones UNIQUE ni las reglas de negocio: los 23 triggers y 6 procedimientos añaden validaciones sobre agenda, estancias, entregas y cobros. Las 6 vistas son consultas guardadas y no se cuentan como tablas.','small'),
        p('Referencia de la semántica NULL: <link href="https://dev.mysql.com/doc/refman/8.0/en/ansi-diff-foreign-keys.html" color="#155e75">Manual oficial de MySQL, claves foráneas</link>.','caption')]
    return story


def module_pages():
    story=[]
    for key,(title,names) in MODULOS.items():
        story += [NextPageTemplate('Landscape'),PageBreak(),heading(title,'modulo_'+key,1),
                  p(f"{len(names)} tablas del área | {sum(len(SCHEMA[n]['fks']) for n in names)} relaciones FK. Cada tarjeta muestra una hija y los padres a los que hace referencia.",'small'),
                  ModuleDiagram(key, landscape(letter)[0]-2*MARGIN),
                  p('Lee de izquierda a derecha: padre a hija. Debajo de cada Fxx se indica cuántas hijas puede tener un padre. La leyenda del padre indica si cada hija exige ese padre. Las referencias de otra área se repiten para mantener el contexto.','caption')]
        no_fk=[n for n in names if not SCHEMA[n]['fks']]
        if no_fk:
            story.append(p('Tablas del área sin FK propias: '+', '.join(link_table(n) for n in no_fk)+'. Sus relaciones entrantes se detallan en las fichas.','caption'))
    return story


def table_pages():
    story=[NextPageTemplate('Portrait'),PageBreak(),heading('Fichas de las tablas','fichas'),
           p('Cada ficha contiene todos los campos del DDL y las relaciones en ambos sentidos. Los UNIQUE se escriben completos para distinguir claves simples de compuestas.'),
           p('Los valores predeterminados no son ejemplos de pacientes. "Sin DEFAULT" significa que el DDL no declara uno; en una columna nullable MySQL puede usar NULL. Las expresiones generadas no se capturan manualmente.','small')]
    for index,(name,t) in enumerate(SCHEMA.items()):
        if index: story.append(PageBreak())
        story += [heading(f'{index+1:02d}. {name}','tabla_'+name,1),p(escape(PROPOSITOS[name]),'small')]
        data=[[p('<b>Campo</b>','cell'),p('<b>Tipo SQL completo</b>','cell'),p('<b>NULL</b>','cell'),p('<b>Clave</b>','cell'),p('<b>Valor inicial / cálculo</b>','cell')]]
        for col in t['columns']:
            default = ('Secuencia automática' if col['auto'] else
                       'G: '+col['generated'] if col['generated'] else
                       col['default'] if col['default'] else 'Sin DEFAULT')
            marks=keys(t,col).replace('UK*','U*')
            data.append([p(code(col['name']),'code'),p(code(col['type']),'code'),p('Sí' if col['nullable'] else 'No','cell'),p(escape(marks),'cell'),p(code(default),'code')])
        tab=LongTable(data,colWidths=[128,148,42,48,162],repeatRows=1,hAlign='LEFT',splitByRow=1)
        tab.setStyle(table_style());story.append(tab)
        story += [p('Claves y restricciones','subheading'),p('<b>PK completa:</b> '+code(', '.join(t['pk']))+'.','small')]
        if t['unique']:
            story.append(p('<b>UNIQUE completos:</b> '+'; '.join('('+code(', '.join(u))+')' for u in t['unique'])+'.','small'))
        if t['checks']:
            for constraint,expression in t['checks']:
                story.append(p('<b>'+code(constraint)+':</b> '+code(expression),'small'))
        outgoing=[r for r in RELATIONS if r['child']==name]
        incoming=[r for r in RELATIONS if r['parent']==name]
        story.append(p('Relaciones que salen de esta tabla (FK)','subheading'))
        if not outgoing:
            story.append(p('No contiene claves foráneas. Puede recibir referencias desde otras tablas.','small'))
        for r in outgoing:
            parent_range='0..1' if r['optional'] else '1'
            story.append(p(f'<b>{r["id"]}</b> - '+code(', '.join(r['cols']))+' → '+link_table(r['parent'])+'('+code(', '.join(r['refs']))+'). '
                +f'Cada fila de esta tabla admite {parent_range} padre; cada padre admite {r["children"]} filas de esta tabla. '
                +'<font color="#536678">'+code(r['constraint'])+'</font>.','small'))
        story.append(p('Tablas que la referencian','subheading'))
        if incoming:
            story.append(p('; '.join('<b>'+r['id']+'</b> '+link_table(r['child'])+' ('+r['children']+' hijas)' for r in incoming)+'.','small'))
        else:
            story.append(p('No recibe claves foráneas desde otras tablas del modelo.','small'))
        if name in ('medico_especialidad','consulta_diagnosticos','usuario_roles'):
            story.append(p('Esta tabla puente representa una relación conceptual de muchos a muchos; sus dos FK físicas se cuentan por separado en el catálogo.','caption'))
        if name=='asignaciones_camilla':
            story.append(p('El historial permite muchas asignaciones por hospitalización y por camilla. Los UNIQUE sobre columnas generadas solo limitan las asignaciones abiertas; no convierten todo el historial en 1:1.','caption'))
        if name=='usuarios':
            story.append(p('Estos usuarios y roles son parte del modelo académico. La aplicación actual conecta con credenciales de MySQL y no implementa autenticación de empleados.','caption'))
    return story


def relation_catalog():
    story=[PageBreak(),heading('Catálogo de las 48 relaciones','relaciones'),
           p('Una fila equivale a una restricción FOREIGN KEY, aunque intervengan varios campos. Las columnas FK están en la hija y apuntan, en el mismo orden, a las columnas del padre.','small')]
    data=[[p('<b>ID / restricción</b>','cell'),p('<b>Padre → hija</b>','cell'),p('<b>FK hija → clave padre</b>','cell'),p('<b>Rangos</b>','cell')]]
    for r in RELATIONS:
        detail = f"Hijas por padre: {r['children']}<br/>Padres por hija: {'0..1' if r['optional'] else '1'}"
        data.append([p('<b>'+r['id']+'</b><br/>'+code(r['constraint']),'code'),
                     p(link_table(r['parent'])+'<br/>→ '+link_table(r['child']),'cell'),
                     p(code(', '.join(r['cols']))+'<br/>→ '+code(', '.join(r['refs'])),'code'),
                     p(detail,'cell')])
    tab=LongTable(data,colWidths=[133,130,174,91],repeatRows=1,splitByRow=1,hAlign='LEFT');tab.setStyle(table_style())
    story += [tab,Spacer(1,10),p('Balance de cobertura','subheading'),
              p('36 tablas, 205 campos y 48 FK: 7 compuestas, 3 opcionales y 6 con un máximo de una hija por padre. Además: 38 restricciones UNIQUE fuera de las PK, 26 CHECK y 7 columnas generadas.','small'),
              p('La estructura del repositorio y la instancia local MySQL coincidieron en nombres, tipos, NULL, PK, UNIQUE, columnas generadas y claves foráneas. No se modificó la base para producir este documento.','small'),
              p('Fuentes del repositorio: 01_esquema.sql, 02_reglas.sql y el diccionario generado de ese mismo DDL. Las fichas no incluyen nombres de pacientes, contactos, contraseñas ni información de conexión.','caption')]
    return story


def story(page_refs):
    flow=cover()+[PageBreak()]+contents(page_refs)+[PageBreak()]+overview()
    flow += module_pages()+table_pages()+relation_catalog()
    return flow


def build():
    global S,SCHEMA,RELATIONS,TABLE_MODULE
    fonts(); S=styles(); SCHEMA=parse_ddl(); RELATIONS=[]
    TABLE_MODULE={name:key for key,(_,names) in MODULOS.items() for name in names}
    for child,t in SCHEMA.items():
        for fk in t['fks']:
            RELATIONS.append({'id':f'F{len(RELATIONS)+1:02d}','child':child,'parent':fk['parent'],
                              'constraint':fk['name'],'cols':fk['cols'],'refs':fk['refs'],
                              'optional':fk_optional(t,fk),'children':'0..1' if fk_child_one(t,fk) else '0..N'})
    assert len(RELATIONS)==48 and sum(len(t['columns']) for t in SCHEMA.values())==205
    OUT.mkdir(parents=True,exist_ok=True);TEMP.mkdir(parents=True,exist_ok=True)
    first=GuideDoc(TEMP/'primera_maqueta.pdf');first.build(story({}))
    total=len(PdfReader(str(TEMP/'primera_maqueta.pdf')).pages)
    final=GuideDoc(PDF,total);final.build(story(first.locations))
    reader=PdfReader(str(PDF))
    assert len(reader.pages)==total and first.locations==final.locations
    fields_verified=0
    table_names=list(SCHEMA)
    for i,name in enumerate(table_names):
        start=final.locations['tabla_'+name]-1
        end=final.locations['tabla_'+table_names[i+1]]-1 if i+1<len(table_names) else final.locations['relaciones']-1
        text=re.sub(r'\s+','', ''.join(page.extract_text() or '' for page in reader.pages[start:end]))
        for col in SCHEMA[name]['columns']:
            assert col['name'] in text,(name,col['name'])
            fields_verified += 1
    catalog=''.join(page.extract_text() or '' for page in reader.pages[final.locations['relaciones']-1:])
    catalog=re.sub(r'\s+','',catalog)
    assert all(r['constraint'] in catalog for r in RELATIONS)
    assert not any('\ufffd' in (page.extract_text() or '') for page in reader.pages)
    report={'estado':'GENERADO; PENDIENTE DE REVISIÓN VISUAL','fecha':'2026-10-23','paginas':total,
            'tablas':len(SCHEMA),'campos':fields_verified,'relaciones_fk':len(RELATIONS),
            'fk_compuestas':sum(len(r['cols'])>1 for r in RELATIONS),'fk_opcionales':sum(r['optional'] for r in RELATIONS),
            'fk_maximo_una_hija':sum(r['children']=='0..1' for r in RELATIONS),
            'diagramas_por_area':len(MODULOS),'tarjetas_hijas':sum(bool(t['fks']) for t in SCHEMA.values()),
            'paginas_por_marcador':final.locations,'indice_enlazado':True,'diagramas_vectoriales':True,
            'campos_verificados_por_ficha':True,'restricciones_fk_verificadas_en_catalogo':True,
            'sha256':{'01_esquema.sql':hashlib.sha256((ROOT/'01_esquema.sql').read_bytes()).hexdigest(),
                      '02_reglas.sql':hashlib.sha256((ROOT/'02_reglas.sql').read_bytes()).hexdigest(),
                      'generar_relaciones_pdf.py':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                      'relaciones_y_tablas_hospital.pdf':hashlib.sha256(PDF.read_bytes()).hexdigest()}}
    (OUT/'REVISION_RELACIONES_PDF.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'pdf':str(PDF),'paginas':total,'tablas':36,'campos':fields_verified,'fk':len(RELATIONS)},ensure_ascii=False))


if __name__=='__main__':
    build()
