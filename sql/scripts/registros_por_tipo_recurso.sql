-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-04-13
-- Descripción: Vista de numero de recursos y registros divididos
--              por tipo de recurso.
-- Base de datos: gbif_wp
-- Vista: registros_por_tipo_recurso
-- 
-- ===================================================================

-- CREATE OR REPLACE VIEW registros_por_tipo_recurso AS

SELECT r.tipo_recurso AS `Tipo recurso`,
		COUNT(*) AS `Nº recursos`,
		SUM(r.numberOfRecords) AS `Nº registros publicados`
FROM registros AS r 
WHERE r.tipo_recurso IS NOT NULL -- Solo recursos con tipo_recurso
GROUP BY r.tipo_recurso

UNION ALL

SELECT 
'TOTAL',
COUNT(*) AS `Nº recursos`,
SUM(r.numberOfRecords) AS `Nº registros publicados`
FROM registros AS r
WHERE r.tipo_recurso IS NOT NULL -- Solo recursos con tipo_recurso











