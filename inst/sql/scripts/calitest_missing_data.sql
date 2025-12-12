
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

-- Estas colecciones no tienen disciplina
SELECT * 
FROM metages_body mb 
WHERE mb.disciplina_fk IS NULL
AND mb.body_type_fk IN (3, 5)
AND private = 0



-- Estas colecciones no tienen localidad
SELECT *
FROM metages_body mb 
left join metages_address ma 
on mb.address_fk = ma.address_id 
WHERE (ma.town IS NULL OR ma.town = '')
AND private = 0



