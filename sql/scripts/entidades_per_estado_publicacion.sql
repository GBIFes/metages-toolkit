-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-01-26
-- Descripción: Vista que muestra el número de ENTIDADES por disciplina
--              derivada (única / Mixta) y estado de publicación en GBIF
--              (Publica / No publica), con totales generales.
-- Regla clave: una entidad publica si al menos una de sus colecciones publica
-- Base de datos: gbif_wp
-- Vista: entidades_per_estado_publicacion
-- ===================================================================

-- CREATE OR REPLACE VIEW entidades_per_estado_publicacion AS
WITH estados AS (
    SELECT TRUE AS publica_en_gbif
    UNION ALL
    SELECT FALSE
) ,

-- ===============================================================
-- Paso 1: Calcular disciplina y estado de publicación por entidad
-- ===============================================================
entidad_agregada AS (
    SELECT
        c.institucion_proyecto,
        CASE
            WHEN COUNT(DISTINCT c.disciplina_def) = 1
                THEN MAX(c.disciplina_def)
            ELSE 'Mixta'
        END AS disciplina_entidad,
        MAX(c.publica_en_gbif) AS publica_entidad
    FROM colecciones c
    WHERE c.institucion_proyecto IS NOT NULL
    GROUP BY c.institucion_proyecto
),

-- ===============================================================
-- Paso 2: Conteo por disciplina y estado (con ceros explícitos)
-- ===============================================================
conteo_disciplina AS (
    SELECT
        d.disciplina_entidad AS disciplina_def,
        CASE
            WHEN e.publica_en_gbif = TRUE  THEN 'Publica en GBIF'
            WHEN e.publica_en_gbif = FALSE THEN 'No publica en GBIF'
        END AS estado_publicacion,
        COALESCE(COUNT(ea.institucion_proyecto), 0) AS total_entidades
    FROM (
        SELECT DISTINCT disciplina_entidad
        FROM entidad_agregada
    ) AS d
    CROSS JOIN estados e
    LEFT JOIN entidad_agregada ea
        ON ea.disciplina_entidad = d.disciplina_entidad
       AND ea.publica_entidad = e.publica_en_gbif
    GROUP BY d.disciplina_entidad, e.publica_en_gbif
)

-- ===============================================================
-- Parte 1: Resultados por disciplina
-- Parte 2: Totales generales por estado
-- ===============================================================
SELECT
    disciplina_def,
    estado_publicacion,
    total_entidades
FROM conteo_disciplina

UNION ALL

SELECT
    'TOTAL GENERAL' AS disciplina_def,
    estado_publicacion,
    SUM(total_entidades) AS total_entidades
FROM conteo_disciplina
GROUP BY estado_publicacion

ORDER BY
    CASE
        WHEN disciplina_def = 'TOTAL GENERAL' THEN 2
        ELSE 1
    END,
    disciplina_def,
    estado_publicacion;
