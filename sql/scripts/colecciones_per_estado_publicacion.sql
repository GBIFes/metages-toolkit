-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-03
-- Descripción: Vista que muestra el número de colecciones por disciplina 
--              y estado de publicación en GBIF (Publica / No publica / Sin información),
--              e incluye totales generales por estado.
-- Base de datos: gbif_wp
-- Vista: colecciones_per_estado_publicacion
-- ===================================================================

CREATE OR REPLACE VIEW colecciones_per_estado_publicacion AS
WITH estados AS (
    SELECT TRUE AS publica_en_gbif
    UNION ALL SELECT FALSE
),
conteo_disciplina AS (
    SELECT 
        d.disciplina_def,
        CASE 
            WHEN e.publica_en_gbif = TRUE THEN 'Publica en GBIF'
            WHEN e.publica_en_gbif = FALSE THEN 'No publica en GBIF'
        END AS estado_publicacion,
        COALESCE(COUNT(c.body_id), 0) AS total_colecciones
    FROM metages_disciplina d
    CROSS JOIN estados e
    LEFT JOIN colecciones c
        ON c.disciplina_id = d.disciplina_id
       AND (
            (c.publica_en_gbif = e.publica_en_gbif)
            OR (c.publica_en_gbif IS NULL AND e.publica_en_gbif IS NULL)
       )
    WHERE d.disciplina_id IN (
        SELECT DISTINCT disciplina_id FROM colecciones
    )
    GROUP BY d.disciplina_def, e.publica_en_gbif
)
-- ===================================================================
-- Parte 1: Resultados por disciplina
-- Parte 2: Totales por estado (sin distinguir disciplina)
-- ===================================================================
SELECT 
    disciplina_def,
    estado_publicacion,
    total_colecciones
FROM conteo_disciplina

UNION ALL

SELECT 
    'TOTAL GENERAL' AS disciplina_def,
    estado_publicacion,
    SUM(total_colecciones) AS total_colecciones
FROM conteo_disciplina
GROUP BY estado_publicacion

ORDER BY 
    CASE 
        WHEN disciplina_def = 'TOTAL GENERAL' THEN 2 
        ELSE 1 
    END,
    disciplina_def,
    estado_publicacion;
