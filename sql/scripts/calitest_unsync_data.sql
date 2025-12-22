-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-12-15
-- Última actualización: -
-- 
-- Descripción:
--   Este check muestra registros de metages donde la informacion no esta 
--	 sincronizada con las tablas con las que deberia. 
-- 
-- Base de datos: gbif_wp
-- calitest_unsync_data
-- ===================================================================

-- Las localidades de estas direcciones no esta registrada en metages_towns
SELECT DISTINCT ma.town 
FROM metages_address ma
LEFT JOIN metages_body mb 
ON ma.address_id = mb.address_fk 
WHERE ma.town NOT IN (SELECT mt.town FROM metages_towns mt)
AND private = 0


SELECT * 
FROM metages_address ma
LEFT JOIN metages_body mb 
ON ma.address_id = mb.address_fk 
WHERE ma.town NOT IN (SELECT mt.town FROM metages_towns mt)
AND mb.private = 0




