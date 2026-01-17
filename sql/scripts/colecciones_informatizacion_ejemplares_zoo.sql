-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-12-03
-- Descripción: Numero y porcentaje de ejemplares informatizados en las colecciones zoologicas
--              
-- Base de datos: gbif_wp
-- Vista: colecciones_informatizacion_ejemplares_zoo
-- ===================================================================


-- CREATE OR REPLACE VIEW colecciones_informatizacion_ejemplares_zoo AS


SELECT 
c.disciplina_subtipo_def AS Subdisciplina,
SUM(c.number_of_subunits) AS total_ejemplares,
CONCAT(ROUND(AVG(c.percent_database), 0), ' %') AS '% informat. (media)',
ROUND(SUM(c.number_of_subunits) * AVG(c.percent_database) / 100) AS `Nº ejemplares informat.`,
ROUND(SUM(c.number_of_subunits) * (100 - AVG(c.percent_database)) / 100) AS `Nº ejemplares no informat.`
FROM colecciones AS c
WHERE tipo_body = 'colección'
AND disciplina_def = 'Zoológica'
GROUP BY c.disciplina_subtipo_def

UNION ALL

SELECT 
'TOTAL' AS Subdisciplina,
SUM(c.number_of_subunits),
CONCAT(ROUND(SUM(c.number_of_subunits * c.percent_database) / SUM(c.number_of_subunits), 0), ' %') AS `% informat. (media)`,
ROUND(SUM(c.number_of_subunits * c.percent_database) / 100) AS `Nº ejemplares informat.`,
ROUND(SUM(c.number_of_subunits * (100 - c.percent_database)) / 100) AS `Nº ejemplares no informat.`
FROM colecciones AS c
WHERE tipo_body = 'colección'
AND disciplina_def = 'Zoológica';