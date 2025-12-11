-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-04
-- Descripción: Vista base que consolida la información de todos los 
--              registros, incluyendo 
--              los datos de disciplina, url numero de records y licencia.
-- Base de datos: gbif_wp
-- Vista: registros
-- 
-- ===================================================================

-- CREATE OR REPLACE VIEW registros AS


    SELECT mr.recurso_id, mr.body_fk, mr.numberOfRecords, 
    	   mr.url_ipt, mr.title, mtd.descripcion_dataset AS disciplina_def,
    	   ml.licencia, mr.publica_en_gbif,
           YEAR(COALESCE(mr.updated_when, mr.created_when)) AS ultima_actualizacion
	FROM metages_recurso mr 
	LEFT JOIN metages_tipo_dataset mtd 
	ON mr.tipo_dataset = CAST(mtd.tipo_dataset_id AS CHAR) OR mr.tipo_dataset = mtd.tipo_dataset 
	LEFT JOIN metages_licencia ml 
	ON mr.licence = ml.licencia_id 
	WHERE mr.tipo_dataset <> '' 
	AND mr.numberOfRecords <> 0 -- Quita checklists, metadata only y errores
	AND mr.private = 0
	AND mtd.tipo_dataset_id BETWEEN 12 AND 17 -- Solo recursos 
	
	
