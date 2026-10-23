# Catálogo de medicamentos del proyecto

El archivo `catalogo_medicamentos.json` contiene 15 productos con nombres, concentraciones, presentaciones y vías de administración documentados en fichas oficiales del Centro de Información de Medicamentos de la AEMPS (CIMA). Se consultaron el 22 de octubre de 2026. Las referencias verifican las características del producto; no certifican su comercialización en México.

Los identificadores 1 a 15 y los códigos `MED-001` a `MED-015` sirven para integrar el catálogo con las tablas existentes. Este archivo no contiene existencias, precios ni movimientos: aplicarlo requiere conservar los identificadores, las cantidades y las relaciones ya registradas.

El catálogo fue completado para el proyecto. Las capturas del compañero muestran identificadores y textos de recetas, pero no permiten recuperar con certeza el nombre del medicamento asociado a cada identificador. Por ello, esta correspondencia no se presenta como una transcripción de aquellos productos.

Todos los expedientes y las operaciones del proyecto son ficticios. El catálogo describe productos y no contiene pautas predeterminadas: `dosis` y `frecuencia` pertenecen al detalle de cada receta. La dosis expresa la cantidad por administración y la frecuencia indica cada cuánto se repite. La revisión del 23 de octubre sustituye el texto incompleto «Según orden médica» por cantidades explícitas en los registros propios del proyecto. Los textos del compañero se conservan como fueron transcritos en sus CSV. Las fichas enlazadas verifican formulación y presentación; no validan la selección, dosis, frecuencia, duración ni combinación de los tratamientos de esta práctica. Las recetas no deben utilizarse para atender personas.

| ID | Producto del catálogo | Característica comprobada y fuente oficial |
|---|---|---|
| 1 | Paracetamol | [CIMA: paracetamol 500 mg, comprimidos](https://cima.aemps.es/cima/dochtml/ft/84217/FT_84217.html). |
| 2 | Ibuprofeno | [CIMA: ibuprofeno 400 mg, comprimidos recubiertos](https://cima.aemps.es/cima/dochtml/ft/90114/FT_90114.html). |
| 3 | Amoxicilina | [CIMA: polvo para suspensión oral de 250 mg/5 mL y frasco de 100 mL](https://cima.aemps.es/cima/dochtml/ft/89319/FT_89319.html). |
| 4 | Omeprazol | [CIMA: omeprazol 20 mg, cápsulas gastrorresistentes](https://cima.aemps.es/cima/dochtml/ft/74958/FT_74958.html). |
| 5 | Ketorolaco trometamol | [CIMA: solución inyectable de 30 mg/mL, ampolla de 1 mL; vías intravenosa e intramuscular](https://cima.aemps.es/cima/dochtml/ft/84357/FT_84357.html). El catálogo selecciona la vía intravenosa para la captura. |
| 6 | Salbutamol | [CIMA: 100 microgramos por dosis, inhalador de 200 aplicaciones](https://cima.aemps.es/cima/dochtml/p/65850/P_65850.html). |
| 7 | Loratadina | [CIMA: loratadina 10 mg, comprimidos](https://cima.aemps.es/cima/dochtml/ft/63946/FT_63946.html). |
| 8 | Metformina | [CIMA: 850 mg de hidrocloruro de metformina por comprimido recubierto](https://cima.aemps.es/cima/dochtml/ft/68167/FichaTecnica_68167.html). La concentración corresponde a la sal del principio activo. |
| 9 | Losartán potásico | [CIMA: losartán potásico 50 mg, comprimidos recubiertos](https://cima.aemps.es/cima/dochtml/ft/67776/FichaTecnica_67776.html). |
| 10 | Diclofenaco sódico | [CIMA: gel de 10 mg/g en tubo de 60 g, uso cutáneo](https://cima.aemps.es/cima/dochtml/p/70538/Prospecto.html). Diez miligramos por gramo equivalen al 1 % en masa. |
| 11 | Insulina humana | [CIMA: solución de insulina humana de 100 UI/mL, vial de 10 mL](https://cima.aemps.es/cima/dochtml/ft/02230003/FT_02230003.html). La referencia corresponde a insulina de acción rápida; el catálogo no atribuye una pauta nocturna ni intercambiabilidad con otras insulinas. |
| 12 | Ceftriaxona | [CIMA: 1 g por vial, polvo para solución inyectable intravenosa](https://cima.aemps.es/cima/dochtml/ft/66753/FichaTecnica_66753.html). La concentración tras reconstitución depende del producto y no se calcula en el proyecto. |
| 13 | Diazepam | [CIMA: solución inyectable de 5 mg/mL, ampolla de 2 mL con 10 mg](https://cima.aemps.es/cima/dochtml/ft/39943/FichaTecnica_39943.html). La presentación admite vía intramuscular o intravenosa; aquí se selecciona intramuscular. |
| 14 | Hidrocortisona | [CIMA: 100 mg por vial, polvo y disolvente para solución inyectable o perfusión](https://cima.aemps.es/cima/dochtml/ft/88465/FT_88465.html). |
| 15 | Furosemida | [CIMA: furosemida 40 mg, comprimidos por vía oral](https://cima.aemps.es/cima/dochtml/ft/83588/FT_83588.html). |

Se usa la palabra «tableta» como etiqueta de captura equivalente a «comprimido». Las marcas de las fichas se usan únicamente como referencias de formulación; no se incorporan al catálogo ni se afirma que sean proveedores del hospital.
