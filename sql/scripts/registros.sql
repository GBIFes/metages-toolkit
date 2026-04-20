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
   md.disciplina_def,
   ml.licencia, 
   mt.name AS tipo_recurso,
   mrc.categoria, 
   mr.publica_en_gbif,
   YEAR(COALESCE(mr.updated_when, mr.created_when)) AS ultima_actualizacion
FROM metages_recurso mr 
LEFT JOIN metages_recurso_cat mrc                              -- Anhadir sector de los recursos
ON mr.recurso_cat_fk = mrc.recurso_cat_id 
LEFT JOIN metages_licencia ml                                  -- Anhadir licencia
ON mr.licence = ml.licencia_id 
LEFT JOIN metages_body mb  
ON mr.body_fk = mb.body_id
LEFT JOIN metages_disciplina AS md								-- Anhadir disciplina de la coleccion (Zoologica, Botanica, etc)  
ON mb.disciplina_fk = md.disciplina_id
LEFT JOIN metages_types mt 
ON mr.Tipo_recurso = mt.types_id 
WHERE mr.numberOfRecords <> 0                                   -- Quita checklists, metadata only y errores
AND mr.private = 0
AND mb.body_type_fk IN (3, 5)
AND mb.disciplina_fk BETWEEN 6 AND 11
AND mrc.recurso_cat_id IN (1,2,3,4)
AND mb.private = 0
AND mt.types_fk = 10
AND mr.body_fk <> 48                                            -- Quita recursos expatriados

	
