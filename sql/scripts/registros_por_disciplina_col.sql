-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-12-01
-- Descripción: Numero de registros por disciplina para las colecciones
--              
-- Base de datos: gbif_wp
-- Vista: registros_por_disciplina_col
-- ===================================================================


-- CREATE OR REPLACE VIEW registros_por_disciplina_col AS

-- Numero total de registros documentados en metages
WITH total AS (

	SELECT SUM(numberOfRecords) AS total_records
    FROM registros AS r 
    WHERE r.tipo_body = "coleccion"
)
    
    
-- Calculo de porcentajes y numero de records por disciplina
SELECT r.disciplina_def AS 'Disciplina', 
	   SUM(r.numberOfRecords) AS 'Nº de registros publicados',
	   CONCAT(ROUND(SUM(r.numberOfRecords) / MAX(total.total_records) * 100, 2),
	   		  '%') AS '% registros publicados'
FROM registros AS r
CROSS JOIN total
WHERE r.tipo_body = "coleccion"
GROUP BY disciplina_def

UNION ALL

SELECT 'TOTAL' AS 'Disciplina', 
		MAX(total.total_records) AS 'Nº de registros publicados',
		'100%' AS '% registros publicados'
FROM total




