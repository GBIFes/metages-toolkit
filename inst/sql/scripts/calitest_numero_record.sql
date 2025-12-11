-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-18
-- Última actualización: /
-- 
-- Descripción:
--   Esta vista compara el numero de records de una colección en diferentes 
--	 plataformas bajo el control de GBIF España.
-- 
-- 		Hay que extraer las consultas del portal y el registro de colecciones web
-- 		Hay que extraer las consultas de gbif.org
-- 		Hay que extraer las consultas de metages
-- 
-- 
-- Numero de records de una institucion
-- Estos numeros pueden diferir por varios motivos, siendo uno de ellos que no se hayan actualizado las ultimas versiones.



-- Cual es la diferencia entre institucion.registros_publicados, recurso.numberOfRecords y body.number_of_subunits??
-- recurso.numberOfRecords -> numero de filas en la tabla occurrence del recurso IPT
-- body.number_of_subunits -> Solo para colecciones biologicas, es el numero total aproximado de registros o ejemplares en la coleccion.
-- institucion.registros_publicados -> En teoria, numero de registros que tiene la institucion, aunque no todos esten digitalizados. 
--										Deberia ser igual a la suma de los recurso.numberOfRecords de los recursos de dicha institucion. 
--										Sin embargo, esto no es asi, es muy inferior al numero de registros. Puede confundirse con  
--										"Numero de registros publicados en GBIF" de la página en gbif.es de cada institucion, 
--										pero ese numero se asemeja mas a sum(mr.numberOfRecords)

-- Base de datos: gbif_wp
-- Vista: calitest_numero_records
-- ===================================================================

CREATE OR REPLACE VIEW calitest_numero_records AS


--	
-- EJEMPLO: Estación Biológica de Doñana. 2025-11-12
									
-- Occurrences in GBIF.ORG
-- https://www.gbif.org/publisher/6b8da9ca-0648-4df3-9f0a-d43ab20a9412
-- 878,124 
 
-- Records en colecciones.gbif.es
-- https://colecciones.gbif.es/public/show/in27?lang=en
-- 754,189
 
-- Records en registros.gbif.es
-- https://registros.gbif.es/occurrences/search?q=institution_uid:in27 
-- 736,386 records returned from 754,189

-- Records en test.gbif.es
-- https://test.gbif.es/instituciones/estacion-biologica-de-donana-csic/ 
-- 435,699

-- Records en gbif.es
-- https://gbif.es/instituciones/estacion-biologica-de-donana-csic/
-- 895,904

-- Sumatoria de TEST.metages_recurso.numberOfRecords
-- 429,181

-- Sumatoria de TEST.metages_body.number_of_subunits
-- 148,278

-- TEST.metages_institucion.registros_publicados
-- 98,467

-- Sumatoria de PROD.metages_recurso.numberOfRecords
-- 889,386

-- Sumatoria de PROD.metages_body.number_of_subunits
-- 163,188

-- PROD.metages_institucion.registros_publicados
-- 98,467


 
 -- recursos
SELECT SUM(mr.numberOfRecords), 
		mi.institucion_id, mi.Institucion_nombre,  mi.registros_publicados 
FROM metages_recurso mr
LEFT JOIN metages_institucion AS mi		ON mr.institucion_fk = mi.body_fk
WHERE mi.institucion_id = 199
GROUP BY mi.institucion_id, mi.Institucion_nombre,  mi.registros_publicados;
 
 
 -- subunits
SELECT SUM(mb.number_of_subunits) 
FROM metages_body mb 
WHERE mb.body_id IN (
	SELECT mi2.child_body_fk 
	FROM metages_ispartof mi2 
	WHERE mi2.parent_body_fk IN (
		SELECT mi.body_fk  
		FROM metages_institucion mi 
		WHERE mi.institucion_id = 199));
		

		
		
--   Esta vista compara metages_provision_ recurso o metages_recurso y
--   muestra recursos desactualizados		
    -- si el valor es positivo, metages_recurso esta desactualizado
    -- si el valor es negativo, metages_provision_recurso esta desactualizado
 
    SELECT mpr.recurso_fk, MAX(mpr.provision_cantidad)- MAX(mr.numberOfRecords) AS desactualizacionNRecords, 
    	mr.url_ipt, mr.title 
    FROM metages_provision_recurso mpr 
    LEFT JOIN metages_recurso mr 
    ON mpr.recurso_fk = mr.recurso_id 
    GROUP BY mpr.recurso_fk, mr.private 
    HAVING mr.private = 0
    AND desactualizacionNRecords <> 0
    ORDER BY desactualizacionNRecords