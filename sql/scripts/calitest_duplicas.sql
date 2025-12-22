-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-18
-- Última actualización: 2025-11-28
-- 
-- Descripción:
--   Este check ejemplifica duplicas en varias tablas 
-- 
-- Base de datos: gbif_wp
-- calitest_duplicas
-- ===================================================================

-- Persona repetida
WITH luis AS (
	SELECT *  FROM metages_person mp 
	WHERE mp.family_name LIKE '%Guasch%'
)

SELECT * FROM metages_personas mp 
WHERE mp.person_fk IN (SELECT person_id FROM luis);



-- Keywords duplicadas
SELECT keyword, COUNT(*) 
FROM metages_keyword mk 
GROUP BY keyword 
HAVING keyword IS NOT NULL
ORDER BY count(*) DESC;