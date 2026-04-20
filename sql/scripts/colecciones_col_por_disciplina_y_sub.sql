-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-04-10
-- Descripción: Numero de colecciones y registros por disciplina y subdisciplina
--              
-- Base de datos: gbif_wp
-- Vista: colecciones_col_por_disciplina_y_sub
-- ===================================================================


-- CREATE OR REPLACE VIEW colecciones_col_por_disciplina_y_sub AS 

SELECT
  disciplina,
  n_colecciones,
  n_colecciones_publican,
  n_registros_publicados
FROM (
  -- por disciplina
  SELECT
    c.disciplina_def AS disciplina,
    COUNT(*) AS n_colecciones,
    COUNT(
      CASE
        WHEN c.publica_en_gbif = 1 THEN 1
      END
    ) AS n_colecciones_publican,
	SUM(c.numberOfRecords) AS n_registros_publicados
  FROM colecciones c
  WHERE c.tipo_body = 'coleccion'
  GROUP BY c.disciplina_def

  UNION ALL
  
  -- por subdisciplina
  SELECT
    c.disciplina_subtipo_def AS disciplina,
    COUNT(*) AS n_colecciones,
    COUNT(
      CASE
        WHEN c.publica_en_gbif = 1 THEN 1
      END
    ) AS n_colecciones_publican,
	SUM(c.numberOfRecords) AS n_registros_publicados
  FROM colecciones c
  WHERE c.tipo_body = 'coleccion'
  AND disciplina_subtipo_def IS NOT NULL
  GROUP BY c.disciplina_subtipo_def

  UNION ALL

  -- TOTAL disciplinas
  SELECT
    'TOTAL' AS disciplina,
    COUNT(*) AS n_colecciones,
    COUNT(
      CASE
        WHEN c.publica_en_gbif = 1 THEN 1
      END
    ) AS n_colecciones_publican,
	SUM(c.numberOfRecords) AS n_registros_publicados
  FROM colecciones c
  WHERE c.tipo_body = 'coleccion'
) AS t;
