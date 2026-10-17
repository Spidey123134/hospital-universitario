# Datos completos para presentar el proyecto

La base conserva **36 tablas y 789 registros relacionados**. Se completaron nombres, apellidos, domicilios y contactos para que las personas y empresas del ejercicio tengan datos comprensibles. Los identificadores de los registros y sus relaciones siguen siendo los mismos.

## Qué se completó

- Nombres y apellidos del personal y de los pacientes que todavía tenían textos como «Ejemplo» o «Paciente Uno».
- **95 teléfonos de diez dígitos**, repartidos entre personal, pacientes, contactos de emergencia, aseguradoras y proveedores.
- **59 correos** derivados del nombre de la persona o empresa, como `elena.marquez.1@example.com`.
- Domicilios de pacientes y nombres de contactos de emergencia, aseguradoras y proveedores.
- Códigos de empleados, expedientes, departamentos, habitaciones, camillas, pólizas y lotes.

Estos datos son **ficticios**. Los teléfonos tienen formato mexicano, pero no se comprobó si pertenecen a alguien; no se deben utilizar para contactar personas. Los correos usan `example.com`, un [dominio reservado para ejemplos por IANA](https://www.iana.org/help/example-domains), y no representan buzones del equipo. Ninguna cédula se presenta como una acreditación profesional verificada.

## Qué se conservó

Los **15 médicos que aportó el compañero conservan sus nombres y cédulas**. También se conservan las fechas, las cantidades, las relaciones entre tablas y los historiales clínicos y contables: recetas, movimientos, facturas, pagos y resultados anteriores.

Por eso algunos textos históricos todavía identifican el ejercicio como demostración. Los medicamentos, dosis y tratamientos del proyecto siguen siendo material académico; completar los contactos no valida tratamientos médicos. Las cuentas de usuario inactivas conservan sus valores de prueba: esta actualización no crea un inicio de sesión para empleados.

## Si vas a instalar la base ahora

Usa [hospital_universitario_respaldo.sql](entrega_base/hospital_universitario_respaldo.sql) y sigue [BASE_DE_DATOS.md](BASE_DE_DATOS.md). **El respaldo ya contiene esta actualización**. Después de importarlo puedes abrir las tablas en MySQL Workbench y ver los datos completos. Python queda para una etapa aparte.

## Si tu copia todavía tiene los contactos anteriores

1. Exporta un respaldo de tu copia antes de cambiarla: en Workbench, abre **Server → Data Export**, selecciona tu base y guarda el archivo.
2. Abre [07_contactos_y_catalogos.sql](07_contactos_y_catalogos.sql) con **File → Open SQL Script**.
3. Comprueba que estás conectado al servidor donde está tu copia de `hospital_universitario`.
4. Activa la opción de detener la ejecución si ocurre un error y ejecuta el archivo completo. Si aparece un error, detente y ejecuta `ROLLBACK;` en la misma conexión; no continúes hasta `COMMIT`.
5. Vuelve a abrir `pacientes` y `personal` para ver los nombres y contactos actualizados.

El archivo 07 cambia cada campo solamente cuando todavía coincide con el valor original de la muestra. Así conserva los campos que el equipo ya haya editado. En una copia modificada, revisa el resultado: puede contener una combinación de datos del equipo y datos de esta actualización. No agrega filas ni reemplaza un respaldo.

## Si reconstruyes todo con los archivos de diseño

Los archivos originales se conservan para poder repetir los tutoriales y sus comprobaciones. La secuencia desde cero es **01 → 02 → 03 → 05 → 07**. Como alternativa, `hospital_demostracion.sql` reúne 01, 02, 03 y 05; después se ejecuta 07. No ejecutes ambos caminos sobre la misma base.

Esta secuencia es para una base nueva. Si ya tienes la base importada del respaldo actual, no necesitas reconstruirla ni repetir esos archivos.
