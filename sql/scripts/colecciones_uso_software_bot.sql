-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-01-17
-- Descripción: Vista que muestra el uso de los softwares de las  
--              colecciones botánicas y su relacion con los registros 
--              publicados.
-- Base de datos: gbif_wp
-- Vista: colecciones_uso_software_bot
-- 
-- ===================================================================

-- CREATE OR REPLACE VIEW colecciones_uso_software_bot AS

WITH soft AS (
    SELECT
        COALESCE(software_gestion_col, 'Sin especificar') AS software_gestion_col,
        COUNT(*) AS total_colecciones
    FROM colecciones
    WHERE disciplina_def = 'Botánica'
    AND tipo_body = 'coleccion'
    GROUP BY COALESCE(software_gestion_col, 'Sin especificar')
),
soft_pub AS (
    SELECT
        COALESCE(software_gestion_col, 'Sin especificar') AS software_gestion_col,
        COUNT(*) AS colecciones_publican,
        SUM(numberOfRecords) AS registros_publicados
    FROM colecciones
    WHERE disciplina_def = 'Botánica'
      AND tipo_body = 'coleccion'
      AND publica_en_gbif = 1
    GROUP BY COALESCE(software_gestion_col, 'Sin especificar')
)

-- 🔹 Tabla por software
SELECT
    s.software_gestion_col AS Software,
    s.total_colecciones AS `Nº total de colecciones`,
    COALESCE(p.colecciones_publican, 0)
        AS `Nº de colecciones que publican datos en GBIF`,
    COALESCE(p.registros_publicados, 0)
        AS `Nº total de registros publicados`
FROM soft s
LEFT JOIN soft_pub p
    ON s.software_gestion_col = p.software_gestion_col

UNION ALL

-- 🔹 Fila TOTAL
SELECT
    'TOTAL' AS Software,
    SUM(s.total_colecciones),
    SUM(COALESCE(p.colecciones_publican, 0)),
    SUM(COALESCE(p.registros_publicados, 0))
FROM soft s
LEFT JOIN soft_pub p
    ON s.software_gestion_col = p.software_gestion_col;
