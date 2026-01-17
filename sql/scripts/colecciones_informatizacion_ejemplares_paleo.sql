-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-01-17
-- Descripción: Numero y porcentaje de ejemplares informatizados en las colecciones Paleontologicas
--              
-- Base de datos: gbif_wp
-- Vista: colecciones_informatizacion_ejemplares_paleo
-- ===================================================================


-- CREATE OR REPLACE VIEW colecciones_informatizacion_ejemplares_paleo AS


SELECT 
COUNT(*) AS `Nº colecciones`,
SUM(c.number_of_subunits) AS `Nº ejemplares total`,
CONCAT(ROUND(AVG(c.percent_database), 0), ' %') AS '% informat. (media)',
ROUND(SUM(c.number_of_subunits) * AVG(c.percent_database) / 100) AS `Nº ejemplares informat.`,
ROUND(SUM(c.number_of_subunits) * (100 - AVG(c.percent_database)) / 100) AS `Nº ejemplares no informat.`
FROM colecciones AS c
WHERE tipo_body = 'colección'
AND disciplina_def = 'Paleontológica'
GROUP BY c.disciplina_def