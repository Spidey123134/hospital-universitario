# Integración del aporte del equipo

Fuente: las capturas del modelo de cinco tablas, de los 15 médicos y de las 15 recetas compartidas por el equipo. Esta integración transcribe lo visible; no recupera registros de archivos `.ibd` ni supone que tenemos un respaldo SQL completo.

## Lo que se conservó

- [medicos_captura.csv](medicos_captura.csv): los 15 nombres, apellidos, cédulas de ejemplo, especialidades y horarios visibles.
- [recetas_captura.csv](recetas_captura.csv): los 15 identificadores de recetas y sus referencias originales, fecha, texto de dosis, vía y observaciones.

Los CSV son archivos de texto que puedes abrir en un editor o importar en una hoja de cálculo con codificación UTF-8. El generador los lee directamente, así que los datos del compañero forman parte de la carga ampliada.

## Dónde quedaron en la estructura

| Prototipo del compañero | Modelo del proyecto |
| --- | --- |
| Nombre y apellido del médico | `personal` |
| Cédula profesional | `medicos` |
| Especialidad | `especialidades` y `medico_especialidad` |
| Paciente y médico de la receta | `consultas`, referenciada por `recetas` |
| Fecha y observaciones | `recetas` |
| Medicamento, dosis y vía | `receta_detalle` |
| Camilla de una estancia | `hospitalizaciones` y `asignaciones_camilla` |
| Existencia del medicamento | Lotes y movimientos; consulta `v_stock_medicamentos` |

La muestra inicial ya utiliza ciertos identificadores. Para conservarla se asignaron nuevos IDs al aporte. Los CSV incluyen el destino de cada fila:

| Referencia original | Destino en la demostración |
| --- | --- |
| Médicos 1–15 | Médicos y personal 9–23; conservan CP-1001 a CP-1015 |
| Pacientes referidos 101–115 | Pacientes ficticios 6–20 |
| Recetas 1–15 | Recetas 26–40, con consultas 31–45 |
| Medicamentos referidos 1–15 | Medicamentos ficticios 1–15, asociación provisional para el ejercicio |

Las últimas dos consultas de `06_ver_datos.sql` muestran solo este aporte. El nombre de Ana Gómez y su especialidad **Urgencias**, por ejemplo, se conservan en la relación correspondiente; Javier Jiménez, Patricia Ruiz y Roberto Díaz también están incluidos.

## Lo que las capturas no permiten confirmar

No se ven los registros de pacientes ni los nombres, presentaciones y existencias de los medicamentos. La demostración completa esas relaciones con datos ficticios. **El medicamento de destino no se identifica como el producto original del compañero**: tener el mismo número no demuestra que sea el mismo medicamento. Cuando el equipo disponga del SQL de esas tablas, habrá que revisar y reemplazar esa correspondencia provisional.

La fecha de las recetas es 10 de octubre de 2026; la hora no aparece. Se agregaron horas de prueba, consultas y citas para completar el flujo. La duración que no se indica se representa con un día y la cantidad con una unidad, como valores docentes. La receta original 4 sí menciona siete días y conserva ese dato. Estas adiciones se declaran en las observaciones de las recetas; las dosis y vías transcritas no constituyen indicaciones para uso clínico.

Los horarios se conservaron en el CSV. El modelo de 36 tablas no representa turnos laborales ni días de trabajo, así que esos horarios no restringen automáticamente las citas. Por ejemplo, el turno 20:00–08:00 de Ana cruza medianoche; convertirlo en disponibilidad requiere también fechas o días de turno, que no se muestran en las capturas.

Los IDs originales de camillas permanecen en el CSV y en las observaciones. No se asigna una estancia a partir de esa referencia: una receta no prueba por sí sola una hospitalización, y la captura no indica fechas de ingreso, alta ni ubicación de cada camilla. Los casos de hospitalización agregados tienen su propio historial ficticio consistente.

Así el equipo puede explicar qué aportó cada versión, ver los ejemplos funcionando y completar después los datos que faltan sin mezclar identificadores por accidente.
