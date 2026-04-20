-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-01-30
-- Descripción: Numero de colecciones por disciplina
--              
-- Base de datos: gbif_wp
-- Vista: col_por_disciplina
-- ===================================================================


-- CREATE OR REPLACE VIEW col_por_disciplina AS



-- Numero total de registros documentados en metages
WITH totalcol AS (

	SELECT COUNT(*) AS total_colecciones
    FROM colecciones
    WHERE tipo_body = 'coleccion'
),

-- Numero total de ejemplares
totaleje AS (

	SELECT SUM(number_of_subunits) AS total_ejemplares
    FROM colecciones
    WHERE tipo_body = 'coleccion'
)

-- Ensamblaje
SELECT 
    c.disciplina_def,
	COUNT(*) AS numero_colecciones,
	CONCAT(ROUND(COUNT(*) / MAX(totalcol.total_colecciones) * 100, 2), '%') AS numero_colecciones_porcentaje,
    SUM(c.number_of_subunits) AS total_ejemplares
FROM colecciones AS c
CROSS JOIN totalcol
CROSS JOIN totaleje
WHERE tipo_body = 'coleccion'
GROUP BY c.disciplina_def


UNION ALL

SELECT 'TOTAL' AS disciplina_def, 
		totalcol.total_colecciones AS numero_colecciones,
		'100%' AS numero_colecciones_porcentaje,
	    totaleje.total_ejemplares
FROM totalcol
CROSS JOIN totaleje