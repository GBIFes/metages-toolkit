-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-03
-- Descripción: Vista que muestra el número de colecciones por disciplina 
--              y estado de publicación en GBIF (Publica / No publica / Sin información),
--              e incluye totales generales por estado.
-- Base de datos: gbif_wp
-- Vista: colecciones_per_estado_publicacion
-- ===================================================================

-- CREATE OR REPLACE VIEW colecciones_per_estado_publicacion AS
WITH estados AS (
    SELECT TRUE AS publica_en_gbif
    UNION ALL
    SELECT FALSE
),

disciplinas AS (
    SELECT DISTINCT disciplina_def
    FROM colecciones
    WHERE disciplina_def IS NOT NULL
),

conteo AS (
    SELECT
        d.disciplina_def,
        e.publica_en_gbif,
        COUNT(c.body_id) AS total_colecciones
    FROM disciplinas d
    CROSS JOIN estados e
    LEFT JOIN colecciones c
        ON c.disciplina_def = d.disciplina_def
       AND c.publica_en_gbif = e.publica_en_gbif
    GROUP BY
        d.disciplina_def,
        e.publica_en_gbif
)


-- ===================================================================
-- Parte 1: Resultados por disciplina
-- Parte 2: Totales por estado (sin distinguir disciplina)
-- ===================================================================

SELECT
    disciplina_def,
    CASE
        WHEN publica_en_gbif = TRUE  THEN 'Publica en GBIF'
        WHEN publica_en_gbif = FALSE THEN 'No publica en GBIF'
    END AS estado_publicacion,
    total_colecciones
FROM conteo

UNION ALL

SELECT
    'TOTAL GENERAL' AS disciplina_def,
    CASE
        WHEN publica_en_gbif = TRUE  THEN 'Publica en GBIF'
        WHEN publica_en_gbif = FALSE THEN 'No publica en GBIF'
    END AS estado_publicacion,
    SUM(total_colecciones)
FROM conteo
GROUP BY publica_en_gbif

ORDER BY
    CASE
        WHEN disciplina_def = 'TOTAL GENERAL' THEN 2
        ELSE 1
    END,
    disciplina_def,
    estado_publicacion;
