


-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-12-01
-- Descripción: Numero de registros por disciplina
--              
-- Base de datos: gbif_wp
-- Vista: registros_por_disciplina
-- ===================================================================


-- CREATE OR REPLACE VIEW registros_por_disciplina AS

-- Numero total de registros documentados en metages
WITH total AS (

	SELECT SUM(numberOfRecords) AS total_records
    FROM registros AS r 
)
    
    
-- Calculo de porcentajes y numero de records por disciplina
SELECT r.disciplina_def, 
	   SUM(r.numberOfRecords) AS records,
	   CONCAT(ROUND(SUM(r.numberOfRecords) / MAX(total.total_records) * 100, 2),
	   		  '%') AS porcentaje
FROM registros AS r
CROSS JOIN total
GROUP BY disciplina_def

UNION ALL

SELECT 'TOTAL' AS disciplina_def, 
		MAX(total.total_records) AS records,
		'100%' AS porcentaje
FROM total




