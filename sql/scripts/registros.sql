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

CREATE OR REPLACE VIEW registros AS

SELECT 
   mr.recurso_id, 
   mr.body_fk, 
   CASE
       WHEN mb.body_type_fk = 3 THEN 'coleccion'
       WHEN mb.body_type_fk = 5 THEN 'base de datos'
   END AS tipo_body,
   mr.numberOfRecords, 
   mr.url_ipt, 
   mr.title, 
   mtd.descripcion_dataset AS disciplina_def,
   ml.licencia, 
   mrc.categoria, 
   mr.publica_en_gbif,
   YEAR(COALESCE(mr.updated_when, mr.created_when)) AS ultima_actualizacion
FROM metages_recurso mr 
LEFT JOIN metages_recurso_cat mrc 
ON mr.recurso_cat_fk = mrc.recurso_cat_id 
LEFT JOIN metages_tipo_dataset mtd 
ON mr.tipo_dataset = CAST(mtd.tipo_dataset_id AS CHAR) OR mr.tipo_dataset = mtd.tipo_dataset 
LEFT JOIN metages_licencia ml 
ON mr.licence = ml.licencia_id 
LEFT JOIN metages_body mb  
ON mr.body_fk = mb.body_id 
WHERE mr.tipo_dataset <> '' 
AND mr.numberOfRecords <> 0 -- Quita checklists, metadata only y errores
AND mr.private = 0
AND mtd.tipo_dataset_id BETWEEN 12 AND 17 -- Solo recursos 
AND mb.body_type_fk IN (3, 5)
AND mb.disciplina_fk BETWEEN 6 AND 11
AND mb.private = 0
	
	
