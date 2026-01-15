-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-01-15
-- Descripción: Numero de colecciones por subdisciplina zoologica
--              
-- Base de datos: gbif_wp
-- Vista: colecciones_por_subdisciplina_zoologica
-- ===================================================================

-- CREATE OR REPLACE VIEW colecciones_por_subdisciplina_zoologica AS



-- Numero total de registros documentados en metages
WITH totalcol AS (

	SELECT COUNT(*) AS total_colecciones
    FROM colecciones
    WHERE disciplina_def = 'Zoológica'
),

-- Numero total de ejemplares
totaleje AS (

	SELECT SUM(number_of_subunits) AS total_ejemplares
    FROM colecciones
    WHERE disciplina_def = 'Zoológica'
)

-- Ensamblaje
SELECT 
    c.disciplina_subtipo_def ,
	COUNT(*) AS numero_colecciones,
	CONCAT(ROUND(COUNT(*) / MAX(totalcol.total_colecciones) * 100, 2), '%') AS numero_colecciones_porcentaje,
    SUM(c.number_of_subunits) AS total_ejemplares
FROM colecciones AS c
CROSS JOIN totalcol
CROSS JOIN totaleje
WHERE disciplina_def = 'Zoológica'
GROUP BY c.disciplina_subtipo_def


UNION ALL

SELECT 'TOTAL' AS disciplina_subtipo_def, 
		totalcol.total_colecciones AS numero_colecciones,
		'100%' AS numero_colecciones_porcentaje,
	    totaleje.total_ejemplares
FROM totalcol
CROSS JOIN totaleje