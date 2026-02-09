-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-01-28
-- Descripción: Vista de numero de recursos y registros divididos
--              por sector.
-- Base de datos: gbif_wp
-- Vista: registros_por_sector
-- 
-- ===================================================================

-- CREATE OR REPLACE VIEW registros_por_sector AS


SELECT r.categoria AS Sectores,
		COUNT(*) AS `Nº recursos`,
		SUM(r.numberOfRecords) AS `Nº registros publicados`
FROM registros AS r 
WHERE r.categoria IS NOT NULL -- Solo recursos con categoria
AND r.categoria <> 'Extranjera' -- Solo categorias nacionales
GROUP BY r.categoria

UNION ALL

SELECT 
'TOTAL',
COUNT(*) AS `Nº recursos`,
SUM(r.numberOfRecords) AS `Nº registros publicados`
FROM registros AS r
WHERE r.categoria IS NOT NULL -- Solo recursos con categoria
AND r.categoria <> 'Extranjera' -- Solo categorias nacionales;









