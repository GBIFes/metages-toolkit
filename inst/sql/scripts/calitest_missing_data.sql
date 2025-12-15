
-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-12-12
-- Última actualización: -
-- 
-- Descripción:
--   Este check muestra colecciones que deberian tener algun valor obligatorio
--   y no lo tienen. Dejandolos fuera de calculos y metricas 
-- 
-- Base de datos: gbif_wp
-- calitest_missing_data
-- ===================================================================

-- Estos bodies no tienen disciplina
SELECT mb.body_id, mb.citation, mb.disciplina_fk   
FROM metages_body mb 
WHERE (mb.disciplina_fk IS NULL OR mb.disciplina_fk = '')
AND mb.body_type_fk IN (3, 5)
AND private = 0
ORDER BY body_type_fk 


-- Estas colecciones ZOOLOGICAS Y BOTANICAS no tienen subdisciplina
SELECT *
FROM colecciones c 
WHERE c.disciplina_id IN (6, 8)
AND c.body_id NOT IN (SELECT mbds.body_fk 
						FROM metages_body_disciplina_subtipo mbds )


-- Estos bodies no tienen localidad
SELECT ma.address_id , mb.citation 
FROM metages_body mb 
LEFT JOIN metages_address ma 
ON mb.address_fk = ma.address_id 
WHERE (ma.town IS NULL OR ma.town = '')
AND private = 0


-- Estas colecciones no tienen 'acceso_informatizado'
SELECT * FROM colecciones c  
WHERE c.acceso_informatizado  IS NULL 
OR c.acceso_informatizado = ''

-- Estas colecciones no tienen 'acceso_informatizado'
SELECT * FROM colecciones c  
WHERE c.acceso_informatizado  IS NULL 
OR c.acceso_informatizado = ''


-- Estas colecciones no tienen 'condiciones_col'
SELECT * FROM colecciones c  
WHERE c.condiciones_col  IS NULL 
OR c.condiciones_col = ''


-- Estas colecciones no tienen 'acceso_col'
SELECT * FROM colecciones c  
WHERE c.acceso_col  IS NULL 
OR c.acceso_col = ''


-- Estas colecciones no tienen 'medio_acceso'
SELECT * FROM colecciones c  
WHERE c.medio_acceso  IS NULL 
OR c.medio_acceso = ''


-- Estas colecciones no tienen 'software_gestion_col'
SELECT * FROM colecciones c  
WHERE (c.software_gestion_col IS NULL OR c.software_gestion_col = '')
AND c.tipo_body = 'colección'