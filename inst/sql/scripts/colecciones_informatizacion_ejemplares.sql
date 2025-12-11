-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-12-03
-- Descripción: Numero y porcentaje de ejemplares informatizados en las colecciones
--              
-- Base de datos: gbif_wp
-- Vista: colecciones_informatizacion_ejemplares
-- ===================================================================


-- CREATE OR REPLACE VIEW colecciones_informatizacion_ejemplares AS


SELECT 
c.disciplina_def,
SUM(c.number_of_subunits) AS total_ejemplares,
ROUND(AVG(c.percent_database), 2) AS '%_ejemplares_informatizados (media)',
ROUND(SUM(c.number_of_subunits) * AVG(c.percent_database) / 100) AS ejemplares_informatizados,
ROUND(SUM(c.number_of_subunits) * (100 - AVG(c.percent_database)) / 100) AS ejemplares_no_informatizados
FROM colecciones AS c
WHERE tipo_body = 'colección'
GROUP BY c.disciplina_def

UNION ALL

SELECT 
'TOTAL',
SUM(c.number_of_subunits),
ROUND(SUM(c.number_of_subunits * c.percent_database) / SUM(c.number_of_subunits), 2) AS media_ponderada,
ROUND(SUM(c.number_of_subunits * c.percent_database) / 100) AS ejemplares_informatizados,
ROUND(SUM(c.number_of_subunits * (100 - c.percent_database)) / 100) AS ejemplares_no_informatizados
FROM colecciones AS c
WHERE tipo_body = 'colección';