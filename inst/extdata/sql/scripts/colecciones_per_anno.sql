-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-03
-- Descripción: Numero de colecciones integradas en metages cada anno y acumulada 
-- Base de datos: gbif_wp
-- Vista: colecciones_per_anno
-- 
-- ===================================================================

CREATE OR REPLACE VIEW colecciones_per_anno AS
SELECT 
    c.disciplina_def,
    c.fecha_alta_coleccion,
    COUNT(*) AS total_colecciones,
    SUM(COUNT(*)) OVER (
        PARTITION BY c.disciplina_def 
        ORDER BY c.fecha_alta_coleccion ASC
    ) AS acumulado
FROM colecciones AS c
GROUP BY c.disciplina_def, c.fecha_alta_coleccion

UNION ALL

SELECT 
    'TOTAL GENERAL' AS disciplina_def,
    c.fecha_alta_coleccion,
    COUNT(*) AS total_colecciones,
    SUM(COUNT(*)) OVER (ORDER BY c.fecha_alta_coleccion ASC) AS acumulado
FROM colecciones AS c
GROUP BY c.fecha_alta_coleccion

ORDER BY CASE 
        WHEN disciplina_def = 'TOTAL GENERAL' THEN 2 
        ELSE 1 
    END,
	disciplina_def, 
	fecha_alta_coleccion;