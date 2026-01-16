-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-01-15
-- Descripción: Numero de colecciones por subdisciplina zoologica
--              
-- Base de datos: gbif_wp
-- Vista: colecciones_por_subdisciplina_zoologica
-- ===================================================================

-- CREATE OR REPLACE VIEW colecciones_por_subdisciplina_zoologica AS




-- Numero total de colecciones documentados en metages
WITH totalcol AS (

	SELECT COUNT(*) AS total_colecciones
    FROM colecciones
    WHERE disciplina_def = 'Zoológica'
    AND tipo_body = 'coleccion'
),

-- Numero total de ejemplares
totaleje AS (

	SELECT SUM(number_of_subunits) AS total_ejemplares
    FROM colecciones
    WHERE disciplina_def = 'Zoológica'
    AND tipo_body = 'coleccion'
),

-- Numero total de registros publicados
totalreg AS (

	SELECT SUM(numberOfRecords) AS total_registros
    FROM colecciones
    WHERE disciplina_def = 'Zoológica'
    AND tipo_body = 'coleccion'
)

-- Ensamblaje
SELECT 
    c.disciplina_subtipo_def AS Subdisciplina,
	CONCAT(COUNT(*), ' (',
			CONCAT(ROUND(COUNT(*) / MAX(totalcol.total_colecciones) * 100, 0), '%'),
			')') AS `Nº colecciones (porcentaje)`,
    SUM(c.number_of_subunits) AS `Nº ejemplares`,
    SUM(c.numberOfRecords) AS `Nº registros publicados`
FROM colecciones AS c
CROSS JOIN totalcol
CROSS JOIN totaleje
CROSS JOIN totalreg
WHERE disciplina_def = 'Zoológica'
AND c.tipo_body = 'coleccion'
GROUP BY c.disciplina_subtipo_def


UNION ALL

SELECT 'TOTAL' AS Subdisciplina, 
		CONCAT(totalcol.total_colecciones,
				' (100%)') AS `Nº colecciones (porcentaje)`,
	    totaleje.total_ejemplares AS `Nº ejemplares`,
	    totalreg.total_registros AS `Nº registros publicados`
FROM totalcol
CROSS JOIN totaleje
CROSS JOIN totalreg