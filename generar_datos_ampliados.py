"""Genera una demostración reproducible con personas y operaciones inventadas."""
from pathlib import Path
from datetime import datetime, timedelta
import json
import csv

ROOT = Path(__file__).resolve().parent

def capture(name):
    with (ROOT/'aporte_equipo'/name).open(encoding='utf-8-sig', newline='') as file:
        return list(csv.DictReader(file))

def lit(value):
    if value is None: return 'NULL'
    if isinstance(value, (int, float)): return str(value)
    return "'" + str(value).replace("'", "''") + "'"

def stamp(value): return value.strftime('%Y-%m-%d %H:%M:%S')

def generate():
    blocks=[]; additions={}
    def insert(name, columns, rows):
        if not rows: return
        additions[name]=additions.get(name,0)+len(rows)
        blocks.append('INSERT INTO '+name+' ('+', '.join(columns)+') VALUES\n  '+',\n  '.join('('+', '.join(lit(x) for x in row)+')' for row in rows)+';\n')

    insert('departamentos',['departamento_id','codigo','nombre'],[
        (6,'DEP-DEMO-06','Imagenologia de demostracion'),
        (7,'DEP-DEMO-07','Cuidados intensivos de demostracion'),
        (8,'DEP-DEMO-08','Urgencias de demostracion')])
    specialties=['Cardiologia','Traumatologia','Ginecologia','Neurologia','Dermatologia','Oftalmologia','Otorrinolaringologia','Oncologia','Psiquiatria','Nefrologia','Endocrinologia','Urologia']
    insert('especialidades',['especialidad_id','nombre'],[(i+4,n) for i,n in enumerate(specialties)]+[(16,'Urgencias')])
    doctors=capture('medicos_captura.csv')
    staff=[(i+9,f'EMP-DEMO-{i+9:03}',[1,8,2,6][i%4],row['nombre'],row['apellido_paterno'],'Simulado','MEDICO',f'TEL-DEMO-{i+9:03}',f'medico.{i+9}@example.invalid',1) for i,row in enumerate(doctors)]
    staff += [(24,'EMP-DEMO-024',2,'Mariana','Vega','Simulado','ENFERMERIA','TEL-DEMO-024','enfermeria.24@example.invalid',1),(25,'EMP-DEMO-025',2,'Daniel','Leon','Simulado','ENFERMERIA','TEL-DEMO-025','enfermeria.25@example.invalid',1)]
    insert('personal',['personal_id','numero_empleado','departamento_id','nombre','apellido_paterno','apellido_materno','puesto','telefono','email','activo'],staff)
    insert('medicos',['medico_id','cedula_profesional'],[(i+9,row['cedula_profesional']) for i,row in enumerate(doctors)])
    specialty_ids=[1,16,4,3,5,6,7,8,9,10,11,12,13,14,15]
    insert('medico_especialidad',['medico_id','especialidad_id'],[(i+9,specialty_ids[i]) for i in range(15)])

    names=[('Andrea','Perez','F'),('Diego','Sanchez','M'),('Valeria','Romero','F'),('Mateo','Ortiz','M'),('Camila','Reyes','F'),('Sebastian','Cruz','M'),('Renata','Aguilar','F'),('Emiliano','Jimenez','M'),('Paula','Rojas','F'),('Nicolas','Chavez','M'),('Fernanda','Molina','F'),('Alejandro','Silva','M'),('Regina','Castillo','F'),('Leonardo','Herrera','M'),('Daniela','Vazquez','F'),('Santiago','Navarro','M'),('Isabella','Acosta','F'),('Gabriel','Luna','M'),('Ximena','Salazar','F'),('Rodrigo','Guerrero','M'),('Natalia','Campos','F'),('Mauricio','Delgado','M'),('Carolina','Paredes','F'),('Joaquin','Fuentes','M'),('Adriana','Mejia','F')]
    insert('pacientes',['paciente_id','expediente_clinico','nombre','apellido_paterno','apellido_materno','fecha_nacimiento','sexo','telefono','email','domicilio','fecha_registro','activo'],[(i+6,f'EXP-DEMO-{i+6:03}',n,a,'Simulado',f'{1970+(i*3)%45:04}-{1+i%12:02}-{1+i%27:02}',s,f'TEL-PAC-DEMO-{i+6:03}',f'paciente.{i+6}@example.invalid',f'Domicilio ficticio {i+6}','2026-09-15 09:00:00',1) for i,(n,a,s) in enumerate(names)])
    insert('contactos_emergencia',['contacto_id','paciente_id','nombre','parentesco','telefono','prioridad'],[(i+7,i+6,f'Contacto simulado de {names[i][0]}','Familiar ficticio',f'TEL-CON-DEMO-{i+7:03}',1) for i in range(25)])
    insert('aseguradoras',['aseguradora_id','nombre','telefono'],[(3,'Aseguradora ficticia Gamma','TEL-ASEG-DEMO-003'),(4,'Aseguradora ficticia Delta','TEL-ASEG-DEMO-004'),(5,'Aseguradora ficticia Epsilon','TEL-ASEG-DEMO-005')])
    insert('polizas',['poliza_id','paciente_id','aseguradora_id','numero_poliza','fecha_inicio','fecha_fin'],[(i+4,i+6,3+i%3,f'POLIZA-DEMO-{i+4:03}','2026-01-01','2027-12-31') for i in range(15)])
    insert('habitaciones',['habitacion_id','departamento_id','codigo','edificio','piso','tipo'],[(i+5,2,f'HAB-DEMO-{i+5:03}','Edificio de prueba C',2+i//3,['GENERAL','PRIVADA','UCI','GENERAL','URGENCIAS'][i]) for i in range(5)])
    insert('camillas',['camilla_id','habitacion_id','codigo','estado_operativo'],[(i+7,5+i//2,f'CAM-DEMO-{i+7:02}','MANTENIMIENTO' if i==8 else 'OPERATIVA') for i in range(9)])

    consultations=[]; appointments=[]
    dates={}
    for i in range(25):
        cid=i+6; pid=i+6; doctor=9+i%15
        date=datetime(2026,10,1)+timedelta(days=i//5,hours=9,minutes=(i%5)*45)
        dates[cid]=date+timedelta(minutes=5)
        appointments.append((i+7,pid,doctor,stamp(date),stamp(date+timedelta(minutes=30)),f'Consulta programada del caso ficticio {pid}','ATENDIDA'))
        consultations.append((cid,i+7,pid,doctor,stamp(dates[cid]),'PROGRAMADA',f'Revision del caso ficticio {pid}','Registro inventado para probar relaciones y consultas; sin uso clinico.',55+i,155+i%25,36.5+(i%3)/10))
    for i in range(8):
        date=datetime(2026,10,20,9)+timedelta(days=i//4,hours=i%4)
        appointments.append((32+i,6+i,9+i,stamp(date),stamp(date+timedelta(minutes=30)),'Seguimiento de demostracion','CONFIRMADA' if i%2 else 'PROGRAMADA'))
    insert('citas',['cita_id','paciente_id','medico_id','inicio','fin','motivo','estado'],appointments)
    insert('consultas',['consulta_id','cita_id','paciente_id','medico_id','fecha','tipo','motivo','notas','peso_kg','talla_cm','temperatura_c'],consultations)
    insert('diagnosticos',['diagnostico_id','codigo','descripcion'],[(i+4,f'DEMO-{i+4:02}',f'Diagnostico ficticio del caso {i+4}; codigo de prueba, no CIE') for i in range(5)])
    dx=[]
    for i in range(25):
        dx.append((i+6,4+i%5,1,'Diagnostico principal simulado'))
        if i%3==0: dx.append((i+6,2,0,'Diagnostico secundario simulado'))
    insert('consulta_diagnosticos',['consulta_id','diagnostico_id','es_principal','observaciones'],dx)
    insert('alergias_paciente',['alergia_id','paciente_id','sustancia','reaccion','fecha_registro'],[(i+3,6+i*4,f'Compuesto de prueba {i+1}','Reaccion simulada para comprobar el expediente','2026-09-15') for i in range(7)])
    stays=[]; beds=[]; notes=[]
    for i in range(9):
        date=dates[i+6]+timedelta(hours=1); end=date+timedelta(days=1) if i>=6 else None
        stays.append((i+3,i+6,i+6,9+i%15,stamp(date),stamp(end) if end else None,'Estancia del caso ficticio '+str(i+6),'Cierre simulado del caso' if end else None))
        beds.append((i+4,i+3,(7+i) if i<6 else [13,14,3][i-6],stamp(date),stamp(end) if end else None))
        for j in range(2): notes.append((4+i*2+j,i+3,24+j,stamp(date+timedelta(minutes=30+j*120)),f'Nota simulada {j+1} de la estancia {i+3}; dato de demostracion.'))
    insert('hospitalizaciones',['hospitalizacion_id','consulta_ingreso_id','paciente_id','medico_responsable_id','fecha_ingreso','fecha_alta','motivo','resumen_alta'],stays)
    insert('asignaciones_camilla',['asignacion_id','hospitalizacion_id','camilla_id','inicio','fin'],beds)
    insert('notas_enfermeria',['nota_id','hospitalizacion_id','personal_id','fecha','observacion'],notes)

    concentrations={m:[5,10,20,25][m%4] for m in range(4,16)}
    insert('medicamentos',['medicamento_id','codigo','principio_activo','concentracion','presentacion','unidad_inventario','stock_minimo'],[(m,f'MED-DEMO-{m:02}',f'Compuesto simulado {m:02}',f'{concentrations[m]} mg (simulado)','Envase de 30 unidades ficticias','unidad simulada',15+(m%4)*5) for m in range(4,16)])
    insert('proveedores',['proveedor_id','nombre','telefono','email'],[(3,'Proveedor ficticio Gamma','TEL-PROV-DEMO-003','proveedor.gamma@example.invalid'),(4,'Proveedor ficticio Delta','TEL-PROV-DEMO-004','proveedor.delta@example.invalid')])
    insert('lotes_medicamento',['lote_id','medicamento_id','proveedor_id','numero_lote','fecha_recepcion','fecha_caducidad','costo_unitario'],[(m+1,m,3+m%2,f'LOTE-DEMO-{m:02}','2026-09-01','2028-12-31',3.5+m) for m in range(4,16)])
    insert('movimientos_inventario',['movimiento_id','lote_id','dispensacion_detalle_id','personal_id','fecha','tipo','cantidad','motivo'],[(m+3,m+1,None,6,'2026-09-01 12:00:00','ENTRADA',200+m*10,'Recepcion del lote ficticio '+str(m)) for m in range(4,16)])
    recipes=[]; lines=[]; amounts={}
    for i in range(22):
        rid=i+4; recipes.append((rid,i+6,stamp(dates[i+6]+timedelta(minutes=15)),'Prescripcion totalmente simulada de un compuesto ficticio; sin uso clinico.'))
        for line in (1,2):
            med=4+(i+(line-1)*4)%12; hours=[6,8,12,24][(i+line)%4]; duration=3+i%5; qty=24//hours*duration
            lines.append((rid,line,med,f'{concentrations[med]} mg (dato simulado)',f'Cada {hours} horas (simulado)',duration,'Oral (simulada)',qty))
            amounts[(rid,line)]=(med,qty)
    insert('recetas',['receta_id','consulta_id','fecha_prescripcion','observaciones'],recipes)
    insert('receta_detalle',['receta_id','renglon','medicamento_id','dosis','frecuencia','duracion_dias','via_administracion','cantidad_prescrita'],lines)
    deliveries=[]; delivered=[]; movements=[]
    for i in range(10):
        rid=i+4; did=i+2; date=dates[i+6]+timedelta(hours=1)
        deliveries.append((did,rid,6,stamp(date)))
        for line in (1,2):
            med,qty=amounts[(rid,line)]; qty=qty if i<5 else max(1,qty//2); detail=3+i*2+line-1
            delivered.append((detail,did,rid,line,med,med+1,qty))
            movements.append((19+i*2+line-1,med+1,detail,6,stamp(date),'SALIDA',-qty,f'Entrega simulada de receta {rid}, renglon {line}'))
    insert('dispensaciones',['dispensacion_id','receta_id','personal_id','fecha'],deliveries)
    insert('dispensacion_detalle',['dispensacion_detalle_id','dispensacion_id','receta_id','renglon','medicamento_id','lote_id','cantidad'],delivered)
    insert('movimientos_inventario',['movimiento_id','lote_id','dispensacion_detalle_id','personal_id','fecha','tipo','cantidad','motivo'],movements)
    insert('procedimientos',['procedimiento_id','codigo','nombre','tipo','precio_referencia'],[(5,'PROC-DEMO-05','Estudio docente de laboratorio B','LABORATORIO',125),(6,'PROC-DEMO-06','Estudio docente de imagen C','IMAGEN',150),(7,'PROC-DEMO-07','Procedimiento docente de cirugia E','CIRUGIA',175),(8,'PROC-DEMO-08','Procedimiento docente ambulatorio F','OTRO',200)])
    orders=[]; results=[]
    for i in range(25):
        request=dates[i+6]+timedelta(minutes=20); oid=i+5
        orders.append((oid,i+6,5+i%4,stamp(request),stamp(request+timedelta(hours=2)),'CANCELADA' if i==23 else ('SOLICITADA' if i<13 else 'PROGRAMADA'),'Indicacion inventada para probar el flujo del sistema.'))
        if i<13: results.append((i+3,oid,8 if i%4==0 else 9+i%15,stamp(request+timedelta(hours=3)),'Informe simulado del estudio '+str(oid)+'; no contiene resultados clinicos reales.'))
    insert('ordenes_procedimiento',['orden_id','consulta_id','procedimiento_id','fecha_solicitud','fecha_programada','estado','indicaciones'],orders)
    insert('resultados_procedimiento',['resultado_id','orden_id','personal_id','fecha_resultado','informe'],results)
    invoices=[]; concepts=[]; payments=[]; payid=5
    for i in range(25):
        fid=i+5; date=dates[i+6]+timedelta(hours=4); fee=350+(i%6)*50; study=125+(i%4)*25
        invoices.append((fid,f'FAC-DEMO-{fid:03}',i+6,i+4 if i<15 else None,stamp(date),'ABIERTA'))
        concepts += [(fid,1,'Consulta de demostracion '+str(i+6),1,fee,0),(fid,2,'Servicio ficticio de procedimiento',1,study,0)]
        values=[fee+study] if i<5 else ([150] if i<10 else ([75,50] if i<15 else []))
        for j,amount in enumerate(values):
            payments.append((payid,fid,stamp(date+timedelta(minutes=15+j*30)),amount,['EFECTIVO','TARJETA','TRANSFERENCIA'][i%3],f'PAGO-DEMO-{payid:03}')); payid+=1
    insert('facturas',['factura_id','folio','paciente_id','poliza_id','fecha','estado'],invoices)
    insert('factura_detalle',['factura_id','renglon','descripcion','cantidad','precio_unitario','descuento'],concepts)
    blocks.append("UPDATE facturas SET estado = 'EMITIDA' WHERE factura_id BETWEEN 5 AND 24;\n")
    insert('pagos',['pago_id','factura_id','fecha','monto','metodo','referencia'],payments)
    insert('roles',['rol_id','nombre','descripcion'],[(5,'LABORATORIO','Rol simulado de la futura aplicacion.'),(6,'ENFERMERIA','Rol simulado de la futura aplicacion.')])
    insert('usuarios',['usuario_id','personal_id','nombre_usuario','password_hash','activo'],[(i+4,p,f'demo.personal.{p}','MARCADOR_DEMO_NO_ES_HASH_VALIDO_NO_INICIAR_SESION',0) for i,p in enumerate([24,25,8,9])])
    insert('usuario_roles',['usuario_id','rol_id'],[(4,6),(5,6),(6,5),(7,2)])

    # Las capturas no muestran pacientes ni nombres de medicamentos. Los
    # destinos son ejemplos docentes; los identificadores fuente quedan en CSV.
    team_appointments=[]; team_consultations=[]; team_recipes=[]; team_lines=[]
    for i,row in enumerate(capture('recetas_captura.csv')):
        rid=int(row['receta_id_destino']); cid=31+i; pid=int(row['paciente_id_destino']); doctor=int(row['medico_id_destino'])
        date=datetime(2026,10,10,9)+timedelta(minutes=30*i)
        team_appointments.append((40+i,pid,doctor,stamp(date),stamp(date+timedelta(minutes=25)),'Caso docente adaptado de la captura del equipo','ATENDIDA'))
        team_consultations.append((cid,40+i,pid,doctor,stamp(date+timedelta(minutes=5)),'PROGRAMADA','Caso docente adaptado de la receta '+row['receta_id_original'],'Consulta y paciente ficticios agregados para adaptar el aporte al modelo normalizado.'))
        observations='[APORTE EQUIPO receta '+row['receta_id_original']+'; paciente fuente '+row['paciente_id_original']+'; camilla fuente '+row['camilla_id_original']+'; medicamento fuente '+row['medicamento_id_original']+']. '+row['observaciones']+' Paciente, medicamento asociado, hora, cantidad y duracion no indicada: ejemplos docentes agregados, no datos recuperados.'
        team_recipes.append((rid,cid,stamp(date+timedelta(minutes=10)),observations))
        # Se conserva el texto de dosis completo sin reinterpretarlo. Cantidad
        # y duracion satisfacen la estructura como parametros de prueba.
        team_lines.append((rid,1,int(row['medicamento_id_original']),row['dosis'],'Ver texto de dosis de la captura',7 if i==3 else 1,row['via_administracion'],1))
    insert('citas',['cita_id','paciente_id','medico_id','inicio','fin','motivo','estado'],team_appointments)
    insert('consultas',['consulta_id','cita_id','paciente_id','medico_id','fecha','tipo','motivo','notas'],team_consultations)
    insert('recetas',['receta_id','consulta_id','fecha_prescripcion','observaciones'],team_recipes)
    insert('receta_detalle',['receta_id','renglon','medicamento_id','dosis','frecuencia','duracion_dias','via_administracion','cantidad_prescrita'],team_lines)
    header='''-- DATOS INVENTADOS PARA DEMOSTRACION UNIVERSITARIA.
-- Agrega casos completos sobre la carga inicial de 03_datos_demo.sql.
-- Ejecutar UNA SOLA VEZ. No reemplaza ni elimina los datos iniciales.
-- En Workbench activa Stop Script Execution On Errors; si falla, ROLLBACK.
-- No ejecutar COMMIT si un INSERT fallo. No importar usando --force.
-- Incluye nombres, cedulas de ejemplo y textos transcritos de las capturas del equipo.
-- Los pacientes, compuestos y operaciones agregadas son ejemplos docentes.
SET NAMES utf8mb4;
USE hospital_universitario;
START TRANSACTION;

'''
    sql=header+'\n'.join(blocks)+'\nCOMMIT;\n'
    (ROOT/'05_datos_demo_ampliados.sql').write_text(sql,encoding='utf-8')
    core=(ROOT/'hospital_completo.sql').read_text(encoding='utf-8-sig')
    (ROOT/'hospital_demostracion.sql').write_text('-- INSTALACION NUEVA CON LA DEMOSTRACION AMPLIADA.\n-- Crea hospital_universitario: no ejecutar tambien hospital_completo.sql.\n'+core+'\n\n'+sql,encoding='utf-8')
    print(json.dumps({'filas_agregadas':sum(additions.values()),'por_tabla':additions},ensure_ascii=True))

if __name__=='__main__': generate()
